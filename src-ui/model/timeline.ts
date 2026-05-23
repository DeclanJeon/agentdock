import type { WorkspaceSnapshot } from './snapshot';
import type { WorkspaceMode } from './scene';

export type TimelineStepId = 'intake' | 'planning' | 'team' | 'tasking' | 'execution' | 'reports' | 'final-ready' | 'complete';
export type TimelineStepState = 'done' | 'active' | 'blocked' | 'pending';

export interface TimelineStep {
  id: TimelineStepId;
  label: string;
  state: TimelineStepState;
  evidenceCount: number;
  note: string;
}

function hasJob(snapshot: WorkspaceSnapshot): boolean {
  return Boolean(snapshot.job?.id || snapshot.job?.path || snapshot.job?.readme_path);
}

function selectedRoles(snapshot: WorkspaceSnapshot): number {
  return (snapshot.roles ?? []).filter((role) => role.selected).length;
}

function requiredReports(snapshot: WorkspaceSnapshot): number {
  return snapshot.reports?.required_selected_roles ?? snapshot.reports?.required ?? selectedRoles(snapshot);
}

function submittedReports(snapshot: WorkspaceSnapshot): number {
  return snapshot.reports?.submitted_selected_roles ?? snapshot.reports?.submitted ?? snapshot.reports?.total ?? 0;
}

function missingReports(snapshot: WorkspaceSnapshot): number {
  return snapshot.reports?.missing_roles?.length ?? Math.max(0, requiredReports(snapshot) - submittedReports(snapshot));
}

function hasBlockers(snapshot: WorkspaceSnapshot): boolean {
  return Boolean((snapshot.alerts ?? []).some((alert) => (alert.severity ?? '').toLowerCase() !== 'info') || (snapshot.roles ?? []).some((role) => role.status === 'blocked'));
}

export function deriveFacilitationTimeline(snapshot: WorkspaceSnapshot, mode: WorkspaceMode): TimelineStep[] {
  const jobPresent = hasJob(snapshot);
  const selected = selectedRoles(snapshot);
  const taskCards = (snapshot.roles ?? []).filter((role) => role.task_path).length;
  const submitted = submittedReports(snapshot);
  const required = requiredReports(snapshot);
  const missing = missingReports(snapshot);
  const blocked = hasBlockers(snapshot);
  const finalReady = Boolean(snapshot.job?.final_ready) && missing === 0 && !blocked;
  const complete = (snapshot.job?.lifecycle_status ?? snapshot.job?.lifecycle ?? '').toLowerCase().includes('complete');
  const modePrefix = mode === 'live' ? '현재 상태' : mode === 'stale' ? '최근 상태' : mode === 'error' ? '상태 확인 필요' : '작업 대기';

  const steps: TimelineStep[] = [
    { id: 'intake', label: 'Intake', state: jobPresent ? 'done' : 'active', evidenceCount: jobPresent ? 1 : 0, note: jobPresent ? `Active job ${snapshot.job?.id ?? 'loaded'}` : `${modePrefix}: 활성 작업을 기다리는 중` },
    { id: 'planning', label: 'CEO Planning', state: jobPresent ? 'done' : 'pending', evidenceCount: jobPresent ? 1 : 0, note: snapshot.job?.lifecycle_status ?? snapshot.job?.lifecycle ?? 'CEO 계획 대기 중' },
    { id: 'team', label: 'Team Selection', state: selected > 0 ? 'done' : jobPresent ? 'active' : 'pending', evidenceCount: selected, note: selected > 0 ? `${selected} selected roles` : '선택된 역할 없음' },
    { id: 'tasking', label: 'Tasking', state: taskCards > 0 ? 'done' : selected > 0 ? 'active' : 'pending', evidenceCount: taskCards, note: taskCards > 0 ? `${taskCards} task cards linked` : '작업 카드 대기 중' },
    { id: 'execution', label: 'Execution', state: blocked ? 'blocked' : submitted > 0 ? 'done' : taskCards > 0 ? 'active' : 'pending', evidenceCount: (snapshot.roles ?? []).filter((role) => ['working','running','reported','blocked'].includes(String(role.status))).length, note: blocked ? '확인 필요 항목이 작업을 막고 있음' : '역할 작업 중 또는 준비 완료' },
    { id: 'reports', label: 'Reports', state: missing > 0 ? 'blocked' : required > 0 && submitted >= required ? 'done' : submitted > 0 ? 'active' : 'pending', evidenceCount: submitted, note: missing > 0 ? `${missing} missing reports` : `${submitted}/${required} reports submitted` },
    { id: 'final-ready', label: 'Final Ready', state: finalReady ? 'active' : complete ? 'done' : blocked || missing > 0 ? 'blocked' : 'pending', evidenceCount: finalReady ? 1 : 0, note: snapshot.job?.final_ready_reason ?? (finalReady ? '최종 확인 준비 완료' : '보고 또는 확인 필요 항목 대기 중') },
    { id: 'complete', label: 'Complete', state: complete ? 'done' : 'pending', evidenceCount: complete ? 1 : 0, note: complete ? '작업 완료/최종 보고 사용 가능' : '진행 중' },
  ];
  return steps;
}
