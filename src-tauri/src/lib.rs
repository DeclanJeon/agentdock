use serde::Serialize;
use serde_json::Value;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};
use std::thread;
use std::time::{Duration, Instant};
use tauri::Manager;

const SNAPSHOT_TIMEOUT: Duration = Duration::from_secs(10);
const JOB_CREATE_TIMEOUT: Duration = Duration::from_secs(30);
const MAX_JOB_REQUEST_CHARS: usize = 8000;

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

#[derive(Debug, Serialize)]
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

#[derive(Debug, Serialize)]
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

fn build_job_create_args(request: &str) -> Vec<String> {
    vec![
        "job".to_string(),
        "--no-attach".to_string(),
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

fn canonicalize_project_root(project_root: &str) -> Result<PathBuf, String> {
    fs::canonicalize(project_root)
        .map_err(|error| format!("Project root is not accessible: {error}"))
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
            agentdock_job_create
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
        assert_eq!(args, vec!["job", "--no-attach", request]);
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
        assert_eq!(recorded, format!("job\n--no-attach\n{request}\n"));
        std::env::remove_var("AGENTDOCK_BIN");
        let _ = fs::remove_dir_all(root);
    }
}
