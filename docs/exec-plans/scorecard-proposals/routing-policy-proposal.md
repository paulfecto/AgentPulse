# Routing policy proposal

- generated at / 생성 시각: `2026-05-16T03:20:27Z`
- improvement mode / 개선 모드: `live-orchestrated`
- current strategy / 현재 전략: `orchestrator-first`
- minimum fresh sample size / 최소 신선 샘플 수: `3`
- max scorecard age days / 최대 scorecard 허용 일수: `30`

## Recommendation

- no routing-policy change is proposed yet because the scorecards are still below the minimum fresh sample threshold

## Scorecard eligibility snapshot

| task class | lane | sample size | age (days) | eligible |
| --- | --- | ---: | ---: | --- |
| none | none | 0 | 0 | no |

## Eval attribution snapshot

- ignored because eval mode is disabled or no fresh scoreboard is available

## Required human review

- benchmark any proposed change on held-out tasks before editing `config/routing_policy.json`
- keep `default_strategy = "orchestrator-first"` unless judged evidence proves a better orchestrator policy

