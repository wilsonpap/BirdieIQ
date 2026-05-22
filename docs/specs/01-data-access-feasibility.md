# 01 — Data Access Feasibility Report

**Status:** Complete  
**Checkpoint:** CP-1  
**Author:** Wilson Papilla (product) + BirdieIQ engineering review  
**Date:** 2026-05-22  
**Sign-off:** Approved for MVP — ADR-001 updated

---

## Executive summary

**18Birdies does not offer a public developer API, OAuth integration, or CSV export of round data.** BirdieIQ cannot legally or reliably depend on automated 18Birdies sync for MVP.

**Recommended MVP ingestion (ADR-001):**

1. **BirdieIQ Round Import v1** — documented CSV template + validation UI  
2. **Manual round wizard** — hole-by-hole entry (score, putts, FIR, GIR, penalties)  
3. **Parallel Phase 2 tracks** — (a) GDPR / “Download Account Data” investigation on a real account, (b) 18Birdies business partnership inquiry, (c) optional post-MVP connectors for sources with better export paths (TheGrint import, Arccos partner API)

**Do not ship in MVP:** browser extensions, reverse-engineered mobile API scraping, or OCR-only pipelines as primary ingestion.

**Product messaging:** Position BirdieIQ as *“works with your golf data”* via import/manual entry today; *“18Birdies connection coming”* only after a sanctioned data path exists.

---

## 1. Research scope

Validated against PRD requirements:

| Data domain | BirdieIQ need |
|-------------|----------------|
| Rounds | History, dates, courses, totals |
| Holes | Score, putts, FIR, GIR, par |
| Shots | Club, lie, distance (optional MVP) |
| Scoring | Gross/net, stableford, game types |
| Clubs | Bag / smart distances (P1) |
| User profile | Handicap index, identity |

Primary source target: **18Birdies**  
Alternates evaluated: Garmin Golf, TheGrint, GHIN, Arccos, Golfshot, Golfity (reference).

---

## 2. 18Birdies findings

### 2.1 Public API & OAuth

| Question | Finding |
|----------|---------|
| Public REST/GraphQL API? | **No** — no developer portal or public API documentation found |
| OAuth 2.0 for third-party apps? | **No** |
| Partner / B2B API? | **No public docs** — “18Birdies for Business” and Community Builder are referral/tournament programs, not consumer data APIs |
| Name collision | **birdie.so “Birdie API”** is unrelated CRM software — not 18Birdies golf |

**Sources:** [18birdies.com](https://18birdies.com/), [Help: CSV export](https://help.18birdies.com/article/643-can-i-export-18birdies-data-to-a-csv-or-excel-spreadsheet), privacy policy, business terms.

### 2.2 Endpoint gap table (required vs available)

| Capability | Required for BirdieIQ | 18Birdies availability | Gap |
|------------|----------------------|------------------------|-----|
| List rounds | P0 | In-app only (Round History) | **No programmatic access** |
| Round detail (18 holes) | P0 | In-app scorecard | **No export** |
| Hole stats (FIR, GIR, putts) | P0 | Profile Stats, Hole Insights (premium filters) | **No export** |
| Shot-level data | P1 | Shot tracking / Smart Tracking (premium) | **No export** |
| Strokes gained | P1 | Premium strokes gained insights | **No export** |
| Club stats | P1 | Club stats (premium) | **No export** |
| Handicap index | P0 | In-app handicap | **No export**; may appear in GDPR bundle (TBD) |
| User profile | P0 | Account settings | **No API** |
| Real-time sync | P2 | N/A | **Blocked** |

### 2.3 CSV / spreadsheet export

**Official answer: No.**

> “At this time, playing data can not be exported to a CSV, Excel, or other spreadsheet formatted file types.”

— [Help article 643](https://help.18birdies.com/article/643-can-i-export-18birdies-data-to-a-csv-or-excel-spreadsheet) (last updated Aug 2022)

### 2.4 Email scorecard workflow

Users can **Share Scorecard** from Round Summary → email app. This is a **sharing/UI flow**, not a structured data export.

**Assessment for BirdieIQ:**

| Aspect | Expectation |
|--------|-------------|
| Format | Likely image or rich share card, not normalized JSON/CSV |
| Hole-level FIR/GIR/putts | Unlikely machine-readable without OCR |
| Automation | **Not suitable as MVP ingestion** |
| Use | Manual reference only; optional future OCR spike |

**User action (CP-1):** Email one real scorecard to yourself, inspect attachment/format, add redacted notes to `docs/journal/CP-01.md`.

**Procedure:** Me → Rounds → Round → Share Scorecard → email → document fields visible.

— [Help article 249](https://help.18birdies.com/article/249-can-i-email-a-scorecard-to-myself)

### 2.5 GDPR / CCPA / data portability

18Birdies states compliance with data subject rights:

| Mechanism | Details |
|-----------|---------|
| Email request | `support@18birdies.com` — access, correction, deletion, **portability** (EU) |
| Download page | [18birdies.com/download-account-data/](https://18birdies.com/download-account-data/) — linked from help articles |
| Account deletion | Up to 30 days to purge |
| CSV export | Explicitly **not** offered as product feature |

**Assessment:** GDPR portability is the **best sanctioned path** to evaluate 18Birdies payload structure, but:

- Format is **unknown** until a real request completes (JSON, ZIP, PDF, etc.)
- BirdieIQ **must not** assume recurring automated access
- Parsing pipeline is **Phase 2**, not MVP blocker

**User action (CP-1):** Submit download/portability request from a personal 18Birdies account; log request date and response format in journal when received.

— [GDPR help](https://help.18birdies.com/article/514-can-i-delete-the-data-associated-with-my-account), [Privacy policy](https://18birdies.com/legal/privacy-policy/)

### 2.6 Partnership / business channel

**18Birdies for Business** and **Community Builder** focus on tournaments, referrals, and course marketing — not third-party analytics OAuth.

**Recommendation:** Send a concise partnership email describing BirdieIQ (read-only analytics, user-consented data access, mutual value). Target: business contact via [18birdies.com](https://18birdies.com/) / LinkedIn / support escalation.

**Template:** See `docs/journal/CP-01.md` § Partnership inquiry.

---

## 3. Fallback options evaluation

Scored 1 (poor) – 5 (excellent).

| Option | Feasibility | Legal / ToS risk | UX | MVP fit |
|--------|-------------|------------------|-----|---------|
| Manual round wizard | 5 | 1 (low) | 3 (tedious) | **Yes — P0** |
| BirdieIQ CSV import v1 | 5 | 1 | 4 | **Yes — P0** |
| GDPR / account data download parser | 3 (unknown format) | 1 (user-initiated) | 4 (one-time) | **Phase 2** |
| Email scorecard → OCR | 2 | 2 | 3 | No (spike only) |
| Browser extension (DOM/session) | 2 | 5 (high) | 4 | **No** |
| Reverse-engineer mobile API | 2 | 5 | 4 | **No** |
| Official partner API | 2 (until deal) | 1 | 5 | **Phase 2** |

---

## 4. Alternate data sources (post-MVP connectors)

| Source | Public API? | Export / access path | Handicap official? | Shot-level | Partner path |
|--------|-------------|----------------------|--------------------|------------|--------------|
| **18Birdies** | No | In-app only; GDPR email; share scorecard | In-app | Premium | Business outreach |
| **TheGrint** | Partner-only ([TheGrint Connect](https://thegrint.com/range/post/thegrint-connect-unlock-new-opportunities-through-our-api)) | **Web import tool** (copy/paste table); email `scores@thegrint.com` for transfers | USGA licensed | Limited in import | Apply for Connect partnership |
| **GHIN** | Approval-only ([USGA GPA](https://www.usga.org/content/usga/home-page/handicapping/world-handicap-system/GPA-Program-Overview.html)) | OAuth-style API for approved vendors | **Yes** | No | Apply via USGA GPA — weeks/months |
| **Arccos** | Partner SSO API ([announcement](https://www.arccosgolf.com/blogs/community/clippd-to-become-first-platform-to-seamlessly-integrate-arccos-on-course-data)) | Unofficial libs exist — **not for product** | Yes | **Excellent** | Partner application (Clippd model) |
| **Garmin Golf** | No public API | Community scripts on Connect session — fragile, breaks | Via device | Some | Not recommended for SaaS |
| **Golfshot** | No | Legacy public-profile scraper only | Varies | No | No |
| **Golfity** (ref) | N/A | Native CSV export (rounds/holes/shots) | App-specific | Yes | Competitive reference |

**Strategic note:** TheGrint’s **paste import** and Golfity’s **CSV export** prove golfers will move data when friction is low. BirdieIQ should match that UX for our own CSV standard, not wait on 18Birdies.

---

## 5. Recommended ingestion strategy

### 5.1 MVP (CP-6 through CP-8)

| Path | Description |
|------|-------------|
| **A. CSV Import v1** | User downloads template, fills one row per hole (or round summary + hole sheet), uploads → validation → `import_batches` audit |
| **B. Manual wizard** | 9 or 18 holes; score + putts + FIR/GIR toggles; optional penalties |
| **C. Onboarding** | Set expectations: “18Birdies auto-sync coming”; show CSV + manual as primary |

**CSV template:** [birdieiq-round-import-v1.example.csv](./birdieiq-round-import-v1.example.csv)

Minimum columns for P0 metrics (CP-4):

- Round: `played_at`, `course_name`, `tee_name`, `round_type` (18|9), `total_score`
- Hole: `hole_number`, `par`, `score`, `putts`, `fairway_hit` (Y/N/NA), `gir` (Y/N), `penalty_strokes`

### 5.2 Phase 2 (18Birdies-specific)

| Priority | Initiative | Owner | Success criteria |
|----------|------------|-------|------------------|
| P2.1 | Complete GDPR/download sample | Wilson | Document file format + field mapping |
| P2.2 | Partnership email + follow-up | Wilson | Meeting or written API policy |
| P2.3 | Build parser if machine-readable | Engineering | One-click import from export file |
| P2.4 | OAuth only if 18Birdies provides partner docs | Engineering | Signed agreement + sandbox |

### 5.3 Phase 2b (expand TAM — optional)

| Connector | When |
|-----------|------|
| TheGrint Connect API | After MVP + partnership approval |
| Arccos On-Course Data API | If targeting serious players with sensors |
| GHIN GPA | If official handicap display required on marketing |

---

## 6. Risks & mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Users expect “Connect 18Birdies” | Churn at signup | Honest landing page; waitlist for sync |
| Manual entry friction | Low activation | CSV bulk import; 9-hole quick mode |
| GDPR export is PDF/images only | No auto-parse | Stay on CSV/manual; OCR backlog |
| Metric mismatch vs 18Birdies | Trust | Label “BirdieIQ calculated” |
| Partnership takes 6+ months | Roadmap slip | MVP does not depend on it |

---

## 7. Open questions

| # | Question | Owner | Due |
|---|----------|-------|-----|
| Q1 | What format does “Download Account Data” return? | Wilson | When request completes |
| Q2 | Does emailed scorecard include structured text or image only? | Wilson | After one test round |
| Q3 | Does 18Birdies business team offer data APIs for analytics partners? | Wilson | After outreach |
| Q4 | Will BirdieIQ pursue TheGrint Connect in parallel? | Product | Post-MVP planning |

---

## 8. Decision record

| Field | Value |
|-------|-------|
| **Recommendation** | MVP = CSV v1 + manual wizard; Phase 2 = GDPR parse + partnership; exclude scraping/extension |
| **Why** | Only legal, shippable paths without external dependency |
| **Alternatives rejected** | Wait for API (indefinite); scrape/extension (ToS/legal) |
| **Risks** | Expectation management; entry friction |
| **Next action** | **CP-2** architecture; **CP-3** schema aligned to CSV template |

**Approved by:** Wilson Papilla — 2026-05-22

---

## 9. References

- [18Birdies — no CSV export](https://help.18birdies.com/article/643-can-i-export-18birdies-data-to-a-csv-or-excel-spreadsheet)
- [18Birdies — email scorecard](https://help.18birdies.com/article/249-can-i-email-a-scorecard-to-myself)
- [18Birdies — GDPR](https://help.18birdies.com/article/514-can-i-delete-the-data-associated-with-my-account)
- [18Birdies — download account data](https://18birdies.com/download-account-data/)
- [TheGrint Connect API](https://thegrint.com/range/post/thegrint-connect-unlock-new-opportunities-through-our-api)
- [Arccos On-Course Data API (partner)](https://www.arccosgolf.com/blogs/community/clippd-to-become-first-platform-to-seamlessly-integrate-arccos-on-course-data)
- [USGA GPA Program](https://www.usga.org/content/usga/home-page/handicapping/world-handicap-system/GPA-Program-Overview.html)
