export type WorkspaceRoleStatus =
  | 'ready'
  | 'running'
  | 'working'
  | 'assigned'
  | 'configured'
  | 'reported'
  | 'blocked'
  | 'offline'
  | 'unknown';

export interface WorkspaceRole {
  id: string;
  role_id?: string;
  display_name?: string;
  department?: string;
  tier?: string;
  selected?: boolean;
  configured?: boolean;
  running_pane?: boolean;
  pane_id?: string;
  task_path?: string;
  latest_report_path?: string;
  status?: WorkspaceRoleStatus | string;
  status_reason?: string;
  template_id?: string;
  agency_profile?: {
    template_id?: string;
    source?: string;
    archetype?: string;
    when_to_use?: string;
    outputs?: string;
    activity?: string;
  };
  source_paths?: string[];
  avatar?: {
    style?: string;
    report_count?: number;
    character_id?: string;
    archetype?: string;
    palette?: string;
    overlay?: string;
  };
}

export interface WorkspaceAlert {
  severity?: string;
  type?: string;
  message?: string;
  role?: string;
  owner?: string;
  next_action?: string;
  path?: string;
}

export type WorkspaceWarning = string | WorkspaceAlert | Record<string, unknown>;

export interface WorkspaceSnapshot {
  schema_version?: string;
  generated_at?: string;
  project?: {
    name?: string;
    root?: string;
    session?: string;
    session_name?: string;
  };
  job?: {
    id?: string;
    path?: string;
    readme_path?: string;
    lifecycle?: string;
    lifecycle_status?: string;
    final_ready?: boolean;
    final_ready_reason?: string;
  };
  reports?: {
    submitted?: number;
    required?: number;
    submitted_selected_roles?: number;
    required_selected_roles?: number;
    selected_roles?: number;
    missing_roles?: string[];
    total?: number;
  };
  roles?: WorkspaceRole[];
  alerts?: WorkspaceAlert[];
  warnings?: WorkspaceWarning[];
  commands?: {
    mode?: string;
    write_bridge_enabled?: boolean;
    allowed_read_commands?: string[];
    allowed_actions?: string[];
  };
  layout?: {
    role_count?: number;
    density?: string;
    density_thresholds?: Record<string, number>;
  };
  team_plan?: {
    coordinator?: string;
    selected_roles?: string[];
    required_worker_reports?: number;
    submitted_worker_reports?: number;
    recommendations?: Array<{
      template_id?: string;
      display_name?: string;
      department?: string;
      archetype?: string;
      score?: number;
      reason?: string;
    }>;
    policy?: string;
  };
  tfts?: Array<{
    name: string;
    source_path?: string;
    status?: string;
    members?: string[];
    goal?: string;
  }>;
  history?: {
    active_job_id?: string;
    recent_jobs?: Array<{
      id: string;
      path?: string;
      readme_path?: string;
      lifecycle?: string;
      created?: string;
      updated_at?: string;
      report_count?: number;
      final_report_path?: string;
      request_preview?: string;
    }>;
  };
  events?: unknown[];
}

export type SnapshotErrorKind =
  | 'none'
  | 'invalid_project'
  | 'missing_cli'
  | 'command_failed'
  | 'invalid_json'
  | 'timeout'
  | 'io';

export interface CommandResult {
  ok: boolean;
  statusCode: number;
  stdout: string;
  stderr: string;
  command: string[];
  parsed?: WorkspaceSnapshot;
  errorKind?: SnapshotErrorKind;
  message?: string;
  durationMs?: number;
}

export const SUPPORTED_SCHEMA_VERSION = 'workspace.snapshot.v1';

export function observedSchema(snapshot?: WorkspaceSnapshot | null): string {
  return snapshot?.schema_version ?? 'missing';
}

export function isSupportedSnapshot(snapshot?: WorkspaceSnapshot | null): snapshot is WorkspaceSnapshot {
  return observedSchema(snapshot) === SUPPORTED_SCHEMA_VERSION;
}

export function redactText(input: string): string {
  return input
    .replace(/sk-[A-Za-z0-9_-]{6,}/g, '[REDACTED_SECRET]')
    .replace(/(OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN|NPM_TOKEN)=\S+/g, '$1=[REDACTED_SECRET]');
}
