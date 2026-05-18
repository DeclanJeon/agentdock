# tmux Directory Structure

## Recommended Project Structure

```txt
project-root/
├── .agents/
│   ├── ceo/
│   │   ├── inbox.md
│   │   ├── outbox.md
│   │   └── scratch.md
│   ├── pm/
│   ├── user/
│   ├── business/
│   ├── marketing/
│   ├── architecture/
│   ├── development/
│   ├── design/
│   ├── qa/
│   ├── devops/
│   └── legal-risk/
├── docs/
│   ├── prd/
│   ├── requirements/
│   │   └── {feature}/
│   │       ├── SRD.md
│   │       └── SRS.md
│   ├── architecture/
│   │   └── {feature}/
│   │       ├── SDD.md
│   │       ├── TDD.md
│   │       ├── API_SPEC.md
│   │       ├── SYSTEM_ARCHITECTURE.md
│   │       ├── FLOW_DIAGRAM.md
│   │       ├── SEQUENCE_DIAGRAM.md
│   │       └── ARCHITECTURE_TO_DEV_HANDOFF.md
│   ├── design/
│   ├── qa/
│   ├── marketing/
│   ├── business/
│   └── decisions/
├── jobs/
│   └── JOB-{YYMMDD}-{slug}/
│       ├── JOB_SPEC.md
│       ├── JOB_LOG.md
│       └── JOB_CHANGELOG.md
├── tasks/
│   ├── backlog.md
│   ├── doing.md
│   ├── blocked.md
│   ├── done.md
│   └── TASK-{YYMMDD}-{team}-{sequence}/
│       ├── TASK_BRIEF.md
│       ├── WORK_CHECKLIST.md
│       ├── TASK_LOG.md
│       ├── TASK_CHANGELOG.md
│       ├── COMPLETION_REPORT.md
│       └── HANDOFF.md
├── handoffs/
│   ├── 0001-pm-to-architecture.md
│   ├── 0002-architecture-to-dev.md
│   └── 0003-dev-to-qa.md
├── reports/
│   ├── daily/
│   └── completion/
├── scripts/
│   ├── tmux-session.sh
│   ├── run-tests.sh
│   └── agent-send.sh
└── README.md
```

## tmux Session Structure

```txt
session: product-war-room
├── window 0: ceo
│   ├── pane 0: CEO Agent
│   └── pane 1: task board watcher
├── window 1: planning
│   ├── pane 0: PM Agent
│   └── pane 1: User Voice Agent
├── window 2: business-marketing
│   ├── pane 0: Business Agent
│   └── pane 1: Marketing Agent
├── window 3: product-design
│   ├── pane 0: Design Agent
│   └── pane 1: UX Reviewer
├── window 4: architecture
│   ├── pane 0: Architect Agent
│   └── pane 1: Architecture Reviewer / Security Reviewer
├── window 5: development
│   ├── pane 0: Frontend Dev Agent
│   ├── pane 1: Backend Dev Agent
│   └── pane 2: Test Writer Agent
└── window 6: qa
    ├── pane 0: QA Agent
    └── pane 1: test runner
```

## Operating Tips

- 각 agent는 자기 `.agents/{role}/inbox.md`를 읽고 작업한다.
- 모든 task는 `tasks/TASK-*` 디렉토리에 기록을 남긴다.
- 결과는 `handoffs/`에 남긴다.
- CEO는 `tasks/*.md`, `tasks/TASK-*`, `handoffs/*.md`, `reports/`를 주기적으로 통합한다.
- 개발팀은 가능하면 `git worktree`로 브랜치를 분리한다.
- Architecture Team은 개발 handoff 전에 `ARCHITECT_TO_DEV_CONTRACT.md`를 통과해야 한다.


## v3 Operational Directories

```txt
07_JOBS/
└── JOB-YYMMDD-000/
    ├── JOB_SPEC.md
    ├── JOB_BREAKDOWN.md
    ├── TASKS/
    ├── LOGS/
    ├── HANDOFFS/
    ├── REPORTS/
    └── OUTPUTS/
08_DECISIONS/
09_HANDOFFS/
10_REPORTS/
11_ARCHIVE/
```

Each job should be self-contained. If an external reviewer opens a job folder, they should understand what was requested, who worked on it, what changed, what was completed, and what remains blocked.
