# BirdieIQ — Agent instructions

Instructions for AI agents (Cursor, etc.) resuming work on this repository.

## First read (in order)

1. [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md) — **current checkpoint and handoff**
2. [docs/PRD.md](docs/PRD.md) — product vision and objectives
3. [docs/PHASE1_WORKPLAN.md](docs/PHASE1_WORKPLAN.md) — procedures for the active CP-* section
4. [docs/DECISIONS.md](docs/DECISIONS.md) — accepted ADRs; do not contradict without new ADR
5. Active journal: `docs/journal/CP-XX.md` for the checkpoint in progress

Cursor rules in `.cursor/rules/` enforce this read order (`alwaysApply: true`).

## Project summary

- **Product:** Golf analytics MVP — import rounds, compute metrics, rules-based insights and practice plans.
- **Data:** No 18Birdies API. CSV import + manual entry ([ADR-001](docs/DECISIONS.md)).
- **MVP auth/billing:** None. Single seeded user via `BIRDIEIQ_DEFAULT_USER_ID` ([ADR-007](docs/DECISIONS.md)).
- **Stack:** Next.js BFF (Vercel) + FastAPI analytics (Railway) + Postgres (Neon).
- **Code:** Not scaffolded yet. Design checkpoints CP-0–2 done; **next is CP-3**.

## Rules

- Work checkpoints **in order** (see [CONVENTIONS.md](docs/CONVENTIONS.md)).
- **No application code** until CP-1 through CP-5 specs are complete (unless user explicitly overrides).
- Each checkpoint: complete procedures → update spec → fill journal → meet exit criteria.
- Use journal task format: Recommendation / Why / Alternatives / Risks / Next action.
- **Minimize scope** — only change what the checkpoint requires.
- **Do not commit** unless the user asks.
- On Windows Git 2.25 in Cursor: prefer `C:\Program Files\Git\mingw64\bin\git.exe` for commits if `--trailer` errors occur.

## Resume commands

| User says | Agent does |
|-----------|------------|
| `start CP-3` | Data model: ERD, SQL migration, update `03-data-model.md`, journal CP-03 |
| `start CP-4` | Metrics spec + fixtures |
| `start CP-5` | Rules engine + 20 rules |
| `start CP-6` | Monorepo scaffold per architecture spec |

## Key paths

```
docs/PROJECT_STATUS.md     ← handoff
docs/PRD.md                ← product vision
docs/PHASE1_WORKPLAN.md    ← master plan
.cursor/rules/             ← Cursor always-apply handoff rule
docs/specs/                ← deliverables 01–05
docs/journal/              ← per-checkpoint logs
docs/DECISIONS.md          ← ADRs
db/migrations/             ← (created CP-3)
apps/web/                  ← (created CP-6)
services/analytics/        ← (created CP-6)
```

## Owner

Wilson Papilla — `wilson.pap@gmail.com` · GitHub `wilsonpap`
