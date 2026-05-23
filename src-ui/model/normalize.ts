import type { WorkspaceAlert, WorkspaceRole, WorkspaceSnapshot, WorkspaceWarning } from './snapshot';

export interface OfficeRoom {
  id: string;
  title: string;
  subtitle: string;
  roles: WorkspaceRole[];
}

const roomDefinitions = [
  {
    id: 'ceo-office',
    title: 'CEO Office',
    subtitle: 'Job control, mission wall, final readiness',
    matches: (role: WorkspaceRole) => role.id === 'orchestrator' || role.tier === 'ceo' || role.department === 'Executive',
  },
  {
    id: 'product-studio',
    title: 'Product / UX Studio',
    subtitle: 'Scope, research, design decisions',
    matches: (role: WorkspaceRole) => /product|ux|design|research/i.test(`${role.id} ${role.department ?? ''}`),
  },
  {
    id: 'engineering-bay',
    title: 'Engineering Bay',
    subtitle: 'Architecture, code, tests, implementation',
    matches: (role: WorkspaceRole) => /developer|engineer|architect|backend|frontend/i.test(`${role.id} ${role.department ?? ''}`),
  },
  {
    id: 'qa-lab',
    title: 'QA Lab',
    subtitle: 'Release gates, blocker checks, verification',
    matches: (role: WorkspaceRole) => /qa|quality|review/i.test(`${role.id} ${role.department ?? ''}`),
  },
  {
    id: 'delivery-desk',
    title: 'Delivery Desk',
    subtitle: 'Roadmap, dependencies, handoff',
    matches: (role: WorkspaceRole) => /delivery|planner|writer|docs/i.test(`${role.id} ${role.department ?? ''}`),
  },
];

export function normalizeRooms(snapshot: WorkspaceSnapshot): OfficeRoom[] {
  const roles = snapshot.roles ?? [];
  const assigned = new Set<string>();
  const rooms: OfficeRoom[] = roomDefinitions.map((room) => {
    const members = roles.filter((role) => {
      if (assigned.has(role.id) || !room.matches(role)) return false;
      assigned.add(role.id);
      return true;
    });
    return { id: room.id, title: room.title, subtitle: room.subtitle, roles: members };
  });

  const general = roles.filter((role) => !assigned.has(role.id));
  if (general.length > 0) {
    rooms.push({
      id: 'general-floor',
      title: 'General Floor',
      subtitle: 'Configured agents without a specialized room mapping',
      roles: general,
    });
  }
  return rooms;
}

export function statusLabel(status?: string): string {
  switch (status) {
    case 'ready':
    case 'reported':
      return '보고 완료';
    case 'running':
    case 'working':
      return '작업 중';
    case 'reviewing':
      return '검토 중';
    case 'assigned':
      return '배정됨';
    case 'blocked':
      return '막힘';
    case 'idle':
      return '대기 중';
    case 'offline':
      return '오프라인';
    case 'configured':
      return '대기';
    default:
      return '상태 불명';
  }
}

export interface ReportState {
  submitted: number;
  required: number;
  missingRoles: string[];
  missingCount: number;
  ready: boolean;
  coverageLabel: string;
  headline: string;
  nextAction: string;
  ceoFinalPending: string;
}

export interface BlockerCard {
  severity: string;
  type: string;
  message: string;
  owner?: string;
  nextAction?: string;
  path?: string;
}

export function reportState(snapshot: WorkspaceSnapshot): ReportState {
  const reports = snapshot.reports ?? {};
  const missingRoles = reports.missing_roles ?? [];
  const submitted = reports.submitted_selected_roles ?? reports.submitted ?? reports.total ?? 0;
  const required = reports.required_selected_roles ?? reports.required ?? 0;
  const ready = snapshot.job?.final_ready === true;
  const missingCount = missingRoles.length;
  const coverageLabel = `선택된 역할 보고: ${submitted}/${required}`;
  const headline = ready
    ? 'Ready to finish: all selected reports are in.'
    : missingCount > 0
      ? `Blocked by missing reports: ${missingCount} selected role${missingCount === 1 ? '' : 's'} still need to submit.`
      : 'Final not ready: waiting for the AgentDock workflow gate.';
  const nextAction = ready
    ? 'Next: CEO/orchestrator may run agentdock job finish from the CLI workflow.'
    : missingCount > 0
      ? `Next: ${missingRoles.join(', ')} must run agentdock job report.`
      : 'Next: continue the assigned AgentDock workflow until final readiness is true.';
  const ceoFinalPending = ready
    ? 'CEO final report is now pending in the CLI workflow.'
    : 'The CEO final report can be submitted after missing worker reports arrive.';
  return { submitted, required, missingRoles, missingCount, ready, coverageLabel, headline, nextAction, ceoFinalPending };
}

export function finalReadyLabel(snapshot: WorkspaceSnapshot): string {
  return snapshot.job?.final_ready ? 'Final ready' : 'Final not ready';
}

function safeString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim() ? value : undefined;
}

function normalizeBlockerItem(item: WorkspaceWarning | WorkspaceAlert, fallbackSeverity = 'warning'): BlockerCard {
  if (typeof item === 'string') {
    return { severity: fallbackSeverity, type: 'config_warning', message: item };
  }
  const record = item as Record<string, unknown>;
  const message = safeString(record.message) ?? safeString(record.summary) ?? safeString(record.reason) ?? 'Workspace warning available; see technical evidence.';
  const owner = safeString(record.role) ?? safeString(record.owner);
  return {
    severity: safeString(record.severity) ?? fallbackSeverity,
    type: safeString(record.type) ?? 'unknown',
    message,
    owner,
    nextAction: safeString(record.next_action) ?? safeString(record.nextAction),
    path: safeString(record.path),
  };
}

export function normalizeBlockers(snapshot: WorkspaceSnapshot): BlockerCard[] {
  const alerts = (snapshot.alerts ?? []).map((alert) => normalizeBlockerItem(alert, alert.severity ?? 'critical'));
  const warnings = (snapshot.warnings ?? []).map((warning) => normalizeBlockerItem(warning, 'warning'));
  return [...alerts, ...warnings];
}

export function reportStateForRole(role: WorkspaceRole, snapshot: WorkspaceSnapshot): 'report needed' | 'reported' | 'not required' {
  const missing = new Set(snapshot.reports?.missing_roles ?? []);
  if (missing.has(role.id)) return 'report needed';
  if (role.latest_report_path) return 'reported';
  return role.selected ? 'not required' : 'not required';
}

export function roleActivityLabel(role: WorkspaceRole, snapshot: WorkspaceSnapshot): string {
  const reportState = reportStateForRole(role, snapshot);
  if (reportState === 'report needed') return '작업 카드 배정됨 · 보고 제출 대기';
  if (reportState === 'reported') return '보고 완료';
  if (!role.selected) return '대기 역할 · 현재 job 미참여';
  if (role.running_pane) return `pane ${role.pane_id ?? ''}에서 작업 중`.trim();
  if (role.task_path) return '작업 카드 배정됨';
  return statusLabel(role.status);
}
