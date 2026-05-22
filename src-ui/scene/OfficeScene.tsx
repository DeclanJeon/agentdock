import { memo, useMemo, useState } from 'react';
import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { deriveSceneModel, type SceneRole, type WorkspaceMode, type ZoneId } from '../model/scene';
import { SceneViewport } from './SceneViewport';
import { OfficeZone } from './OfficeZone';
import { MissionBoard } from './MissionBoard';
import { ReportDeskScene } from './ReportDeskScene';
import { BlockerDeskScene } from './BlockerDeskScene';
import { FinalGateScene } from './FinalGateScene';
import { DenseRoleNavigator, type NavSection, type RoleFilter } from './DenseRoleNavigator';
import { SceneInspector } from './SceneInspector';

export function filterRolesForScene(roles: SceneRole[], query: string, activeFilter: RoleFilter): SceneRole[] {
  const normalizedQuery = query.trim().toLowerCase();
  return roles.filter((role) => {
    const matchesQuery = normalizedQuery.length === 0 || role.denseMetadata.searchableText.includes(normalizedQuery);
    const matchesFilter = activeFilter === 'all'
      || (activeFilter === 'active' && role.selected && !role.bench)
      || (activeFilter === 'missing report' && role.reportState === 'report needed')
      || (activeFilter === 'blocked' && role.blocked)
      || (activeFilter === 'reported' && role.reportState === 'reported')
      || (activeFilter === 'bench' && role.bench)
      || (activeFilter === 'offline' && role.offline);
    return matchesQuery && matchesFilter;
  });
}

function BottomTrustBar({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const projectPath = snapshot.project?.root ?? '~/projects/agentdock';
  const compactPath = projectPath.replace('/home/declan/Documents/Develop/Project', '~');
  return (
    <footer className="bottom-trust-bar" aria-label="Read-only source and runtime trust status">
      <span><strong>Hermes</strong> running <i aria-hidden="true" className="status-dot good" /></span>
      <span><strong>tmux</strong> active <i aria-hidden="true" className="status-dot good" /></span>
      <span><strong>Session</strong> {snapshot.project?.session ?? snapshot.project?.session_name ?? 'agentdock'}</span>
      <span><strong>Project Path</strong> {compactPath}</span>
      <span><strong>Workspace</strong> read-only 🔒</span>
      <span><strong>Snapshot</strong> {snapshot.generated_at ? new Date(snapshot.generated_at).toLocaleString() : 'pending'}</span>
      <span><strong>Mode</strong> visual-office ({mode})</span>
    </footer>
  );
}

function OfficeSceneView({ snapshot, mode, selectedRoleId, onSelectRole }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode; selectedRoleId?: string; onSelectRole: (role: WorkspaceRole) => void }) {
  const [focusedZone, setFocusedZone] = useState<ZoneId | undefined>();
  const [query, setQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState<RoleFilter>('all');
  const [activeSection, setActiveSection] = useState<NavSection>('office');
  const scene = useMemo(() => deriveSceneModel(snapshot, { mode }), [snapshot, mode]);
  const filteredRoles = useMemo(() => filterRolesForScene(scene.roles, query, activeFilter), [scene.roles, query, activeFilter]);
  const filteredRoleIds = useMemo(() => new Set(filteredRoles.map((role) => role.id)), [filteredRoles]);
  const selectedSceneRole = scene.roles.find((role) => role.id === selectedRoleId)
    ?? scene.roles.find((role) => role.blocked)
    ?? scene.roles.find((role) => role.reportState === 'report needed')
    ?? scene.roles.find((role) => role.id === 'orchestrator')
    ?? scene.roles.find((role) => role.selected)
    ?? scene.roles[0];
  function selectNavSection(section: NavSection) {
    setActiveSection(section);
    switch (section) {
      case 'office':
        setActiveFilter('all');
        setFocusedZone(undefined);
        break;
      case 'roles':
        setActiveFilter('all');
        setFocusedZone(undefined);
        break;
      case 'tasks':
        setActiveFilter('active');
        setFocusedZone('mission');
        break;
      case 'reports':
        setActiveFilter('missing report');
        setFocusedZone('report');
        break;
      case 'alerts':
        setActiveFilter('blocked');
        setFocusedZone('blocker');
        break;
      case 'files':
        setActiveFilter('active');
        break;
      case 'settings':
        setFocusedZone('utility');
        break;
    }
  }

  const roleZones = scene.office.zones.filter((zone) => !['report', 'blocker', 'utility'].includes(zone.id));
  const rolesByZone = new Map(scene.office.zones.map((zone) => [zone.id, scene.roles.filter((role) => role.zoneId === zone.id)]));

  return (
    <main className={`office-scene reference-office-shell ${focusedZone ? `focused-zone-${focusedZone}` : ''}`} aria-label="AgentDock reference Visual Office workspace">
      <DenseRoleNavigator
        scene={scene}
        query={query}
        activeFilter={activeFilter}
        activeSection={activeSection}
        focusedZone={focusedZone}
        visibleCount={filteredRoles.length}
        hiddenCount={scene.roles.length - filteredRoles.length}
        onQueryChange={setQuery}
        onFilterChange={setActiveFilter}
        onSectionChange={selectNavSection}
        onZoneFocus={setFocusedZone}
      />
      <SceneViewport density={scene.office.density}>
        <div className="office-zone-grid" aria-label="Role rooms">
          {roleZones.map((zone) => (
            <OfficeZone
              key={zone.id}
              zone={zone}
              roles={rolesByZone.get(zone.id) ?? []}
              visibleRoleIds={filteredRoleIds}
              focused={focusedZone === zone.id}
              selectedRoleId={selectedSceneRole?.id}
              onSelectRole={(role) => onSelectRole(role.role)}
            />
          ))}
        </div>
        <div className="office-status-grid" aria-label="Workspace status desks">
          <MissionBoard scene={scene} />
          <ReportDeskScene scene={scene} onSelectRole={onSelectRole} />
          <BlockerDeskScene scene={scene} />
          <FinalGateScene scene={scene} />
          <section className="scene-desk security-nook-scene" aria-label="Security Nook read-only boundary">
            <p className="eyebrow">Security Nook</p>
            <h2>🔒 Read-only</h2>
            <p>Read-only snapshot sourced · write bridge disabled</p>
          </section>
        </div>
      </SceneViewport>
      <SceneInspector snapshot={snapshot} role={selectedSceneRole} scene={scene} />
      <BottomTrustBar snapshot={snapshot} mode={mode} />
    </main>
  );
}

export const OfficeScene = memo(OfficeSceneView);
