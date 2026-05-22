import { useCallback, useEffect, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import type { CommandResult, WorkspaceRole, WorkspaceSnapshot } from './model/snapshot';
import type { JobCreateResult } from './model/actions';
import { isSupportedSnapshot, observedSchema, redactText, SUPPORTED_SCHEMA_VERSION } from './model/snapshot';
import type { VisualWorkspaceMode, WorkspaceMode } from './model/scene';
import { demoSnapshot } from './model/fixtures';
import { TopHud } from './components/TopHud';
import { PixelOffice } from './components/PixelOffice';
import { Inspector } from './components/Inspector';
import { OfficeScene } from './scene/OfficeScene';
import { CeoTaskComposer } from './components/CeoTaskComposer';
import { FacilitationTimeline } from './components/FacilitationTimeline';
import { ActionAuditPanel } from './components/ActionAuditPanel';
import { InterventionPanel } from './components/InterventionPanel';
import { completeJobCreateAudit, newAuditAttempt, type ActionAuditEvent } from './model/actionAudit';

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

type SnapshotRefreshOutcome = 'succeeded' | 'failed' | 'skipped';


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

export default function App() {
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot>(demoSnapshot);
  const [lastGoodSnapshot, setLastGoodSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const lastGoodSnapshotRef = useRef<WorkspaceSnapshot | null>(null);
  const [selectedRole, setSelectedRole] = useState<WorkspaceRole | undefined>(demoSnapshot.roles?.[0]);
  const [mode, setMode] = useState<WorkspaceMode>('demo');
  const [visualMode, setVisualMode] = useState<VisualWorkspaceMode>(initialVisualMode);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<string | null>(null);
  const [refreshInFlight, setRefreshInFlight] = useState(false);
  const [lastCreateRefreshStatus, setLastCreateRefreshStatus] = useState<'idle' | 'pending' | 'succeeded' | 'failed'>('idle');
  const [auditEvents, setAuditEvents] = useState<ActionAuditEvent[]>([]);
  const refreshInFlightRef = useRef(false);

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
            setSnapshot(demoSnapshot);
            setSelectedRole(demoSnapshot.roles?.[0]);
          }
          return 'failed';
        }
        setSnapshot(result.parsed);
        lastGoodSnapshotRef.current = result.parsed;
        setLastGoodSnapshot(result.parsed);
        setSelectedRole((current) => result.parsed?.roles?.find((role) => role.id === current?.id) ?? result.parsed?.roles?.[0]);
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
          setSnapshot(demoSnapshot);
          setSelectedRole(demoSnapshot.roles?.[0]);
        }
        return 'failed';
      }
    } catch (err) {
      const previousGoodSnapshot = lastGoodSnapshotRef.current;
      const message = redactText(err instanceof Error ? err.message : String(err));
      setError(message);
      setMode(previousGoodSnapshot ? 'stale' : 'error');
      if (!previousGoodSnapshot) {
          setSnapshot(demoSnapshot);
          setSelectedRole(demoSnapshot.roles?.[0]);
        }
      return 'failed';
    } finally {
      refreshInFlightRef.current = false;
      setRefreshInFlight(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    const guardedLoad = async () => {
      if (!cancelled) await loadSnapshot();
    };
    guardedLoad();
    const id = window.setInterval(guardedLoad, 5000);
    return () => {
      cancelled = true;
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

  return (
    <div className={`app-shell mode-${mode}`}>
      <TopHud snapshot={snapshot} />
      <ErrorStrip mode={mode} error={error} lastUpdatedAt={lastUpdatedAt} />
      <div className="workspace-command-strip" aria-label="Compact command and status controls">
        <CeoTaskComposer onCreateJob={createCeoJob} refreshStatus={lastCreateRefreshStatus} lastRefreshAt={lastUpdatedAt} />
        <FacilitationTimeline snapshot={snapshot} mode={mode} />
        <div className="refresh-row" aria-label="Snapshot refresh controls">
          <button type="button" onClick={loadSnapshot} disabled={refreshInFlight}>
            {refreshInFlight ? 'Refreshing…' : 'Refresh snapshot'}
          </button>
          <span>{lastUpdatedAt ? `Last refresh: ${new Date(lastUpdatedAt).toLocaleTimeString()}` : 'Waiting for live refresh'}</span>
          <div className="visual-mode-switch" aria-label="Visual workspace render mode">
            <button type="button" className={visualMode === 'pixelOffice' ? 'active' : ''} onClick={() => switchVisualMode('pixelOffice')}>
              Pixel Office
            </button>
            <button type="button" className={visualMode === 'classic' ? 'active' : ''} onClick={() => switchVisualMode('classic')}>
              Classic
            </button>
          </div>
          <SecurityStatusStrip snapshot={snapshot} mode={mode} />
        </div>
      </div>
      <ErrorStrip mode={mode} error={error} lastUpdatedAt={lastUpdatedAt} />
      <CeoTaskComposer onCreateJob={createCeoJob} refreshStatus={lastCreateRefreshStatus} lastRefreshAt={lastUpdatedAt} />
      <FacilitationTimeline snapshot={snapshot} mode={mode} />
      {visualMode === 'pixelOffice' ? (
        <OfficeScene snapshot={snapshot} mode={mode} selectedRoleId={selectedRole?.id} onSelectRole={setSelectedRole} />
      ) : (
        <div className="workspace-layout classic-workspace-layout">
          <PixelOffice snapshot={snapshot} selectedRoleId={selectedRole?.id} onSelectRole={setSelectedRole} />
          <Inspector snapshot={snapshot} role={selectedRole} />
        </div>
      )}
      <aside className="auxiliary-panel-dock" aria-label="Collapsed auxiliary controls">
        <ActionAuditPanel events={auditEvents} />
        <InterventionPanel snapshot={snapshot} />
      </aside>
    </div>
  );
}
