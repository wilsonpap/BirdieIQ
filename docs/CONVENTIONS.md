# BirdieIQ — Project Conventions

## Checkpoints

- Work [PHASE1_WORKPLAN.md](./PHASE1_WORKPLAN.md) checkpoints **in order** (CP-0 → CP-1 → …).
- Do not start the next checkpoint until **exit criteria** for the current one are met.
- Each checkpoint gets a journal file: `docs/journal/CP-XX.md` (copy from `_TEMPLATE.md`).

## Documentation

| Path | Use |
|------|-----|
| `docs/journal/` | What was done, when, blockers, commits |
| `docs/specs/` | Deliverable specs (01–05) |
| `docs/diagrams/` | Mermaid / architecture visuals |
| `docs/DECISIONS.md` | ADRs — one entry per major technical choice |

## Phase 1 build gate

**No application feature code** until CP-1 through CP-5 are complete and signed off, unless a time-boxed spike is noted in the active journal.

Spikes must include: hypothesis, time limit, and whether the spike code will be thrown away.

## Git

- **Branch:** `main` for integration; feature branches `cp-N-short-description` optional for large checkpoints.
- **Commits:** Reference checkpoint in message when possible, e.g. `docs(cp-1): data access feasibility report`.
- **Tags:** Release-style tags at end of build weeks: `v0.1-foundation`, etc. (see workplan).

## Commit authorship (local Git)

This repo uses Git 2.25. If `git commit` fails with `unknown option trailer` in Cursor’s terminal, use:

```powershell
& "C:\Program Files\Git\mingw64\bin\git.exe" commit -m "your message"
```

Or refresh PATH after installing tools and open a **new** terminal.
