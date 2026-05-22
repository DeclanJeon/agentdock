import { redactText } from './snapshot';
import type { JobCreateResult } from './actions';

export type AuditStatus = 'attempt' | 'success' | 'failure' | 'partial';

export interface ActionAuditEvent {
  id: string;
  actionType: string;
  status: AuditStatus;
  startedAt: string;
  completedAt?: string;
  durationMs?: number;
  requestPreview: string;
  resultSummary?: string;
  jobId?: string;
  jobPath?: string;
}

export function previewText(input: string, max = 96): string {
  const redacted = redactText(input).replace(/\s+/g, ' ').trim();
  return redacted.length > max ? `${redacted.slice(0, max - 1)}…` : redacted;
}

export function newAuditAttempt(actionType: string, request: string): ActionAuditEvent {
  return {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    actionType,
    status: 'attempt',
    startedAt: new Date().toISOString(),
    requestPreview: previewText(request),
  };
}

export function completeJobCreateAudit(event: ActionAuditEvent, result: JobCreateResult): ActionAuditEvent {
  const completedAt = new Date().toISOString();
  const started = Date.parse(event.startedAt);
  const completed = Date.parse(completedAt);
  return {
    ...event,
    status: result.ok ? 'success' : 'failure',
    completedAt,
    durationMs: Number.isFinite(started) ? Math.max(0, completed - started) : result.durationMs,
    resultSummary: previewText(result.message || result.stderr || result.stdout || result.errorKind || (result.ok ? 'ok' : 'failed')),
    jobId: result.jobId,
    jobPath: result.jobPath,
  };
}
