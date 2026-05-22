# BirdieIQ — Project Status (handoff)

**Last updated:** 2026-05-22  
**Repo:** https://github.com/wilsonpap/BirdieIQ  
**Phase:** Phase 1 design — pre-code scaffold

> **Start here** after clearing context. Read this file, then [PHASE1_WORKPLAN.md](./PHASE1_WORKPLAN.md) for the active checkpoint.

---

## Current state (one paragraph)

BirdieIQ is a golf analytics MVP (AI coach from round data). **Design checkpoints CP-0 through CP-2 are complete.** CP-3 (data model) is **next**. There is **no application code yet** — only docs, ADRs, journals, and a CSV import example. **18Birdies has no API** — MVP uses CSV import + manual entry. **Clerk and Stripe are deferred** until after core MVP ([ADR-007](./DECISIONS.md)).

---

## Checkpoint progress

| CP | Name | Status | Journal |
|----|------|--------|---------|
| CP-0 | Doc setup | ✅ Complete | [CP-00](journal/CP-00.md) |
| CP-1 | Data access feasibility | ✅ Complete | [CP-01](journal/CP-01.md) |
| CP-2 | MVP architecture | ✅ Complete | [CP-02](journal/CP-02.md) |
| **CP-3** | **Data model (ERD + SQL)** | **⏭ Next** | — |
| CP-4 | Metrics engine spec | ⬜ Not started | — |
| CP-5 | Rules engine spec (20 rules) | ⬜ Not started | — |
| CP-6 | Monorepo scaffold | ⬜ Blocked until CP-3–5 | — |
| CP-7–12 | 8-week build | ⬜ Not started | — |

**Spec index:** [specs/00-INDEX.md](specs/00-INDEX.md)

---

## Accepted decisions (do not re-litigate without cause)

| ADR | Summary |
|-----|---------|
| [ADR-001](DECISIONS.md#adr-001--data-ingestion-mvp) | MVP ingestion = CSV v1 + manual wizard; no 18Birdies scrape |
| [ADR-002](DECISIONS.md#adr-002--metrics-computation-trigger) | Async `metrics_jobs` after import/save |
| [ADR-003](DECISIONS.md#adr-003--hosting) | Vercel + Railway + Neon |
| [ADR-006](DECISIONS.md#adr-006--bff-pattern) | Next.js BFF only; FastAPI internal |
| [ADR-007](DECISIONS.md#adr-007--defer-auth-and-billing-post-mvp) | **No Clerk/Stripe in MVP** — `BIRDIEIQ_DEFAULT_USER_ID` seed |

**Open:** ADR-004 (Drizzle vs Prisma) — decide at CP-6. ADR-005 (strokes gained proxy) — confirm at CP-4.

---

## Stack (MVP)

| Layer | Choice |
|-------|--------|
| Frontend + BFF | Next.js 14, Tailwind, shadcn (CP-6) |
| Analytics | FastAPI Python (CP-6) |
| DB | PostgreSQL / Neon |
| Auth | Deferred — seeded user |
| Billing | Deferred |

**Architecture:** [specs/02-architecture.md](specs/02-architecture.md) · **Diagram:** [diagrams/architecture.mmd](diagrams/architecture.mmd)

---

## Key artifacts

| File | Purpose |
|------|---------|
| [PHASE1_WORKPLAN.md](PHASE1_WORKPLAN.md) | Full checkpoint procedures + 8-week plan |
| [specs/01-data-access-feasibility.md](specs/01-data-access-feasibility.md) | 18Birdies + fallbacks |
| [specs/birdieiq-round-import-v1.example.csv](specs/birdieiq-round-import-v1.example.csv) | Import column template |
| [CONVENTIONS.md](CONVENTIONS.md) | Checkpoint order, no code until CP-5, git notes |
| [DECISIONS.md](DECISIONS.md) | ADR log |
| [PRD.md](PRD.md) | Product vision + Phase 1 objectives |

---

## Open items (human)

From [CP-01 journal](journal/CP-01.md) — **not blocking CP-3**:

- [ ] Submit 18Birdies “Download Account Data” / GDPR request — log format when received
- [ ] Email one scorecard to self — document if image vs structured
- [ ] Send partnership email (draft in CP-01 journal)

---

## How to resume development

1. Read this file.
2. Say or run: **“start CP-3”** (data model).
3. Deliverables: `docs/specs/03-data-model.md`, `docs/diagrams/erd.mmd`, `db/migrations/001_initial.sql`.
4. Journal: copy `docs/journal/_TEMPLATE.md` → `docs/journal/CP-03.md`.
5. Do **not** scaffold app code until CP-3, CP-4, CP-5 exit criteria pass ([CONVENTIONS.md](CONVENTIONS.md)).

---

## Git / environment notes

- **Branch:** `main`
- **Remote:** `origin` → `https://github.com/wilsonpap/BirdieIQ.git`
- **Git 2.25 on Windows:** If `git commit` fails with `unknown option trailer` in Cursor terminal, use:
  ```powershell
  & "C:\Program Files\Git\mingw64\bin\git.exe" commit -m "message"
  ```
- **gh CLI:** `C:\Program Files\GitHub CLI\gh.exe` (refresh PATH in old terminals)

---

## Product context

Full PRD: **[PRD.md](PRD.md)**. Summary: golf analytics coach from round data; rules-based MVP; 18Birdies aspirational; auth/billing deferred (ADR-007).
