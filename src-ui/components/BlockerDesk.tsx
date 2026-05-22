import type { WorkspaceSnapshot } from '../model/snapshot';
import { normalizeBlockers } from '../model/normalize';

export function BlockerDesk({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  const blockers = normalizeBlockers(snapshot);
  return (
    <section className="office-room blocker-desk" aria-label="Blocker Desk">
      <div className="room-header">
        <h2>Blocker Desk</h2>
        <p>Warnings, locks, and finalization blockers</p>
      </div>
      {blockers.length === 0 ? <p className="empty-room">No active blocker</p> : null}
      {blockers.length > 0 ? (
        <ul className="blocker-card-list">
          {blockers.map((blocker, index) => (
            <li
              className={`blocker-card severity-${blocker.severity.toLowerCase()}`}
              key={`${blocker.type}-${index}`}
              aria-label={`${blocker.severity} blocker, ${blocker.type}, ${blocker.owner ?? 'unassigned'}, ${blocker.message}`}
            >
              <div className="blocker-meta">
                <span>Severity: {blocker.severity}</span>
                <span>Type: {blocker.type}</span>
              </div>
              {blocker.owner ? <p>Owner: {blocker.owner}</p> : null}
              <p>Issue: {blocker.message}</p>
              {blocker.nextAction ? <p>Next action: {blocker.nextAction}</p> : null}
              {blocker.path ? <p className="technical-path">Path: {blocker.path}</p> : null}
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
