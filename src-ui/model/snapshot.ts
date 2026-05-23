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

export interface WorkspaceModelOption {
  label?: string;
  provider: string;
  model: string;
}

export interface WorkspaceModelSettings {
  ok?: boolean;
  message?: string;
  provider: string;
  model: string;
  source?: 'project' | 'hermes-config' | 'default' | string;
  options?: WorkspaceModelOption[];
  global_persisted?: boolean;
  applied_running_count?: number;
  applied_roles?: string[];
}

export interface WorkspaceOrchestration {
  schema_version?: string;
  job_id?: string;
  mode?: 'idle' | 'solo_direct' | 'assisted_single_lane' | 'standard_team' | 'critical_review' | 'legacy_controlled_actions' | string;
  complexity?: string;
  risk?: string;
  intents?: string[];
  requires_code_change?: boolean;
  requires_user_visible_change?: boolean;
  requires_qa?: boolean;
  requires_security_review?: boolean;
  approval_required?: boolean;
  team_cap?: number;
  reason?: string;
  budget?: {
    max_roles?: number;
    max_tfts?: number;
    max_meetings?: number;
    expected_minutes?: number;
    escalation_requires_reason?: boolean;
  };
  runtime?: {
    provider?: string;
    model?: string;
    source?: string;
  };
  selected_roles?: string[];
  selected_role_details?: Array<{
    role?: string;
    source?: 'reuse' | 'recruit' | string;
    template?: string;
    mission?: string;
    distinct_output?: string;
  }>;
  rejected_roles?: Array<string | { template?: string; role?: string; reason?: string }>;
}

export interface WorkspaceQaStatus {
  required?: boolean;
  status?: 'not_required' | 'pending' | 'passed' | 'failed' | string;
  path?: string;
  reason?: string;
}

export interface WorkspaceDependencies {
  schema_version?: string;
  items?: Array<{
    role?: string;
    waiting_on?: string;
    type?: string;
    status?: string;
    reason?: string;
    source_path?: string;
  }>;
}

export interface WorkspaceMeetings {
  schema_version?: string;
  items?: Array<{
    title?: string;
    status?: string;
    reason?: string;
    decision?: string;
    source_path?: string;
  }>;
}

export interface WorkspaceWriteConflicts {
  schema_version?: string;
  items?: Array<{ file?: string; roles?: string[]; status?: string }>;
}

export interface WorkspaceCommunications {
  schema_version?: string;
  items?: Array<{ time?: string; actor?: string; action?: string; status?: string; summary?: string; source_path?: string }>;
}

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
  orchestration?: WorkspaceOrchestration;
  dependencies?: WorkspaceDependencies;
  meetings?: WorkspaceMeetings;
  write_conflicts?: WorkspaceWriteConflicts;
  communications?: WorkspaceCommunications;
  qa?: WorkspaceQaStatus;
  model?: WorkspaceModelSettings;
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
    exit_condition?: string;
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
