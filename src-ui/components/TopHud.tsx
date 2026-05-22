import type { WorkspaceSnapshot } from '../model/snapshot';
import { finalReadyLabel } from '../model/normalize';

export function TopHud({ snapshot }: { snapshot: WorkspaceSnapshot; mode?: string }) {
  const job = snapshot.job ?? {};
  const reports = snapshot.reports ?? {};
  const lifecycle = job.lifecycle_status ?? job.lifecycle ?? 'unknown';
  const submitted = reports.submitted_selected_roles ?? reports.submitted ?? reports.total ?? 0;
  const required = reports.required_selected_roles ?? reports.required ?? 0;
  const writeBridgeEnabled = snapshot.commands?.write_bridge_enabled === true;

  return (
    <header className="top-hud reference-top-bar" aria-label="AgentDock desktop workspace status">
      <div className="brand-lockup">
        <h1>AgentDock Visual Office</h1>
        <span className="divider" aria-hidden="true">|</span>
        <span className="snapshot-mode">Visual Office workspace</span>
        <span className={writeBridgeEnabled ? 'trust-pill warn' : 'trust-pill good'} aria-label="Write bridge status">
          🔒 {writeBridgeEnabled ? 'write bridge enabled' : 'write bridge disabled'}
        </span>
      </div>
      <div className="hud-badges compact-hud-badges">
        <span className="job-chip" title={job.id || 'none'}>Job: {job.id || 'none'}</span>
        <span>Lifecycle: {lifecycle}</span>
        <span className="report-count">Reports: {submitted}/{required}</span>
        <span className={job.final_ready ? 'good' : 'warn'}>Final: {finalReadyLabel(snapshot)}</span>
      </div>
    </header>
  );
}
