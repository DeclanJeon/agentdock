import type { ActionAuditEvent } from '../model/actionAudit';

export function ActionAuditPanel({ events }: { events: ActionAuditEvent[] }) {
  return (
    <details className="action-audit-panel auxiliary-panel" aria-label="Session local action audit log">
      <summary>
        <span>
          <p className="eyebrow">Session-local audit</p>
          <strong>Action Audit Panel</strong>
        </span>
        <em>{events.length} events</em>
      </summary>
      <p>이 session-local 로그는 현재 앱 세션에만 보관됩니다. 새로고침하면 사라지며, shell fallback은 제공하지 않습니다. Request/result text is redacted before display.</p>
      {events.length === 0 ? (
        <p className="empty-audit">No actions attempted in this session.</p>
      ) : (
        <ol>
          {events.map((event) => (
            <li key={event.id} className={`audit-event status-${event.status}`}>
              <strong>{event.actionType}</strong>
              <span>{event.status}</span>
              <code>{event.requestPreview}</code>
              {event.jobId ? <span>job {event.jobId}</span> : null}
              {event.jobPath ? <code>{event.jobPath}</code> : null}
              {typeof event.durationMs === 'number' ? <span>{event.durationMs}ms</span> : null}
              {event.resultSummary ? <small>{event.resultSummary}</small> : null}
              <time dateTime={event.completedAt ?? event.startedAt}>{new Date(event.completedAt ?? event.startedAt).toLocaleTimeString()}</time>
            </li>
          ))}
        </ol>
      )}
    </details>
  );
}
