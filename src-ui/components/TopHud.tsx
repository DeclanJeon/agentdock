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
  const sourceLabel = mode === 'live' ? '연결됨' : mode === 'stale' ? '최근 상태' : mode === 'error' ? '확인 필요' : '대기';
  const staleAlerts = (snapshot.alerts ?? []).filter((alert) => alert.type === 'stale_role').length;
  const blockerAlerts = (snapshot.alerts ?? []).filter((alert) => alert.severity === 'error' || alert.type === 'blocker').length;

  return (
    <header className="top-hud reference-top-bar" aria-label="AgentDock desktop workspace status">
      <div className="brand-lockup">
        <div className="brand-mark" aria-hidden="true">AD</div>
        <div className="brand-copy">
          <p className="eyebrow">작업 운영 화면</p>
          <h1>AgentDock Visual Office</h1>
        </div>
        <span className={writeBridgeEnabled ? 'trust-pill warn' : 'trust-pill good'} aria-label="Write bridge status">
          🔒 {writeBridgeEnabled ? '관리 액션 가능' : '안전 모드'}
        </span>
      </div>
      <div className="hud-badges compact-hud-badges" aria-label="Workspace summary">
        <span className="mode-chip">상태: {sourceLabel}</span>
        <span className="job-chip" title={job.id || 'none'}>작업: {job.id || '없음'}</span>
        <span>단계: {lifecycle}</span>
        <span className="report-count">보고: {submitted}/{required}</span>
        <span className={staleAlerts > 0 ? 'warn' : 'good'}>팀 상태: {staleAlerts > 0 ? `${staleAlerts}개 확인` : '정상'}</span>
        <span className={blockerAlerts > 0 ? 'warn' : 'good'}>확인 필요: {blockerAlerts}</span>
        <span className={job.final_ready ? 'good' : 'warn'}>최종: {finalReadyLabel(snapshot)}</span>
        <time className="clock" dateTime={lastUpdatedAt ?? snapshot.generated_at ?? undefined}>
          <small>업데이트</small>
          {lastUpdatedAt ? new Date(lastUpdatedAt).toLocaleTimeString() : snapshot.generated_at ? new Date(snapshot.generated_at).toLocaleTimeString() : '대기'}
        </time>
      </div>
    </header>
  );
}
