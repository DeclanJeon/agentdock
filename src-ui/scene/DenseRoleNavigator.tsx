import type { SceneModel, ZoneId } from '../model/scene';

export type RoleFilter = 'all' | 'active' | 'missing report' | 'blocked' | 'reported' | 'bench' | 'offline';

const navItems = [
  { id: 'office', icon: '⌂', label: 'Office' },
  { id: 'roles', icon: '👥', label: 'Roles' },
  { id: 'tasks', icon: '▣', label: 'Tasks' },
  { id: 'reports', icon: '▤', label: 'Reports' },
  { id: 'alerts', icon: '⚠', label: 'Alerts' },
  { id: 'files', icon: '▰', label: 'Files' },
  { id: 'settings', icon: '⚙', label: 'Settings' },
];

export function DenseRoleNavigator({
  scene,
  query,
  activeFilter,
  focusedZone,
  visibleCount,
  hiddenCount,
  onQueryChange,
  onFilterChange,
  onZoneFocus,
}: {
  scene: SceneModel;
  query: string;
  activeFilter: RoleFilter;
  focusedZone?: ZoneId;
  visibleCount: number;
  hiddenCount: number;
  onQueryChange: (query: string) => void;
  onFilterChange: (filter: RoleFilter) => void;
  onZoneFocus?: (zone: ZoneId) => void;
}) {
  const filters: RoleFilter[] = ['all', ...(scene.navigation.filters as RoleFilter[])];
  return (
    <nav className="dense-role-navigator reference-nav-rail" aria-label="Read-only workspace navigation and dense role filters">
      <div className="nav-item-stack" aria-label="Workspace sections">
        {navItems.map((item, index) => (
          <button
            type="button"
            key={item.id}
            className={`nav-rail-item ${index === 0 ? 'active' : ''}`}
            aria-pressed={index === 0}
            aria-label={`${item.label} read-only view`}
          >
            <span aria-hidden="true">{item.icon}</span>
            <strong>{item.label}</strong>
          </button>
        ))}
      </div>

      <div className="rail-filter-panel" aria-label="Dense role search and filters">
        <label>
          Roles
          <input
            type="search"
            placeholder="Search roles"
            aria-label="Search roles by name status or zone"
            value={query}
            onChange={(event) => onQueryChange(event.currentTarget.value)}
          />
        </label>
        <div className="filter-chip-row compact" aria-label="Role status filters">
          {filters.slice(0, 5).map((filter) => (
            <button
              type="button"
              key={filter}
              className={activeFilter === filter ? 'active' : ''}
              aria-pressed={activeFilter === filter}
              aria-label={`Show ${filter} roles`}
              onClick={() => onFilterChange(filter)}
            >
              {filter}
            </button>
          ))}
        </div>
        <p>{visibleCount} visible · {hiddenCount} hidden</p>
      </div>

      <div className="zone-jump-row rail-zones" aria-label="Zone jumps">
        {scene.navigation.zoneJumps.map((zone) => (
          <button
            type="button"
            key={zone.id}
            className={focusedZone === zone.id ? 'active' : ''}
            aria-pressed={focusedZone === zone.id}
            onClick={() => onZoneFocus?.(zone.id)}
            aria-label={`Jump to ${zone.label}, ${zone.count} roles`}
          >
            {zone.label.replace(' Office', '').replace(' Bay', '')} <span>{zone.count}</span>
          </button>
        ))}
      </div>

      <div className="local-runtime-card" aria-label="Local runtime status">
        <strong>LOCAL</strong>
        <span>Hermes <i aria-hidden="true" className="status-dot good" /></span>
        <span>tmux <i aria-hidden="true" className="status-dot good" /></span>
        <small>Session {scene.meta.jobId === 'no-active-job' ? 'idle' : 'agentdock'}</small>
      </div>
    </nav>
  );
}
