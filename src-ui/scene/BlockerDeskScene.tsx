import type { SceneModel } from '../model/scene';

export function BlockerDeskScene({ scene }: { scene: SceneModel }) {
  return (
    <section className="scene-desk blocker-desk-scene" aria-label="Blocker Desk scene">
      <p className="eyebrow">Blocker Desk</p>
      <h2>{scene.blockerDesk.hasBlockers ? 'Active warnings' : 'No active blocker'}</h2>
      {scene.blockerDesk.cards.length === 0 ? <p>No structured blocker cards.</p> : null}
      <ul className="scene-blocker-list">
        {scene.blockerDesk.cards.map((card, index) => (
          <li key={`${card.type}-${index}`} className={`scene-blocker-card severity-${card.severity.toLowerCase()}`} aria-label={`${card.severity} ${card.type} ${card.owner ?? 'unassigned'} ${card.message}`}>
            <strong>{card.severity} · {card.type}</strong>
            {card.owner ? <span>Owner: {card.owner}</span> : null}
            <p>{card.message}</p>
            {card.nextAction ? <small>Next: {card.nextAction}</small> : null}
          </li>
        ))}
      </ul>
    </section>
  );
}
