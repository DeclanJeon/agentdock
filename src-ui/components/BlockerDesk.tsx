import type { WorkspaceSnapshot } from '../model/snapshot';
import { normalizeBlockers } from '../model/normalize';

export function BlockerDesk({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  const blockers = normalizeBlockers(snapshot);
  return (
    <section className="office-room blocker-desk" aria-label="Blocker Desk">
      <div className="room-header">
        <h2>Blocker Desk</h2>
        <p>경고, 잠금, 최종 확인 필요 항목</p>
      </div>
      {blockers.length === 0 ? <p className="empty-room">막힘 없음</p> : null}
      {blockers.length > 0 ? (
        <ul className="blocker-card-list">
          {blockers.map((blocker, index) => (
            <li
              className={`blocker-card severity-${blocker.severity.toLowerCase()}`}
              key={`${blocker.type}-${index}`}
              aria-label={`${blocker.severity} blocker, ${blocker.type}, ${blocker.owner ?? 'unassigned'}, ${blocker.message}`}
            >
              <div className="blocker-meta">
                <span>심각도: {blocker.severity}</span>
                <span>유형: {blocker.type}</span>
              </div>
              {blocker.owner ? <p>담당: {blocker.owner}</p> : null}
              <p>내용: {blocker.message}</p>
              {blocker.nextAction ? <p>다음 액션: {blocker.nextAction}</p> : null}
              {blocker.path ? <p className="technical-path">경로: {blocker.path}</p> : null}
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
