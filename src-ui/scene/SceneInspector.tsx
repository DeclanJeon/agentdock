import type { SceneModel, SceneRole } from '../model/scene';
import type { WorkspaceSnapshot } from '../model/snapshot';

function taskRows(role: SceneRole) {
  const baseId = role.id.replace(/[^a-z0-9]/gi, '').slice(0, 6).toUpperCase() || 'ROLE';
  return [
    { id: `${baseId}-1`, title: role.role.task_path ? 'Read assigned task card' : 'Await assigned task', status: role.role.task_path ? '보고 완료' : '배정됨' },
    { id: `${baseId}-2`, title: role.reportState === 'reported' ? 'Submit role report' : 'Prepare role report', status: role.reportState === 'reported' ? '보고 완료' : '보고 필요' },
    { id: `${baseId}-3`, title: 'Preserve read-only boundary', status: role.blocked ? '차단됨' : '배정됨' },
  ];
}

export function SceneInspector({ snapshot, role, scene }: { snapshot: WorkspaceSnapshot; role?: SceneRole; scene?: SceneModel }) {
  if (!role) {
    return (
      <aside className="scene-inspector reference-inspector" aria-label="Scene inspector">
        <header className="inspector-panel-header">
          <p className="eyebrow">Selected Role</p>
          <span aria-hidden="true">—</span>
        </header>
        <h2>Workspace Snapshot</h2>
        <p>Read-only scene derived from {snapshot.schema_version ?? 'unknown schema'}.</p>
      </aside>
    );
  }
  const tasks = taskRows(role);
  const submitted = snapshot.reports?.submitted_selected_roles ?? snapshot.reports?.submitted ?? snapshot.reports?.total ?? 0;
  const required = snapshot.reports?.required_selected_roles ?? snapshot.reports?.required ?? 0;
  const blockerCount = scene?.blockerDesk.cards.length ?? snapshot.alerts?.length ?? 0;
  return (
    <aside className="scene-inspector reference-inspector" aria-label={`${role.id} selected role inspector`}>
      <header className="inspector-panel-header">
        <p className="eyebrow">Selected Role</p>
        <span aria-hidden="true">—</span>
      </header>
      <section className="selected-role-card">
        <span className={`inspector-avatar avatar-${role.archetype}`} aria-hidden="true">{role.archetype === 'qa' ? '🧪' : role.archetype === 'ux' ? '🎨' : role.archetype === 'architect' ? '🏗' : role.archetype === 'developer' ? '💻' : role.archetype === 'product' ? '📋' : role.archetype === 'delivery' ? '📦' : '🧑‍💼'}</span>
        <div>
          <h2>{role.displayName}</h2>
          <span className={`role-state-pill state-${role.state}`}>{role.badge}</span>
          <p>{scene?.office.zones.find((zone) => zone.id === role.zoneId)?.title ?? role.zoneId}</p>
        </div>
      </section>

      <div className="inspector-tabs" role="tablist" aria-label="Read-only role detail tabs">
        <button type="button" role="tab" aria-selected="true">Tasks ({tasks.length})</button>
        <button type="button" role="tab" aria-selected="false">Details</button>
        <button type="button" role="tab" aria-selected="false">Files</button>
        <button type="button" role="tab" aria-selected="false">Logs</button>
      </div>

      <section className="task-card-list" aria-label="Read-only task cards">
        {tasks.map((task) => (
          <article className="inspector-task-card" key={task.id}>
            <span aria-hidden="true">▣</span>
            <div>
              <strong>{task.title}</strong>
              <small>ID: {task.id}</small>
            </div>
            <em className={`task-status ${task.status === '보고 완료' ? 'good' : task.status === '차단됨' ? 'bad' : 'warn'}`}>{task.status}</em>
          </article>
        ))}
      </section>

      <section className="inspector-section role-summary" aria-label="Role summary">
        <h3>Role Summary</h3>
        <dl>
          <dt>Tasks</dt><dd>{tasks.length}</dd>
          <dt>Completed</dt><dd>{tasks.filter((task) => task.status === '보고 완료').length}</dd>
          <dt>Pending</dt><dd>{tasks.filter((task) => task.status !== '보고 완료').length}</dd>
          <dt>Report</dt><dd>{role.reportState}</dd>
          <dt>Activity</dt><dd>{role.activityState}</dd>
        </dl>
      </section>

      <section className="inspector-section latest-report-card" aria-label="Latest report preview">
        <h3>Latest Report</h3>
        <p>{role.role.latest_report_path ? role.recentEventLabel : 'No report submitted yet'}</p>
        <small>{role.role.latest_report_path ?? 'Read-only snapshot has no report path for this role.'}</small>
      </section>

      <section className="inspector-section office-status-summary" aria-label="Office status summary">
        <h3>Office Status</h3>
        <dl>
          <dt>Lifecycle</dt><dd>{snapshot.job?.lifecycle_status ?? snapshot.job?.lifecycle ?? 'unknown'}</dd>
          <dt>Final</dt><dd>{scene?.finalGate.label ?? (snapshot.job?.final_ready ? 'ready' : 'locked')}</dd>
          <dt>Reports</dt><dd>{submitted}/{required}</dd>
          <dt>Blockers</dt><dd>{blockerCount}</dd>
        </dl>
      </section>
    </aside>
  );
}
