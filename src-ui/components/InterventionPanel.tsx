import { useEffect, useMemo, useState } from 'react';
import type { ControlledActionName, ControlledActionResult } from '../model/actions';
import type { WorkspaceSnapshot, WorkspaceRole } from '../model/snapshot';
import { teamPlanFromSnapshot } from '../model/teamPlan';

function selectedRoles(snapshot: WorkspaceSnapshot): WorkspaceRole[] {
  return (snapshot.roles ?? []).filter((role) => role.selected);
}

interface Props {
  snapshot: WorkspaceSnapshot;
  onControlledAction: (action: ControlledActionName, payload: Record<string, string>) => Promise<ControlledActionResult>;
}

function resultLine(result?: ControlledActionResult | null) {
  if (!result) return null;
  return <p className={`controlled-action-result ${result.ok ? 'success' : 'failure'}`}>{result.message ?? (result.ok ? 'Action succeeded.' : 'Action failed.')}</p>;
}

export function InterventionPanel({ snapshot, onControlledAction }: Props) {
  const jobId = snapshot.job?.id ?? '';
  const selected = useMemo(() => selectedRoles(snapshot), [snapshot.roles]);
  const finishReady = Boolean(snapshot.job?.final_ready);
  const teamPlan = useMemo(() => teamPlanFromSnapshot(snapshot), [snapshot]);
  const [busyAction, setBusyAction] = useState<string | null>(null);
  const [lastResult, setLastResult] = useState<ControlledActionResult | null>(null);
  const [followup, setFollowup] = useState('Please review the current blockers, report the next action, and keep the selected team synchronized.');
  const [broadcast, setBroadcast] = useState('Selected team sync: confirm current task status, blockers, and next evidence artifact.');
  const [roleTarget, setRoleTarget] = useState(selected[0]?.id ?? '');
  const [roleMessage, setRoleMessage] = useState('Please update your current task status, next step, and verification evidence.');
  const [recruitRole, setRecruitRole] = useState(teamPlan.recommendations.find((item) => !item.matchedRole)?.roleHint ?? '');
  const [recruitTemplate, setRecruitTemplate] = useState(teamPlan.recommendations.find((item) => !item.matchedRole)?.templateHint ?? 'developer');
  const [recruitMission, setRecruitMission] = useState(teamPlan.recommendations.find((item) => !item.matchedRole)?.reason ?? 'Join the active job and complete the assigned task card.');
  const [taskRole, setTaskRole] = useState(selected[0]?.id ?? '');
  const [taskProposal, setTaskProposal] = useState('Proposed task update: clarify owner, deliverable, acceptance criteria, and verification evidence.');
  const [reportRole, setReportRole] = useState(selected.find((role) => role.id !== teamPlan.coordinator)?.id ?? selected[0]?.id ?? '');
  const [reportSummary, setReportSummary] = useState('Native UI controlled-action matrix report: assigned work completed with no known blocker.');
  const [finishSummary, setFinishSummary] = useState('Completed through AgentDock UI controlled finish after selected-role report review.');
  const recommendedRecruit = teamPlan.recommendations.find((item) => !item.matchedRole);
  const selectedRoleIds = useMemo(() => selected.map((role) => role.id), [selected]);
  const canRun = Boolean(jobId) && !busyAction;

  useEffect(() => {
    const firstSelected = selected[0]?.id ?? '';
    const firstWorker = selected.find((role) => role.id !== teamPlan.coordinator)?.id ?? firstSelected;
    if (!selectedRoleIds.includes(roleTarget)) setRoleTarget(firstSelected);
    if (!selectedRoleIds.includes(taskRole)) setTaskRole(firstSelected);
    if (!selectedRoleIds.includes(reportRole)) setReportRole(firstWorker);
    if (recommendedRecruit && (!recruitRole.trim() || recruitRole === 'product-manager')) {
      setRecruitRole(recommendedRecruit.roleHint);
    }
    if (recommendedRecruit && (!recruitTemplate.trim() || recruitTemplate === 'product-manager' || recruitTemplate === 'developer')) {
      setRecruitTemplate(recommendedRecruit.templateHint);
    }
    if (recommendedRecruit && (!recruitMission.trim() || recruitMission === '요구사항과 acceptance criteria 정리가 필요합니다.')) {
      setRecruitMission(recommendedRecruit.reason);
    }
  }, [recommendedRecruit, recruitMission, recruitRole, recruitTemplate, reportRole, roleTarget, selected, selectedRoleIds, taskRole, teamPlan.coordinator]);

  async function run(action: ControlledActionName, payload: Record<string, string>, clear?: () => void) {
    setBusyAction(action);
    try {
      const result = await onControlledAction(action, { jobId, ...payload });
      setLastResult(result);
      if (result.ok) clear?.();
    } finally {
      setBusyAction(null);
    }
  }

  return (
    <details className="intervention-panel auxiliary-panel" aria-label="Controlled intervention console" open>
      <summary>
        <span>
          <span className="eyebrow">개입 콘솔</span>
          <strong>Safe Intervention Console</strong>
        </span>
        <span className="auxiliary-summary-chip">{busyAction ? 'running' : 'controlled actions'}</span>
      </summary>
      <div className="auxiliary-panel-body">
        <p>고정 argv 기반 통제 액션만 제공합니다. arbitrary shell, 직접 TASKS 파일 쓰기, 무제한 write bridge는 열지 않습니다.</p>
        <section className="team-plan-card" aria-label="CEO team plan preview">
          <h3>Team/TFT plan</h3>
          <p><strong>Coordinator:</strong> {teamPlan.coordinator ?? 'unknown'} · <strong>Selected:</strong> {teamPlan.selectedRoles.length}</p>
          <p><strong>TFT:</strong> {teamPlan.tfts.join(', ') || 'TEAM.md에 TFT가 아직 기록되지 않음'}</p>
          <ul>
            {teamPlan.recommendations.slice(0, 5).map((item) => (
              <li key={`${item.source ?? 'ui'}-${item.templateHint}-${item.capability}`}>
                {item.capability}: {item.matchedRole ? `reuse ${item.matchedRole}` : `recruit ${item.roleHint}`}
                {typeof item.score === 'number' ? ` · score ${item.score}` : ''} — {item.reason}
              </li>
            ))}
          </ul>
        </section>
        {resultLine(lastResult)}
        <div className="intervention-grid">
          <article>
            <h3>CEO follow-up</h3>
            <p>{jobId ? `Active job ${jobId}의 coordinator에게 후속 지시를 보냅니다.` : 'No active job: follow-up disabled.'}</p>
            <textarea aria-label="CEO follow-up message" value={followup} onChange={(event) => setFollowup(event.target.value)} placeholder="후속 지시를 입력하세요" />
            <button type="button" disabled={!canRun || !followup.trim()} onClick={() => run('agentdock_job_followup', { message: followup }, () => setFollowup(''))}>{busyAction === 'agentdock_job_followup' ? 'Sending…' : 'Send follow-up'}</button>
          </article>
          <article>
            <h3>Selected-team broadcast</h3>
            <p>{selected.length} selected roles: {selected.map((role) => role.id).join(', ') || 'none'}</p>
            <textarea aria-label="Selected-team broadcast message" value={broadcast} onChange={(event) => setBroadcast(event.target.value)} placeholder="팀 전체 공지" />
            <button type="button" disabled={!canRun || selected.length === 0 || !broadcast.trim()} onClick={() => run('agentdock_team_broadcast', { message: broadcast }, () => setBroadcast(''))}>{busyAction === 'agentdock_team_broadcast' ? 'Broadcasting…' : 'Broadcast to selected team'}</button>
          </article>
          <article>
            <h3>Role direct send</h3>
            <select aria-label="Role direct send target" value={roleTarget} onChange={(event) => setRoleTarget(event.target.value)}>
              {selected.map((role) => <option key={role.id} value={role.id}>{role.id}</option>)}
            </select>
            <textarea aria-label="Role direct send message" value={roleMessage} onChange={(event) => setRoleMessage(event.target.value)} placeholder="역할별 직접 메시지" />
            <button type="button" disabled={!canRun || !roleTarget || !roleMessage.trim()} onClick={() => run('agentdock_role_send', { role: roleTarget, message: roleMessage }, () => setRoleMessage(''))}>{busyAction === 'agentdock_role_send' ? 'Sending…' : 'Send to role'}</button>
          </article>
          <article>
            <h3>Recruit role</h3>
            <input aria-label="Recruit role id" value={recruitRole} onChange={(event) => setRecruitRole(event.target.value)} placeholder="role-id" />
            <input aria-label="Recruit template id" value={recruitTemplate} onChange={(event) => setRecruitTemplate(event.target.value)} placeholder="template-id" />
            <textarea aria-label="Recruit mission and instructions" value={recruitMission} onChange={(event) => setRecruitMission(event.target.value)} placeholder="mission / instructions" />
            <div className="split-action-row">
              <button type="button" disabled={!canRun || !recruitRole.trim() || !recruitTemplate.trim() || !recruitMission.trim()} onClick={() => run('agentdock_recruit_preview', { role: recruitRole, template: recruitTemplate, mission: recruitMission })}>Preview</button>
              <button type="button" disabled={!canRun || !recruitRole.trim() || !recruitTemplate.trim() || !recruitMission.trim()} onClick={() => run('agentdock_recruit_role', { role: recruitRole, template: recruitTemplate, mission: recruitMission, instructions: recruitMission })}>{busyAction === 'agentdock_recruit_role' ? 'Recruiting…' : 'Recruit'}</button>
            </div>
          </article>
          <article>
            <h3>Task change proposal</h3>
            <select aria-label="Task proposal target role" value={taskRole} onChange={(event) => setTaskRole(event.target.value)}>
              {selected.map((role) => <option key={role.id} value={role.id}>{role.id}</option>)}
            </select>
            <textarea aria-label="Task proposal message" value={taskProposal} onChange={(event) => setTaskProposal(event.target.value)} placeholder="TASKS/*.md 직접 수정 대신 coordinator에게 보낼 제안" />
            <button type="button" disabled={!canRun || !taskRole || !taskProposal.trim()} onClick={() => run('agentdock_task_proposal', { role: taskRole, proposal: taskProposal }, () => setTaskProposal(''))}>{busyAction === 'agentdock_task_proposal' ? 'Sending…' : 'Send proposal'}</button>
          </article>
          <article>
            <h3>Submit role report</h3>
            <p>선택된 역할의 완료 보고를 job REPORTS에 제출합니다.</p>
            <select aria-label="Report submit role" value={reportRole} onChange={(event) => setReportRole(event.target.value)}>
              {selected.map((role) => <option key={role.id} value={role.id}>{role.id}</option>)}
            </select>
            <textarea aria-label="Role report summary" value={reportSummary} onChange={(event) => setReportSummary(event.target.value)} placeholder="완료 작업, 테스트, 리스크 요약" />
            <button type="button" disabled={!canRun || !reportRole || !reportSummary.trim()} onClick={() => run('agentdock_job_report', { role: reportRole, summary: reportSummary }, () => setReportSummary(''))}>{busyAction === 'agentdock_job_report' ? 'Submitting…' : 'Submit report'}</button>
          </article>
          <article>
            <h3>Finish readiness assist</h3>
            <p>{finishReady ? 'Final-ready evidence is true.' : snapshot.job?.final_ready_reason ?? 'Finish is not ready.'}</p>
            <textarea aria-label="Finish summary" value={finishSummary} onChange={(event) => setFinishSummary(event.target.value)} placeholder="final summary" />
            <div className="split-action-row">
              <button type="button" disabled={!canRun} onClick={() => run('agentdock_finish_preview', {})}>Preview finish</button>
              <button type="button" disabled={!canRun || !finishReady || !finishSummary.trim()} onClick={() => run('agentdock_job_finish', { summary: finishSummary })}>{busyAction === 'agentdock_job_finish' ? 'Finishing…' : 'Finish job'}</button>
            </div>
          </article>
        </div>
      </div>
    </details>
  );
}
