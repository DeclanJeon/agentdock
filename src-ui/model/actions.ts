import { redactText, type SnapshotErrorKind } from './snapshot';

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
