import type { SceneRole } from '../model/scene';

const characterCount = 50;
function characterSrc(roleId: string): string {
  let hash = 0;
  for (const char of roleId) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  const index = String((hash % characterCount) + 1).padStart(2, '0');
  return `/workspace-characters/character-${index}.gif`;
}

export function AgentSprite({ role }: { role: SceneRole }) {
  return (
    <span className={`agent-sprite sprite-${role.archetype} pose-${role.pose} activity-${role.activityState} urgency-${role.visualUrgency}`} aria-hidden="true">
      <span className="sprite-shadow" />
      <img src={characterSrc(role.id)} alt="" />
      <span className={`sprite-badge state-${role.state}`}>{role.badge}</span>
      <span className="activity-signal">{role.activityState}</span>
    </span>
  );
}
