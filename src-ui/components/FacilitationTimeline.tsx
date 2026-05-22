import { deriveFacilitationTimeline } from '../model/timeline';
import type { WorkspaceSnapshot } from '../model/snapshot';
import type { WorkspaceMode } from '../model/scene';

export function FacilitationTimeline({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const steps = deriveFacilitationTimeline(snapshot, mode);
  return (
    <section className="facilitation-timeline timeline-progress-strip" aria-label="Facilitation timeline">
      <div className="timeline-strip-heading">
        <p className="eyebrow">Progress</p>
        <h2>진행 흐름</h2>
        <p>Snapshot-only · active, done, blocked, pending.</p>
      </div>
      <ol className="timeline-strip">
        {steps.map((step) => (
          <li
            key={step.id}
            className={`timeline-step state-${step.state}`}
            aria-label={`${step.label}: ${step.state}. ${step.note}. Evidence ${step.evidenceCount}`}
            title={`${step.label}: ${step.state} · evidence ${step.evidenceCount} · ${step.note}`}
          >
            <span className="timeline-dot" aria-hidden="true" />
            <strong>{step.label}</strong>
            <span className="timeline-state">{step.state}</span>
            <span className="timeline-evidence" aria-label={`evidence ${step.evidenceCount}`}>{step.evidenceCount}</span>
            <small className="sr-only">{step.note}</small>
          </li>
        ))}
      </ol>
    </section>
  );
}
