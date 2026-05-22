import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { normalizeRooms } from '../model/normalize';
import { Room } from './Room';
import { FinalReadinessPanel } from './FinalReadinessPanel';
import { ReportDesk } from './ReportDesk';
import { BlockerDesk } from './BlockerDesk';

export function PixelOffice({ snapshot, selectedRoleId, onSelectRole }: { snapshot: WorkspaceSnapshot; selectedRoleId?: string; onSelectRole: (role: WorkspaceRole) => void }) {
  const rooms = normalizeRooms(snapshot);
  return (
    <main className="pixel-office" aria-label="Pixel office workspace map">
      <div className="mission-room">
        <h2>Mission Room</h2>
        <p>{snapshot.job?.final_ready_reason ?? 'No active job reason available.'}</p>
      </div>
      <FinalReadinessPanel snapshot={snapshot} />
      <ReportDesk snapshot={snapshot} onSelectRole={onSelectRole} />
      {rooms.map((room) => (
        <Room key={room.id} room={room} selectedRoleId={selectedRoleId} onSelectRole={onSelectRole} />
      ))}
      <BlockerDesk snapshot={snapshot} />
    </main>
  );
}
