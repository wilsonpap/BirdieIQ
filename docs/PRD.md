# BirdieIQ — Product Requirements Document (PRD)

**Version:** 1.0  
**Owner:** Wilson Papilla  
**Last updated:** 2026-05-22  

**Related docs:** [PROJECT_STATUS.md](./PROJECT_STATUS.md) · [PHASE1_WORKPLAN.md](./PHASE1_WORKPLAN.md) · [DECISIONS.md](./DECISIONS.md)

---

## Implementation status (engineering)

This PRD is the **product source of truth**. Engineering execution is tracked separately:

| PRD area | Status | Where decided |
|----------|--------|----------------|
| Phase 1 design (objectives 1–5) | ✅ CP-1–CP-5 complete | Specs 01–05, [rules/](../rules/v1/) |
| 8-week build (objective 6) | ⏭ CP-6 scaffold → CP-7–12 | Workplan |
| Clerk / Stripe auth & billing | **Deferred post-MVP** | [ADR-007](./DECISIONS.md) |
| 18Birdies live API | **Not available** — CSV + manual MVP | [ADR-001](./DECISIONS.md) |

---

## Product vision

BirdieIQ connects to golfer round data and analyzes past rounds to identify:

- Strengths  
- Weaknesses  
- Trends  
- Scoring leaks  
- Personalized practice plans  

**Goal:** Become an **“AI golf coach”** powered by historical round data.

**Initial data source (aspirational):** 18Birdies user data. **MVP reality:** See [01-data-access-feasibility.md](./specs/01-data-access-feasibility.md) — import and manual entry until a sanctioned 18Birdies path exists.

---

## Phase 1 objectives

### 1. Validate data access

Research and determine:

- Does 18Birdies have a public API?  
- Is OAuth available?  
- What endpoints exist for: rounds, shot data, scoring, clubs, user profile?  
- Are there partner APIs?  
- If no API: fallback options (CSV exports, scraping risks, browser extension, manual upload).

**Deliverable:** Feasibility report with recommended ingestion strategy.  
**Status:** ✅ [01-data-access-feasibility.md](./specs/01-data-access-feasibility.md)

---

### 2. Define MVP architecture

Recommend a scalable architecture including:

| Layer | PRD ask | Decision (CP-2) |
|-------|---------|-----------------|
| Frontend | Next.js, React, Tailwind | Next.js 14 App Router + shadcn |
| Backend | Node or Python | Next.js BFF + **FastAPI** analytics |
| Database | PostgreSQL | **Neon** |
| Analytics | Python stats + recommendations | FastAPI service on **Railway** |
| Hosting | Low-cost startup | **Vercel** + Railway + Neon |
| Authentication | Best auth provider | **Clerk — post-MVP** ([ADR-007](./DECISIONS.md)) |
| Billing | Subscription SaaS | **Stripe — post-MVP** ([ADR-007](./DECISIONS.md)) |

**Deliverable:** Architecture diagram + stack recommendation + reasoning.  
**Status:** ✅ [02-architecture.md](./specs/02-architecture.md), [architecture.mmd](./diagrams/architecture.mmd)

---

### 3. Design data model

Database schemas for:

- Users  
- Rounds  
- Holes  
- Shots  
- Practice plans  
- Insights  
- Trend snapshots  

Include: primary keys, relationships, indexes.

**Deliverable:** ERD + SQL schema draft.  
**Status:** ⏭ CP-3 — [03-data-model.md](./specs/03-data-model.md) (stub)

---

### 4. Define core metrics engine

Design logic to calculate:

- Scoring average  
- Handicap trend  
- Fairways hit %  
- GIR %  
- Putting trends  
- Strokes gained (approximation if needed)  
- Volatility  
- Scoring leaks  

For each metric: formula, required data, edge cases.

**Deliverable:** Metrics spec doc.  
**Status:** ⬜ CP-4 — [04-metrics-engine.md](./specs/04-metrics-engine.md) (stub)

---

### 5. Define recommendation engine v1

**Rules-based (not ML)** in v1.

Examples:

- IF putting inside 6 ft &lt; 75% → short-putt drills  
- IF GIR drops &gt;10% → wedge practice  

**Deliverable:** Rules engine design + **20 starter rules**.  
**Status:** ⬜ CP-5 — [05-recommendation-engine.md](./specs/05-recommendation-engine.md) (stub); starter list in [PHASE1_WORKPLAN.md](./PHASE1_WORKPLAN.md#cp-5--recommendation-engine-v1-rules)

---

### 6. Build MVP roadmap

8-week build plan with:

- Engineering milestones  
- Technical risks  
- Dependencies  

**Deliverable:** Week-by-week plan.  
**Status:** ✅ [PHASE1_WORKPLAN.md](./PHASE1_WORKPLAN.md) (CP-7–12)

---

## Constraints (Phase 1)

| Constraint | Notes |
|------------|--------|
| Speed to MVP | Defer auth/billing and 18Birdies sync |
| Low infrastructure cost | Target &lt; ~$30/mo until scale |
| Scalability later | Clean schema, async metrics jobs |
| Subscription SaaS | Stripe after core MVP works |
| Mobile-responsive web first | No native app in Phase 1 |
| Avoid overengineering | Two services (BFF + analytics), not microservices |
| No unnecessary AI/ML in v1 | Rules engine only; LLM layer post-MVP |

---

## Output format (per task)

For every task, provide:

- **Recommendation**  
- **Why**  
- **Alternatives**  
- **Risks**  
- **Next action**  

Captured in checkpoint journals: `docs/journal/CP-XX.md`.

---

## Success criteria (Phase 1 MVP)

A golfer can:

1. Import or enter round data (CSV or manual wizard).  
2. See core metrics and trends on a dashboard.  
3. View strengths, weaknesses, and scoring leaks.  
4. Receive a rules-based practice plan with drills.  
5. Use the product on mobile web without signing in (MVP seed user; auth before public launch).

---

## Out of scope (Phase 1)

- Native iOS/Android apps  
- ML / LLM-generated coaching (rules only)  
- Live 18Birdies OAuth sync  
- Multi-user production deployment without auth  
- GHIN / Arccos / TheGrint connectors (post-MVP backlog)  
- Tournament management  
- Real-time round tracking GPS  

---

## Post-MVP backlog (from workplan CP-14)

- 18Birdies partnership + GDPR export parser  
- Clerk authentication  
- Stripe subscriptions + free tier limits  
- Additional data source connectors (TheGrint Connect, Arccos API, GHIN GPA)  
- LLM narrative layer on top of rules (optional)  

---

## Glossary

| Term | Meaning |
|------|---------|
| GIR | Greens in regulation |
| FIR | Fairways in regulation |
| SG | Strokes gained |
| BFF | Backend-for-frontend (Next.js Route Handlers) |
| CP-N | Checkpoint N in Phase 1 workplan |

---

*Original PRD provided 2026-05-22. Amended to reflect ADR-001 (ingestion), ADR-007 (defer auth/billing), and checkpoint progress.*
