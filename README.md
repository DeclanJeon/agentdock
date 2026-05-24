# 🤖 AgentDock

<p align="center">
  <strong>CLI-only Hermes/tmux workrooms for local multi-agent jobs.</strong><br>
  <sub>터미널 하나로 CEO-주도 멀티에이전트 작업실을 구성하세요.</sub>
</p>

<p align="center">
  <a href="https://github.com/DeclanJeon/agentdock/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/DeclanJeon/agentdock/ci.yml?branch=main&label=ci&logo=github"></a>
  <a href="https://github.com/DeclanJeon/agentdock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/DeclanJeon/agentdock?label=release&logo=github"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.3.2-0f766e">
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Hermes%20Agent-111827">
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash%204%2B-4EAA25?logo=gnubash&logoColor=white">
  <img alt="tmux" src="https://img.shields.io/badge/orchestration-tmux-1f2937">
  <img alt="Lines" src="https://img.shields.io/badge/code-5891%20lines%20Bash-333">
</p>

---

## 📖 Overview

Status: Version `0.3.2` is the current CLI-only Hermes/tmux release.

AgentDock는 프로젝트 디렉토리를 **로컬 멀티에이전트 작업실**로 변환합니다. 데스크톱 앱이나 브라우저 UI 없이, 순수 터미널 CLI와 tmux만으로 작동합니다.

핵심 아이디어: 하나의 명령어로 CEO 에이전트가 작업을 분류하고, 필요할 때만 최소한의 팀을 구성하여 작업을 실행합니다.

```bash
adock job "작업내용"
```

작업이 끝난 뒤에도 CEO Hermes tmux pane은 살아있습니다. 그 pane에 사용자가 새 작업을 직접 주면, AgentDock는 `agentdock intake` 경로로 다시 접수하여 기존 `adock job`과 같은 solo/team 분류 로직을 사용합니다. 팀이 필요하면 Hermes 내부 subagent가 아니라 `agentdock recruit`로 tmux 역할을 구성합니다.

---

## 🧠 작동 원리 (How It Works)

### 전체 흐름

```
 User                     CEO Hermes                    Worker Hermes
  │                          │                              │
  ├─ adock job "버그 수정" ──→│                              │
  │  또는 agentdock intake    │                              │
  │                          ├─ 분류 (solo? team?)          │
  │                          ├─ ORCHESTRATION.json 생성     │
  │                          ├─ 작업카드 발행 ──────────────→│
  │                          │                              ├─ 작업 실행
  │                          │                              ├─ agentdock job report
  │                          │←─ 역할 보고서 수신 ──────────┤
  │                          ├─ QA 게이트 검증               │
  │                          ├─ adock job finish            │
  │                          ├─ 최종 보고서 작성             │
  │                          ├─ 완료 워커 pane 종료          │
  │  ←── 최종 보고서 ────────┤                              │
```

### 📊 적응형 오케스트레이션 (Adaptive Orchestration)

CEO는 모든 작업을 4가지 모드 중 하나로 자동 분류합니다:

| 모드 | 언제 사용? | 팀 규모 | QA 필요? | 작업 예시 |
|:---:|---|---|:---:|---|
| 🟢 `solo_direct` | 단순/읽기전용/문서 작업 | CEO 혼자 (0명) | ❌ | "README 업데이트해줘" |
| 🔵 `assisted_single_lane` | 구현 레인 1개로 충분 | 최대 1명 | 선택 | "설정 파일 추가해줘" |
| 🟡 `standard_team` | 다중 역량/사용자 영향 | 최대 4-5명 | ✅ | "백엔드 API 리팩토링" |
| 🔴 `critical_review` | 보안/권한/배포 위험 | 최대 5명 | ✅ + Security | "프로덕션 배포 스크립트 수정" |

**분류 로직** — CEO는 한글 + 영어 키워드 패턴 매칭으로 의도를 감지합니다:

```
UI · UX · backend · QA · docs · security · devops · architecture · research
```

그리고 **위험 신호**(production, destructive, delete, install, dependency)를 감지하여 critical 모드로 상향 조정합니다.

### 📁 상태 레이아웃 (State Layout)

모든 조정 상태는 프로젝트 내 파일시스템에 저장됩니다 — 데이터베이스나 메시지 큐 없이 순수 파일 기반:

```
project/
├── .agentdock/              ← 런타임 설정
│   ├── config.runtime       ← 역할별 CLI/부트 설정
│   ├── config.yml           ← 자동 생성 YAML 스냅샷
│   ├── prompts/<role>.md    ← 역할 프롬프트
│   ├── generated/boot-*.md  ← 부트 프롬프트 (해시 캐싱)
│   └── state/panes.env      ← tmux pane ID 매핑
│
└── .agent-work/             ← 조정 작업공간
    ├── 07_JOBS/JOB-*/       ← 활성/완료 작업
    ├── 07_JOBS/CURRENT.md   ← 미완료 활성 작업 포인터
    ├── 07_JOBS/LAST_FINISHED.md ← 최근 완료 작업/최종보고서 포인터
    │   ├── README.md        ← 작업 요청서
    │   ├── ORCHESTRATION.json ← 오케스트레이션 정책
    │   ├── TEAM.md          ← 팀 구성 계획
    │   ├── LIFECYCLE.md     ← 작업 생명주기 로그
    │   ├── QA.md            ← QA 게이트
    │   ├── TASKS/<role>.md  ← 역할별 작업 카드
    │   ├── REPORTS/*.md     ← 역할 보고서
    │   ├── TFTS/*.md        ← 임시 대응팀 기록
    │   ├── MEETINGS/*.md    ← 회의 및 결정 기록
    │   └── ACTIONS.md       ← 감사 로그
    ├── 12_INBOX/<role>/     ← 역할별 내구성 메시지함
    ├── 15_STATUS/<role>.json ← 실시간 역할 상태
    └── 14_SHARED_CONTEXT/   ← 공유 브로드캐스트/컨텍스트
```

---

## 🚀 설치 (Install)

```bash
git clone https://github.com/DeclanJeon/agentdock.git
cd agentdock
./install.sh --prefix "$HOME/.local"
adock doctor
```

`./install.sh`는 자동으로 Hermes Agent를 감지하고, 없으면 GitHub에서 설치합니다. 건너뛰려면:

```bash
./install.sh --skip-hermes --prefix "$HOME/.local"
```

**의존성**: Bash 4.0+, tmux, git, python3, Hermes Agent

---

## 📋 명령어 (Commands)

### 🏗️ 프로젝트 설정

| 명령어 | 설명 |
|---|---|
| `adock init` | `.agentdock` + `.agent-work` 초기화 |
| `adock setup` | tmux, Hermes 등 런타임 의존성 설치 |
| `adock doctor [--json]` | 시스템 도구, Hermes, 프로젝트 상태 진단 |

### 🎯 작업 (Job)

| 명령어 | 설명 |
|---|---|
| `adock job "작업내용"` | CEO 주도 작업 시작 (분류 → 팀구성 → 실행 → 보고) |
| `agentdock intake --from <role> --request "..."` | 살아있는 Hermes pane에서 직접 받은 새 작업을 CEO 주도 job으로 재접수 |
| `adock-delegate --from <role> --request "..."` | `agentdock intake` 호환 alias |
| `adock job report --from <role> --summary "..."` | 역할 보고서 제출 |
| `adock job finish --summary "..."` | 작업 완료: 보고서 집계 + 워커 pane 정리 |
| `adock job tick [--json] [--apply]` | 작업 상태 점검 및 다음 액션 제안 |
| `adock job tft create \| close ...` | 임시 대응팀 (TFT) 생성/종료 |
| `adock job meeting start \| conclude ...` | 공식 회의 기록 및 결정 문서화 |

### 👥 팀 (Team)

| 명령어 | 설명 |
|---|---|
| `adock recruit <role> --template <id>` | 새 tmux/Hermes 역할 시작 |
| `adock team` | 구성된 역할 목록 표시 |
| `adock send <role> "..."` | 역할에게 내구성 메시지 전송 |
| `adock broadcast "..."` | 모든 역할에 공유 메시지 전송 |
| `adock inbox [role]` | 역할별 메시지함 조회 |
| `adock watch <role>` | 역할 메시지함 실시간 폴링 |

### 🔍 진단 (Diagnostics)

| 명령어 | 설명 |
|---|---|
| `adock workspace snapshot --json` | 읽기 전용 작업공간 상태 JSON |
| `adock workspace export --out <file>` | 정적 HTML 상태 보고서 |
| `adock workspace model [set] --json` | Hermes 모델 설정 조회/변경 |
| `adock status set --role <id> --state ...` | 역할 실시간 상태 업데이트 |
| `adock report [--json \| --fast]` | 프로젝트 상태 요약 |

### 🌲 작업트리 (Worktree)

| 명령어 | 설명 |
|---|---|
| `adock worktree init` | 역할별 git worktree 모드 활성화 |
| `adock worktree create --role <id>` | 역할 전용 git worktree 생성 |
| `adock worktree merge --role <id>` | worktree 변경사항 병합 (충돌 사전 감지) |
| `adock worktree status [--role <id>]` | worktree 상태 확인 |

---

## 🎭 역할 템플릿 (Role Templates)

AgentDock는 두 가지 역할 템플릿 소스를 제공합니다:

### BMAD Method (6개 역할)

| 템플릿 ID | 역할 | 담당 |
|---|---|---|
| `bmad-analyst` | Analyst (Mary) | 조사, 브레인스토밍, 시장/기술 리서치 |
| `bmad-pm` | Product Manager (John) | PRD 작성, 에픽/스토리, 구현 준비 |
| `bmad-architect` | Architect (Winston) | 아키텍처 설계, 기술 방향 |
| `bmad-agent-dev` | Developer (Amelia) | 개발, 코드 리뷰, QA 테스트 생성 |
| `bmad-ux-designer` | UX Designer (Sally) | UX/UI 설계, 인터랙션 기획 |
| `bmad-tech-writer` | Technical Writer (Paige) | 문서화, 다이어그램, 표준 |

### AgentDock 보충 (5개 역할)

| 템플릿 ID | 역할 | 담당 |
|---|---|---|
| `agentdock-ceo` | CEO Orchestrator | 작업 접수, 팀 설계, 위임, 최종 보고 |
| `agentdock-cto` | CTO / Technical Director | 기술 전략, 아키텍처 검토, 구현 순서 |
| `agentdock-marketing` | Marketing Strategist | 포지셔닝, 메시징, 출시 계획 |
| `agentdock-planner` | Planning Manager | 로드맵, 마일스톤, 의존성 추적 |
| `agentdock-qa` | QA / Quality Engineer | 테스트 전략, 회귀, 버그 재현, 릴리스 준비 |

```bash
# BMAD 템플릿 동기화
adock roles sync bmad --yes

# 템플릿 목록 확인
adock roles list

# 작업에 맞는 템플릿 추천
adock roles recommend "보안 취약점 분석하고 수정해줘"
```

---

## 🔄 작업 생명주기 (Job Lifecycle)

```
planning → recruiting → executing → verifying → complete
```

1. **planning** — CEO가 요청을 분석하고 ORCHESTRATION.json 생성
2. **recruiting** — 필요시 `agentdock recruit`로 tmux/Hermes 역할 시작
3. **executing** — 작업 카드 실행 (역할별 독립 레인)
4. **verifying** — QA 게이트, 역할 보고서 검토, TFT 해결
5. **complete** — 최종 보고서 작성, 완료된 워커 pane 정리

완료 후에는 `CURRENT.md`가 제거되고 `LAST_FINISHED.md`에 최근 완료 job과 최종 보고서 위치가 기록됩니다. 따라서 살아있는 coordinator pane이 다음 direct request를 받더라도 완료된 job에 다시 붙지 않고 새 intake를 시작합니다. 단, 미완료 active job이 있으면 새 intake는 조용히 덮어쓰지 않고 명시적으로 거부합니다.

### 완료 게이트 (Finish Gates)

`adock job finish`는 다음 조건을 모두 만족해야 실행됩니다:

- ✅ QA 게이트 통과 (필요한 경우)
- ✅ 차단 TFT 없음
- ✅ 모든 선택된 역할의 보고서 제출 완료

---

## 🔒 보안 (Security)

- **프롬프트 인젝션 방지**: 사용자 요청은 `BEGIN_UNTRUSTED_USER_REQUEST` 블록으로 감싸져, 에이전트가 이를 신뢰 경계 밖의 데이터로 인식
- **시크릿 마스킹**: API_KEY, TOKEN, PASSWORD, sk-*, gh*_*, xox*-* 패턴 자동 감지 → [REDACTED]
- **파일 잠금**: `.agent-work/LOCKS.md`로 역할 간 파일 충돌 방지
- **심볼릭 링크 방지**: `workspace export`에서 symlink 및 상위 디렉토리 탐색 차단

---

## 🧪 테스트 (Tests)

14개 셸 기반 통합 테스트 + 50개 이상의 JSON 픽스처:

```bash
bash tests/smoke.sh                           # 기본 CLI 정상작동
bash tests/workspace_adaptive_orchestration.sh # 적응형 분류 검증
bash tests/post_finish_direct_intake.sh         # 완료 후 direct Hermes intake 검증
bash tests/workspace_qa_gate.sh                # QA 게이트 적용
bash tests/workspace_security_redaction.sh     # 시크릿 마스킹
bash tests/workspace_p05.sh                    # P0.5 지연시간 목표
```

---

## 📦 릴리스 (Release)

```bash
bash scripts/check-version.sh   # 버전 일관성 확인
bash tests/smoke.sh             # 스모크 테스트
git tag v0.3.2
git push origin v0.3.2
```

---

## 📚 문서

| 문서 | 설명 |
|---|---|
| [CHANGELOG.md](CHANGELOG.md) | 버전별 변경 이력 |
| [DESIGN.md](DESIGN.md) | 제품 경계 및 설계 원칙 |
| [docs/DEVELOPER_NOTES.md](docs/DEVELOPER_NOTES.md) | 개발자 노트 (아키텍처, 데이터 구조, 로직 상세) |
| [docs/adaptive-orchestration-design.md](docs/adaptive-orchestration-design.md) | 적응형 오케스트레이션 설계 |
| [docs/adaptive-orchestration-modes.md](docs/adaptive-orchestration-modes.md) | 오케스트레이션 모드별 동작 |
| [docs/post-finish-direct-intake-design.md](docs/post-finish-direct-intake-design.md) | 완료 후 살아있는 Hermes pane direct intake 설계 |
| [docs/post-finish-direct-intake-checklist.md](docs/post-finish-direct-intake-checklist.md) | post-finish intake 구현/검증 체크리스트 |
| [docs/post-finish-direct-intake-work-order.md](docs/post-finish-direct-intake-work-order.md) | AgentDock job 실행용 작업지시서 |

---

## 🏗️ 기술 스택

| 구성요소 | 기술 |
|---|---|
| 언어 | **Bash 4.0+** (순수 셸, 5891 lines) |
| 프로세스 관리 | **tmux** (pane 단위 에이전트 수명주기) |
| AI 런타임 | **Hermes Agent** (유일한 워커 CLI) |
| 조정 버스 | **파일시스템** (마크다운 + JSON) |
| 템플릿 소스 | **BMAD Method** + AgentDock 보충 |
| JSON/YAML 처리 | **Python 3** 인라인 스크립트 |

---

## ⚡ v0.3.2 변경사항

- 🗑️ 데스크톱 앱 전체 제거 (React, Vite, Tauri, 캐릭터 에셋)
- 🎯 CLI-only: `adock job "..."` 중심으로 단순화
- 📦 설치/릴리스 아티팩트 최소화 (CLI + 어댑터 + 역할 + 테스트만)
- 🏗️ 작업공간 HTML 익스포트를 경량 CLI 진단으로 대체
- 🔁 완료 후 살아있는 CEO Hermes pane direct request를 `agentdock intake`로 재접수
- 🧭 `CURRENT.md`는 미완료 작업 전용, `LAST_FINISHED.md`는 최근 완료 작업 기록으로 분리
- 🧪 post-finish direct intake 회귀 테스트 추가

---

<p align="center">
  <sub>AgentDock · v0.3.2 · CLI-only · Hermes/tmux local multi-agent orchestration</sub>
</p>
