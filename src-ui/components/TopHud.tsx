import type { WorkspaceSnapshot } from '../model/snapshot';
import { finalReadyLabel } from '../model/normalize';

export function TopHud({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: string }) {
  const job = snapshot.job ?? {};
  const reports = snapshot.reports ?? {};
  const lifecycle = job.lifecycle_status ?? job.lifecycle ?? 'unknown';
  const submitted = reports.submitted_selected_roles ?? reports.submitted ?? reports.total ?? 0;
  const required = reports.required_selected_roles ?? reports.required ?? 0;
  const readOnlyMode = snapshot.commands?.mode ?? 'read-only';
  const writeBridgeEnabled = snapshot.commands?.write_bridge_enabled === true;
  const allowedActions = snapshot.commands?.allowed_actions ?? [];
  const localTime = new Date().toLocaleTimeString();

  return (
    <header className="top-hud reference-top-bar" aria-label="AgentDock desktop workspace status">
      <div className="brand-lockup">
        <h1>AgentDock Visual Office</h1>
        <span className="divider" aria-hidden="true">|</span>
        <span className="snapshot-mode">Read-only snapshot</span>
        <span className={writeBridgeEnabled ? 'trust-pill warn' : 'trust-pill good'} aria-label="Write bridge status">
          🔒 {writeBridgeEnabled ? 'write bridge enabled' : 'write bridge disabled'}
        </span>
      </div>
      <div className="hud-badges compact-hud-badges">
        <span>Job: {job.id || 'none'}</span>
        <span>Lifecycle: {lifecycle}</span>
        <span className={job.final_ready ? 'good' : 'warn'}>✅ {finalReadyLabel(snapshot)}</span>
        <span className="report-count">Reports: {submitted}/{required}</span>
        <span className="clock">{localTime}<small>Local</small></span>
        <span className="mode-chip">Mode: {mode}</span>
        <span className="read-only-chip">{readOnlyMode}</span>
        <span className="controlled-action-chip">Allowed action: {allowedActions.length ? allowedActions.join(', ') : 'none'}</span>
      </div>
    </header>
  );
}
