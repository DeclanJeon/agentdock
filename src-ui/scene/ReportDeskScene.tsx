import type { WorkspaceRole } from '../model/snapshot';
import type { SceneModel } from '../model/scene';

export function ReportDeskScene({ scene, onSelectRole }: { scene: SceneModel; onSelectRole: (role: WorkspaceRole) => void }) {
  const roleById = new Map(scene.roles.map((role) => [role.id, role.role]));
  return (
    <section className="scene-desk report-desk-scene" aria-label="Report Desk scene">
      <p className="eyebrow">Report Desk</p>
      <h2>{scene.reportDesk.coverageLabel}</h2>
      <p className={scene.reportDesk.ready ? 'ready-line' : 'warning-line'}>{scene.reportDesk.headline}</p>
      <div className="report-slot-grid" aria-label="Selected role report slots">
        {scene.reportDesk.slots.map((slot) => {
          const role = roleById.get(slot.roleId);
          return (
            <button
              type="button"
              key={slot.roleId}
              className={`report-slot ${slot.filled ? 'filled' : ''} ${slot.missing ? 'missing' : ''}`}
              aria-label={`${slot.label}, ${slot.missing ? 'report needed' : slot.filled ? 'reported' : 'report not required'}`}
              onClick={() => role ? onSelectRole(role) : undefined}
            >
              <span aria-hidden="true">{slot.filled ? '✓' : slot.missing ? '!' : '·'}</span>{slot.label}
            </button>
          );
        })}
      </div>
      <p className="next-action-line">{scene.reportDesk.nextAction}</p>
    </section>
  );
}
