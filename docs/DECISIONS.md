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

**Status:** Accepted  
**Date:** 2026-05-22  
**Checkpoint:** CP-2  
**Context:** Metrics and rules over full round history exceed Vercel serverless timeouts; users need responsive import UX.

**Decision:**

1. On round **import** or **save**, BFF inserts `metrics_jobs` row (`pending`) and calls Analytics `POST /internal/jobs/metrics`.
2. FastAPI runs computation in background (same Railway service for MVP).
3. UI polls `GET /api/jobs/{id}` until `complete` or `failed`.
4. Dashboard reads precomputed `trend_snapshots`, `insights`, `practice_plans` — no compute on read path.
5. **v1.1:** Optional nightly snapshot refresh via Railway cron or Inngest.

**Consequences:** CP-3 must include `metrics_jobs` table. Analytics requires shared `BIRDIEIQ_SERVICE_SECRET`. Failed jobs surface in UI.

**Spec:** [02-architecture.md](./specs/02-architecture.md) §5

---

## ADR-003 — Hosting

**Status:** Accepted  
**Date:** 2026-05-22  
**Checkpoint:** CP-2  

**Decision:**

| Component | Host |
|-----------|------|
| Next.js (UI + BFF) | Vercel |
| FastAPI analytics | Railway |
| PostgreSQL | Neon (serverless) |
| Auth | Clerk (managed) |
| Billing | Stripe (managed) |

**Consequences:** Three cloud vendors; env vars split across Vercel + Railway. Local dev uses Docker Postgres. Estimated MVP infra ~$5–45/mo under 100 MAU.

**Spec:** [02-architecture.md](./specs/02-architecture.md) §6–7

---

## ADR-004 — ORM / migrations

**Status:** Open  
**Checkpoint:** CP-3 (schema draft) → **decide at CP-6**  
**Context:** CP-3 delivered ORM-agnostic SQL in `db/migrations/001_initial.sql` and [03-data-model.md](./specs/03-data-model.md). Either Drizzle or Prisma can target the same tables.

**Decision:** TBD at CP-6 (Drizzle vs Prisma — document choice here).

**Consequences until CP-6:** Do not apply migration in app repo; use raw SQL or `psql` for manual verification if needed.

---

## ADR-005 — Strokes gained MVP method

**Status:** Proposed  
**Decision:** Par-based bucket proxy until benchmark data available.

---

## ADR-006 — BFF pattern

**Status:** Accepted  
**Date:** 2026-05-22  
**Checkpoint:** CP-2  

**Decision:** Next.js Route Handlers act as BFF for all browser-facing APIs. FastAPI is internal-only (service secret), not called from client.

**Consequences:** No CORS exposure of Analytics; all tenant checks in BFF before enqueue.

**Spec:** [02-architecture.md](./specs/02-architecture.md) §3.4

---

## ADR-007 — Defer auth and billing (post-MVP)

**Status:** Accepted  
**Date:** 2026-05-22  
**Checkpoint:** CP-2 (amendment)  
**Context:** Product owner direction: validate analytics + coaching engine before investing in SaaS plumbing.

**Decision:**

1. **MVP (CP-6–CP-12):** No Clerk, no Stripe, no sign-in UI, no paywalls.
2. **User model:** Seed one `users` row; BFF uses `BIRDIEIQ_DEFAULT_USER_ID` env for all requests.
3. **Schema:** Keep `clerk_id`, `email`, `subscription_status` nullable for forward compatibility.
4. **Deploy:** MVP suitable for **local + private staging** only until auth ships.
5. **Post-MVP track:** Add Clerk + Stripe (see CP-14); replace `getCurrentUserId()` with session-based resolver.

**Consequences:** CP-7 is import/dashboard focused, not auth. CP-12 is polish/deploy, not billing. Public beta requires ADR-007 completion first.

**Spec:** [02-architecture.md](./specs/02-architecture.md) — MVP scope boundary
