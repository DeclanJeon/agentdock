# Design

## Source of truth
- Status: Active
- Last refreshed: 2026-05-23
- Primary product surfaces: Tauri/Vite Visual Office workspace in `src-ui/App.tsx`, `src-ui/scene/*`, `src-ui/components/*`, and `src-ui/styles.css`.
- Evidence reviewed: `docs/visual-workspace-reference-ui-design.md`, `src-ui/App.tsx`, `src-ui/components/TopHud.tsx`, `src-ui/components/CeoTaskComposer.tsx`, `src-ui/components/TeamActivityPanel.tsx`, `src-ui/components/FacilitationTimeline.tsx`, `src-ui/scene/OfficeScene.tsx`, `src-ui/scene/AgentSprite.tsx`, `src-ui/scene/DenseRoleNavigator.tsx`, `src-ui/scene/SceneInspector.tsx`, `src-ui/model/scene.ts`, `src-tauri/src/lib.rs`, `src-ui/styles.css`.

## Brand
- Personality: operational, trustworthy, compact, slightly playful through the pixel-office metaphor.
- Trust signals: persistent read-only language, visible write-bridge state, snapshot mode, report/final readiness counts, local runtime state.
- Avoid: decorative clutter, mutation-looking controls, raw JSON/object text, oversized panels that compete with the office map.

## Product goals
- Goals: make the next user action, job status, live sync state, team work, reports, blockers, final readiness, selected role, and read-only boundary answerable within 10 seconds.
- Non-goals: full task editing, arbitrary shell execution, recruiting/sending/finish controls, release-proof claims without native evidence.
- Success signals: one clear stage, one control sidecar, one inspector, no horizontal page scroll at desktop widths, buttons grouped by purpose.

## Personas and jobs
- Primary personas: local AgentDock operator, CEO/orchestrator reviewer, QA/release reviewer.
- User jobs: submit a CEO-led task, see whether the workspace is live-syncing, understand which teams are working, jump to a role, understand missing reports/blockers/final gate, manually refresh only when needed.
- Key contexts of use: desktop-first local Tauri app, read-only snapshot review, dense multi-agent sessions.

## Information architecture
- Primary navigation: compact Visual Office rail for workspace orientation.
- Core routes/screens: single workspace screen with top status bar, left operations sidecar, center office map, right scene inspector, bottom trust bar.
- Content hierarchy: 1) always-visible CEO command, 2) live sync and quick guide, 3) readable team activity, 4) office map/final state, 5) selected-role inspector, 6) audit/intervention details.

## Design principles
- Principle 1: Scene first — the office map and selected inspector are the primary interface, not a pile of control cards.
- Principle 2: Controls by risk — job creation, refresh/view switching, and disabled interventions are visually separated.
- Tradeoffs: sidecar reduces map width on desktop, but makes command/timeline/buttons predictable and keeps the center stage clean.

## Visual language
- Color: dark navy console base, cyan focus/interactive accents, green for ready/reported, amber for pending/missing, red for blockers.
- Typography: compact system/pixel-adjacent sans-serif with uppercase micro-labels only for section eyebrows.
- Spacing/layout rhythm: 8px shell gap, 12px card radius/padding, compact rail buttons, no decorative gaps larger than the content group needs.
- Shape/radius/elevation: flat console cards with subtle borders; stage/inspector/sidecar use consistent rounded panels.
- Motion: characters should visibly work through role-specific sprite motion, tool overlays, signals, and monitor pulses; all repeated motion must respect reduced motion.
- Imagery/iconography: pixel-office sprites remain secondary to labels and status chips.

## Components
- Existing components to reuse: `TopHud`, `OfficeScene`, `DenseRoleNavigator`, `SceneInspector`, `CeoTaskComposer`, `FacilitationTimeline`, `ActionAuditPanel`, `InterventionPanel`.
- New/changed components: `App` owns `LiveRefreshPanel` and `OperatorGuidePanel`; `TeamActivityPanel` rows are role-jump controls; `AgentSprite` exposes work-tool/motion overlays while preserving GIF character assets.
- Variants and states: live/stale/demo/error app mode, Visual Office/Classic view switch, ready/pending/blocked/report-needed status chips, disabled unsafe controls.
- Token/component ownership: `src-ui/styles.css` owns layout tokens and responsive behavior.

## Accessibility
- Target standard: keyboard-accessible status console with visible focus states and text labels for color states.
- Keyboard/focus behavior: focus reaches CEO request, refresh/view switch, nav rail, role stations, report slots, blocker/final surfaces, inspector tabs, details panels.
- Contrast/readability: dark surfaces with high-contrast cyan/green/amber/red labels; avoid color-only semantics.
- Screen-reader semantics: preserve `aria-label`, `role=status`, tablist/tab, section landmarks.
- Reduced motion and sensory considerations: existing `prefers-reduced-motion` disables repeated animations.

## Responsive behavior
- Supported breakpoints/devices: desktop-first, graceful tablet/mobile stacking.
- Layout adaptations: desktop uses sidecar + stage; medium widths stack sidecar above stage; small widths stack nav/map/inspector/trust.
- Touch/hover differences: buttons retain labels and minimum touch-friendly heights in stacked layouts.

## Interaction states
- Loading: refresh button shows `Refreshing…` and disables duplicate refresh; live sync explains whether updates are event-driven, fallback, or unavailable.
- Empty: no job/no report/no blocker copy remains explicit.
- Error: `ErrorStrip` shows stale/error snapshot fallback.
- Success: green reported/final-ready states and CEO create result.
- Disabled: unsafe intervention buttons stay disabled with explanatory copy.
- Offline/slow network, if applicable: stale/error mode appears in top status and error strip; live watch failures fall back to low-frequency backup refresh.

## Content voice
- Tone: concise Korean operator copy with English product/status terms where already established.
- Terminology: `Visual Office`, `Snapshot`, `Read-only`, `write bridge disabled`, `CEO 작업 요청`, `Final Gate`, `Report Desk`.
- Microcopy rules: every action button says what happens; every disabled area explains why it is unavailable.

## Implementation constraints
- Framework/styling system: React 19 + Vite + Tauri; plain CSS in `src-ui/styles.css`.
- Design-token constraints: no new dependency or design-system package; extend existing classes and status colors.
- Performance constraints: keep model derivation pure; avoid direct Tauri imports outside `App` invoke boundary; prefer backend file-change events plus debounced refresh over frequent snapshot polling.
- Compatibility constraints: preserve Classic view fallback and snapshot schema support.
- Test/screenshot expectations: run `npm run build`; visual screenshot evidence is separate release evidence if needed.

## Open questions
- [ ] Whether to remove Classic mode entirely once Visual Office has sufficient screenshot/regression evidence / owner: product / impact: simplifies layout.
- [ ] Whether sidecar should be collapsible in future dense sessions / owner: UX / impact: gives more map width on small laptops.
