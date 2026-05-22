import { useMemo, useState } from 'react';
import { jobCreateErrorMessage, MAX_CEO_TASK_CHARS, validateCeoTaskRequest, type JobCreateResult } from '../model/actions';

interface CeoTaskComposerProps {
  onCreateJob: (request: string) => Promise<JobCreateResult>;
  refreshStatus?: 'idle' | 'pending' | 'succeeded' | 'failed';
  lastRefreshAt?: string | null;
}

export function CeoTaskComposer({ onCreateJob, refreshStatus = 'idle', lastRefreshAt = null }: CeoTaskComposerProps) {
  const [request, setRequest] = useState('');
  const [inFlight, setInFlight] = useState(false);
  const [result, setResult] = useState<JobCreateResult | null>(null);
  const validation = useMemo(() => validateCeoTaskRequest(request), [request]);
  const canSubmit = validation.ok && !inFlight;

  async function submit() {
    if (!canSubmit) return;
    setInFlight(true);
    setResult(null);
    try {
      setResult(await onCreateJob(request.trim()));
      setRequest('');
    } catch (error) {
      setResult({
        ok: false,
        statusCode: -1,
        stdout: '',
        stderr: '',
        command: ['agentdock', 'job', '--no-attach'],
        message: error instanceof Error ? error.message : String(error),
      });
    } finally {
      setInFlight(false);
    }
  }

  return (
    <section className="ceo-task-composer" aria-label="CEO task composer">
      <div className="composer-copy">
        <p className="eyebrow">Controlled action</p>
        <h2>CEO에게 작업 주기 / Send work to CEO</h2>
        <p>Creates a CEO-led AgentDock job only. No arbitrary shell, recruit, send, finish, report, or task-edit controls.</p>
      </div>
      <label className="composer-input-label" htmlFor="ceo-task-request">
        CEO task request
      </label>
      <textarea
        id="ceo-task-request"
        value={request}
        maxLength={MAX_CEO_TASK_CHARS}
        onChange={(event) => setRequest(event.target.value)}
        placeholder="Describe the work for the CEO to analyze, recruit, assign, and facilitate..."
        aria-describedby="ceo-task-validation ceo-task-trust"
        disabled={inFlight}
        rows={4}
      />
      <div className="composer-actions">
        <span id="ceo-task-validation" className={validation.ok ? 'composer-validation ok' : 'composer-validation warn'}>
          {validation.ok ? `${request.trim().length}/${MAX_CEO_TASK_CHARS} characters` : validation.message}
        </span>
        <button type="button" onClick={submit} disabled={!canSubmit}>
          {inFlight ? 'Sending to CEO…' : 'Send to CEO'}
        </button>
      </div>
      <p id="ceo-task-trust" className="trust-copy">Controlled action · creates a CEO-led job only · no arbitrary shell · duplicate submit locked while sending</p>
      <p className={`snapshot-refresh-state state-${refreshStatus}`} aria-live="polite">
        Snapshot refresh after create: {refreshStatus}
        {lastRefreshAt ? ` · last refreshed ${new Date(lastRefreshAt).toLocaleTimeString()}` : ''}
      </p>
      {result ? (
        <div className={result.ok ? 'composer-result success' : 'composer-result failure'} role="status" aria-live="polite">
          {result.ok ? (
            <>
              <strong>{result.jobId ? `Created ${result.jobId}` : 'CEO-led job created'}</strong>
              {result.jobPath ? <code>{result.jobPath}</code> : null}
              <span>{result.message || 'Snapshot refresh will show CEO facilitation progress.'}</span>
            </>
          ) : (
            <>
              <strong>CEO task was not created</strong>
              <span>{jobCreateErrorMessage(result)}</span>
            </>
          )}
        </div>
      ) : null}
    </section>
  );
}
