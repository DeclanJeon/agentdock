import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { reportState } from '../model/normalize';

export function ReportDesk({ snapshot, onSelectRole }: { snapshot: WorkspaceSnapshot; onSelectRole?: (role: WorkspaceRole) => void }) {
  const state = reportState(snapshot);
  const rolesById = new Map((snapshot.roles ?? []).map((role) => [role.id, role]));

  return (
    <section className="office-room report-desk" aria-label="Report Desk">
      <div className="room-header">
        <h2>Report Desk</h2>
        <p>{state.coverageLabel}</p>
      </div>
      <p className={state.ready ? 'ready-line' : 'warning-line'}>{state.headline}</p>
      <p className="next-action-line">{state.nextAction}</p>
      <p className="ceo-final-note">{state.ceoFinalPending}</p>
      {state.missingRoles.length === 0 ? (
        <p className="empty-room">No missing selected-role reports</p>
      ) : (
        <ul className="missing-report-list" aria-label="Missing report roles">
          {state.missingRoles.map((roleId) => {
            const role = rolesById.get(roleId);
            const canSelect = Boolean(role && onSelectRole);
            return (
              <li key={roleId}>
                {canSelect ? (
                  <button
                    type="button"
                    className="missing-report-chip"
                    aria-label={`Missing report role ${roleId}`}
                    onClick={() => onSelectRole?.(role!)}
                  >
                    {role?.display_name ?? roleId}
                  </button>
                ) : (
                  <span className="missing-report-chip" aria-label={`Missing report role ${roleId}`}>
                    {role?.display_name ?? roleId}
                  </span>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
