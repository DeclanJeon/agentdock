import { useCallback, useEffect, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import type { CommandResult, WorkspaceRole, WorkspaceSnapshot } from './model/snapshot';
import type { ControlledActionName, ControlledActionResult, JobCreateResult } from './model/actions';
import { isSupportedSnapshot, observedSchema, redactText, SUPPORTED_SCHEMA_VERSION } from './model/snapshot';
import type { VisualWorkspaceMode, WorkspaceMode } from './model/scene';
import { createEmptyWorkspaceSnapshot } from './model/emptySnapshot';
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
import { ModelSettingsPanel } from './components/ModelSettingsPanel';
import { OrchestrationPanel } from './components/OrchestrationPanel';
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

interface WorkspaceChangedPayload {
  projectRoot?: string;
  changedAt?: string;
  fileCount?: number;
  source?: string;
}

function userFacingStatus(snapshot: WorkspaceSnapshot): { headline: string; summary: string; tone: 'idle' | 'active' | 'blocked' | 'ready' } {
  const hasJob = Boolean(snapshot.job?.id);
  const selectedCount = (snapshot.roles ?? []).filter((role) => role.selected).length;
  const missingReports = snapshot.reports?.missing_roles?.length ?? 0;
  const blockerCount = snapshot.alerts?.length ?? 0;
  if (!hasJob) {
    return {
      headline: '작업 대기 중',
      summary: '상단 입력창에 작업을 적으면 CEO가 필요한 팀과 역할을 구성합니다.',
      tone: 'idle',
    };
  }
  if (blockerCount > 0) {
    return {
      headline: `${blockerCount}개 확인 필요`,
      summary: '막힌 역할을 선택해 원인과 다음 지시를 확인하세요.',
      tone: 'blocked',
    };
  }
  if (missingReports > 0) {
    return {
      headline: `${missingReports}개 보고 대기`,
      summary: `${selectedCount > 0 ? `${selectedCount}개 역할이` : '선택된 역할이'} 작업 중입니다. 팀 활동에서 현재 진행 상황을 확인하세요.`,
      tone: 'active',
    };
  }
  if (snapshot.job?.final_ready) {
    return {
      headline: '최종 확인 가능',
      summary: '모든 핵심 보고가 모였습니다. 최종 요약과 남은 리스크를 검토하세요.',
      tone: 'ready',
    };
  }
  return {
    headline: '팀 작업 진행 중',
    summary: `${selectedCount > 0 ? `${selectedCount}개 역할이` : '각 역할이'} 맡은 작업을 진행하고 있습니다.`,
    tone: 'active',
  };
}

function AdvancedStatusDetails({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const readOnlyMode = snapshot.commands?.mode ?? 'read-only';
  const allowedActions = snapshot.commands?.allowed_actions ?? [];
  return (
    <details className="advanced-status-details">
      <summary>고급 상태</summary>
      <dl>
        <div><dt>화면 상태</dt><dd>{mode}</dd></div>
        <div><dt>작업 모드</dt><dd>{readOnlyMode}</dd></div>
        <div><dt>허용 액션</dt><dd>{allowedActions.length ? allowedActions.join(', ') : '없음'}</dd></div>
      </dl>
    </details>
  );
}

function WorkspaceStatusCard({
  snapshot,
  mode,
  lastUpdatedAt,
  refreshInFlight,
  visualMode,
  onRefresh,
  switchVisualMode,
}: {
  snapshot: WorkspaceSnapshot;
  mode: WorkspaceMode;
  lastUpdatedAt: string | null;
  refreshInFlight: boolean;
  visualMode: VisualWorkspaceMode;
  onRefresh: () => void | Promise<unknown>;
  switchVisualMode: (mode: VisualWorkspaceMode) => void;
}) {
  const status = userFacingStatus(snapshot);
  return (
    <section className={`snapshot-control-card workspace-status-card tone-${status.tone}`} aria-label="Workspace status and view controls">
      <header>
        <p className="eyebrow">작업 현황</p>
        <h2>{status.headline}</h2>
      </header>
      <p className="workspace-status-next">{status.summary}</p>
      <button type="button" onClick={onRefresh} disabled={refreshInFlight}>
        {refreshInFlight ? '업데이트 중…' : '상태 업데이트'}
      </button>
      <p className="snapshot-refresh-state">
        {lastUpdatedAt ? `마지막 업데이트 ${new Date(lastUpdatedAt).toLocaleTimeString()}` : '아직 작업 상태를 불러오지 못했습니다.'}
      </p>
      <div className="visual-mode-switch" aria-label="Workspace view mode">
        <button type="button" className={visualMode === 'pixelOffice' ? 'active' : ''} onClick={() => switchVisualMode('pixelOffice')}>
          오피스
        </button>
        <button type="button" className={visualMode === 'classic' ? 'active' : ''} onClick={() => switchVisualMode('classic')}>
          간단 보기
        </button>
      </div>
      <AdvancedStatusDetails snapshot={snapshot} mode={mode} />
    </section>
  );
}

function ErrorStrip({ mode, error, lastUpdatedAt }: { mode: WorkspaceMode; error: string | null; lastUpdatedAt: string | null }) {
  if (!error) return null;
  const prefix = mode === 'stale' ? '최근 저장된 상태를 보여주는 중' : '프로젝트 상태를 불러오지 못했습니다';
  return (
    <div className={`error-strip mode-${mode}`} role="status" aria-live="polite">
      {prefix}: {error}
      {lastUpdatedAt ? <span className="last-good-note"> 마지막 정상 업데이트: {new Date(lastUpdatedAt).toLocaleTimeString()}</span> : null}
    </div>
  );
}

function OperatorGuidePanel({ snapshot, selectedRole }: { snapshot: WorkspaceSnapshot; selectedRole?: WorkspaceRole }) {
  const hasJob = Boolean(snapshot.job?.id);
  const selectedCount = (snapshot.roles ?? []).filter((role) => role.selected).length;
  const missingReports = snapshot.reports?.missing_roles?.length ?? 0;
  const blockerCount = snapshot.alerts?.length ?? 0;
  const nextStep = !hasJob
    ? '상단 작업 입력창에 요청을 적고 CEO에게 전달하세요.'
    : blockerCount > 0
      ? '확인이 필요한 역할을 선택해 원인과 후속 지시를 확인하세요.'
      : missingReports > 0
        ? '보고 필요 역할을 확인하고 Report 액션을 진행하세요.'
        : snapshot.job?.final_ready
          ? 'Final Gate가 준비되었습니다. 최종 요약을 검토하세요.'
          : '팀 활동 패널에서 현재 역할별 작업을 확인하세요.';
  return (
    <section className="operator-guide-panel" aria-label="Operator quick guide">
      <header>
        <p className="eyebrow">안내</p>
        <h2>다음에 볼 곳</h2>
      </header>
      <ol>
        <li className={hasJob ? 'done' : 'active'}><span>1</span><p>작업 입력</p></li>
        <li className={selectedCount > 0 ? 'done' : hasJob ? 'active' : ''}><span>2</span><p>CEO 팀 구성</p></li>
        <li className={blockerCount > 0 ? 'blocked' : missingReports > 0 ? 'active' : selectedCount > 0 ? 'done' : ''}><span>3</span><p>진행/보고 확인</p></li>
      </ol>
      <p className="operator-next-action">{nextStep}</p>
      {selectedRole ? <small>현재 선택: {selectedRole.display_name ?? selectedRole.id}</small> : <small>역할 카드를 누르면 상세 정보가 바뀝니다.</small>}
    </section>
  );
}

export default function App() {
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot>(() => createEmptyWorkspaceSnapshot(projectRootFromLocation()));
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
            setSnapshot(createEmptyWorkspaceSnapshot(projectRootFromLocation()));
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
          setSnapshot(createEmptyWorkspaceSnapshot(projectRootFromLocation()));
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
        setSnapshot(createEmptyWorkspaceSnapshot(projectRootFromLocation()));
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
    const scheduleEventRefresh = (_payload?: WorkspaceChangedPayload) => {
      if (eventRefreshTimerRef.current) window.clearTimeout(eventRefreshTimerRef.current);
      eventRefreshTimerRef.current = window.setTimeout(() => {
        eventRefreshTimerRef.current = null;
        if (!document.hidden) void guardedLoad();
      }, 650);
    };

    guardedLoad();
    invoke<CommandResult>('workspace_watch_start', { projectRoot: projectRootFromLocation() })
      .then((result) => {
        if (!cancelled && !result.ok) {
          console.warn('Workspace file watcher unavailable; periodic refresh remains active.', snapshotErrorMessage(result));
        }
      })
      .catch((error) => {
        if (!cancelled) {
          console.warn('Workspace file watcher failed to start; periodic refresh remains active.', redactText(error instanceof Error ? error.message : String(error)));
        }
      });
    listen<WorkspaceChangedPayload>('workspace_changed', (event) => scheduleEventRefresh(event.payload))
      .then((dispose) => {
        if (cancelled) dispose();
        else unlisten = dispose;
      })
      .catch((error) => {
        if (!cancelled) {
          console.warn('Workspace event listener unavailable; periodic refresh remains active.', redactText(error instanceof Error ? error.message : String(error)));
        }
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
        <aside className="workspace-sidecar" aria-label="Workspace operation guidance">
          <OperatorGuidePanel snapshot={snapshot} selectedRole={selectedRole} />
          <WorkspaceStatusCard
            snapshot={snapshot}
            mode={mode}
            lastUpdatedAt={lastUpdatedAt}
            refreshInFlight={refreshInFlight}
            visualMode={visualMode}
            onRefresh={loadSnapshot}
            switchVisualMode={switchVisualMode}
          />
          <ModelSettingsPanel projectRoot={projectRootFromLocation()} snapshotModel={snapshot.model} onApplied={loadSnapshot} />
          <OrchestrationPanel
            orchestration={snapshot.orchestration}
            qa={snapshot.qa}
            dependencies={snapshot.dependencies}
            meetings={snapshot.meetings}
            writeConflicts={snapshot.write_conflicts}
            communications={snapshot.communications}
          />
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
