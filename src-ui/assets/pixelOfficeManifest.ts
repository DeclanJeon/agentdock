import type { RoleArchetype, SceneRoleState, ZoneId } from '../model/scene';

export interface AssetRef { kind: 'css' | 'gif'; ref: string; }
export interface PixelOfficeAssetManifest {
  rooms: Record<ZoneId, AssetRef>;
  stations: Record<RoleArchetype, AssetRef>;
  status: Record<SceneRoleState | 'read-only' | 'final-ready' | 'final-blocked', AssetRef>;
  fallback: AssetRef;
}

const css = (ref: string): AssetRef => ({ kind: 'css', ref });

export const pixelOfficeManifest: PixelOfficeAssetManifest = {
  rooms: {
    command: css('zone-tone-gold'), mission: css('zone-tone-cyan'), build: css('zone-tone-blue'), design: css('zone-tone-violet'), qa: css('zone-tone-mint'), report: css('zone-tone-green'), blocker: css('zone-tone-red'), bench: css('zone-tone-lounge'), utility: css('zone-tone-steel'),
  },
  stations: {
    orchestrator: css('station-command'), product: css('station-product'), ux: css('station-ux'), developer: css('station-developer'), architect: css('station-architect'), qa: css('station-qa'), delivery: css('station-delivery'), generic: css('station-generic'),
  },
  status: {
    working: css('state-working'), reported: css('state-reported'), 'report-needed': css('state-report-needed'), blocked: css('state-blocked'), offline: css('state-offline'), bench: css('state-bench'), assigned: css('state-assigned'), unknown: css('state-unknown'), 'read-only': css('state-read-only'), 'final-ready': css('state-final-ready'), 'final-blocked': css('state-final-blocked'),
  },
  fallback: css('pixel-office-fallback'),
};
