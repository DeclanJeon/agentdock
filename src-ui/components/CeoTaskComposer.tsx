import { useMemo, useRef, useState } from 'react';
import { jobCreateErrorMessage, MAX_CEO_TASK_CHARS, validateCeoTaskRequest, type JobCreateResult } from '../model/actions';

interface CeoTaskComposerProps {
  onCreateJob: (request: string) => Promise<JobCreateResult>;
  refreshStatus?: 'idle' | 'pending' | 'succeeded' | 'failed';
  lastRefreshAt?: string | null;
}

export function CeoTaskComposer({ onCreateJob, refreshStatus = 'idle', lastRefreshAt = null }: CeoTaskComposerProps) {
  const [request, setRequest] = useState('');
  const [inFlight, setInFlight] = useState(false);
  const submitInFlightRef = useRef(false);
  const [result, setResult] = useState<JobCreateResult | null>(null);
  const [expanded, setExpanded] = useState(false);
  const validation = useMemo(() => validateCeoTaskRequest(request), [request]);
  const canSubmit = validation.ok && !inFlight && !submitInFlightRef.current;

  async function submit() {
    if (!canSubmit || submitInFlightRef.current) return;
    submitInFlightRef.current = true;
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
      submitInFlightRef.current = false;
      setInFlight(false);
    }
  }

  return (
    <section className={expanded ? 'ceo-task-composer expanded' : 'ceo-task-composer compact'} aria-label="CEO task composer">
      <div className="composer-copy">
        <p className="eyebrow">Controlled action</p>
        <h2>Send work to CEO</h2>
        <p id="ceo-task-trust" className="trust-copy">Creates a CEO-led job only · no arbitrary shell · duplicate submit locked.</p>
      </div>
      <div className="composer-entry">
        <label className="composer-input-label" htmlFor="ceo-task-request">
          CEO task request
        </label>
        <textarea
          id="ceo-task-request"
          value={request}
          maxLength={MAX_CEO_TASK_CHARS}
          onChange={(event) => setRequest(event.target.value)}
          placeholder="Describe the CEO-led work..."
          aria-describedby="ceo-task-validation ceo-task-trust"
          disabled={inFlight}
          rows={expanded ? 3 : 1}
        />
      </div>
      <div className="composer-actions">
        <span id="ceo-task-validation" className={validation.ok ? 'composer-validation ok' : 'composer-validation warn'}>
          {validation.ok ? `${request.trim().length}/${MAX_CEO_TASK_CHARS}` : validation.message}
        </span>
        <button type="button" className="composer-expand-button" aria-expanded={expanded} onClick={() => setExpanded((current) => !current)}>
          {expanded ? 'Collapse' : 'Expand'}
        </button>
        <button type="button" onClick={submit} disabled={!canSubmit}>
          {inFlight ? 'Sending…' : 'Send to CEO'}
        </button>
      </div>
      <p className={`snapshot-refresh-state state-${refreshStatus}`} aria-live="polite">
        Refresh after create: {refreshStatus}{lastRefreshAt ? ` · ${new Date(lastRefreshAt).toLocaleTimeString()}` : ''}
      </p>
      {result ? (
        <div className={result.ok ? 'composer-result success' : 'composer-result failure'} role="status" aria-live="polite">
          {result.ok ? (
            <>
              <strong>{result.jobId ? `Created ${result.jobId}` : 'CEO-led job created'}</strong>
              {result.jobPath ? <code>{result.jobPath}</code> : null}
              <span>{result.message || 'Snapshot refresh will show facilitation progress.'}</span>
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
