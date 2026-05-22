import type { SceneModel, ZoneId } from '../model/scene';

export type RoleFilter = 'all' | 'active' | 'missing report' | 'blocked' | 'reported' | 'bench' | 'offline';
export type NavSection = 'office' | 'roles' | 'tasks' | 'reports' | 'alerts' | 'files' | 'settings';

const navItems: Array<{ id: NavSection; icon: string; label: string; description: string }> = [
  { id: 'office', icon: '⌂', label: 'Office', description: '전체 작업장 보기' },
  { id: 'roles', icon: '👥', label: 'Roles', description: '전체 역할 보기' },
  { id: 'tasks', icon: '▣', label: 'Tasks', description: '작업 배정 역할' },
  { id: 'reports', icon: '▤', label: 'Reports', description: '보고 필요/완료' },
  { id: 'alerts', icon: '⚠', label: 'Alerts', description: '블로커/경고' },
  { id: 'files', icon: '▰', label: 'Files', description: '선택 역할 파일' },
  { id: 'settings', icon: '⚙', label: 'Settings', description: '런타임 상태' },
];

export function DenseRoleNavigator({
  scene,
  query,
  activeFilter,
  activeSection,
  focusedZone,
  visibleCount,
  hiddenCount,
  onQueryChange,
  onFilterChange,
  onSectionChange,
  onZoneFocus,
}: {
  scene: SceneModel;
  query: string;
  activeFilter: RoleFilter;
  activeSection: NavSection;
  focusedZone?: ZoneId;
  visibleCount: number;
  hiddenCount: number;
  onQueryChange: (query: string) => void;
  onFilterChange: (filter: RoleFilter) => void;
  onSectionChange: (section: NavSection) => void;
  onZoneFocus?: (zone: ZoneId) => void;
}) {
  const filters: RoleFilter[] = ['all', ...(scene.navigation.filters as RoleFilter[])];
  return (
    <nav className="dense-role-navigator reference-nav-rail" aria-label="Read-only workspace navigation and dense role filters">
      <div className="nav-item-stack" aria-label="Workspace sections">
        {navItems.map((item) => (
          <button
            type="button"
            key={item.id}
            className={`nav-rail-item ${activeSection === item.id ? 'active' : ''}`}
            aria-pressed={activeSection === item.id}
            aria-label={`${item.label}: ${item.description}`}
            title={item.description}
            onClick={() => onSectionChange(item.id)}
          >
            <span aria-hidden="true">{item.icon}</span>
            <strong>{item.label}</strong>
            <small>{item.description}</small>
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
        <p>{visibleCount} visible · {hiddenCount} hidden · {activeSection}</p>
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
