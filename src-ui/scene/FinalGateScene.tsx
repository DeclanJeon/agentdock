import type { SceneModel } from '../model/scene';
import { StatusProp } from './StatusProp';

export function FinalGateScene({ scene }: { scene: SceneModel }) {
  return (
    <section className={`scene-desk final-gate-scene ${scene.finalGate.ready ? 'ready' : 'blocked'}`} aria-label="Final Gate scene">
      <p className="eyebrow">Final Gate</p>
      <h2>{scene.finalGate.label}</h2>
      <StatusProp state={scene.finalGate.ready ? 'final-ready' : 'final-blocked'} label={scene.finalGate.ready ? 'Final seal ready' : 'Final gate locked'} />
      <p>{scene.finalGate.reason}</p>
      <p className="next-action-line">{scene.finalGate.nextAction}</p>
    </section>
  );
}
