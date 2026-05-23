use serde::Serialize;
use serde_json::{json, Value};
use std::collections::{hash_map::DefaultHasher, HashSet};
use std::fs;
use std::hash::{Hash, Hasher};
use std::io;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};
use std::sync::{Mutex, OnceLock};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tauri::{Emitter, Manager};

const SNAPSHOT_TIMEOUT: Duration = Duration::from_secs(10);
const MODEL_UPDATE_TIMEOUT: Duration = Duration::from_secs(12);
const JOB_CREATE_TIMEOUT: Duration = Duration::from_secs(30);
const CONTROLLED_ACTION_TIMEOUT: Duration = Duration::from_secs(30);
const MAX_JOB_REQUEST_CHARS: usize = 8000;
const MAX_ACTION_MESSAGE_CHARS: usize = 4000;
const MAX_SUMMARY_CHARS: usize = 4000;
const MAX_ROLE_ID_CHARS: usize = 64;
const MAX_MODEL_ID_CHARS: usize = 120;
const WATCH_SCAN_INTERVAL: Duration = Duration::from_millis(1500);
const WATCH_EVENT_COOLDOWN: Duration = Duration::from_millis(900);
const WATCH_SCAN_FILE_LIMIT: usize = 1800;

static ACTIVE_WORKSPACE_WATCHERS: OnceLock<Mutex<HashSet<String>>> = OnceLock::new();

#[derive(Debug, Clone, PartialEq, Eq)]
struct CreatedJob {
    job_id: String,
    job_path: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum SnapshotErrorKind {
    None,
    InvalidProject,
    MissingCli,
    CommandFailed,
    InvalidJson,
    Timeout,
    Io,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CommandResult {
    ok: bool,
    status_code: i32,
    stdout: String,
    stderr: String,
    command: Vec<String>,
    parsed: Option<Value>,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct JobCreateResult {
    ok: bool,
    status_code: i32,
    stdout: String,
    stderr: String,
    command: Vec<String>,
    job_id: Option<String>,
    job_path: Option<String>,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ControlledActionResult {
    ok: bool,
    status_code: i32,
    stdout: String,
    stderr: String,
    command: Vec<String>,
    action: String,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct WorkspaceChangedPayload {
    project_root: String,
    changed_at: String,
    file_count: usize,
    source: String,
}

fn redact_text(input: &str) -> String {
    input
        .split_whitespace()
        .map(|token| {
            if token.starts_with("sk-")
                || token.contains("OPENAI_API_KEY=")
                || token.contains("ANTHROPIC_API_KEY=")
            {
                "[REDACTED_SECRET]".to_string()
            } else {
                token.to_string()
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn validate_job_request(request: &str) -> Result<String, String> {
    let trimmed = request.trim();
    if trimmed.is_empty() {
        return Err("CEO job request is empty.".to_string());
    }
    if trimmed.chars().count() > MAX_JOB_REQUEST_CHARS {
        return Err(format!(
            "CEO job request exceeds {MAX_JOB_REQUEST_CHARS} characters."
        ));
    }
    Ok(trimmed.to_string())
}

fn validate_text_field(label: &str, value: &str, max_chars: usize) -> Result<String, String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err(format!("{label} is empty."));
    }
    if trimmed.chars().count() > max_chars {
        return Err(format!("{label} exceeds {max_chars} characters."));
    }
    Ok(trimmed.to_string())
}

fn validate_id(label: &str, value: &str, max_chars: usize) -> Result<String, String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err(format!("{label} is empty."));
    }
    if trimmed.chars().count() > max_chars {
        return Err(format!("{label} exceeds {max_chars} characters."));
    }
    if !trimmed
        .chars()
        .all(|ch| ch.is_ascii_alphanumeric() || ch == '-' || ch == '_')
    {
        return Err(format!("{label} contains unsupported characters."));
    }
    Ok(trimmed.to_string())
}

fn validate_job_id(job_id: &str) -> Result<String, String> {
    let value = validate_id("job id", job_id, 40)?;
    if !value.starts_with("JOB-") {
        return Err("job id must start with JOB-.".to_string());
    }
    Ok(value)
}

fn validate_model_id(label: &str, value: &str, max_chars: usize, allow_empty: bool) -> Result<String, String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        if allow_empty {
            return Ok(String::new());
        }
        return Err(format!("{label} is empty."));
    }
    if trimmed.chars().count() > max_chars {
        return Err(format!("{label} exceeds {max_chars} characters."));
    }
    if !trimmed.chars().all(|ch| {
        ch.is_ascii_alphanumeric() || matches!(ch, '-' | '_' | '.' | ':' | '/' | '@' | '+')
    }) {
        return Err(format!("{label} contains unsupported characters."));
    }
    Ok(trimmed.to_string())
}

fn build_followup_message(job_id: &str, message: &str) -> String {
    format!("[AgentDock UI follow-up for {job_id}]\n{message}")
}

fn build_broadcast_message(job_id: &str, message: &str) -> String {
    format!("[AgentDock UI selected-team broadcast for {job_id}]\n{message}")
}

fn build_task_proposal_message(job_id: &str, role: &str, proposal: &str) -> String {
    format!("[AgentDock UI task proposal for {job_id}]\nTarget role: {role}\n\nProposal:\n{proposal}\n\nDo not apply silently: review this proposal, update the task card if appropriate, and notify the selected team.")
}

fn build_job_create_args(request: &str) -> Vec<String> {
    vec![
        "job".to_string(),
        "--no-attach".to_string(),
        "--fast-return".to_string(),
        request.to_string(),
    ]
}

fn parse_created_job(text: &str) -> Option<CreatedJob> {
    let marker = "JOB-";
    let start = text.find(marker)?;
    let rest = &text[start..];
    let job_id: String = rest
        .chars()
        .take_while(|ch| ch.is_ascii_alphanumeric() || *ch == '-')
        .collect();
    if job_id.len() <= marker.len() {
        return None;
    }

    let before = &text[..start];
    let path_start = before
        .rfind(|ch: char| ch.is_whitespace())
        .map(|idx| idx + 1)
        .unwrap_or(0);
    let path_tail = &text[start..];
    let path_end = path_tail
        .find("/README.md")
        .map(|idx| start + idx)
        .or_else(|| {
            path_tail
                .find(|ch: char| ch.is_whitespace())
                .map(|idx| start + idx)
        })
        .unwrap_or(start + job_id.len());
    let job_path = text[path_start..path_end]
        .trim_matches(['`', ':'])
        .to_string();

    Some(CreatedJob { job_id, job_path })
}

fn directory_is_agentdock_project(path: &Path) -> bool {
    path.is_dir() && path.join(".agentdock").is_dir() && path.join(".agent-work").is_dir()
}

fn find_agentdock_project_ancestor(start: &Path) -> Option<PathBuf> {
    let mut current = if start.is_file() {
        start.parent()?
    } else {
        start
    };
    loop {
        if directory_is_agentdock_project(current) {
            return Some(current.to_path_buf());
        }
        current = current.parent()?;
    }
}

fn discover_agentdock_project_root() -> Option<PathBuf> {
    if let Ok(current_dir) = std::env::current_dir() {
        if let Some(root) = find_agentdock_project_ancestor(&current_dir) {
            return Some(root);
        }
    }
    if let Ok(current_exe) = std::env::current_exe() {
        if let Some(root) = find_agentdock_project_ancestor(&current_exe) {
            return Some(root);
        }
    }
    None
}

fn canonicalize_project_root(project_root: &str) -> Result<PathBuf, String> {
    let trimmed = project_root.trim();
    let is_default_root = trimmed.is_empty() || trimmed == ".";
    match fs::canonicalize(if trimmed.is_empty() { "." } else { trimmed }) {
        Ok(root) if !is_default_root || directory_is_agentdock_project(&root) => Ok(root),
        Ok(root) => discover_agentdock_project_root()
            .or(Some(root))
            .ok_or_else(|| {
                "Project root is not accessible and no AgentDock project ancestor was found."
                    .to_string()
            }),
        Err(error) => {
            if is_default_root {
                discover_agentdock_project_root().ok_or_else(|| {
                    format!("Project root is not accessible: {error}; no AgentDock project ancestor was found.")
                })
            } else {
                Err(format!("Project root is not accessible: {error}"))
            }
        }
    }
}

fn validate_agentdock_project(project_root: &Path) -> Result<(), String> {
    if !project_root.is_dir() {
        return Err("Project root is not a directory.".to_string());
    }
    let agentdock_dir = project_root.join(".agentdock");
    let agent_work_dir = project_root.join(".agent-work");
    if !agentdock_dir.is_dir() || !agent_work_dir.is_dir() {
        return Err(
            "Project root must contain .agentdock/ and .agent-work/ directories.".to_string(),
        );
    }
    Ok(())
}

fn resolve_agentdock(project_root: &Path) -> String {
    let project_bin = project_root.join("bin").join("agentdock");
    if project_bin.is_file() {
        project_bin.to_string_lossy().to_string()
    } else if let Ok(from_env) = std::env::var("AGENTDOCK_BIN") {
        from_env
    } else {
        "agentdock".to_string()
    }
}

fn project_root_from_args(fallback: &str) -> String {
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        if arg == "--project" {
            if let Some(value) = args.next() {
                return value;
            }
        } else if let Some(value) = arg.strip_prefix("--project=") {
            return value.to_string();
        }
    }
    fallback.to_string()
}

fn run_command_with_timeout(
    command: &str,
    args: &[String],
    cwd: &Path,
    timeout: Duration,
) -> io::Result<Result<Output, ()>> {
    let mut child = Command::new(command)
        .args(args)
        .current_dir(cwd)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    let started = Instant::now();
    loop {
        if child.try_wait()?.is_some() {
            return child.wait_with_output().map(Ok);
        }
        if started.elapsed() >= timeout {
            let _ = child.kill();
            let _ = child.wait_with_output();
            return Ok(Err(()));
        }
        thread::sleep(Duration::from_millis(25));
    }
}

fn unix_time_millis(time: SystemTime) -> u128 {
    time.duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis()
}

fn now_isoish() -> String {
    format!("{}", unix_time_millis(SystemTime::now()))
}

fn hash_workspace_entry(path: &Path, root: &Path, hasher: &mut DefaultHasher) -> io::Result<()> {
    let metadata = fs::metadata(path)?;
    path.strip_prefix(root)
        .unwrap_or(path)
        .to_string_lossy()
        .hash(hasher);
    metadata.is_dir().hash(hasher);
    metadata.len().hash(hasher);
    if let Ok(modified) = metadata.modified() {
        unix_time_millis(modified).hash(hasher);
    }
    Ok(())
}

fn should_skip_watch_path(path: &Path, root: &Path) -> bool {
    let relative = path.strip_prefix(root).unwrap_or(path).to_string_lossy();
    relative.starts_with(".agent-work/11_ARCHIVE")
        || relative.starts_with(".agent-work/16_WORKTREES")
        || relative.starts_with(".agentdock/generated")
        || relative.starts_with(".agentdock/prompts")
        || relative == ".agentdock/state/workspace-snapshot-cache.json"
        || relative.ends_with(".hash")
}

fn scan_workspace_dir(
    dir: &Path,
    root: &Path,
    hasher: &mut DefaultHasher,
    file_count: &mut usize,
) -> io::Result<()> {
    if *file_count >= WATCH_SCAN_FILE_LIMIT || !dir.exists() {
        return Ok(());
    }
    let mut entries = fs::read_dir(dir)?.collect::<Result<Vec<_>, io::Error>>()?;
    entries.sort_by_key(|entry| entry.path());
    for entry in entries {
        if *file_count >= WATCH_SCAN_FILE_LIMIT {
            break;
        }
        let path = entry.path();
        if should_skip_watch_path(&path, root) {
            continue;
        }
        if hash_workspace_entry(&path, root, hasher).is_err() {
            continue;
        }
        *file_count += 1;
        if entry
            .file_type()
            .map(|file_type| file_type.is_dir())
            .unwrap_or(false)
        {
            scan_workspace_dir(&path, root, hasher, file_count)?;
        }
    }
    Ok(())
}

fn workspace_change_signature(project_root: &Path) -> io::Result<(u64, usize)> {
    let mut hasher = DefaultHasher::new();
    let mut file_count = 0;
    for relative in [".agentdock", ".agent-work"] {
        let dir = project_root.join(relative);
        relative.hash(&mut hasher);
        hash_workspace_entry(&dir, project_root, &mut hasher)?;
        scan_workspace_dir(&dir, project_root, &mut hasher, &mut file_count)?;
    }
    Ok((hasher.finish(), file_count))
}

fn ensure_workspace_watcher(app: tauri::AppHandle, canonical_root: PathBuf) -> bool {
    let key = canonical_root.to_string_lossy().to_string();
    let watchers = ACTIVE_WORKSPACE_WATCHERS.get_or_init(|| Mutex::new(HashSet::new()));
    {
        let mut active = watchers.lock().expect("workspace watcher mutex poisoned");
        if !active.insert(key.clone()) {
            return false;
        }
    }

    thread::spawn(move || {
        let mut last_signature = workspace_change_signature(&canonical_root)
            .map(|(signature, _)| signature)
            .unwrap_or(0);
        let mut last_emit = Instant::now()
            .checked_sub(Duration::from_secs(10))
            .unwrap_or_else(Instant::now);
        loop {
            thread::sleep(WATCH_SCAN_INTERVAL);
            let Ok((signature, file_count)) = workspace_change_signature(&canonical_root) else {
                continue;
            };
            if signature == last_signature {
                continue;
            }
            last_signature = signature;
            if last_emit.elapsed() < WATCH_EVENT_COOLDOWN {
                continue;
            }
            last_emit = Instant::now();
            let payload = WorkspaceChangedPayload {
                project_root: key.clone(),
                changed_at: now_isoish(),
                file_count,
                source: "workspace_file_watch".to_string(),
            };
            let _ = app.emit("workspace_changed", payload);
        }
    });
    true
}

fn result_from_error(
    command: Vec<String>,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
) -> CommandResult {
    CommandResult {
        ok: false,
        status_code: -1,
        stdout: String::new(),
        stderr: redact_text(&message),
        command,
        parsed: None,
        error_kind,
        message: redact_text(&message),
        duration_ms,
    }
}

fn job_create_result_from_error(
    command: Vec<String>,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
) -> JobCreateResult {
    JobCreateResult {
        ok: false,
        status_code: -1,
        stdout: String::new(),
        stderr: redact_text(&message),
        command,
        job_id: None,
        job_path: None,
        error_kind,
        message: redact_text(&message),
        duration_ms,
    }
}

fn controlled_action_result_from_error(
    action: &str,
    command: Vec<String>,
    error_kind: SnapshotErrorKind,
    message: String,
    duration_ms: u128,
) -> ControlledActionResult {
    ControlledActionResult {
        ok: false,
        status_code: -1,
        stdout: String::new(),
        stderr: redact_text(&message),
        command,
        action: action.to_string(),
        error_kind,
        message: redact_text(&message),
        duration_ms,
    }
}

fn controlled_action_success(
    action: &str,
    command: Vec<String>,
    message: String,
    duration_ms: u128,
) -> ControlledActionResult {
    ControlledActionResult {
        ok: true,
        status_code: 0,
        stdout: String::new(),
        stderr: String::new(),
        command,
        action: action.to_string(),
        error_kind: SnapshotErrorKind::None,
        message: redact_text(&message),
        duration_ms,
    }
}

fn load_workspace_snapshot_value(canonical_root: &Path) -> Result<Value, String> {
    let agentdock = resolve_agentdock(canonical_root);
    let args = vec![
        "workspace".to_string(),
        "snapshot".to_string(),
        "--json".to_string(),
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    match run_command_with_timeout(&agentdock, &args, canonical_root, SNAPSHOT_TIMEOUT) {
        Ok(Ok(output)) => {
            if !output.status.success() {
                let stderr = redact_text(&String::from_utf8_lossy(&output.stderr));
                return Err(if stderr.is_empty() {
                    "workspace snapshot command failed.".to_string()
                } else {
                    stderr
                });
            }
            let stdout = String::from_utf8_lossy(&output.stdout);
            serde_json::from_str::<Value>(&stdout)
                .map_err(|error| format!("workspace snapshot returned invalid JSON: {error}"))
        }
        Ok(Err(())) => Err("workspace snapshot command timed out.".to_string()),
        Err(error) => Err(error.to_string()),
    }
}

fn active_job_path_from_snapshot(snapshot: &Value, job_id: &str) -> Result<String, String> {
    let snapshot_job_id = snapshot
        .get("job")
        .and_then(|job| job.get("id"))
        .and_then(Value::as_str)
        .unwrap_or("");
    if snapshot_job_id != job_id {
        return Err(format!(
            "active job mismatch: expected {job_id}, snapshot has {snapshot_job_id}. Refresh first."
        ));
    }
    let job_path = snapshot
        .get("job")
        .and_then(|job| job.get("path"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .trim();
    if job_path.is_empty() {
        return Err("active job path is missing from snapshot.".to_string());
    }
    Ok(job_path.to_string())
}

fn coordinator_role_from_snapshot(snapshot: &Value) -> Option<String> {
    let roles = snapshot.get("roles")?.as_array()?;
    roles
        .iter()
        .filter_map(|role| role.get("id").and_then(Value::as_str))
        .find(|id| id.contains("orchestrator") || *id == "ceo" || id.contains("ceo"))
        .map(ToString::to_string)
        .or_else(|| {
            roles
                .iter()
                .find(|role| {
                    role.get("selected")
                        .and_then(Value::as_bool)
                        .unwrap_or(false)
                })
                .and_then(|role| role.get("id").and_then(Value::as_str))
                .map(ToString::to_string)
        })
}

fn role_is_selected(snapshot: &Value, role_id: &str) -> bool {
    snapshot
        .get("roles")
        .and_then(Value::as_array)
        .map(|roles| {
            roles.iter().any(|role| {
                role.get("id").and_then(Value::as_str) == Some(role_id)
                    && role
                        .get("selected")
                        .and_then(Value::as_bool)
                        .unwrap_or(false)
            })
        })
        .unwrap_or(false)
}

fn snapshot_final_ready(snapshot: &Value) -> bool {
    snapshot
        .get("job")
        .and_then(|job| job.get("final_ready"))
        .and_then(Value::as_bool)
        .unwrap_or(false)
}

fn snapshot_final_reason(snapshot: &Value) -> String {
    snapshot
        .get("job")
        .and_then(|job| job.get("final_ready_reason"))
        .and_then(Value::as_str)
        .unwrap_or("No final readiness reason supplied by snapshot.")
        .to_string()
}

fn prepare_action_context(
    project_root: &str,
    job_id: &str,
) -> Result<(PathBuf, String, Value, String), String> {
    let validated_job_id = validate_job_id(job_id)?;
    let requested_root = project_root_from_args(project_root);
    let canonical_root = canonicalize_project_root(&requested_root)?;
    validate_agentdock_project(&canonical_root)?;
    let snapshot = load_workspace_snapshot_value(&canonical_root)?;
    let job_path = active_job_path_from_snapshot(&snapshot, &validated_job_id)?;
    Ok((canonical_root, validated_job_id, snapshot, job_path))
}

fn run_agentdock_action(
    action: &str,
    canonical_root: &Path,
    args: Vec<String>,
    started: Instant,
    success_message: &str,
) -> ControlledActionResult {
    let agentdock = resolve_agentdock(canonical_root);
    let command_vec: Vec<String> = std::iter::once(agentdock.clone())
        .chain(args.clone())
        .collect();
    match run_command_with_timeout(&agentdock, &args, canonical_root, CONTROLLED_ACTION_TIMEOUT) {
        Ok(Ok(output)) => {
            let stdout = redact_text(&String::from_utf8_lossy(&output.stdout));
            let stderr = redact_text(&String::from_utf8_lossy(&output.stderr));
            let status_code = output.status.code().unwrap_or(-1);
            let ok = output.status.success();
            let message = if ok {
                success_message.to_string()
            } else if !stderr.is_empty() {
                stderr.clone()
            } else if !stdout.is_empty() {
                stdout.clone()
            } else {
                format!("AgentDock action {action} failed with status {status_code}.")
            };
            ControlledActionResult {
                ok,
                status_code,
                stdout,
                stderr,
                command: command_vec,
                action: action.to_string(),
                error_kind: if ok {
                    SnapshotErrorKind::None
                } else {
                    SnapshotErrorKind::CommandFailed
                },
                message: redact_text(&message),
                duration_ms: started.elapsed().as_millis(),
            }
        }
        Ok(Err(())) => controlled_action_result_from_error(
            action,
            command_vec,
            SnapshotErrorKind::Timeout,
            format!("AgentDock action {action} timed out."),
            started.elapsed().as_millis(),
        ),
        Err(error) => {
            let kind = if error.kind() == io::ErrorKind::NotFound {
                SnapshotErrorKind::MissingCli
            } else {
                SnapshotErrorKind::Io
            };
            controlled_action_result_from_error(
                action,
                command_vec,
                kind,
                error.to_string(),
                started.elapsed().as_millis(),
            )
        }
    }
}

#[tauri::command]
fn workspace_snapshot(project_root: String) -> CommandResult {
    let started = Instant::now();
    let requested_root = project_root_from_args(&project_root);
    let canonical_root = match canonicalize_project_root(&requested_root) {
        Ok(root) => root,
        Err(message) => {
            return result_from_error(
                vec![
                    "agentdock".to_string(),
                    "workspace".to_string(),
                    "snapshot".to_string(),
                    "--json".to_string(),
                ],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            );
        }
    };

    if let Err(message) = validate_agentdock_project(&canonical_root) {
        return result_from_error(
            vec![
                "agentdock".to_string(),
                "workspace".to_string(),
                "snapshot".to_string(),
                "--json".to_string(),
            ],
            SnapshotErrorKind::InvalidProject,
            message,
            started.elapsed().as_millis(),
        );
    }

    let agentdock = resolve_agentdock(&canonical_root);
    let project_root_string = canonical_root.to_string_lossy().to_string();
    let args = vec![
        "workspace".to_string(),
        "snapshot".to_string(),
        "--json".to_string(),
        "--cache-ms".to_string(),
        "700".to_string(),
        "--project".to_string(),
        project_root_string,
    ];
    let command_vec: Vec<String> = std::iter::once(agentdock.clone())
        .chain(args.clone())
        .collect();

    match run_command_with_timeout(&agentdock, &args, &canonical_root, SNAPSHOT_TIMEOUT) {
        Ok(Ok(output)) => {
            let stdout = redact_text(&String::from_utf8_lossy(&output.stdout));
            let stderr = redact_text(&String::from_utf8_lossy(&output.stderr));
            let status_code = output.status.code().unwrap_or(-1);
            let parsed = if output.status.success() {
                serde_json::from_str::<Value>(&stdout).ok()
            } else {
                None
            };
            let error_kind = if !output.status.success() {
                SnapshotErrorKind::CommandFailed
            } else if parsed.is_none() {
                SnapshotErrorKind::InvalidJson
            } else {
                SnapshotErrorKind::None
            };
            let ok = output.status.success() && parsed.is_some();
            let message = if ok {
                "Snapshot loaded.".to_string()
            } else if !stderr.is_empty() {
                stderr.clone()
            } else if !stdout.is_empty() {
                stdout.clone()
            } else {
                format!("Snapshot command failed with status {status_code}.")
            };
            CommandResult {
                ok,
                status_code,
                stdout,
                stderr,
                command: command_vec,
                parsed,
                error_kind,
                message,
                duration_ms: started.elapsed().as_millis(),
            }
        }
        Ok(Err(())) => result_from_error(
            command_vec,
            SnapshotErrorKind::Timeout,
            "AgentDock snapshot command timed out.".to_string(),
            started.elapsed().as_millis(),
        ),
        Err(error) => {
            let kind = if error.kind() == io::ErrorKind::NotFound {
                SnapshotErrorKind::MissingCli
            } else {
                SnapshotErrorKind::Io
            };
            result_from_error(
                command_vec,
                kind,
                error.to_string(),
                started.elapsed().as_millis(),
            )
        }
    }
}

fn run_workspace_model_args(project_root: String, args: Vec<String>, started: Instant) -> CommandResult {
    let requested_root = project_root_from_args(&project_root);
    let canonical_root = match canonicalize_project_root(&requested_root) {
        Ok(root) => root,
        Err(message) => {
            return result_from_error(
                vec!["agentdock".to_string(), "workspace".to_string(), "model".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            );
        }
    };

    if let Err(message) = validate_agentdock_project(&canonical_root) {
        return result_from_error(
            vec!["agentdock".to_string(), "workspace".to_string(), "model".to_string()],
            SnapshotErrorKind::InvalidProject,
            message,
            started.elapsed().as_millis(),
        );
    }

    let agentdock = resolve_agentdock(&canonical_root);
    let command_vec: Vec<String> = std::iter::once(agentdock.clone())
        .chain(args.clone())
        .collect();
    match run_command_with_timeout(&agentdock, &args, &canonical_root, MODEL_UPDATE_TIMEOUT) {
        Ok(Ok(output)) => {
            let stdout = redact_text(&String::from_utf8_lossy(&output.stdout));
            let stderr = redact_text(&String::from_utf8_lossy(&output.stderr));
            let status_code = output.status.code().unwrap_or(-1);
            let parsed = if output.status.success() {
                serde_json::from_str::<Value>(&stdout).ok()
            } else {
                None
            };
            let ok = output.status.success() && parsed.is_some();
            let message = if ok {
                "AI model settings loaded.".to_string()
            } else if !stderr.is_empty() {
                stderr.clone()
            } else if !stdout.is_empty() {
                stdout.clone()
            } else {
                format!("AgentDock model command failed with status {status_code}.")
            };
            CommandResult {
                ok,
                status_code,
                stdout,
                stderr,
                command: command_vec,
                parsed,
                error_kind: if ok {
                    SnapshotErrorKind::None
                } else if output.status.success() {
                    SnapshotErrorKind::InvalidJson
                } else {
                    SnapshotErrorKind::CommandFailed
                },
                message: redact_text(&message),
                duration_ms: started.elapsed().as_millis(),
            }
        }
        Ok(Err(())) => result_from_error(
            command_vec,
            SnapshotErrorKind::Timeout,
            "AgentDock model command timed out.".to_string(),
            started.elapsed().as_millis(),
        ),
        Err(error) => {
            let kind = if error.kind() == io::ErrorKind::NotFound {
                SnapshotErrorKind::MissingCli
            } else {
                SnapshotErrorKind::Io
            };
            result_from_error(command_vec, kind, error.to_string(), started.elapsed().as_millis())
        }
    }
}

#[tauri::command]
fn workspace_model(project_root: String) -> CommandResult {
    let started = Instant::now();
    let requested_root = project_root_from_args(&project_root);
    let args = vec![
        "workspace".to_string(),
        "model".to_string(),
        "--json".to_string(),
        "--project".to_string(),
        requested_root,
    ];
    run_workspace_model_args(project_root, args, started)
}

#[tauri::command]
fn workspace_model_set(project_root: String, model: String, provider: String) -> CommandResult {
    let started = Instant::now();
    let model = match validate_model_id("model", &model, MAX_MODEL_ID_CHARS, false) {
        Ok(value) => value,
        Err(message) => {
            return result_from_error(
                vec!["agentdock".to_string(), "workspace".to_string(), "model".to_string(), "set".to_string()],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            );
        }
    };
    let provider = match validate_model_id("provider", &provider, 80, true) {
        Ok(value) => value,
        Err(message) => {
            return result_from_error(
                vec!["agentdock".to_string(), "workspace".to_string(), "model".to_string(), "set".to_string()],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            );
        }
    };
    let requested_root = project_root_from_args(&project_root);
    let mut args = vec![
        "workspace".to_string(),
        "model".to_string(),
        "set".to_string(),
        "--model".to_string(),
        model,
        "--apply-running".to_string(),
        "--global".to_string(),
        "--json".to_string(),
        "--project".to_string(),
        requested_root,
    ];
    if !provider.is_empty() {
        args.insert(5, provider);
        args.insert(5, "--provider".to_string());
    }
    run_workspace_model_args(project_root, args, started)
}

#[tauri::command]
fn workspace_watch_start(app: tauri::AppHandle, project_root: String) -> CommandResult {
    let started = Instant::now();
    let requested_root = project_root_from_args(&project_root);
    let canonical_root = match canonicalize_project_root(&requested_root) {
        Ok(root) => root,
        Err(message) => {
            return result_from_error(
                vec![
                    "agentdock".to_string(),
                    "workspace".to_string(),
                    "watch".to_string(),
                ],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            );
        }
    };

    if let Err(message) = validate_agentdock_project(&canonical_root) {
        return result_from_error(
            vec![
                "agentdock".to_string(),
                "workspace".to_string(),
                "watch".to_string(),
            ],
            SnapshotErrorKind::InvalidProject,
            message,
            started.elapsed().as_millis(),
        );
    }

    let started_new_watcher = ensure_workspace_watcher(app, canonical_root.clone());
    let watched_files = workspace_change_signature(&canonical_root)
        .map(|(_, count)| count)
        .unwrap_or(0);
    CommandResult {
        ok: true,
        status_code: 0,
        stdout: String::new(),
        stderr: String::new(),
        command: vec![
            "agentdock".to_string(),
            "workspace".to_string(),
            "watch".to_string(),
            "--event-driven".to_string(),
        ],
        parsed: Some(json!({
            "project_root": canonical_root.to_string_lossy(),
            "started": started_new_watcher,
            "already_running": !started_new_watcher,
            "watched_files": watched_files,
            "event": "workspace_changed"
        })),
        error_kind: SnapshotErrorKind::None,
        message: if started_new_watcher {
            "Workspace live watch started.".to_string()
        } else {
            "Workspace live watch already running.".to_string()
        },
        duration_ms: started.elapsed().as_millis(),
    }
}

#[tauri::command]
fn agentdock_job_create(project_root: String, request: String) -> JobCreateResult {
    let started = Instant::now();
    let validated_request = match validate_job_request(&request) {
        Ok(value) => value,
        Err(message) => {
            return job_create_result_from_error(
                vec![
                    "agentdock".to_string(),
                    "job".to_string(),
                    "--no-attach".to_string(),
                ],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            );
        }
    };
    let requested_root = project_root_from_args(&project_root);
    let canonical_root = match canonicalize_project_root(&requested_root) {
        Ok(root) => root,
        Err(message) => {
            return job_create_result_from_error(
                vec![
                    "agentdock".to_string(),
                    "job".to_string(),
                    "--no-attach".to_string(),
                ],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            );
        }
    };

    if let Err(message) = validate_agentdock_project(&canonical_root) {
        return job_create_result_from_error(
            vec![
                "agentdock".to_string(),
                "job".to_string(),
                "--no-attach".to_string(),
            ],
            SnapshotErrorKind::InvalidProject,
            message,
            started.elapsed().as_millis(),
        );
    }

    let agentdock = resolve_agentdock(&canonical_root);
    let args = build_job_create_args(&validated_request);
    let command_vec: Vec<String> = std::iter::once(agentdock.clone())
        .chain(args.clone())
        .collect();

    match run_command_with_timeout(&agentdock, &args, &canonical_root, JOB_CREATE_TIMEOUT) {
        Ok(Ok(output)) => {
            let stdout = redact_text(&String::from_utf8_lossy(&output.stdout));
            let stderr = redact_text(&String::from_utf8_lossy(&output.stderr));
            let status_code = output.status.code().unwrap_or(-1);
            let created = parse_created_job(&format!("{stdout}\n{stderr}"));
            let ok = output.status.success();
            let message = if ok {
                "CEO-led job created. Snapshot refresh will show orchestration progress."
                    .to_string()
            } else if !stderr.is_empty() {
                stderr.clone()
            } else if !stdout.is_empty() {
                stdout.clone()
            } else {
                format!("AgentDock job create failed with status {status_code}.")
            };
            JobCreateResult {
                ok,
                status_code,
                stdout,
                stderr,
                command: command_vec,
                job_id: created.as_ref().map(|job| job.job_id.clone()),
                job_path: created.as_ref().map(|job| job.job_path.clone()),
                error_kind: if ok {
                    SnapshotErrorKind::None
                } else {
                    SnapshotErrorKind::CommandFailed
                },
                message: redact_text(&message),
                duration_ms: started.elapsed().as_millis(),
            }
        }
        Ok(Err(())) => job_create_result_from_error(
            command_vec,
            SnapshotErrorKind::Timeout,
            "AgentDock job create command timed out.".to_string(),
            started.elapsed().as_millis(),
        ),
        Err(error) => {
            let kind = if error.kind() == io::ErrorKind::NotFound {
                SnapshotErrorKind::MissingCli
            } else {
                SnapshotErrorKind::Io
            };
            job_create_result_from_error(
                command_vec,
                kind,
                error.to_string(),
                started.elapsed().as_millis(),
            )
        }
    }
}

#[tauri::command]
fn agentdock_job_followup(
    project_root: String,
    job_id: String,
    message: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let message = match validate_text_field("follow-up message", &message, MAX_ACTION_MESSAGE_CHARS)
    {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_job_followup",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, job_id, snapshot, _) = match prepare_action_context(&project_root, &job_id)
    {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_job_followup",
                vec!["agentdock".to_string(), "send".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let coordinator = match coordinator_role_from_snapshot(&snapshot) {
        Some(role) => role,
        None => {
            return controlled_action_result_from_error(
                "agentdock_job_followup",
                vec!["agentdock".to_string(), "send".to_string()],
                SnapshotErrorKind::CommandFailed,
                "No coordinator role found in snapshot.".to_string(),
                started.elapsed().as_millis(),
            )
        }
    };
    let args = vec![
        "send".to_string(),
        coordinator,
        build_followup_message(&job_id, &message),
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_job_followup",
        &canonical_root,
        args,
        started,
        "CEO follow-up sent to the coordinator.",
    )
}

#[tauri::command]
fn agentdock_team_broadcast(
    project_root: String,
    job_id: String,
    message: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let message = match validate_text_field("broadcast message", &message, MAX_ACTION_MESSAGE_CHARS)
    {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_team_broadcast",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, job_id, _, job_path) = match prepare_action_context(&project_root, &job_id)
    {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_team_broadcast",
                vec!["agentdock".to_string(), "broadcast".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let args = vec![
        "broadcast".to_string(),
        "--from".to_string(),
        "user".to_string(),
        "--selected".to_string(),
        "--job".to_string(),
        job_path,
        build_broadcast_message(&job_id, &message),
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_team_broadcast",
        &canonical_root,
        args,
        started,
        "Selected-team broadcast sent.",
    )
}

#[tauri::command]
fn agentdock_role_send(
    project_root: String,
    job_id: String,
    role: String,
    message: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let role = match validate_id("role", &role, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_role_send",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let message = match validate_text_field("role message", &message, MAX_ACTION_MESSAGE_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_role_send",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, job_id, snapshot, _) = match prepare_action_context(&project_root, &job_id)
    {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_role_send",
                vec!["agentdock".to_string(), "send".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    if !role_is_selected(&snapshot, &role) {
        return controlled_action_result_from_error(
            "agentdock_role_send",
            vec!["agentdock".to_string(), "send".to_string(), role],
            SnapshotErrorKind::CommandFailed,
            "Role is not in the selected team for the active job.".to_string(),
            started.elapsed().as_millis(),
        );
    }
    let args = vec![
        "send".to_string(),
        role,
        build_followup_message(&job_id, &message),
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_role_send",
        &canonical_root,
        args,
        started,
        "Role message sent.",
    )
}

#[tauri::command]
fn agentdock_recruit_preview(
    project_root: String,
    job_id: String,
    role: String,
    template: String,
    mission: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let role = match validate_id("role", &role, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_preview",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let template = match validate_id("template", &template, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_preview",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let mission = match validate_text_field("mission", &mission, MAX_ACTION_MESSAGE_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_preview",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    if let Err(message) = prepare_action_context(&project_root, &job_id).map(|_| ()) {
        return controlled_action_result_from_error(
            "agentdock_recruit_preview",
            vec!["agentdock".to_string(), "recruit".to_string()],
            SnapshotErrorKind::InvalidProject,
            message,
            started.elapsed().as_millis(),
        );
    }
    controlled_action_success("agentdock_recruit_preview", vec!["agentdock".to_string(), "recruit".to_string(), role.clone(), "--template".to_string(), template.clone(), "--mission".to_string(), mission.clone()], format!("Preview only: recruit role `{role}` from template `{template}` with mission `{mission}`."), started.elapsed().as_millis())
}

#[tauri::command]
fn agentdock_recruit_role(
    project_root: String,
    job_id: String,
    role: String,
    template: String,
    mission: String,
    instructions: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let role = match validate_id("role", &role, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_role",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let template = match validate_id("template", &template, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_role",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let mission = match validate_text_field("mission", &mission, MAX_ACTION_MESSAGE_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_role",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let instructions =
        match validate_text_field("instructions", &instructions, MAX_ACTION_MESSAGE_CHARS) {
            Ok(value) => value,
            Err(message) => {
                return controlled_action_result_from_error(
                    "agentdock_recruit_role",
                    vec![],
                    SnapshotErrorKind::CommandFailed,
                    message,
                    started.elapsed().as_millis(),
                )
            }
        };
    let (canonical_root, _, _, _) = match prepare_action_context(&project_root, &job_id) {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_recruit_role",
                vec!["agentdock".to_string(), "recruit".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let args = vec![
        "recruit".to_string(),
        role,
        "--template".to_string(),
        template,
        "--mission".to_string(),
        mission,
        "--instructions".to_string(),
        instructions,
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_recruit_role",
        &canonical_root,
        args,
        started,
        "Recruit command executed for the requested role.",
    )
}

#[tauri::command]
fn agentdock_task_proposal(
    project_root: String,
    job_id: String,
    role: String,
    proposal: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let role = match validate_id("role", &role, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_task_proposal",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let proposal = match validate_text_field("proposal", &proposal, MAX_ACTION_MESSAGE_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_task_proposal",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, job_id, snapshot, _) = match prepare_action_context(&project_root, &job_id)
    {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_task_proposal",
                vec!["agentdock".to_string(), "send".to_string()],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    if !role_is_selected(&snapshot, &role) {
        return controlled_action_result_from_error(
            "agentdock_task_proposal",
            vec!["agentdock".to_string(), "send".to_string(), role],
            SnapshotErrorKind::CommandFailed,
            "Task proposals are limited to selected active-job roles.".to_string(),
            started.elapsed().as_millis(),
        );
    }
    let coordinator = match coordinator_role_from_snapshot(&snapshot) {
        Some(role) => role,
        None => {
            return controlled_action_result_from_error(
                "agentdock_task_proposal",
                vec!["agentdock".to_string(), "send".to_string()],
                SnapshotErrorKind::CommandFailed,
                "No coordinator role found in snapshot.".to_string(),
                started.elapsed().as_millis(),
            )
        }
    };
    let args = vec![
        "send".to_string(),
        coordinator,
        build_task_proposal_message(&job_id, &role, &proposal),
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_task_proposal",
        &canonical_root,
        args,
        started,
        "Task proposal sent to the coordinator for review.",
    )
}

#[tauri::command]
fn agentdock_job_report(
    project_root: String,
    job_id: String,
    role: String,
    summary: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let role = match validate_id("role", &role, MAX_ROLE_ID_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_job_report",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let summary = match validate_text_field("report summary", &summary, MAX_SUMMARY_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_job_report",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, _, snapshot, job_path) =
        match prepare_action_context(&project_root, &job_id) {
            Ok(context) => context,
            Err(message) => {
                return controlled_action_result_from_error(
                    "agentdock_job_report",
                    vec![
                        "agentdock".to_string(),
                        "job".to_string(),
                        "report".to_string(),
                    ],
                    SnapshotErrorKind::InvalidProject,
                    message,
                    started.elapsed().as_millis(),
                )
            }
        };
    if !role_is_selected(&snapshot, &role) {
        return controlled_action_result_from_error(
            "agentdock_job_report",
            vec![
                "agentdock".to_string(),
                "job".to_string(),
                "report".to_string(),
                "--from".to_string(),
                role,
            ],
            SnapshotErrorKind::CommandFailed,
            "Reports are limited to selected active-job roles.".to_string(),
            started.elapsed().as_millis(),
        );
    }
    let args = vec![
        "job".to_string(),
        "report".to_string(),
        "--job".to_string(),
        job_path,
        "--from".to_string(),
        role,
        "--summary".to_string(),
        summary,
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_job_report",
        &canonical_root,
        args,
        started,
        "Role report submitted for the active job.",
    )
}

#[tauri::command]
fn agentdock_finish_preview(project_root: String, job_id: String) -> ControlledActionResult {
    let started = Instant::now();
    let (_, _, snapshot, _) = match prepare_action_context(&project_root, &job_id) {
        Ok(context) => context,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_finish_preview",
                vec![
                    "agentdock".to_string(),
                    "job".to_string(),
                    "finish".to_string(),
                ],
                SnapshotErrorKind::InvalidProject,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let ready = snapshot_final_ready(&snapshot);
    let reason = snapshot_final_reason(&snapshot);
    controlled_action_success(
        "agentdock_finish_preview",
        vec![
            "agentdock".to_string(),
            "job".to_string(),
            "finish".to_string(),
        ],
        if ready {
            format!("Finish is allowed by snapshot readiness: {reason}")
        } else {
            format!("Finish is blocked by snapshot readiness: {reason}")
        },
        started.elapsed().as_millis(),
    )
}

#[tauri::command]
fn agentdock_job_finish(
    project_root: String,
    job_id: String,
    summary: String,
) -> ControlledActionResult {
    let started = Instant::now();
    let summary = match validate_text_field("finish summary", &summary, MAX_SUMMARY_CHARS) {
        Ok(value) => value,
        Err(message) => {
            return controlled_action_result_from_error(
                "agentdock_job_finish",
                vec![],
                SnapshotErrorKind::CommandFailed,
                message,
                started.elapsed().as_millis(),
            )
        }
    };
    let (canonical_root, _, snapshot, job_path) =
        match prepare_action_context(&project_root, &job_id) {
            Ok(context) => context,
            Err(message) => {
                return controlled_action_result_from_error(
                    "agentdock_job_finish",
                    vec![
                        "agentdock".to_string(),
                        "job".to_string(),
                        "finish".to_string(),
                    ],
                    SnapshotErrorKind::InvalidProject,
                    message,
                    started.elapsed().as_millis(),
                )
            }
        };
    if !snapshot_final_ready(&snapshot) {
        return controlled_action_result_from_error(
            "agentdock_job_finish",
            vec![
                "agentdock".to_string(),
                "job".to_string(),
                "finish".to_string(),
            ],
            SnapshotErrorKind::CommandFailed,
            format!("Finish blocked: {}", snapshot_final_reason(&snapshot)),
            started.elapsed().as_millis(),
        );
    }
    let args = vec![
        "job".to_string(),
        "finish".to_string(),
        "--job".to_string(),
        job_path,
        "--summary".to_string(),
        summary,
        "--project".to_string(),
        canonical_root.to_string_lossy().to_string(),
    ];
    run_agentdock_action(
        "agentdock_job_finish",
        &canonical_root,
        args,
        started,
        "Job finish command executed.",
    )
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            if std::env::var("AGENTDOCK_NATIVE_EVIDENCE_CAPTURE").as_deref() == Ok("1") {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.set_always_on_top(true);
                    let _ = window.set_focus();
                }
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            workspace_snapshot,
            workspace_model,
            workspace_model_set,
            workspace_watch_start,
            agentdock_job_create,
            agentdock_job_followup,
            agentdock_team_broadcast,
            agentdock_role_send,
            agentdock_recruit_preview,
            agentdock_recruit_role,
            agentdock_task_proposal,
            agentdock_job_report,
            agentdock_finish_preview,
            agentdock_job_finish
        ])
        .run(tauri::generate_context!())
        .expect("error while running AgentDock Visual Office");
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temp_dir(name: &str) -> PathBuf {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = std::env::temp_dir().join(format!("agentdock-workspace-{name}-{stamp}"));
        fs::create_dir_all(&path).unwrap();
        path
    }

    #[test]
    fn validation_rejects_non_agentdock_project() {
        let root = temp_dir("invalid");
        let canonical = canonicalize_project_root(root.to_str().unwrap()).unwrap();
        let error = validate_agentdock_project(&canonical).unwrap_err();
        assert!(error.contains(".agentdock"));
        let _ = fs::remove_dir_all(root);
    }

    #[test]
    fn project_discovery_finds_agentdock_ancestor_from_release_path() {
        let root = temp_dir("discover-root");
        fs::create_dir_all(root.join(".agentdock")).unwrap();
        fs::create_dir_all(root.join(".agent-work")).unwrap();
        let release_dir = root.join("src-tauri").join("target").join("release");
        fs::create_dir_all(&release_dir).unwrap();
        let discovered = find_agentdock_project_ancestor(&release_dir).unwrap();
        assert_eq!(discovered, root);
        let _ = fs::remove_dir_all(discovered);
    }

    #[test]
    fn validation_accepts_agentdock_project_markers() {
        let root = temp_dir("valid");
        fs::create_dir_all(root.join(".agentdock")).unwrap();
        fs::create_dir_all(root.join(".agent-work")).unwrap();
        let canonical = canonicalize_project_root(root.to_str().unwrap()).unwrap();
        assert!(validate_agentdock_project(&canonical).is_ok());
        let _ = fs::remove_dir_all(root);
    }

    #[test]
    fn redaction_masks_common_secret_tokens() {
        let redacted = redact_text("OPENAI_API_KEY=sk-secret123 sk-other value");
        assert!(!redacted.contains("sk-secret123"));
        assert!(!redacted.contains("sk-other"));
        assert!(redacted.contains("[REDACTED_SECRET]"));
    }

    #[test]
    fn job_create_builds_exact_no_shell_args() {
        let request = "summarize risk; rm -rf /";
        let args = build_job_create_args(request);
        assert_eq!(args, vec!["job", "--no-attach", "--fast-return", request]);
    }

    #[test]
    fn job_create_parses_created_job_id_and_path() {
        let text =
            "Job kickoff: /tmp/project/.agent-work/07_JOBS/JOB-260522164003906385/README.md\n";
        let parsed = parse_created_job(text).expect("job id/path should parse");
        assert_eq!(parsed.job_id, "JOB-260522164003906385");
        assert_eq!(
            parsed.job_path,
            "/tmp/project/.agent-work/07_JOBS/JOB-260522164003906385"
        );
    }

    #[test]
    fn job_create_rejects_empty_request() {
        let error = validate_job_request("  \n\t  ").unwrap_err();
        assert!(error.contains("empty"));
    }

    #[test]
    fn job_create_rejects_overlong_request() {
        let request = "x".repeat(MAX_JOB_REQUEST_CHARS + 1);
        let error = validate_job_request(&request).unwrap_err();
        assert!(error.contains("8000"));
    }

    #[test]
    fn job_create_redacts_secret_output() {
        let redacted =
            redact_text("created job with OPENAI_API_KEY=sk-secret123456 and sk-live7890");
        assert!(!redacted.contains("sk-secret"));
        assert!(!redacted.contains("sk-live"));
        assert!(redacted.contains("[REDACTED_SECRET]"));
    }

    #[test]
    fn controlled_action_validates_safe_ids() {
        assert_eq!(validate_job_id("JOB-260523123").unwrap(), "JOB-260523123");
        assert!(validate_job_id("not-a-job").is_err());
        assert!(validate_id("role", "developer;rm", MAX_ROLE_ID_CHARS).is_err());
        assert_eq!(
            validate_id("role", "agentdock-qa", MAX_ROLE_ID_CHARS).unwrap(),
            "agentdock-qa"
        );
    }

    #[test]
    fn model_validation_allows_provider_model_ids_without_shell_chars() {
        assert_eq!(
            validate_model_id("model", "openai/gpt-5.1", MAX_MODEL_ID_CHARS, false).unwrap(),
            "openai/gpt-5.1"
        );
        assert_eq!(
            validate_model_id("provider", "openai-codex", 80, false).unwrap(),
            "openai-codex"
        );
        assert!(validate_model_id("model", "gpt-5.5;rm", MAX_MODEL_ID_CHARS, false).is_err());
        assert!(validate_model_id("model", "", MAX_MODEL_ID_CHARS, false).is_err());
        assert_eq!(validate_model_id("provider", "", 80, true).unwrap(), "");
    }

    #[test]
    fn controlled_action_messages_include_job_context_without_shell_splitting() {
        let message = build_task_proposal_message("JOB-123", "developer", "change task; rm -rf /");
        assert!(message.contains("JOB-123"));
        assert!(message.contains("developer"));
        assert!(message.contains("Do not apply silently"));
        assert!(message.contains("change task; rm -rf /"));
    }

    #[test]
    fn fake_agentdock_job_create_uses_single_request_argv() {
        let root = temp_dir("job-create");
        fs::create_dir_all(root.join(".agentdock")).unwrap();
        fs::create_dir_all(root.join(".agent-work")).unwrap();
        let bin = root.join("fake-agentdock");
        let argv_file = root.join("argv.txt");
        fs::write(
            &bin,
            format!(
                "#!/usr/bin/env bash\nprintf '%s\\n' \"$@\" > '{}'\necho 'Created CEO-led job: {}/.agent-work/07_JOBS/JOB-FAKE123'\n",
                argv_file.display(),
                root.display()
            ),
        )
        .unwrap();
        let mut perms = fs::metadata(&bin).unwrap().permissions();
        #[cfg(unix)]
        {
            {
                use std::os::unix::fs::PermissionsExt;
                perms.set_mode(0o755);
                fs::set_permissions(&bin, perms).unwrap();
            }
        }
        std::env::set_var("AGENTDOCK_BIN", bin.to_str().unwrap());

        let request = "ship this; rm -rf /";
        let result = agentdock_job_create(root.to_string_lossy().to_string(), request.to_string());
        assert!(result.ok, "{}", result.message);
        assert_eq!(result.job_id.as_deref(), Some("JOB-FAKE123"));
        let recorded = fs::read_to_string(argv_file).unwrap();
        assert_eq!(recorded, format!("job\n--no-attach\n--fast-return\n{request}\n"));
        std::env::remove_var("AGENTDOCK_BIN");
        let _ = fs::remove_dir_all(root);
    }
}
