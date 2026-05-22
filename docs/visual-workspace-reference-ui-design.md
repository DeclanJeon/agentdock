# Visual Workspace Reference UI Implementation Design

Job: JOB-260522040235176748
Reference image: `docs/reference_ui_workspace.png`
Status: implementation design baseline

## 1. Direction change

The previous generated concept is too complex for implementation and daily operation. The new target is the simpler, more legible UI in `docs/reference_ui_workspace.png`.

The core design rule is:

> Keep the office visual metaphor, but make it operate like a clear read-only status console.

This means fewer decorative rooms, clearer zones, stronger hierarchy, and one obvious right-side inspector. Dense detail should appear only where it helps answer operational questions.

## 2. UX principles to preserve from the reference

1. One glance status bar
   - App title: `AgentDock Visual Office`.
   - Explicit read-only snapshot label.
   - `write bridge disabled` lock badge.
   - Job id, lifecycle, final readiness, report count, local time/session status.

2. Left navigation rail
   - Stable vertical sections: Office, Roles, Tasks, Reports, Alerts, Files, Settings.
   - Bottom local runtime status: Hermes, tmux, session id, pid.
   - Navigation is visual orientation only unless implemented safely as read-only view switching.

3. Central office map
   - Simple room grid with clear labels and strong boundaries:
     - Command Office
     - Mission Board
     - Product Bay
     - Engineering Bay
     - Quality Bay
     - Delivery Bay
     - Report Desk
     - Blocker Desk
     - Security Nook
     - Final Gate
   - Rooms are visually rich but not overloaded.
   - Each active role gets one station/card-like in-world label with state badge.

4. Right inspector
   - Selected role detail panel with avatar, role, report state, room.
   - Tabs: Tasks, Details, Files, Logs.
   - Role summary, latest report, office status.
   - This keeps detailed information out of the map and prevents label clutter.

5. Bottom trust/status bar
   - Hermes running, tmux active, session, project path, workspace read-only, snapshot timestamp, mode.
   - This is the trust layer for source/freshness/read-only state.

6. Status surfaces
   - Report Desk shows report slots and `Reports n/N`.
   - Blocker Desk shows `No active blockers` or concise blocker cards.
   - Security Nook shows lock and `Read-only snapshot / write bridge disabled`.
   - Final Gate is large and obvious: ready/locked/blocked.

## 3. Layout contract

Target viewport: desktop-first, 16:9 and 16:10.

```
+--------------------------------------------------------------------------------+
| Top status bar: title | read-only | job | lifecycle | final | reports | time   |
+----+-------------------------------------------------------------+-------------+
|Nav |                                                             | Inspector   |
|Rail|                  Visual Office Map                          | selected    |
|    |  room grid + role stations + report/blocker/final surfaces  | role/status |
|    |                                                             | details     |
+----+-------------------------------------------------------------+-------------+
| Bottom trust/status bar: Hermes | tmux | session | path | snapshot | mode       |
+--------------------------------------------------------------------------------+
```

Recommended proportions:
- Left rail: 72-88px collapsed icon rail, expandable later.
- Right inspector: 300-360px.
- Top bar: 52-64px.
- Bottom bar: 48-64px.
- Center map fills remaining space and must avoid horizontal scroll at 1440px.

## 4. Information architecture

### Top status bar

Required fields:
- product name
- read-only snapshot
- write bridge disabled
- active job id or empty state
- lifecycle
- final readiness
- reports complete/required
- current local time or snapshot time
- local/demo/stale/error source mode

Rules:
- Never show mutation-looking controls.
- If data is stale/demo/error, top bar must say so clearly.
- Final-ready cannot be green unless required reports and blockers allow it.

### Office map rooms

Command Office:
- orchestrator station
- report badge
- final decision context

Mission Board:
- job id, lifecycle, selected role count, local session, Hermes/tmux state

Product Bay:
- product-manager and ux-designer stations
- roadmap/design wall props

Engineering Bay:
- developer and system-architect stations
- code/architecture/test props

Quality Bay:
- agentdock-qa station
- test board and screenshot wall props

Delivery Bay:
- delivery-planner station
- milestone calendar

Report Desk:
- one slot per selected role
- missing slots amber, reported slots green
- concise label: `Reports n/N`

Blocker Desk:
- all clear or concise blocker cards
- no raw dict/JSON/object strings

Security Nook:
- lock, camera/server props
- explicit read-only/write bridge disabled copy

Final Gate:
- large status surface: ready/locked/blocked
- concise reason if not ready

### Right inspector

Default selection:
- selected role if user clicked/focused station
- orchestrator or most urgent role otherwise

Required panels:
- selected role header: avatar, role id, report state, room
- tabs: tasks, details, files, logs
- task list: title, id, state badge
- role summary: task counts, reports, last report time
- latest report card
- office status summary: lifecycle/final/reports/blockers

## 5. Data/model requirements

Keep `SceneModel` pure and snapshot-derived.

Add or preserve derived fields only:
- `sourceMode`: live | stale | demo | error
- `readOnly`: true
- `writeBridgeDisabled`: true
- `selectedRoleId`
- per-role room assignment
- per-role report state: reported | report-needed | bench | offline
- per-role task summary
- per-role urgency/activity state
- report slot model
- blocker summary model
- final readiness model
- snapshot timestamp/freshness

Forbidden:
- scene/model layer importing Tauri directly
- recruit/send/report/finish/edit/delete/shell/control bridge
- raw secrets or unredacted paths/tokens
- non-additive snapshot schema breakage

## 6. Component implementation map

Likely files:
- `src-ui/App.tsx`: keep centralized snapshot invoke and mode switch.
- `src-ui/model/scene.ts`: derive simplified visual-office model.
- `src-ui/scene/OfficeScene.tsx`: top-level layout shell: top bar, nav rail, map, inspector, bottom bar.
- `src-ui/scene/OfficeZone.tsx`: reusable room/station rendering.
- `src-ui/scene/MissionBoard.tsx`: simplified mission board.
- `src-ui/scene/ReportDeskScene.tsx`: report slots.
- `src-ui/scene/BlockerDeskScene.tsx`: friendly blockers.
- `src-ui/scene/FinalGateScene.tsx`: final readiness.
- `src-ui/scene/DenseRoleNavigator.tsx`: either simplified into Roles view/rail or retained as compact dense mode.
- `src-ui/components/PixelOffice.tsx`: preserve classic/fallback if still used.
- CSS files for layout, room grid, focus, reduced motion.

## 7. Accessibility requirements

- Keyboard focus must reach nav rail, role stations, report slots, blocker desk, final gate, inspector tabs, and dense controls.
- Visible focus ring must be obvious on dark UI.
- Each station accessible name should include role, room, selected/bench state, report state, blocker state.
- Use icon + label + shape, not color alone.
- `prefers-reduced-motion` disables repeated animation while preserving status via static symbols.

## 8. Evidence and release requirements

This design is not release evidence by itself. Release requires:
- native Tauri screenshot pack populated from real app
- dense 20/50 evidence if dense mode remains a claim
- keyboard/focus/reduced-motion screenshots
- no-write/security/redaction gates
- package/build/full regression after final code change
- QA final GO

## 9. Acceptance bar

M5 UI implementation is acceptable when:
- the app visually matches the simpler reference structure
- status is answerable in 10 seconds
- map text no longer clutters the scene
- right inspector carries detail instead of central map overload
- read-only/write-disabled posture is unmistakable
- report/blocker/final state is clear without dev tools

This design document alone is not M6/M7 release evidence. M6/M7 wording is allowed only when the current job's primary native evidence manifest has `releaseProof=true`, required screenshots are present, and the final QA release matrix explicitly passes.

For the 2026-05-22 release-cleanup job, the controlling evidence is recorded under `.agent-work/07_JOBS/JOB-260522142505456533/OUTPUTS/`.
