import { useCallback, useEffect, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import type { CommandResult, WorkspaceRole, WorkspaceSnapshot } from './model/snapshot';
import type { ControlledActionName, ControlledActionResult, JobCreateResult } from './model/actions';
import { isSupportedSnapshot, observedSchema, redactText, SUPPORTED_SCHEMA_VERSION } from './model/snapshot';
import type { VisualWorkspaceMode, WorkspaceMode } from './model/scene';
import { emptySnapshot } from './model/fixtures';
import { TopHud } from './components/TopHud';
import { PixelOffice } from './components/PixelOffice';
import { Inspector } from './components/Inspector';
import { OfficeScene } from './scene/OfficeScene';
import { CeoTaskComposer } from './components/CeoTaskComposer';
import { FacilitationTimeline } from './components/FacilitationTimeline';
import { ActionAuditPanel } from './components/ActionAuditPanel';
import { InterventionPanel } from './components/InterventionPanel';
import { JobHistoryPanel } from './components/JobHistoryPanel';
import { TeamActivityPanel } from './components/TeamActivityPanel';
import { completeControlledActionAudit, completeJobCreateAudit, newAuditAttempt, type ActionAuditEvent } from './model/actionAudit';

function projectRootFromLocation(): string {
  const params = new URLSearchParams(window.location.search);
  return params.get('project') ?? document.body.dataset.projectRoot ?? window.localStorage.getItem('agentdock.projectRoot') ?? '.';
}

function snapshotErrorMessage(result: CommandResult): string {
  return redactText(result.message || result.stderr || result.stdout || result.errorKind || 'AgentDock snapshot command failed.');
}

function initialVisualMode(): VisualWorkspaceMode {
  const params = new URLSearchParams(window.location.search);
  const requested = params.get('visualWorkspaceMode') ?? params.get('visual');
  if (requested === 'classic' || requested === 'pixelOffice') return requested;
  const stored = window.localStorage.getItem('agentdock.visualWorkspaceMode');
  return stored === 'classic' || stored === 'pixelOffice' ? stored : 'pixelOffice';
}

function unsupportedSchemaMessage(snapshot: WorkspaceSnapshot): string {
  return `Unsupported snapshot schema: ${observedSchema(snapshot)}. Expected ${SUPPORTED_SCHEMA_VERSION}.`;
}

function stableSnapshotSignature(snapshot: WorkspaceSnapshot): string {
  const stable = { ...snapshot, generated_at: undefined };
  return JSON.stringify(stable);
}

type SnapshotRefreshOutcome = 'succeeded' | 'failed' | 'skipped';
type LiveRefreshStatus = 'starting' | 'watching' | 'changed' | 'fallback' | 'unavailable';

interface LiveRefreshState {
  status: LiveRefreshStatus;
  message: string;
  lastEventAt?: string | null;
}

interface WorkspaceChangedPayload {
  projectRoot?: string;
  changedAt?: string;
  fileCount?: number;
  source?: string;
}

function SecurityStatusStrip({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const readOnlyMode = snapshot.commands?.mode ?? 'read-only';
  const allowedActions = snapshot.commands?.allowed_actions ?? [];
  return (
    <aside className="security-status-strip" aria-label="Read-only security and action boundary">
      <span><strong>Mode</strong>{mode}</span>
      <span><strong>Snapshot</strong>{readOnlyMode}</span>
      <span><strong>Allowed action</strong>{allowedActions.length ? allowedActions.join(', ') : 'none'}</span>
    </aside>
  );
}

function ErrorStrip({ mode, error, lastUpdatedAt }: { mode: WorkspaceMode; error: string | null; lastUpdatedAt: string | null }) {
  if (!error) return null;
  const prefix = mode === 'stale' ? 'Showing last-good snapshot' : 'Live snapshot unavailable';
  return (
    <div className={`error-strip mode-${mode}`} role="status" aria-live="polite">
      {prefix}: {error}
      {lastUpdatedAt ? <span className="last-good-note"> Last good: {new Date(lastUpdatedAt).toLocaleTimeString()}</span> : null}
    </div>
  );
}

function LiveRefreshPanel({ state, refreshInFlight }: { state: LiveRefreshState; refreshInFlight: boolean }) {
  const label = state.status === 'watching' ? '실시간 감시 중'
    : state.status === 'changed' ? '변경 감지됨'
      : state.status === 'fallback' ? '백업 동기화'
        : state.status === 'unavailable' ? '감시 불가'
          : '감시 준비 중';
  return (
    <section className={`live-refresh-panel state-${state.status}`} aria-label="Live workspace refresh status">
      <div>
        <p className="eyebrow">Live sync</p>
        <h2>{label}</h2>
      </div>
      <p>{state.message}</p>
      <small>
        {refreshInFlight ? '상태를 반영하는 중…' : state.lastEventAt ? `마지막 변경: ${new Date(Number(state.lastEventAt)).toLocaleTimeString()}` : '파일 변경 시 자동 갱신'}
      </small>
    </section>
  );
}

function OperatorGuidePanel({ snapshot, selectedRole }: { snapshot: WorkspaceSnapshot; selectedRole?: WorkspaceRole }) {
  const hasJob = Boolean(snapshot.job?.id);
  const selectedCount = (snapshot.roles ?? []).filter((role) => role.selected).length;
  const missingReports = snapshot.reports?.missing_roles?.length ?? 0;
  const blockerCount = snapshot.alerts?.length ?? 0;
  const nextStep = !hasJob
    ? '위 Command Center에 작업을 적고 Send to CEO를 누르세요.'
    : blockerCount > 0
      ? 'Alerts/블로커 역할을 선택해 원인과 후속 지시를 확인하세요.'
      : missingReports > 0
        ? '보고 필요 역할을 확인하고 Report 액션을 진행하세요.'
        : snapshot.job?.final_ready
          ? 'Final Gate가 준비되었습니다. 최종 요약을 검토하세요.'
          : '팀 활동 패널에서 현재 역할별 작업을 확인하세요.';
  return (
    <section className="operator-guide-panel" aria-label="Operator quick guide">
      <header>
        <p className="eyebrow">Quick guide</p>
        <h2>지금 무엇을 보면 되나</h2>
      </header>
      <ol>
        <li className={hasJob ? 'done' : 'active'}><span>1</span><p>작업 입력</p></li>
        <li className={selectedCount > 0 ? 'done' : hasJob ? 'active' : ''}><span>2</span><p>CEO 팀 구성</p></li>
        <li className={blockerCount > 0 ? 'blocked' : missingReports > 0 ? 'active' : selectedCount > 0 ? 'done' : ''}><span>3</span><p>팀 작업/보고 확인</p></li>
      </ol>
      <p className="operator-next-action">{nextStep}</p>
      {selectedRole ? <small>현재 선택: {selectedRole.display_name ?? selectedRole.id}</small> : <small>역할을 클릭하면 상세 패널이 바뀝니다.</small>}
    </section>
  );
}

export default function App() {
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot>(emptySnapshot);
  const [lastGoodSnapshot, setLastGoodSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const lastGoodSnapshotRef = useRef<WorkspaceSnapshot | null>(null);
  const [selectedRole, setSelectedRole] = useState<WorkspaceRole | undefined>(undefined);
  const [mode, setMode] = useState<WorkspaceMode>('idle');
  const [visualMode, setVisualMode] = useState<VisualWorkspaceMode>(initialVisualMode);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<string | null>(null);
  const [refreshInFlight, setRefreshInFlight] = useState(false);
  const [lastCreateRefreshStatus, setLastCreateRefreshStatus] = useState<'idle' | 'pending' | 'succeeded' | 'failed'>('idle');
  const [auditEvents, setAuditEvents] = useState<ActionAuditEvent[]>([]);
  const [liveRefresh, setLiveRefresh] = useState<LiveRefreshState>({
    status: 'starting',
    message: '워크스페이스 파일 변경 감시를 시작합니다.',
    lastEventAt: null,
  });
  const refreshInFlightRef = useRef(false);
  const snapshotSignatureRef = useRef('');
  const eventRefreshTimerRef = useRef<number | null>(null);

  const switchVisualMode = useCallback((nextMode: VisualWorkspaceMode) => {
    setVisualMode(nextMode);
    window.localStorage.setItem('agentdock.visualWorkspaceMode', nextMode);
  }, []);

  const loadSnapshot = useCallback(async (): Promise<SnapshotRefreshOutcome> => {
    if (refreshInFlightRef.current) return 'skipped';
    refreshInFlightRef.current = true;
    setRefreshInFlight(true);
    try {
      const result = await invoke<CommandResult>('workspace_snapshot', { projectRoot: projectRootFromLocation() });
      if (result.ok && result.parsed) {
        const previousGoodSnapshot = lastGoodSnapshotRef.current;
        if (!isSupportedSnapshot(result.parsed)) {
          const message = unsupportedSchemaMessage(result.parsed);
          setError(message);
          setMode(previousGoodSnapshot ? 'stale' : 'error');
          if (!previousGoodSnapshot) {
            setSnapshot(emptySnapshot);
            setSelectedRole(undefined);
          }
          return 'failed';
        }
        const nextSignature = stableSnapshotSignature(result.parsed);
        if (nextSignature !== snapshotSignatureRef.current) {
          snapshotSignatureRef.current = nextSignature;
          setSnapshot(result.parsed);
          lastGoodSnapshotRef.current = result.parsed;
          setLastGoodSnapshot(result.parsed);
          setSelectedRole((current) => result.parsed?.roles?.find((role) => role.id === current?.id) ?? result.parsed?.roles?.[0]);
        }
        setMode('live');
        setError(null);
        setLastUpdatedAt(new Date().toISOString());
        return 'succeeded';
      } else {
        const previousGoodSnapshot = lastGoodSnapshotRef.current;
        const message = snapshotErrorMessage(result);
        setError(message);
        setMode(previousGoodSnapshot ? 'stale' : 'error');
        if (!previousGoodSnapshot) {
          setSnapshot(emptySnapshot);
          setSelectedRole(undefined);
        }
        return 'failed';
      }
    } catch (err) {
      const previousGoodSnapshot = lastGoodSnapshotRef.current;
      const message = redactText(err instanceof Error ? err.message : String(err));
      setError(message);
      setMode(previousGoodSnapshot ? 'stale' : 'error');
      if (!previousGoodSnapshot) {
        setSnapshot(emptySnapshot);
        setSelectedRole(undefined);
      }
      return 'failed';
    } finally {
      refreshInFlightRef.current = false;
      setRefreshInFlight(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    let unlisten: UnlistenFn | null = null;
    const guardedLoad = async () => {
      if (!cancelled) await loadSnapshot();
    };
    const scheduleEventRefresh = (payload?: WorkspaceChangedPayload) => {
      if (eventRefreshTimerRef.current) window.clearTimeout(eventRefreshTimerRef.current);
      setLiveRefresh({
        status: 'changed',
        message: payload?.fileCount ? `${payload.fileCount}개 워크스페이스 파일 범위에서 변경이 감지되었습니다.` : '워크스페이스 변경이 감지되었습니다.',
        lastEventAt: payload?.changedAt ?? String(Date.now()),
      });
      eventRefreshTimerRef.current = window.setTimeout(() => {
        eventRefreshTimerRef.current = null;
        if (!document.hidden) void guardedLoad();
      }, 650);
    };

    guardedLoad();
    invoke<CommandResult>('workspace_watch_start', { projectRoot: projectRootFromLocation() })
      .then((result) => {
        if (cancelled) return;
        if (result.ok) {
          setLiveRefresh({
            status: 'watching',
            message: '스냅샷을 반복 생성하지 않고, 파일 변경 이벤트가 있을 때만 화면을 갱신합니다.',
            lastEventAt: null,
          });
        } else {
          setLiveRefresh({
            status: 'fallback',
            message: `실시간 감시를 시작하지 못해 저빈도 백업 동기화만 사용합니다: ${snapshotErrorMessage(result)}`,
            lastEventAt: null,
          });
        }
      })
      .catch((error) => {
        if (cancelled) return;
        setLiveRefresh({
          status: 'unavailable',
          message: `실시간 감시 연결 실패: ${redactText(error instanceof Error ? error.message : String(error))}`,
          lastEventAt: null,
        });
      });
    listen<WorkspaceChangedPayload>('workspace_changed', (event) => scheduleEventRefresh(event.payload))
      .then((dispose) => {
        if (cancelled) dispose();
        else unlisten = dispose;
      })
      .catch((error) => {
        if (cancelled) return;
        setLiveRefresh({
          status: 'unavailable',
          message: `실시간 이벤트 수신 실패: ${redactText(error instanceof Error ? error.message : String(error))}`,
          lastEventAt: null,
        });
      });
    const onVisibilityChange = () => {
      if (!document.hidden) void guardedLoad();
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    const id = window.setInterval(() => {
      if (!document.hidden) void guardedLoad();
    }, 60000);
    return () => {
      cancelled = true;
      if (eventRefreshTimerRef.current) window.clearTimeout(eventRefreshTimerRef.current);
      eventRefreshTimerRef.current = null;
      unlisten?.();
      document.removeEventListener('visibilitychange', onVisibilityChange);
      window.clearInterval(id);
    };
  }, [loadSnapshot]);

  const createCeoJob = useCallback(async (request: string): Promise<JobCreateResult> => {
    const attempt = newAuditAttempt('agentdock_job_create', request);
    setAuditEvents((events) => [attempt, ...events].slice(0, 20));
    const result = await invoke<JobCreateResult>('agentdock_job_create', { projectRoot: projectRootFromLocation(), request });
    setAuditEvents((events) => events.map((event) => event.id === attempt.id ? completeJobCreateAudit(event, result) : event));
    if (result.ok) {
      setLastCreateRefreshStatus('pending');
      const refreshOutcome = await loadSnapshot();
      setLastCreateRefreshStatus(refreshOutcome === 'succeeded' ? 'succeeded' : refreshOutcome === 'failed' ? 'failed' : 'pending');
    }
    return result;
  }, [loadSnapshot]);

  const runControlledAction = useCallback(async (action: ControlledActionName, payload: Record<string, string>): Promise<ControlledActionResult> => {
    const attempt = newAuditAttempt(action, Object.entries(payload).map(([key, value]) => `${key}=${value}`).join(' '));
    setAuditEvents((events) => [attempt, ...events].slice(0, 30));
    const result = await invoke<ControlledActionResult>(action, { projectRoot: projectRootFromLocation(), ...payload });
    setAuditEvents((events) => events.map((event) => event.id === attempt.id ? completeControlledActionAudit(event, result) : event));
    if (result.ok && action !== 'agentdock_recruit_preview' && action !== 'agentdock_finish_preview') {
      await loadSnapshot();
    }
    return result;
  }, [loadSnapshot]);

  return (
    <div className={`app-shell mode-${mode} visual-mode-${visualMode}`}>
      <TopHud snapshot={snapshot} mode={mode} lastUpdatedAt={lastUpdatedAt} />
      <ErrorStrip mode={mode} error={error} lastUpdatedAt={lastUpdatedAt} />
      <section className="ceo-command-center" aria-label="Primary CEO command input">
        <CeoTaskComposer onCreateJob={createCeoJob} refreshStatus={lastCreateRefreshStatus} lastRefreshAt={lastUpdatedAt} />
      </section>
      <div className="workspace-mainframe">
        <aside className="workspace-sidecar" aria-label="Operations and snapshot controls">
          <section className="snapshot-control-card" aria-label="Snapshot refresh and view controls">
            <header>
              <p className="eyebrow">Snapshot</p>
              <h2>상태 새로고침</h2>
            </header>
            <button type="button" onClick={loadSnapshot} disabled={refreshInFlight}>
              {refreshInFlight ? 'Refreshing…' : 'Refresh snapshot'}
            </button>
            <p>{lastUpdatedAt ? `Last refresh: ${new Date(lastUpdatedAt).toLocaleTimeString()}` : 'Waiting for live refresh'}</p>
            <div className="visual-mode-switch" aria-label="Visual workspace render mode">
              <button type="button" className={visualMode === 'pixelOffice' ? 'active' : ''} onClick={() => switchVisualMode('pixelOffice')}>
                Visual Office
              </button>
              <button type="button" className={visualMode === 'classic' ? 'active' : ''} onClick={() => switchVisualMode('classic')}>
                Classic
              </button>
            </div>
            <SecurityStatusStrip snapshot={snapshot} mode={mode} />
          </section>
          <LiveRefreshPanel state={liveRefresh} refreshInFlight={refreshInFlight} />
          <OperatorGuidePanel snapshot={snapshot} selectedRole={selectedRole} />
          <FacilitationTimeline snapshot={snapshot} mode={mode} />
          <TeamActivityPanel snapshot={snapshot} selectedRoleId={selectedRole?.id} onSelectRole={setSelectedRole} />
          <div className="auxiliary-panel-dock sidecar-auxiliary" aria-label="Secondary audit and intervention panels">
            <ActionAuditPanel events={auditEvents} />
            <JobHistoryPanel snapshot={snapshot} />
            <InterventionPanel snapshot={snapshot} onControlledAction={runControlledAction} />
          </div>
        </aside>

        <section className="workspace-stage" aria-label="AgentDock visual workspace stage">
          {visualMode === 'pixelOffice' ? (
            <OfficeScene snapshot={snapshot} mode={mode} selectedRoleId={selectedRole?.id} onSelectRole={setSelectedRole} />
          ) : (
            <div className="workspace-layout classic-workspace-layout">
              <PixelOffice snapshot={snapshot} selectedRoleId={selectedRole?.id} onSelectRole={setSelectedRole} />
              <Inspector snapshot={snapshot} role={selectedRole} />
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
