import { deriveFacilitationTimeline } from '../model/timeline';
import type { WorkspaceSnapshot } from '../model/snapshot';
import type { WorkspaceMode } from '../model/scene';

export function FacilitationTimeline({ snapshot, mode }: { snapshot: WorkspaceSnapshot; mode: WorkspaceMode }) {
  const steps = deriveFacilitationTimeline(snapshot, mode);
  return (
    <section className="facilitation-timeline compact-timeline" aria-label="Facilitation timeline">
      <div className="timeline-heading">
        <p className="eyebrow">Facilitation</p>
        <h2>Intake → Planning → Team → Tasking → Reports → Final</h2>
      </div>
      <ol>
        {steps.map((step) => (
          <li key={step.id} className={`timeline-step state-${step.state}`} aria-label={`${step.label}: ${step.state}. ${step.note}`} title={step.note}>
            <strong>{step.label}</strong>
            <span className="timeline-state">{step.state}</span>
            <span className="timeline-evidence">{step.evidenceCount}</span>
            <small>{step.note}</small>
          </li>
        ))}
      </ol>
    </section>
  );
}
