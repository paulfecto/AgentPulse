# Active execution plans / 활성 실행 계획

This directory contains the active execution plans for non-trivial work.
이 디렉터리는 비사소한 작업에 대한 활성 실행 계획을 담습니다.

Protocol: / 프로토콜

- do not start non-trivial implementation without an active plan
  - 활성 계획 없이는 비사소한 구현을 시작하지 않습니다.
- create at least one real plan file in this directory for active work
  - 활성 작업에는 이 디렉터리 안에 실제 계획 파일을 최소 하나 둡니다.
- keep the plan scoped to the current task or change set
  - 계획은 현재 작업 또는 변경 범위에 맞게 유지합니다.
- archive or remove stale plans when the work is no longer active
  - 더 이상 활성 작업이 아니면 오래된 계획을 정리합니다.
- use the global execution-plan template from `agentOS` as the default
  shape
  - 기본 형식은 `agentOS`의 실행 계획 템플릿을 사용합니다.
- before claiming completion, fill the validation evidence, review evidence,
  TDD evidence, and completion status sections in the active plan
  - 완료를 주장하기 전에 validation evidence, TDD evidence, review evidence, completion status를 채웁니다.

Minimum plan expectations: / 최소 계획 항목

- target behavior / 목표 동작
- owning layer / 소유 레이어
- planned write set / 변경 예정 범위
- acceptance criteria / 완료 기준
- TDD plan / TDD 계획
- validation matrix / 검증 매트릭스
- deploy or runtime impact / 배포 또는 런타임 영향
- review risks or open questions / 리뷰 위험 또는 열린 질문
