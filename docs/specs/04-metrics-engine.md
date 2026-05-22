# 04 — Core Metrics Engine

**Status:** Complete  
**Checkpoint:** CP-4  
**Date:** 2026-05-22  
**Sign-off:** Approved for CP-5 (rules) and CP-9 (implementation)

**Depends on:** [03-data-model.md](./03-data-model.md), [02-architecture.md](./02-architecture.md) §5 (ADR-002)  
**Workplan:** [PHASE1_WORKPLAN.md](../PHASE1_WORKPLAN.md#cp-4--core-metrics-engine-spec)

---

## 1. Engine decision summary

| Field | Decision |
|-------|----------|
| **Recommendation** | FastAPI `metrics/` module computes all metrics on job run; persist to `trend_snapshots`; BFF reads snapshots only |
| **Why** | Matches ADR-002 async pipeline; Python-friendly stats; dashboard stays fast |
| **Alternatives** | Compute on read — rejected (timeout); SQL-only aggregates — too rigid for SG proxies |
| **Risks** | BirdieIQ numbers ≠ 18Birdies — disclose in UI as “BirdieIQ calculated” |
| **Next action** | CP-5 rules consume `metric_key` outputs; CP-9 implement with pytest fixtures |

---

## 2. Scope

| In MVP | Out of MVP |
|--------|------------|
| P0 + P1 metrics below | ML predictions |
| Rolling windows: `last_5`, `last_10`, `last_20`, `last_90d` | GHIN official handicap API |
| Par-based strokes-gained proxy (ADR-005) | Tour benchmark SG |
| Job recompute on import/save | Real-time per-hole SG from shot GPS |

---

## 3. Definitions

### 3.1 Round eligibility

A round is **complete** when:

1. `rounds.total_score` is set, **or**
2. Every hole in the round has non-null `holes.score`.

A round is **eligible** for a metric if it is complete **and** meets that metric’s minimum field requirements (§4).

Rounds are ordered by `played_at DESC`, then `created_at DESC` for ties.

### 3.2 Window selection

| `window_label` | Round set |
|----------------|-----------|
| `last_5` | Up to 5 most recent eligible rounds |
| `last_10` | Up to 10 |
| `last_20` | Up to 20 |
| `last_90d` | All eligible rounds with `played_at >= today - 90 days` |

If fewer rounds exist than the window size, use all available (label confidence **low** when count &lt; 3 in UI).

### 3.3 Nine-hole normalization

| Context | Rule |
|---------|------|
| **Scoring average** | Use raw `total_score` per round (9-hole scores are not doubled) |
| **Handicap proxy** | Only **18-hole** rounds enter handicap pool in MVP |
| **FIR / GIR / putting** | Hole-level stats; no doubling |
| **UI** | Show badge “9-hole” on round cards |

### 3.4 Hole-level helpers

```text
score_to_par(h)  = h.score - h.par
fairway_in_scope = h.par >= 4 AND h.fairway_hit IN ('Y', 'N')
gir_in_scope     = h.gir IS NOT NULL
putts_in_scope   = h.putts IS NOT NULL
```

**Picked up hole:** `score IS NULL` — excluded from hole-level metrics; may disqualify round completeness.

---

## 4. Metric catalog

### 4.1 Summary table

| metric_key | Priority | Windows | Min rounds | Required fields |
|------------|----------|---------|------------|-----------------|
| `scoring_avg` | P0 | 5, 10, 20, 90d | 1 | complete round |
| `handicap_index` | P0 | latest | 3 × 18-hole | 18-hole complete |
| `fir_pct` | P0 | 5, 10, 20, 90d | 1 | `fairway_hit` on par 4/5 |
| `gir_pct` | P0 | 5, 10, 20, 90d | 1 | `gir` not null |
| `putting_avg` | P0 | 5, 10, 20, 90d | 1 | `putts` not null |
| `volatility_std` | P1 | 10, 20 | 3 | complete round |
| `sg_vs_par` | P1 | 5, 10, 20 | 1 | complete + putts |
| `sg_putt` | P1 | 5, 10, 20 | 1 | putts |
| `sg_ott` | P1 | 5, 10, 20 | 1 | par 4/5 + fairway |
| `sg_app` | P1 | 5, 10, 20 | 1 | complete + putts |
| `sg_arg` | P1 | 5, 10, 20 | 1 | complete + putts |
| `scoring_leak_par3` | P0 | 10, 20 | 2 | par 3 holes |
| `scoring_leak_par4` | P0 | 10, 20 | 2 | par 4 holes |
| `scoring_leak_par5` | P0 | 10, 20 | 2 | par 5 holes |
| `blow_up_rate` | P0 | 5, 10, 20 | 1 | complete holes |

---

### 4.2 `scoring_avg` (P0)

**Formula:**

```text
scoring_avg(window) = mean(total_score) over eligible rounds in window
```

`total_score` = `rounds.total_score` or `sum(holes.score)` when all holes scored.

**Snapshot:** `value_numeric` = rounded to 1 decimal.

**Example:** scores [82, 79, 85] → `82.0` for last_3 (if window last_5 has only 3 rounds).

---

### 4.3 `handicap_index` (P0) — BirdieIQ Handicap Proxy (BHP)

Simplified WHS-style index for coaching trends — **not** USGA official.

**Step 1 — Round differential (18-hole only):**

```text
par_total = sum(holes.par)
differential = total_score - par_total
```

**Step 2 — Select lowest differentials:**

| Rounds in pool | Count of lowest differentials used |
|----------------|-----------------------------------|
| 3–5 | 1 |
| 6–8 | 2 |
| 9–11 | 3 |
| 12–14 | 4 |
| 15–16 | 5 |
| 17–18 | 6 |
| 19 | 7 |
| 20+ | 8 |

**Step 3 — Index:**

```text
handicap_index = round(average(lowest_differentials) × 0.96, 1)
```

**Snapshot:** `window_label = 'latest'`, `value_numeric` = index, `value_json.rounds_in_pool`, `value_json.differentials_used`.

**UI disclaimer:** “Estimated handicap index — not GHIN certified.”

---

### 4.4 `fir_pct` (P0)

**Formula (hole-weighted across rounds in window):**

```text
fir_pct = 100 × (count fairway_hit = 'Y') / (count fairway_hit IN ('Y','N'))
```

Par 3 holes (`fairway_hit = 'NA'`) excluded from denominator.

**Snapshot:** `value_numeric` = percent, 1 decimal.

---

### 4.5 `gir_pct` (P0)

```text
gir_pct = 100 × (count gir = true) / (count gir IS NOT NULL)
```

---

### 4.6 `putting_avg` (P0)

**Per round:**

```text
round_putts = sum(putts) / count(putts IS NOT NULL)   # putts per hole played
```

**Window:**

```text
putting_avg = mean(round_putts) over eligible rounds
```

Alternative display: `total_putts_avg` = mean(sum(putts)) — use `putting_avg` as primary (per-hole rate).

---

### 4.7 `volatility_std` (P1)

```text
volatility_std(window) = population_stddev(total_score) over eligible rounds
```

Population formula: `sqrt(sum((x - mean)²) / n)`. Require **n ≥ 3**.

---

### 4.8 Strokes gained — par-based proxy (P1, ADR-005)

No shot GPS in MVP. Proxy decomposes **strokes gained vs par** into buckets using score, putts, par, GIR, and fairway.

**Per hole (when `score` and `putts` known):**

```text
sg_total_hole = par - score

sg_putt_hole  = 2 - putts                    # expected 2 putts once on green

sg_non_putt   = sg_total_hole - sg_putt_hole
```

**Allocate `sg_non_putt` to OTT / APP / ARG:**

| Condition | OTT | APP | ARG |
|-----------|-----|-----|-----|
| par 3 | 0 | 100% of sg_non_putt | 0 |
| par 4/5, `gir = false`, `fairway_hit = 'N'` | 60% | 30% | 10% |
| par 4/5, `gir = false`, `fairway_hit = 'Y'` | 20% | 60% | 20% |
| par 4/5, `gir = true` | 0 | 80% | 20% |
| `gir` unknown | 0 | 100% | 0 |

Percentages apply to `sg_non_putt` (heuristic, documented for user transparency).

**Window aggregates:**

```text
sg_vs_par  = sum(sg_total_hole) / n_holes
sg_putt    = sum(sg_putt_hole) / n_holes
sg_ott     = sum(sg_ott_hole) / n_holes
... likewise app, arg
```

Store per-round in `value_json` optional; snapshot stores window mean per hole played.

---

### 4.9 Scoring leaks (P0)

**Par-type leak (strokes over par per hole):**

```text
leak_parX = mean(score - par) for holes where par = X, across rounds in window
```

Separate keys: `scoring_leak_par3`, `scoring_leak_par4`, `scoring_leak_par5`.

Positive = losing strokes to par on that hole type.

**Blow-up rate:**

```text
blow_up_rate = mean over rounds of (count holes where score >= par + 3) / holes_played
```

`metric_key = 'blow_up_rate'`, `value_numeric` = rate per round (e.g. 0.22 = 0.22 blow-ups/hole).

**Rich breakdown:** store in `value_json`:

```json
{
  "par3_avg_to_par": 0.6,
  "par4_avg_to_par": 0.9,
  "par5_avg_to_par": 1.2,
  "worst_hole_numbers": [7, 12, 15]
}
```

---

## 5. Edge case matrix

| Scenario | Policy |
|----------|--------|
| Partial 9-hole round | Eligible for hole metrics; excluded from handicap pool |
| Missing `fairway_hit` on par 4/5 | Hole excluded from FIR denominator |
| `fairway_hit = 'NA'` on par 3 | Correct — not in FIR |
| `gir` NULL | Excluded from GIR %; SG uses “gir unknown” row |
| Picked up hole (`score` NULL) | Round incomplete unless other holes sum to `total_score` |
| `putts` NULL on some holes | Putting avg uses holes with putts; SG holes need putts |
| &lt; 3 rounds | Show metrics with “low confidence” badge |
| &lt; 3 rounds for volatility | Omit `volatility_std` snapshot |
| Duplicate `played_at` | Tie-break `created_at DESC` |
| Tournament vs casual | Not distinguished in MVP — `rounds.notes` only |
| Mixed 9 and 18 in window | Scoring avg mixes; document in tooltip |
| Re-import same `round_id` | BFF rejects duplicate (CP-3); metrics unchanged |

---

## 6. Computation schedule (ADR-002)

| Trigger | Action |
|---------|--------|
| `import` | After rounds/holes committed → enqueue `metrics_jobs` |
| `round_save` | Manual create/update/delete → enqueue job |
| `manual` | User “Refresh stats” button (optional CP-10) |
| `nightly` | v1.1 cron — recompute `last_90d` snapshots |

**Job algorithm (`POST /internal/jobs/metrics`):**

1. Load all eligible rounds + holes for `user_id`.
2. For each `metric_key` × `window_label`, compute value.
3. `UPSERT` into `trend_snapshots` on `(user_id, metric_key, window_label, as_of_date)` with `as_of_date = CURRENT_DATE`.
4. Return job `complete` (rules engine runs after metrics in same job — CP-5).

**Idempotency:** Re-running job overwrites same-day snapshots.

---

## 7. `trend_snapshots` write contract

| Field | Rule |
|-------|------|
| `metric_key` | Stable strings in §4.1 |
| `window_label` | `last_5`, `last_10`, `last_20`, `last_90d`, or `latest` (handicap) |
| `value_numeric` | Primary scalar |
| `value_json` | Breakdowns, confidence, sample sizes |
| `as_of_date` | Date of job run (UTC date) |
| `computed_at` | Job timestamp |

**Recommended `value_json` shape:**

```json
{
  "sample_rounds": 8,
  "sample_holes": 144,
  "confidence": "medium",
  "disclaimer": "birdieiq_calculated"
}
```

---

## 8. API contract (BFF)

Browser calls BFF only. BFF reads `trend_snapshots` (no Analytics on read path).

### 8.1 `GET /api/metrics/summary`

**Response 200:**

```yaml
MetricsSummaryResponse:
  type: object
  required: [as_of_date, metrics]
  properties:
    as_of_date:
      type: string
      format: date
    metrics:
      type: array
      items:
        $ref: '#/components/schemas/MetricSnapshot'
```

**Default keys returned (latest window per metric):**

| UI card | metric_key | window_label |
|---------|------------|--------------|
| Scoring avg | `scoring_avg` | `last_10` |
| Handicap | `handicap_index` | `latest` |
| FIR % | `fir_pct` | `last_10` |
| GIR % | `gir_pct` | `last_10` |
| Putting | `putting_avg` | `last_10` |
| Volatility | `volatility_std` | `last_10` |

Query: `?window=last_10` optional override for all scalar cards.

### 8.2 `GET /api/metrics/trends`

**Query parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `metric` | string | Required — e.g. `scoring_avg` |
| `window` | string | `last_5` … `last_90d` |
| `points` | int | Max snapshot dates to return (default 12) |

**Response 200:**

```yaml
MetricsTrendsResponse:
  type: object
  properties:
    metric_key: { type: string }
    window_label: { type: string }
    series:
      type: array
      items:
        type: object
        properties:
          as_of_date: { type: string, format: date }
          value_numeric: { type: number }
          value_json: { type: object }
```

### 8.3 Shared schema

```yaml
components:
  schemas:
    MetricSnapshot:
      type: object
      required: [metric_key, window_label, value_numeric, as_of_date]
      properties:
        metric_key: { type: string }
        window_label: { type: string }
        value_numeric: { type: number, nullable: true }
        value_json: { type: object, nullable: true }
        as_of_date: { type: string, format: date }
        computed_at: { type: string, format: date-time }
```

### 8.4 Errors

| Code | When |
|------|------|
| 404 | No snapshots yet (new user) — return empty `metrics: []` preferred over 404 |
| 400 | Unknown `metric` query param |

FastAPI internal job endpoint unchanged from [02-architecture.md](./02-architecture.md).

---

## 9. Worked examples (fixtures)

Use these in CP-9 pytest. Hole tuples: `(hole#, par, score, putts, fir, gir)` — `fir`: Y/N/NA.

### Example A — Single round FIR / GIR

**Round R1** (18 holes, played 2026-05-01, total 82):

| # | par | score | putts | fir | gir |
|---|-----|-------|-------|-----|-----|
| 1 | 4 | 5 | 2 | N | N |
| 2 | 5 | 5 | 2 | Y | Y |
| 3 | 4 | 4 | 1 | NA | Y |

*(… assume remaining 15 holes sum to 68 more strokes for total 82; for FIR/GIR worked example only holes 1–3 matter.)*

**FIR (holes 1–2 in scope):** 1/2 = **50.0%**  
**GIR (holes 1–3):** 2/3 = **66.7%**

---

### Example B — Scoring average `last_5`

| Round | played_at | total | type |
|-------|-----------|-------|------|
| R1 | 2026-05-10 | 82 | 18 |
| R2 | 2026-05-05 | 79 | 18 |
| R3 | 2026-04-28 | 85 | 18 |

`scoring_avg(last_5)` = (82 + 79 + 85) / 3 = **82.0**

---

### Example C — Handicap proxy (5 × 18-hole rounds)

| Round | total | par_total | differential |
|-------|-------|-----------|--------------|
| R1 | 90 | 72 | 18 |
| R2 | 85 | 72 | 13 |
| R3 | 82 | 72 | 10 |
| R4 | 79 | 72 | 7 |
| R5 | 88 | 72 | 16 |

Pool = 5 rounds → use **lowest 1** differential = 7.  
`handicap_index` = round(7 × 0.96, 1) = **6.7**

---

### Example D — Nine-hole round

**Round R9** — 9 holes, total 40, par_total 36.

- Included in `scoring_avg` as **40.0**
- **Excluded** from `handicap_index` pool
- FIR/GIR computed on 9 holes only

---

### Example E — Putting average

| Round | sum(putts) | holes with putts |
|-------|------------|------------------|
| R1 | 32 | 18 |
| R2 | 30 | 18 |

`round_putts`: R1 = 1.78, R2 = 1.67  
`putting_avg(last_5)` = (1.78 + 1.67) / 2 = **1.72** putts/hole

---

### Example F — Blow-up rate

**Round R1:** two holes with score ≥ par + 3 (e.g. triple on par 4), 18 holes played.  
`blow_up_rate` for round = 2/18 = 0.111.  
Window mean over one round = **0.111**.

---

### Example G — SG proxy (one hole)

Par 4, score 5, putts 2, gir false, fairway_hit N:

```text
sg_total = 4 - 5 = -1
sg_putt  = 2 - 2 = 0
sg_non_putt = -1
sg_ott = 0.6 × (-1) = -0.6
sg_app = 0.3 × (-1) = -0.3
sg_arg = 0.1 × (-1) = -0.1
```

---

## 10. CP-4 exit criteria

- [x] Every P0 metric has formula + fixtures (§4, §9)
- [x] OpenAPI stub for summary + trends (§8)
- [x] ADR-005 accepted — par-based SG proxy (§4.8)

---

## 11. Open items for CP-5 / CP-9

| Item | Owner |
|------|-------|
| Rule thresholds referencing `metric_key` | CP-5 |
| `fixtures/rounds/*.json` test files | CP-9 |
| Nightly `nightly` trigger | v1.1 |
| GHIN integration | Post-MVP |

---

## 12. Approval

| Role | Name | Date |
|------|------|------|
| Product / engineering | Wilson Papilla | 2026-05-22 |

**Approved** — proceed to **CP-5** (recommendation engine spec).
