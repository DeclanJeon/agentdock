import type { SceneModel } from '../model/scene';

export function MissionBoard({ scene }: { scene: SceneModel }) {
  return (
    <section className="scene-desk mission-board-scene" aria-label="Mission Board">
      <p className="eyebrow">Mission Board</p>
      <h2>{scene.meta.jobId}</h2>
      <p>{scene.meta.lifecycle} · {scene.meta.freshnessLabel}</p>
      <p>{scene.office.selectedCount}/{scene.office.roleCount} roles selected · read-only snapshot</p>
      <div className="mission-tokens" aria-label="Selected role count and density">
        <span>{scene.office.density}</span>
        <span>{scene.reportDesk.coverageLabel}</span>
      </div>
    </section>
  );
}
