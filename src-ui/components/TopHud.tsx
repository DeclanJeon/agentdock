import type { WorkspaceSnapshot } from '../model/snapshot';
import { finalReadyLabel } from '../model/normalize';
import type { WorkspaceMode } from '../model/scene';

export function TopHud({ snapshot, mode = 'idle', lastUpdatedAt }: { snapshot: WorkspaceSnapshot; mode?: WorkspaceMode; lastUpdatedAt?: string | null }) {
  const job = snapshot.job ?? {};
  const reports = snapshot.reports ?? {};
  const lifecycle = job.lifecycle_status ?? job.lifecycle ?? 'unknown';
  const submitted = reports.submitted_selected_roles ?? reports.submitted ?? reports.total ?? 0;
  const required = reports.required_selected_roles ?? reports.required ?? 0;
  const writeBridgeEnabled = snapshot.commands?.write_bridge_enabled === true;
  const sourceLabel = mode === 'live' ? 'Live' : mode === 'stale' ? 'Stale' : mode === 'error' ? 'Error fallback' : 'Not connected';
  const staleAlerts = (snapshot.alerts ?? []).filter((alert) => alert.type === 'stale_role').length;
  const blockerAlerts = (snapshot.alerts ?? []).filter((alert) => alert.severity === 'error' || alert.type === 'blocker').length;

  return (
    <header className="top-hud reference-top-bar" aria-label="AgentDock desktop workspace status">
      <div className="brand-lockup">
        <div className="brand-mark" aria-hidden="true">AD</div>
        <div className="brand-copy">
          <p className="eyebrow">Read-only operations console</p>
          <h1>AgentDock Visual Office</h1>
        </div>
        <span className={writeBridgeEnabled ? 'trust-pill warn' : 'trust-pill good'} aria-label="Write bridge status">
          🔒 {writeBridgeEnabled ? 'write bridge enabled' : 'write bridge disabled'}
        </span>
      </div>
      <div className="hud-badges compact-hud-badges" aria-label="Workspace snapshot summary">
        <span className="mode-chip">Source: {sourceLabel}</span>
        <span className="job-chip" title={job.id || 'none'}>Job: {job.id || 'none'}</span>
        <span>Lifecycle: {lifecycle}</span>
        <span className="report-count">Reports: {submitted}/{required}</span>
        <span className={staleAlerts > 0 ? 'warn' : 'good'}>Heartbeat: {staleAlerts > 0 ? `${staleAlerts} stale` : 'ok'}</span>
        <span className={blockerAlerts > 0 ? 'warn' : 'good'}>Blockers: {blockerAlerts}</span>
        <span className={job.final_ready ? 'good' : 'warn'}>Final: {finalReadyLabel(snapshot)}</span>
        <time className="clock" dateTime={lastUpdatedAt ?? snapshot.generated_at ?? undefined}>
          <small>Updated</small>
          {lastUpdatedAt ? new Date(lastUpdatedAt).toLocaleTimeString() : snapshot.generated_at ? new Date(snapshot.generated_at).toLocaleTimeString() : 'pending'}
        </time>
      </div>
    </header>
  );
}
