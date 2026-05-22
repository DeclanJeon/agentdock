import type { SceneRole } from '../model/scene';
import { pixelOfficeManifest } from '../assets/pixelOfficeManifest';
import { AgentSprite } from './AgentSprite';
import { StatusProp } from './StatusProp';

export function RoleStation({ role, selected, hiddenByFilter, onSelectRole }: { role: SceneRole; selected: boolean; hiddenByFilter?: boolean; onSelectRole: (role: SceneRole) => void }) {
  const kitClass = pixelOfficeManifest.stations[role.archetype]?.ref ?? pixelOfficeManifest.fallback.ref;
  return (
    <button
      type="button"
      className={`role-station archetype-${role.archetype} state-${role.state} urgency-${role.visualUrgency} station-kit-${role.archetype} ${kitClass} ${selected ? 'selected' : ''} ${hiddenByFilter ? 'filtered-out' : ''}`}
      aria-label={role.accessibleName}
      aria-pressed={selected}
      aria-hidden={hiddenByFilter ? true : undefined}
      tabIndex={hiddenByFilter ? -1 : 0}
      onClick={() => onSelectRole(role)}
    >
      <span className="station-kit" aria-hidden="true">
        <span className="station-desk" />
        <span className="station-monitor" />
        <span className="station-test-strip" />
        <span className={`station-prop prop-link-${role.reportLink.slotState}`} />
        {role.blockerLink ? <span className="station-beacon" /> : null}
      </span>
      <AgentSprite role={role} />
      <strong>{role.displayName}</strong>
      <small>{role.stationLabel}</small>
      <StatusProp state={role.state} label={`${role.badge} · ${role.recentEventLabel}`} />
    </button>
  );
}
