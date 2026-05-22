import type { WorkspaceRole } from '../model/snapshot';
import { statusLabel } from '../model/normalize';

const characterCount = 50;

function characterSrc(roleId: string): string {
  let hash = 0;
  for (const char of roleId) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  const index = String((hash % characterCount) + 1).padStart(2, '0');
  return `/workspace-characters/character-${index}.gif`;
}

export function AgentCharacter({ role, selected, onSelect }: { role: WorkspaceRole; selected: boolean; onSelect: (role: WorkspaceRole) => void }) {
  const status = role.status ?? 'unknown';
  const hasReport = Boolean(role.latest_report_path || role.avatar?.report_count);
  const needsReport = role.selected === true && !hasReport && !['reported', 'ready'].includes(String(status));
  const bench = role.configured === true && role.selected !== true;
  const stateParts = [
    statusLabel(status),
    selected ? 'selected in inspector' : undefined,
    bench ? 'configured bench role' : 'active team role',
    needsReport ? 'missing report' : undefined,
    hasReport ? 'report submitted' : undefined,
  ].filter(Boolean).join(', ');

  return (
    <button
      type="button"
      className={`agent-character status-${status} ${selected ? 'selected' : ''} ${needsReport ? 'needs-report' : ''} ${bench ? 'bench-role' : 'active-role'}`}
      onClick={() => onSelect(role)}
      aria-label={`${role.display_name ?? role.id} character, ${stateParts}`}
    >
      <span className="pet-shadow" aria-hidden="true" />
      <img className="pet" src={characterSrc(role.id)} alt="" aria-hidden="true" />
      <span className="status-orb" aria-hidden="true" />
      {needsReport ? <span className="report-badge" aria-hidden="true">보고 필요</span> : null}
      {hasReport && !needsReport ? <span className="report-badge report-done" aria-hidden="true">보고 완료</span> : null}
      <strong>{role.display_name ?? role.id}</strong>
      <small>{statusLabel(status)}</small>
    </button>
  );
}
