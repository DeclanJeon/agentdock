import type { WorkspaceSnapshot, WorkspaceRole } from '../model/snapshot';

function selectedRoles(snapshot: WorkspaceSnapshot): WorkspaceRole[] {
  return (snapshot.roles ?? []).filter((role) => role.selected);
}

export function InterventionPanel({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  const jobId = snapshot.job?.id;
  const selected = selectedRoles(snapshot);
  const finishReady = Boolean(snapshot.job?.final_ready);
  return (
    <section className="intervention-panel" aria-label="Controlled intervention console">
      <div>
        <p className="eyebrow">개입 콘솔</p>
        <h2>Safe Intervention Console</h2>
        <p>직접 finish/task edit은 열지 않습니다. 현재 slice는 작업 생성과 안전한 preview/readiness 안내만 제공합니다.</p>
      </div>
      <div className="intervention-grid">
        <article>
          <h3>CEO follow-up</h3>
          <p>{jobId ? `Active job ${jobId}에 대한 CEO follow-up route 준비됨.` : 'No active job: follow-up disabled.'}</p>
          <button type="button" disabled aria-disabled="true">Follow-up bridge pending next slice</button>
        </article>
        <article>
          <h3>Selected-team broadcast</h3>
          <p>{selected.length} selected roles preview: {selected.map((role) => role.id).join(', ') || 'none'}</p>
          <button type="button" disabled aria-disabled="true">Broadcast requires confirmation slice</button>
        </article>
        <article>
          <h3>Role direct send</h3>
          <p>Targets must come from snapshot roles only; offline/bench state is visible in the role inspector.</p>
          <button type="button" disabled aria-disabled="true">Role send bridge pending</button>
        </article>
        <article>
          <h3>Recruit role</h3>
          <p>Template allowlist and tmux side-effect warning required before enabling.</p>
          <button type="button" disabled aria-disabled="true">Recruit bridge pending</button>
        </article>
        <article>
          <h3>Task change proposal</h3>
          <p>Direct TASKS/*.md edits are forbidden; proposals route through CEO follow-up.</p>
          <button type="button" disabled aria-disabled="true">Proposal route pending</button>
        </article>
        <article>
          <h3>Finish readiness assist</h3>
          <p>{finishReady ? 'Final appears ready; run CLI finish from orchestrator after reports are reviewed.' : snapshot.job?.final_ready_reason ?? 'Finish is not ready.'}</p>
          {finishReady ? (
            <code>agentdock job finish --summary '&lt;reviewed result&gt;'</code>
          ) : (
            <p className="disabled-reason">Finish guidance is hidden until final-ready evidence is true; no direct finish bridge is available.</p>
          )}
        </article>
      </div>
    </section>
  );
}
