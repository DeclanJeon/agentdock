import type { WorkspaceCommunications, WorkspaceDependencies, WorkspaceMeetings, WorkspaceOrchestration, WorkspaceQaStatus, WorkspaceWriteConflicts } from '../model/snapshot';

const MODE_LABELS: Record<string, string> = {
  idle: '작업 대기',
  solo_direct: '간단 작업',
  assisted_single_lane: '단일 실행 + 보조 1명',
  standard_team: '표준 팀 작업',
  critical_review: '고위험 검토 작업',
  legacy_controlled_actions: '기존 작업',
};

const QA_LABELS: Record<string, string> = {
  not_required: 'QA 불필요',
  pending: 'QA 대기',
  passed: 'QA 통과',
  failed: 'QA 실패',
};

function modeTone(mode?: string) {
  if (mode === 'critical_review') return 'critical';
  if (mode === 'standard_team') return 'team';
  if (mode === 'assisted_single_lane') return 'assist';
  return 'solo';
}

function compactReason(orchestration?: WorkspaceOrchestration) {
  if (!orchestration?.reason) return '작업을 만들면 CEO가 규모와 위험도를 판단합니다.';
  return orchestration.reason;
}

function roleName(value: string | { role?: string; template?: string; reason?: string }) {
  return typeof value === 'string' ? value : value.role ?? value.template ?? 'unknown';
}

export function OrchestrationPanel({
  orchestration,
  qa,
  dependencies,
  meetings,
  writeConflicts,
  communications,
}: {
  orchestration?: WorkspaceOrchestration;
  qa?: WorkspaceQaStatus;
  dependencies?: WorkspaceDependencies;
  meetings?: WorkspaceMeetings;
  writeConflicts?: WorkspaceWriteConflicts;
  communications?: WorkspaceCommunications;
}) {
  const mode = orchestration?.mode ?? 'idle';
  const tone = modeTone(mode);
  const teamCap = orchestration?.team_cap ?? orchestration?.budget?.max_roles ?? 0;
  const qaStatus = qa?.status ?? (orchestration?.requires_qa ? 'pending' : 'not_required');
  const intents = orchestration?.intents?.filter(Boolean) ?? [];
  const selected = orchestration?.selected_role_details?.length
    ? orchestration.selected_role_details.map((role) => role.role).filter(Boolean)
    : orchestration?.selected_roles ?? [];
  const rejected = orchestration?.rejected_roles ?? [];
  const openDependencies = dependencies?.items?.filter((item) => item.status !== 'closed') ?? [];
  const concludedMeetings = meetings?.items?.filter((item) => item.status === 'concluded' && item.decision) ?? [];
  const conflicts = writeConflicts?.items ?? [];
  const recentActions = communications?.items?.slice(-3).reverse() ?? [];
  return (
    <section className={`orchestration-panel tone-${tone}`} aria-label="CEO orchestration policy">
      <header>
        <p className="eyebrow">CEO 판단</p>
        <h2>{MODE_LABELS[mode] ?? mode}</h2>
      </header>
      <p className="orchestration-reason">{compactReason(orchestration)}</p>
      <dl className="orchestration-metrics">
        <div><dt>최대 팀</dt><dd>{teamCap ? `${teamCap}명` : '없음'}</dd></div>
        <div><dt>QA</dt><dd className={`qa-${qaStatus}`}>{QA_LABELS[qaStatus] ?? qaStatus}</dd></div>
        <div><dt>위험도</dt><dd>{orchestration?.risk ?? '낮음'}</dd></div>
      </dl>
      {mode === 'solo_direct' || mode === 'assisted_single_lane' ? (
        <p className="orchestration-note">간단한 작업은 불필요한 팀 생성 없이 가볍게 진행합니다.</p>
      ) : (
        <p className="orchestration-note">역할 보고와 QA 게이트를 통과해야 최종 완료할 수 있습니다.</p>
      )}
      {intents.length ? <p className="orchestration-tags">{intents.map((intent) => <span key={intent}>{intent}</span>)}</p> : null}
      {orchestration?.approval_required ? <p className="orchestration-warning">권한/보안/운영 영향이 있어 명시적 검토가 필요합니다.</p> : null}
      {selected.length || rejected.length ? (
        <details className="orchestration-details">
          <summary>역할 선택 근거</summary>
          {selected.length ? <p><strong>선택:</strong> {selected.join(', ')}</p> : null}
          {rejected.length ? <p><strong>제외:</strong> {rejected.map(roleName).join(', ')}</p> : null}
        </details>
      ) : null}
      {openDependencies.length ? (
        <div className="orchestration-dependencies" aria-label="Open role dependencies">
          <strong>대기/의존</strong>
          {openDependencies.slice(0, 3).map((item, index) => (
            <p key={`${item.role}-${item.waiting_on}-${index}`}>{item.role} → {item.waiting_on}: {item.reason ?? '의존성 대기'}</p>
          ))}
        </div>
      ) : null}
      {concludedMeetings.length ? (
        <details className="orchestration-details">
          <summary>결정 기록</summary>
          {concludedMeetings.slice(0, 3).map((meeting) => <p key={meeting.source_path ?? meeting.title}><strong>{meeting.title}</strong>: {meeting.decision}</p>)}
        </details>
      ) : null}
      {conflicts.length ? (
        <div className="orchestration-dependencies" aria-label="Write scope conflicts">
          <strong>공유 파일 충돌</strong>
          {conflicts.slice(0, 3).map((item) => <p key={item.file}>{item.file}: {(item.roles ?? []).join(', ')}</p>)}
        </div>
      ) : null}
      {recentActions.length ? (
        <details className="orchestration-details">
          <summary>최근 조율 기록</summary>
          {recentActions.map((item, index) => <p key={`${item.time}-${index}`}><strong>{item.action}</strong>: {item.summary}</p>)}
        </details>
      ) : null}
    </section>
  );
}
