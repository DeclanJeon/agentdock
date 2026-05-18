# Example: Architecture To Dev Package

- Job ID: JOB-260517-youtube-shorts-auto-editor
- Task ID: TASK-260517-ARCH-001
- Timestamp: 26051714:32:09
- From: Architecture Team
- To: Development Team

## Original Job Composition

```txt
Job: YouTube Shorts 자동 편집 MVP 설계
Tasks:
- PRD 작성
- SRS 작성
- API SPEC 작성
- 시스템 아키텍처 작성
```

## Final Job Composition

```txt
Job: YouTube Shorts 자동 편집 MVP 설계
Tasks:
- PRD 작성
- SRD 작성
- SRS 작성
- SDD 작성
- TDD 작성
- API SPEC 작성
- SYSTEM ARCHITECTURE 작성
- FLOW DIAGRAM 작성
- SEQUENCE DIAGRAM 작성
- ARCHITECTURE_TO_DEV_HANDOFF 작성
```

## Added Tasks

- SRD 작성: 운영/시스템 요구사항 분리가 필요함
- SDD 작성: 개발팀 구현 기준이 필요함
- TDD 작성: QA와 개발 테스트 기준이 필요함
- FLOW_DIAGRAM 작성: 사용자 흐름 정리가 필요함
- SEQUENCE_DIAGRAM 작성: 시스템 호출 순서 정리가 필요함

## Removed Tasks

- 없음

## Modified Tasks

- `API SPEC 작성` → 인증, 에러코드, request/response schema 포함으로 확장

## Handoff To Development

Development Team은 `ARCHITECTURE_TO_DEV_HANDOFF.md`의 구현 task를 기준으로 frontend/backend/test/devops 작업을 시작한다.
