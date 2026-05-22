import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { statusLabel } from '../model/normalize';

export function Inspector({ snapshot, role }: { snapshot: WorkspaceSnapshot; role?: WorkspaceRole }) {
  if (!role) {
    return (
      <aside className="inspector" aria-label="Job inspector">
        <p className="eyebrow">Inspector</p>
        <h2>Job Summary</h2>
        <dl>
          <dt>Project</dt><dd>{snapshot.project?.name ?? 'unknown'}</dd>
          <dt>Root</dt><dd>{snapshot.project?.root ?? 'unknown'}</dd>
          <dt>Generated</dt><dd>{snapshot.generated_at ?? 'unknown'}</dd>
          <dt>Read boundary</dt><dd>Reads AgentDock snapshot only. No write bridge is enabled.</dd>
        </dl>
      </aside>
    );
  }

  return (
    <aside className="inspector" aria-label={`${role.id} inspector`}>
      <p className="eyebrow">Selected Character</p>
      <h2>{role.display_name ?? role.id}</h2>
      <dl>
        <dt>Status</dt><dd>{statusLabel(role.status)}</dd>
        <dt>Reason</dt><dd>{role.status_reason ?? 'No reason supplied by snapshot.'}</dd>
        <dt>Department</dt><dd>{role.department ?? 'General'}</dd>
        <dt>Task</dt><dd>{role.task_path || 'No task path'}</dd>
        <dt>Report</dt><dd>{role.latest_report_path || 'No current report'}</dd>
        <dt>Pane</dt><dd>{role.running_pane ? role.pane_id || 'running' : 'not running'}</dd>
      </dl>
      <h3>Evidence</h3>
      <ul>
        {(role.source_paths ?? []).map((path) => <li key={path}>{path}</li>)}
      </ul>
    </aside>
  );
}
