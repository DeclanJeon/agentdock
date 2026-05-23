import type { OfficeRoom } from '../model/normalize';
import type { WorkspaceRole } from '../model/snapshot';
import { AgentCharacter } from './AgentCharacter';

export function Room({ room, selectedRoleId, onSelectRole }: { room: OfficeRoom; selectedRoleId?: string; onSelectRole: (role: WorkspaceRole) => void }) {
  return (
    <section className={`office-room ${room.id}`} aria-label={room.title}>
      <div className="room-header">
        <h2>{room.title}</h2>
        <p>{room.subtitle}</p>
      </div>
      <div className="room-grid">
        {room.roles.length === 0 ? (
          <p className="empty-room">활성 역할 없음</p>
        ) : (
          room.roles.map((role) => (
            <AgentCharacter key={role.id} role={role} selected={role.id === selectedRoleId} onSelect={onSelectRole} />
          ))
        )}
      </div>
    </section>
  );
}
