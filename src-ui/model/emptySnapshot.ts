import type { WorkspaceSnapshot } from './snapshot';

function projectNameFromRoot(projectRoot: string): string | undefined {
  const cleaned = projectRoot.trim().replace(/\/+$/, '');
  if (!cleaned || cleaned === '.') return undefined;
  return cleaned.split('/').filter(Boolean).pop();
}

export function createEmptyWorkspaceSnapshot(projectRoot = ''): WorkspaceSnapshot {
  const cleanedRoot = projectRoot.trim() === '.' ? '' : projectRoot.trim();
  return {
    schema_version: 'workspace.snapshot.v1',
    project: { name: projectNameFromRoot(cleanedRoot), root: cleanedRoot },
    job: {
      lifecycle: 'idle',
      final_ready: false,
      final_ready_reason: '',
    },
    reports: { submitted_selected_roles: 0, required_selected_roles: 0, missing_roles: [] },
    roles: [],
    alerts: [],
    warnings: [],
    commands: { mode: 'read-only', write_bridge_enabled: false, allowed_actions: [] },
    orchestration: { mode: 'idle', reason: '작업을 만들면 CEO가 규모와 위험도를 판단합니다.', requires_qa: false, team_cap: 0 },
    dependencies: { schema_version: 'agentdock.dependencies.v1', items: [] },
    meetings: { schema_version: 'agentdock.meetings.v1', items: [] },
    write_conflicts: { schema_version: 'agentdock.write_conflicts.v1', items: [] },
    communications: { schema_version: 'agentdock.communications.v1', items: [] },
    qa: { required: false, status: 'not_required' },
    layout: { role_count: 0, density: 'normal' },
  };
}
