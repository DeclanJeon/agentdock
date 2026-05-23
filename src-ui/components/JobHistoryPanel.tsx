import type { WorkspaceSnapshot } from '../model/snapshot';

export function JobHistoryPanel({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  const jobs = snapshot.history?.recent_jobs ?? [];
  const active = snapshot.history?.active_job_id ?? snapshot.job?.id;
  return (
    <details className="job-history-panel auxiliary-panel" aria-label="Read-only job history">
      <summary>
        <span>
          <span className="eyebrow">Job history</span>
          <strong>최근 작업 기록</strong>
        </span>
        <span className="auxiliary-summary-chip">{jobs.length} jobs</span>
      </summary>
      <div className="auxiliary-panel-body">
        <p>읽기 전용 기록입니다. 이전 작업을 보기 위해 CURRENT.md를 바꾸지 않습니다.</p>
        {jobs.length === 0 ? <p className="empty-audit">최근 작업 기록이 없습니다.</p> : (
          <ol className="job-history-list">
            {jobs.map((job) => (
              <li key={job.id} className={job.id === active ? 'active' : ''}>
                <div>
                  <strong>{job.id}</strong>
                  <span>{job.lifecycle ?? 'unknown'} · reports {job.report_count ?? 0}</span>
                </div>
                <p>{job.request_preview || '요청 요약 없음'}</p>
                {job.final_report_path ? <code>{job.final_report_path}</code> : <small>최종 보고 없음</small>}
              </li>
            ))}
          </ol>
        )}
      </div>
    </details>
  );
}
