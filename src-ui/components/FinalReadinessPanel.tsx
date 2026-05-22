import type { WorkspaceSnapshot } from '../model/snapshot';
import { reportState } from '../model/normalize';

export function FinalReadinessPanel({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  const state = reportState(snapshot);
  return (
    <section className="office-room final-readiness-panel" aria-label="Final readiness panel">
      <div className="room-header">
        <h2>{state.ready ? 'Final ready' : 'Final not ready'}</h2>
        <p>{state.headline}</p>
      </div>
      <p className={state.ready ? 'ready-line' : 'warning-line'}>
        {snapshot.job?.final_ready_reason ?? state.headline}
      </p>
      <p className="next-action-line">{state.nextAction}</p>
    </section>
  );
}
