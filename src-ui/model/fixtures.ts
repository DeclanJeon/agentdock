import type { WorkspaceSnapshot } from './snapshot';

export const demoSnapshot: WorkspaceSnapshot = {
  schema_version: 'workspace.snapshot.demo',
  generated_at: new Date().toISOString(),
  project: { name: 'AgentDock Demo', root: 'not connected' },
  job: { id: 'demo', lifecycle: 'desktop-preview', final_ready: false, final_ready_reason: 'Connect to an AgentDock project to load live snapshot state.' },
  reports: { submitted_selected_roles: 1, required_selected_roles: 6, missing_roles: ['product-manager', 'ux-designer', 'developer', 'agentdock-qa', 'delivery-planner'] },
  roles: [
    { id: 'orchestrator', display_name: 'CEO', department: 'Executive', tier: 'ceo', selected: true, status: 'working', latest_report_path: '.agent-work/demo/orchestrator.md', status_reason: 'Demo coordination loop' },
    { id: 'product-manager', department: 'Product', selected: true, status: 'assigned', status_reason: 'Demo scope task assigned' },
    { id: 'ux-designer', department: 'UX', selected: true, status: 'working', status_reason: 'Demo office layout design in progress' },
    { id: 'system-architect', department: 'Engineering', selected: true, status: 'reported', latest_report_path: '.agent-work/demo/architect.md', status_reason: 'Demo architecture report submitted' },
    { id: 'developer', department: 'Engineering', selected: true, status: 'working', status_reason: 'Demo implementation active' },
    { id: 'agentdock-qa', department: 'Quality', selected: true, status: 'blocked', status_reason: 'Demo gate waiting for app build evidence' },
    { id: 'delivery-planner', department: 'Delivery', selected: true, status: 'assigned', status_reason: 'Demo roadmap task assigned' },
    { id: 'researcher', department: 'Research', configured: true, selected: false, status: 'configured', status_reason: 'Demo bench role' },
  ],
  alerts: [{ severity: 'warning', type: 'demo_blocker', role: 'agentdock-qa', message: 'Demo gate waiting for native evidence.', next_action: 'Run native screenshot capture in a release job.' }],
  warnings: ['Demo mode: live AgentDock snapshot was not loaded yet.'],
  commands: { mode: 'read-only', write_bridge_enabled: false },
  layout: { role_count: 8, density: 'normal' },
};
