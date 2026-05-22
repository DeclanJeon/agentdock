import type { WorkspaceRole, WorkspaceSnapshot } from './snapshot';

export type JobCapability = 'product' | 'ux' | 'architecture' | 'frontend' | 'backend' | 'qa' | 'delivery' | 'security' | 'docs' | 'research';

export interface JobIntent {
  capabilities: JobCapability[];
  confidence: 'low' | 'medium' | 'high';
  rationale: string[];
}

export interface TeamPlanRecommendation {
  capability: JobCapability | 'agency';
  roleHint: string;
  templateHint: string;
  reason: string;
  matchedRole?: string;
  score?: number;
  source?: 'snapshot' | 'ui';
}

export interface TeamPlanView {
  coordinator?: string;
  selectedRoles: string[];
  tfts: string[];
  recommendations: TeamPlanRecommendation[];
  policy: string;
}

const CAPABILITY_KEYWORDS: Record<JobCapability, RegExp[]> = {
  product: [/기획|요구|prd|product|scope|유저|사용자/i],
  ux: [/ui|ux|화면|레이아웃|디자인|반응형|버튼|visual|figma/i],
  architecture: [/설계|architecture|구조|시스템|경계|contract|api/i],
  frontend: [/frontend|react|css|tsx|브라우저|tauri|화면/i],
  backend: [/backend|server|api|rust|cli|bash|데이터|로직/i],
  qa: [/qa|test|검증|테스트|품질|버그|회귀/i],
  delivery: [/release|배포|문서|완료|handoff|delivery|작업지시/i],
  security: [/보안|security|권한|secret|redact|sandbox|shell|안전/i],
  docs: [/docs|문서|체크리스트|작업지시서|readme|guide/i],
  research: [/research|조사|벤치마크|레퍼런스|비교/i],
};

const ROLE_HINTS: Record<JobCapability, { roleHint: string; templateHint: string; reason: string }> = {
  product: { roleHint: 'product-manager', templateHint: 'product-manager', reason: '요구사항과 acceptance criteria 정리가 필요합니다.' },
  ux: { roleHint: 'ux-designer', templateHint: 'ux-designer', reason: '화면 흐름, 반응형, 시각 계층 정리가 필요합니다.' },
  architecture: { roleHint: 'architect', templateHint: 'architect', reason: '계약, 경계, 장기 구조 판단이 필요합니다.' },
  frontend: { roleHint: 'frontend-developer', templateHint: 'developer', reason: 'React/Tauri UI 구현이 필요합니다.' },
  backend: { roleHint: 'runtime-developer', templateHint: 'developer', reason: 'CLI/Tauri/runtime 로직 구현이 필요합니다.' },
  qa: { roleHint: 'agentdock-qa', templateHint: 'qa', reason: '회귀 테스트와 release evidence가 필요합니다.' },
  delivery: { roleHint: 'delivery-planner', templateHint: 'delivery-planner', reason: '완료 기준과 산출물 묶음이 필요합니다.' },
  security: { roleHint: 'security-reviewer', templateHint: 'security-reviewer', reason: '권한·비밀정보·shell 경계 검토가 필요합니다.' },
  docs: { roleHint: 'technical-writer', templateHint: 'writer', reason: '문서/체크리스트/작업지시 산출물이 필요합니다.' },
  research: { roleHint: 'researcher', templateHint: 'researcher', reason: '외부/내부 근거 조사와 비교가 필요합니다.' },
};

function matchRole(capability: JobCapability, roles: WorkspaceRole[]): string | undefined {
  const hint = ROLE_HINTS[capability].roleHint;
  const fragments = [hint, capability, ...hint.split('-')].filter(Boolean);
  return roles.find((role) => fragments.some((fragment) => role.id.toLowerCase().includes(fragment.toLowerCase())))?.id;
}

export function inferJobIntent(text: string): JobIntent {
  const capabilities = (Object.keys(CAPABILITY_KEYWORDS) as JobCapability[]).filter((capability) =>
    CAPABILITY_KEYWORDS[capability].some((pattern) => pattern.test(text)),
  );
  const unique: JobCapability[] = capabilities.length ? capabilities : ['product', 'architecture', 'frontend', 'qa'];
  return {
    capabilities: unique,
    confidence: capabilities.length >= 3 ? 'high' : capabilities.length > 0 ? 'medium' : 'low',
    rationale: unique.map((capability) => ROLE_HINTS[capability].reason),
  };
}

export function teamPlanFromSnapshot(snapshot: WorkspaceSnapshot, latestRequest = ''): TeamPlanView {
  const roles = snapshot.roles ?? [];
  const selectedRoles = snapshot.team_plan?.selected_roles ?? roles.filter((role) => role.selected).map((role) => role.id);
  const intent = inferJobIntent(latestRequest || `${snapshot.job?.lifecycle ?? ''} ${selectedRoles.join(' ')}`);
  const snapshotRecommendations = (snapshot.team_plan?.recommendations ?? [])
    .filter((item) => item.template_id || item.display_name)
    .map((item) => ({
      capability: 'agency' as const,
      roleHint: item.template_id?.replace(/^agency-/, '') ?? item.display_name ?? 'agency-specialist',
      templateHint: item.template_id ?? 'agency-specialist',
      reason: item.reason ?? '작업 요청에 맞는 큐레이션 specialist 후보입니다.',
      score: item.score,
      source: 'snapshot' as const,
      matchedRole: roles.find((role) => role.template_id === item.template_id || role.agency_profile?.template_id === item.template_id)?.id,
    }));
  const uiRecommendations = intent.capabilities.map((capability) => ({
    capability,
    ...ROLE_HINTS[capability],
    matchedRole: matchRole(capability, roles),
    source: 'ui' as const,
  }));
  const recommendations = snapshotRecommendations.length ? snapshotRecommendations : uiRecommendations;
  return {
    coordinator: snapshot.team_plan?.coordinator ?? roles.find((role) => role.id.includes('orchestrator') || role.id.includes('ceo'))?.id,
    selectedRoles,
    tfts: (snapshot.tfts ?? []).map((tft) => tft.name).filter(Boolean),
    recommendations,
    policy: snapshot.team_plan?.policy ?? 'Reuse configured/running roles first; recruit missing capabilities only.',
  };
}
