import { redactText, type SnapshotErrorKind, type WorkspaceModelSettings } from './snapshot';

export const MAX_CEO_TASK_CHARS = 8000;

export interface ValidationResult {
  ok: boolean;
  message?: string;
}

export interface JobCreateResult {
  ok: boolean;
  statusCode: number;
  stdout: string;
  stderr: string;
  command: string[];
  jobId?: string;
  jobPath?: string;
  errorKind?: SnapshotErrorKind;
  message?: string;
  durationMs?: number;
}

export function validateCeoTaskRequest(text: string): ValidationResult {
  const trimmed = text.trim();
  if (!trimmed) {
    return { ok: false, message: 'Describe work for the CEO before sending.' };
  }
  if (trimmed.length > MAX_CEO_TASK_CHARS) {
    return { ok: false, message: `CEO task request must be ${MAX_CEO_TASK_CHARS} characters or fewer.` };
  }
  return { ok: true };
}

export function jobCreateErrorMessage(result: JobCreateResult): string {
  return redactText(result.message || result.stderr || result.stdout || result.errorKind || 'AgentDock job create failed.');
}


export type ControlledActionName =
  | 'agentdock_job_followup'
  | 'agentdock_team_broadcast'
  | 'agentdock_role_send'
  | 'agentdock_recruit_preview'
  | 'agentdock_recruit_role'
  | 'agentdock_task_proposal'
  | 'agentdock_job_report'
  | 'agentdock_finish_preview'
  | 'agentdock_job_finish';

export interface ControlledActionResult {
  ok: boolean;
  statusCode: number;
  stdout: string;
  stderr: string;
  command: string[];
  action: ControlledActionName | string;
  errorKind?: SnapshotErrorKind;
  message?: string;
  durationMs?: number;
}

export function controlledActionErrorMessage(result: ControlledActionResult): string {
  return redactText(result.message || result.stderr || result.stdout || result.errorKind || 'AgentDock controlled action failed.');
}

export interface WorkspaceModelCommandResult {
  ok: boolean;
  statusCode: number;
  stdout: string;
  stderr: string;
  command: string[];
  parsed?: WorkspaceModelSettings;
  errorKind?: SnapshotErrorKind;
  message?: string;
  durationMs?: number;
}

export function workspaceModelErrorMessage(result: WorkspaceModelCommandResult): string {
  return redactText(result.message || result.stderr || result.stdout || result.errorKind || 'AgentDock model command failed.');
}
