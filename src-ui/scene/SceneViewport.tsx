import type { ReactNode } from 'react';
import type { SceneDensity } from '../model/scene';

export function SceneViewport({ density, children }: { density: SceneDensity; children: ReactNode }) {
  return (
    <div className={`scene-viewport density-${density}`} aria-label={`Pixel office viewport, ${density} density`}>
      {children}
    </div>
  );
}
