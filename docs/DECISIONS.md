# Architecture Decision Log (ADR)

Record one entry per major decision. Link to specs and journal checkpoints.

---

## ADR-001 — Data ingestion (MVP)

**Status:** Accepted  
**Date:** 2026-05-22  
**Checkpoint:** CP-1  
**Context:** 18Birdies has no public API, no OAuth, and no CSV export ([help article 643](https://help.18birdies.com/article/643-can-i-export-18birdies-data-to-a-csv-or-excel-spreadsheet)). GDPR/download and partnership paths are Phase 2.

**Decision:**

1. **MVP:** BirdieIQ **CSV Import v1** (`docs/specs/birdieiq-round-import-v1.example.csv`) plus **manual round wizard** (9/18 holes).
2. **Phase 2:** Parse user-initiated GDPR/account download if machine-readable; pursue 18Birdies business partnership for official API.
3. **Exclude from MVP:** browser extensions, reverse-engineered API scraping, OCR-primary ingestion.

**Consequences:** Marketing must not promise “Connect 18Birdies” at launch. CP-3 schema and CP-4 metrics align to CSV columns. User tests for download format and email scorecard remain open (see `docs/journal/CP-01.md`).

**Spec:** [01-data-access-feasibility.md](./specs/01-data-access-feasibility.md)

---

## ADR-002 — Metrics computation trigger

**Status:** Proposed  
**Decision:** Async recompute on round import/save; nightly snapshot refresh optional in v1.1.

---

## ADR-003 — Hosting

**Status:** Proposed  
**Decision:** Vercel (web) + Railway or Render (FastAPI) + Neon (Postgres).

---

## ADR-004 — ORM / migrations

**Status:** Open  
**Decision:** TBD at CP-6 (Drizzle vs Prisma — document choice here).

---

## ADR-005 — Strokes gained MVP method

**Status:** Proposed  
**Decision:** Par-based bucket proxy until benchmark data available.
