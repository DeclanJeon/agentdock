import { deriveFacilitationTimeline } from '../model/timeline';
import type { WorkspaceSnapshot } from '../model/snapshot';
import type { WorkspaceMode } from '../model/scene';

export function FacilitationTimeline({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const steps = deriveFacilitationTimeline(snapshot, mode);
  return (
    <section className="facilitation-timeline" aria-label="Facilitation timeline">
      <div>
        <p className="eyebrow">운영 타임라인</p>
        <h2>Facilitation Timeline</h2>
        <p>Intake → CEO planning → team/task/report/final 상태를 snapshot 기준으로만 표시합니다.</p>
      </div>
      <ol>
        {steps.map((step) => (
          <li key={step.id} className={`timeline-step state-${step.state}`} aria-label={`${step.label}: ${step.state}. ${step.note}`}>
            <strong>{step.label}</strong>
            <span className="timeline-state">{step.state}</span>
            <span className="timeline-evidence">evidence {step.evidenceCount}</span>
            <small>{step.note}</small>
          </li>
        ))}
      </ol>
    </section>
  );
}
