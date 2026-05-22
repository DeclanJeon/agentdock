import { deriveFacilitationTimeline } from '../model/timeline';
import type { WorkspaceSnapshot } from '../model/snapshot';
import type { WorkspaceMode } from '../model/scene';

export function FacilitationTimeline({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const steps = deriveFacilitationTimeline(snapshot, mode);
  return (
    <section className="facilitation-timeline progress-strip" aria-label="Facilitation timeline">
      <div className="timeline-strip-heading">
        <p className="eyebrow">운영 타임라인</p>
        <h2>Facilitation Timeline</h2>
        <p>Snapshot-only progress · blocked/done/active/pending semantics preserved.</p>
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
