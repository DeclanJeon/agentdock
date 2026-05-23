import type { WorkspaceAlert, WorkspaceRole, WorkspaceSnapshot } from './snapshot';
import { normalizeBlockers, reportState, reportStateForRole, roleActivityLabel, statusLabel } from './normalize';

export type WorkspaceMode = 'idle' | 'live' | 'stale' | 'error';
export type VisualWorkspaceMode = 'classic' | 'pixelOffice';
export type ZoneId = 'command' | 'mission' | 'build' | 'design' | 'qa' | 'report' | 'blocker' | 'bench' | 'utility';
export type RoleArchetype = 'orchestrator' | 'product' | 'ux' | 'developer' | 'architect' | 'qa' | 'delivery' | 'generic';
export type SceneRoleState = 'working' | 'reported' | 'report-needed' | 'blocked' | 'offline' | 'bench' | 'assigned' | 'unknown';
export type SceneDensity = 'normal' | 'dense' | 'clustered';
export type SceneActivityState = 'typing' | 'reviewing' | 'testing' | 'designing' | 'planning' | 'blocked' | 'reporting' | 'standby' | 'offline';
export type SceneVisualUrgency = 'low' | 'medium' | 'high' | 'critical';

export interface SceneGeometry { x: number; y: number; w: number; h: number; }
export interface SceneZone {
  id: ZoneId;
  title: string;
  subtitle: string;
  geometry: SceneGeometry;
  tone: string;
  roleIds: string[];
}
export interface SceneRole {
  id: string;
  displayName: string;
  role: WorkspaceRole;
  archetype: RoleArchetype;
  zoneId: ZoneId;
  state: SceneRoleState;
  reportState: 'report needed' | 'reported' | 'not required';
  selected: boolean;
  bench: boolean;
  blocked: boolean;
  offline: boolean;
  stationLabel: string;
  pose: string;
  badge: string;
  activityLabel: string;
  activityState: SceneActivityState;
  lastActivityLabel: string;
  recentEventLabel: string;
  visualUrgency: SceneVisualUrgency;
  reportLink: { slotState: 'filled' | 'missing' | 'not-required'; label: string };
  blockerLink?: { owner: string; label: string; severity: string };
  denseMetadata: { rank: number; zoneIndex: number; zoneSize: number; lod: 'full' | 'compact' | 'cluster'; searchableText: string };
  accessibleName: string;
}
export interface SceneReportSlot { roleId: string; label: string; filled: boolean; missing: boolean; }
export interface SceneModel {
  meta: {
    mode: WorkspaceMode;
    schemaVersion?: string;
    generatedAt?: string;
    readOnly: true;
    jobId: string;
    lifecycle: string;
    freshnessLabel: string;
  };
  office: { density: SceneDensity; zones: SceneZone[]; roleCount: number; selectedCount: number; };
  roles: SceneRole[];
  reportDesk: ReturnType<typeof reportState> & { slots: SceneReportSlot[] };
  blockerDesk: { cards: ReturnType<typeof normalizeBlockers>; affectedRoleIds: string[]; hasBlockers: boolean; };
  finalGate: { ready: boolean; label: string; reason: string; nextAction: string; };
  navigation: { zoneJumps: Array<{ id: ZoneId; label: string; count: number }>; filters: string[]; searchableText: string; visibleCount: number; hiddenCount: number; };
}

const zoneBlueprints: Array<Omit<SceneZone, 'roleIds'>> = [
  { id: 'command', title: 'Command Office', subtitle: 'orchestrator command station', geometry: { x: 1, y: 1, w: 18, h: 12 }, tone: 'gold' },
  { id: 'mission', title: 'Mission Board', subtitle: 'job, lifecycle, selected team', geometry: { x: 20, y: 1, w: 18, h: 12 }, tone: 'cyan' },
  { id: 'design', title: 'Product Bay', subtitle: 'roadmap and UX design wall', geometry: { x: 39, y: 1, w: 19, h: 12 }, tone: 'violet' },
  { id: 'build', title: 'Engineering Bay', subtitle: 'developer and architecture consoles', geometry: { x: 1, y: 14, w: 27, h: 13 }, tone: 'blue' },
  { id: 'qa', title: 'Quality Bay', subtitle: 'QA test matrix and screenshot wall', geometry: { x: 29, y: 14, w: 29, h: 13 }, tone: 'mint' },
  { id: 'bench', title: 'Delivery Bay', subtitle: 'milestones and waiting bench roles', geometry: { x: 1, y: 28, w: 14, h: 10 }, tone: 'lounge' },
  { id: 'report', title: 'Report Desk', subtitle: 'selected-role report slots', geometry: { x: 16, y: 28, w: 16, h: 10 }, tone: 'green' },
  { id: 'blocker', title: 'Blocker Desk', subtitle: 'blockers and warnings', geometry: { x: 33, y: 28, w: 10, h: 10 }, tone: 'red' },
  { id: 'utility', title: '안전 구역', subtitle: '승인된 액션만 사용', geometry: { x: 44, y: 28, w: 14, h: 10 }, tone: 'steel' },
];

export function deriveRoleArchetype(role: WorkspaceRole): RoleArchetype {
  const text = `${role.id} ${role.display_name ?? ''} ${role.department ?? ''} ${role.tier ?? ''}`.toLowerCase();
  if (/orchestrator|ceo|executive/.test(text)) return 'orchestrator';
  if (/product|pm/.test(text)) return 'product';
  if (/ux|design/.test(text)) return 'ux';
  if (/architect|system/.test(text)) return 'architect';
  if (/qa|quality|test|review/.test(text)) return 'qa';
  if (/delivery|planner|roadmap/.test(text)) return 'delivery';
  if (/developer|engineer|frontend|backend|code/.test(text)) return 'developer';
  return 'generic';
}

export function deriveRoleZone(role: WorkspaceRole): ZoneId {
  if (role.configured === true && role.selected !== true) return 'bench';
  switch (deriveRoleArchetype(role)) {
    case 'orchestrator': return 'command';
    case 'product':
    case 'ux': return 'design';
    case 'developer':
    case 'architect': return 'build';
    case 'qa': return 'qa';
    case 'delivery': return 'mission';
    default: return role.selected ? 'mission' : 'bench';
  }
}

export function deriveDensity(snapshot: WorkspaceSnapshot): SceneDensity {
  const roleCount = snapshot.layout?.role_count ?? snapshot.roles?.length ?? 0;
  const hinted = snapshot.layout?.density;
  if (hinted === 'clustered' || roleCount >= 36) return 'clustered';
  if (hinted === 'dense' || roleCount >= 18) return 'dense';
  return 'normal';
}

function roleIsBlocked(role: WorkspaceRole, blockers: ReturnType<typeof normalizeBlockers>): boolean {
  if (role.status === 'blocked') return true;
  return blockers.some((card) => card.owner === role.id || card.owner === role.display_name);
}

function deriveRoleState(role: WorkspaceRole, snapshot: WorkspaceSnapshot, blockers: ReturnType<typeof normalizeBlockers>): SceneRoleState {
  if (role.configured === true && role.selected !== true) return 'bench';
  if (role.status === 'offline') return 'offline';
  if (roleIsBlocked(role, blockers)) return 'blocked';
  const report = reportStateForRole(role, snapshot);
  if (report === 'report needed') return 'report-needed';
  if (report === 'reported' || role.status === 'reported' || role.status === 'ready') return 'reported';
  if (role.status === 'working' || role.status === 'running') return 'working';
  if (role.status === 'assigned' || role.selected) return 'assigned';
  return 'unknown';
}

function stationLabel(archetype: RoleArchetype): string {
  const labels: Record<RoleArchetype, string> = {
    orchestrator: 'command desk with decision stamp',
    product: 'roadmap board and acceptance checklist',
    ux: 'pixel canvas and reference board',
    developer: 'multi-monitor build console',
    architect: 'schema table and boundary shield',
    qa: 'test matrix wall and screenshot monitor',
    delivery: 'milestone board and dependency string',
    generic: 'general operations station',
  };
  return labels[archetype];
}

function derivePose(state: SceneRoleState): string {
  const poses: Record<SceneRoleState, string> = {
    working: 'typing', reported: 'stamped', 'report-needed': 'holding-report', blocked: 'needs-help', offline: 'dimmed', bench: 'standby', assigned: 'reading-task', unknown: 'idle',
  };
  return poses[state];
}

function deriveBadge(state: SceneRoleState): string {
  const badges: Record<SceneRoleState, string> = {
    working: '작업 중', reported: '보고 완료', 'report-needed': '보고 필요', blocked: '블로커', offline: '오프라인', bench: '대기', assigned: '배정됨', unknown: '상태 불명',
  };
  return badges[state];
}

function deriveActivityState(archetype: RoleArchetype, state: SceneRoleState, report: SceneRole['reportState']): SceneActivityState {
  if (state === 'offline') return 'offline';
  if (state === 'bench') return 'standby';
  if (state === 'blocked') return 'blocked';
  if (report === 'report needed') return 'reporting';
  if (archetype === 'developer') return 'typing';
  if (archetype === 'qa') return 'testing';
  if (archetype === 'ux') return 'designing';
  if (archetype === 'product' || archetype === 'delivery' || archetype === 'orchestrator') return 'planning';
  if (archetype === 'architect') return 'reviewing';
  return state === 'reported' ? 'reviewing' : 'planning';
}

function deriveVisualUrgency(state: SceneRoleState, report: SceneRole['reportState'], blocked: boolean): SceneVisualUrgency {
  if (blocked || state === 'blocked') return 'critical';
  if (report === 'report needed') return 'high';
  if (state === 'offline') return 'medium';
  return 'low';
}

function deriveRecentEventLabel(role: WorkspaceRole, state: SceneRoleState, report: SceneRole['reportState']): string {
  if (role.status_reason) return role.status_reason;
  if (state === 'blocked') return '블로커가 연결되어 있습니다. Alerts/Inspector에서 원인과 다음 액션을 확인하세요';
  if (report === 'report needed') return 'Selected role still needs a report';
  if (report === 'reported') return 'Latest report is on file';
  if (role.latest_report_path) return 'Report artifact available';
  return statusLabel(role.status);
}

export function deriveAccessibleName(role: SceneRole, zone: SceneZone): string {
  const teamState = role.bench ? 'bench role' : role.selected ? 'selected active role' : 'available role';
  const blocker = role.blockerLink ? `, blocker ${role.blockerLink.severity}` : '';
  return `${role.displayName}, ${teamState}, ${role.state}, ${role.reportState}, ${role.activityState}, ${role.visualUrgency} urgency${blocker}, ${zone.title}`;
}

export function deriveSceneModel(snapshot: WorkspaceSnapshot, options: { mode: WorkspaceMode }): SceneModel {
  const blockers = normalizeBlockers(snapshot);
  const zones = zoneBlueprints.map((zone) => ({ ...zone, roleIds: [] }));
  const zoneMap = new Map<ZoneId, SceneZone>(zones.map((zone) => [zone.id, zone]));
  const roleZoneSizes = new Map<ZoneId, number>();
  for (const role of snapshot.roles ?? []) {
    const zoneId = deriveRoleZone(role);
    roleZoneSizes.set(zoneId, (roleZoneSizes.get(zoneId) ?? 0) + 1);
  }
  const roleZoneSeen = new Map<ZoneId, number>();
  const density = deriveDensity(snapshot);
  const roles = (snapshot.roles ?? []).map((role, rank): SceneRole => {
    const archetype = deriveRoleArchetype(role);
    const zoneId = deriveRoleZone(role);
    const state = deriveRoleState(role, snapshot, blockers);
    const report = reportStateForRole(role, snapshot);
    const blocked = roleIsBlocked(role, blockers);
    const linkedBlocker = blockers.find((card) => card.owner === role.id || card.owner === role.display_name);
    const zoneIndex = roleZoneSeen.get(zoneId) ?? 0;
    roleZoneSeen.set(zoneId, zoneIndex + 1);
    const roleSearchText = `${role.id} ${role.display_name ?? ''} ${role.department ?? ''} ${role.tier ?? ''} ${state} ${report} ${zoneId}`.toLowerCase();
    const sceneRole: SceneRole = {
      id: role.id,
      displayName: role.display_name ?? role.id,
      role,
      archetype,
      zoneId,
      state,
      reportState: report,
      selected: role.selected === true,
      bench: role.configured === true && role.selected !== true,
      blocked,
      offline: state === 'offline',
      stationLabel: stationLabel(archetype),
      pose: derivePose(state),
      badge: deriveBadge(state),
      activityLabel: roleActivityLabel(role, snapshot),
      activityState: deriveActivityState(archetype, state, report),
      lastActivityLabel: roleActivityLabel(role, snapshot),
      recentEventLabel: deriveRecentEventLabel(role, state, report),
      visualUrgency: deriveVisualUrgency(state, report, blocked),
      reportLink: { slotState: report === 'reported' ? 'filled' : report === 'report needed' ? 'missing' : 'not-required', label: report === 'reported' ? 'report slot filled' : report === 'report needed' ? 'amber report slot missing' : 'report not required' },
      blockerLink: linkedBlocker ? { owner: linkedBlocker.owner ?? role.id, label: linkedBlocker.message, severity: linkedBlocker.severity } : undefined,
      denseMetadata: { rank, zoneIndex, zoneSize: roleZoneSizes.get(zoneId) ?? 1, lod: density === 'clustered' ? 'cluster' : density === 'dense' ? 'compact' : 'full', searchableText: roleSearchText },
      accessibleName: '',
    };
    const zone = zoneMap.get(zoneId) ?? zoneMap.get('mission')!;
    sceneRole.accessibleName = deriveAccessibleName(sceneRole, zone);
    zone.roleIds.push(role.id);
    return sceneRole;
  });
  const reports = reportState(snapshot);
  const selectedRoles = roles.filter((role) => role.selected);
  const slots = selectedRoles.map((role) => ({ roleId: role.id, label: role.displayName, filled: role.reportState === 'reported', missing: role.reportState === 'report needed' }));
  const affectedRoleIds = blockers.map((card) => card.owner).filter((value): value is string => Boolean(value));
  const zoneJumps = zones.map((zone) => ({ id: zone.id, label: zone.title, count: zone.roleIds.length }));
  return {
    meta: {
      mode: options.mode,
      schemaVersion: snapshot.schema_version,
      generatedAt: snapshot.generated_at,
      readOnly: true,
      jobId: snapshot.job?.id ?? 'no-active-job',
      lifecycle: snapshot.job?.lifecycle ?? snapshot.job?.lifecycle_status ?? 'unknown',
      freshnessLabel: options.mode === 'live' ? '현재 작업 상태' : options.mode === 'idle' ? '작업 상태 대기 중' : options.mode === 'stale' ? '최근 작업 상태' : '작업 상태 확인 필요',
    },
    office: { density, zones, roleCount: roles.length, selectedCount: selectedRoles.length },
    roles,
    reportDesk: { ...reports, slots },
    blockerDesk: { cards: blockers, affectedRoleIds, hasBlockers: blockers.length > 0 },
    finalGate: { ready: reports.ready, label: reports.ready ? 'Final ready' : 'Final not ready', reason: snapshot.job?.final_ready_reason ?? reports.headline, nextAction: reports.nextAction },
    navigation: { zoneJumps, filters: ['active', 'missing report', 'blocked', 'reported', 'bench', 'offline'], searchableText: roles.map((role) => `${role.id} ${role.displayName} ${role.state} ${role.zoneId}`).join(' ').toLowerCase(), visibleCount: roles.length, hiddenCount: 0 },
  };
}
