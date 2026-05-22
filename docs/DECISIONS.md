# Architecture Decision Log (ADR)

Record one entry per major decision. Link to specs and journal checkpoints.

---

## ADR-001 — Data ingestion (MVP)

**Status:** Proposed (confirm after CP-1)  
**Date:** TBD  
**Context:** 18Birdies has no public API; no CSV export per help docs.  
**Decision:** TBD after `docs/specs/01-data-access-feasibility.md`  
**Default recommendation:** CSV import + manual round entry; parallel partner/GDPR track for 18Birdies.

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
