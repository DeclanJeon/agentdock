import type { SceneRole, SceneZone } from '../model/scene';
import { RoleStation } from './RoleStation';

export function OfficeZone({
  zone,
  roles,
  visibleRoleIds,
  focused,
  selectedRoleId,
  onSelectRole,
}: {
  zone: SceneZone;
  roles: SceneRole[];
  visibleRoleIds?: Set<string>;
  focused?: boolean;
  selectedRoleId?: string;
  onSelectRole: (role: SceneRole) => void;
}) {
  const style = {
    gridColumn: `${zone.geometry.x} / span ${zone.geometry.w}`,
    gridRow: `${zone.geometry.y} / span ${zone.geometry.h}`,
  };
  const visibleCount = roles.filter((role) => visibleRoleIds?.has(role.id) ?? true).length;
  return (
    <section className={`office-zone zone-${zone.id} zone-tone-${zone.tone} ${focused ? 'zone-focused' : ''}`} style={style} aria-label={`${zone.title}, ${visibleCount} visible roles`}>
      <div className="zone-floor" aria-hidden="true" />
      <div className="zone-wall" aria-hidden="true" />
      <header className="zone-label">
        <h2>{zone.title}</h2>
        <p>{zone.subtitle}</p>
      </header>
      <div className="station-row" aria-label={`${zone.title} role stations`}>
        {roles.length === 0 ? <span className="empty-station">배정된 역할 없음</span> : null}
        {roles.map((role) => (
          <RoleStation key={role.id} role={role} hiddenByFilter={!(visibleRoleIds?.has(role.id) ?? true)} selected={role.id === selectedRoleId} onSelectRole={onSelectRole} />
        ))}
      </div>
    </section>
  );
}
