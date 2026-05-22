import type { ReactNode } from 'react';

export function SceneLayer({ name, children }: { name: string; children: ReactNode }) {
  return <div className={`scene-layer scene-layer-${name}`}>{children}</div>;
}
