import type { SceneRoleState } from '../model/scene';

export function StatusProp({ state, label }: { state: SceneRoleState | 'read-only' | 'final-ready' | 'final-blocked'; label: string }) {
  return <span className={`status-prop prop-${state}`} aria-label={label}>{label}</span>;
}
