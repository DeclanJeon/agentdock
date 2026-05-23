import type { WorkspaceRole, WorkspaceSnapshot } from '../model/snapshot';
import { statusLabel } from '../model/normalize';

export function Inspector({ snapshot, role }: { snapshot: WorkspaceSnapshot; role?: WorkspaceRole }) {
  if (!role) {
    return (
      <aside className="inspector" aria-label="Job inspector">
        <p className="eyebrow">상세 정보</p>
        <h2>작업 요약</h2>
        <dl>
          <dt>프로젝트</dt><dd>{snapshot.project?.name ?? '대기'}</dd>
          <dt>경로</dt><dd>{snapshot.project?.root ?? '대기'}</dd>
          <dt>업데이트</dt><dd>{snapshot.generated_at ?? '대기'}</dd>
          <dt>안전</dt><dd>현재 상태를 보여주며 실행은 승인된 액션으로만 진행합니다.</dd>
        </dl>
      </aside>
    );
  }

  return (
    <aside className="inspector" aria-label={`${role.id} inspector`}>
      <p className="eyebrow">선택된 역할</p>
      <h2>{role.display_name ?? role.id}</h2>
      <dl>
        <dt>상태</dt><dd>{statusLabel(role.status)}</dd>
        <dt>이유</dt><dd>{role.status_reason ?? '이유가 아직 없습니다.'}</dd>
        <dt>분야</dt><dd>{role.department ?? 'General'}</dd>
        <dt>작업</dt><dd>{role.task_path || '작업 경로 없음'}</dd>
        <dt>보고</dt><dd>{role.latest_report_path || '현재 보고 없음'}</dd>
        <dt>실행</dt><dd>{role.running_pane ? role.pane_id || '실행 중' : '대기'}</dd>
      </dl>
      <h3>근거</h3>
      <ul>
        {(role.source_paths ?? []).map((path) => <li key={path}>{path}</li>)}
      </ul>
    </aside>
  );
}
