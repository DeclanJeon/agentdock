import type { WorkspaceSnapshot } from './snapshot';

export const emptySnapshot: WorkspaceSnapshot = {
  schema_version: 'workspace.snapshot.v1',
  project: { name: 'AgentDock', root: 'not connected' },
  job: {
    id: undefined,
    lifecycle: 'idle',
    final_ready: false,
    final_ready_reason: 'Connect to an AgentDock project to load live snapshot state.',
  },
  reports: { submitted_selected_roles: 0, required_selected_roles: 0, missing_roles: [] },
  roles: [],
  alerts: [],
  warnings: [],
  commands: { mode: 'read-only', write_bridge_enabled: false, allowed_actions: [] },
  layout: { role_count: 0, density: 'normal' },
};
