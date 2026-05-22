# BirdieIQ

AI golf coach MVP — analyze rounds, find scoring leaks, and generate practice plans.

## Documentation

- **[Project status](docs/PROJECT_STATUS.md)** — **start here** after a break (current checkpoint, ADRs, open items)
- **[PRD](docs/PRD.md)** — product vision and Phase 1 objectives
- **[Agent instructions](AGENTS.md)** — for Cursor / AI handoff
- **[Phase 1 Workplan](docs/PHASE1_WORKPLAN.md)** — checkpoints, procedures, 8-week build plan
- **[Conventions](docs/CONVENTIONS.md)** — checkpoint order, build gate, git notes
- **[Decision log](docs/DECISIONS.md)** — ADRs
- **[Spec index](docs/specs/00-INDEX.md)** — deliverables per checkpoint
- **[Journals](docs/journal/)** — [CP-00](docs/journal/CP-00.md) … [CP-03](docs/journal/CP-03.md) complete
- **[Data access report](docs/specs/01-data-access-feasibility.md)** — CP-1 feasibility (18Birdies + fallbacks)
- **[Architecture spec](docs/specs/02-architecture.md)** — CP-2 (Vercel + FastAPI + Neon)
- **[Journal template](docs/journal/_TEMPLATE.md)** — copy for each new checkpoint

## Get started

### Clone the repo

```bash
git clone https://github.com/wilsonpap/BirdieIQ.git
cd BirdieIQ
```

### Resume in Cursor (new chat)

After opening this project, start a **new Agent chat** and paste:

```text
Resume BirdieIQ — read PROJECT_STATUS.md
```

That loads the current checkpoint, ADRs, and open items. To continue the next task:

```text
start CP-6
```

**Current progress:** CP-0–5 complete (design gate) → **next: CP-6** (monorepo scaffold). Details: [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md).

## License

TBD
