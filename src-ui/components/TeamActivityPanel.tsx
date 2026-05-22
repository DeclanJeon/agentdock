import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { reportStateForRole, roleActivityLabel, statusLabel } from '../model/normalize';

function nextActionForRole(roleId: string, reportState: string, status?: string) {
  if (status === 'blocked') return '블로커를 확인하고 CEO 후속지시 또는 재할당이 필요합니다.';
  if (reportState === 'report needed') return '작업 완료 후 role report 제출이 필요합니다.';
  if (reportState === 'reported') return '보고 완료. CEO 최종 검토 대기.';
  return '작업 카드 또는 팀 브로드캐스트를 확인합니다.';
}

export function TeamActivityPanel({ snapshot, selectedRoleId, onSelectRole }: { snapshot: WorkspaceSnapshot; selectedRoleId?: string; onSelectRole?: (role: WorkspaceRole) => void }) {
  const roles = (snapshot.roles ?? []).filter((role) => role.selected);
  const blockers = new Set((snapshot.alerts ?? []).map((alert) => alert.role ?? alert.owner).filter(Boolean));
  return (
    <section className="team-activity-panel" aria-label="Selected team activity summary">
      <header>
        <p className="eyebrow">Team activity</p>
        <h2>팀별 현재 작업</h2>
      </header>
      {roles.length === 0 ? <p className="empty-audit">선택된 팀이 없습니다. CEO 작업을 먼저 생성하세요.</p> : (
        <ol>
          {roles.map((role) => {
            const report = reportStateForRole(role, snapshot);
            const blocked = role.status === 'blocked' || blockers.has(role.id);
            const active = selectedRoleId === role.id;
            return (
              <li key={role.id} className={`${blocked ? 'blocked' : report === 'reported' ? 'reported' : report === 'report needed' ? 'needs-report' : ''} ${active ? 'selected' : ''}`}>
                <button type="button" onClick={() => onSelectRole?.(role)} aria-pressed={active}>
                  <div>
                    <strong>{role.display_name ?? role.id}</strong>
                    <span>{blocked ? '블로커 있음' : statusLabel(role.status)}</span>
                  </div>
                  <p>{roleActivityLabel(role, snapshot)}</p>
                  <small>{nextActionForRole(role.id, report, blocked ? 'blocked' : role.status)}</small>
                </button>
              </li>
            );
          })}
        </ol>
      )}
    </section>
  );
}
