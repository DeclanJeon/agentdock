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
      setExpanded(false);
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
    <section className={`ceo-task-composer compact${expanded ? ' expanded' : ''}`} aria-label="CEO task composer">
      <header className="composer-header">
        <div className="composer-copy">
          <p className="eyebrow">Controlled action</p>
          <h2>CEO 작업 요청</h2>
        </div>
        <p className="composer-safety-copy">CEO-led job 생성 전용 · shell/finish/edit 브리지는 열지 않습니다.</p>
      </header>

      <div className="composer-entry">
        <label className="composer-input-label" htmlFor="ceo-task-request">
          CEO TASK REQUEST
        </label>
        <textarea
          id="ceo-task-request"
          value={request}
          maxLength={MAX_CEO_TASK_CHARS}
          onChange={(event) => setRequest(event.target.value)}
          placeholder="CEO가 분석하고 팀을 구성할 작업을 적어주세요…"
          aria-describedby="ceo-task-validation ceo-task-trust"
          disabled={inFlight}
          rows={expanded ? 5 : 3}
        />
      </div>

      <footer className="composer-footer">
        <span id="ceo-task-validation" className={validation.ok ? 'composer-validation ok' : 'composer-validation warn'}>
          {validation.ok ? `${request.trim().length}/${MAX_CEO_TASK_CHARS}` : validation.message}
        </span>
        <div className="composer-buttons">
          <button
            className="composer-expand-button"
            type="button"
            onClick={() => setExpanded((current) => !current)}
            aria-expanded={expanded}
            aria-controls="ceo-task-request"
          >
            {expanded ? '접기' : '펼치기'}
          </button>
          <button type="button" onClick={submit} disabled={!canSubmit}>
            {inFlight ? '전송 중…' : 'Send to CEO'}
          </button>
        </div>
      </footer>

      <p id="ceo-task-trust" className="trust-copy">안전 경계: CEO 작업 생성만 가능하며 no arbitrary shell, 중복 전송은 잠깁니다. duplicate submit locked.</p>
      <p className={`snapshot-refresh-state state-${refreshStatus}`} aria-live="polite">
        Refresh after create: {refreshStatus}
        {lastRefreshAt ? ` · ${new Date(lastRefreshAt).toLocaleTimeString()}` : ''}
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
