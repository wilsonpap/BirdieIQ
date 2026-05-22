-- BirdieIQ — Initial schema (CP-3 draft)
-- PostgreSQL 16+
-- Apply via migration tool at CP-6 (Drizzle or Prisma — ADR-004)

BEGIN;

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
CREATE TYPE round_source AS ENUM ('csv', 'manual', 'api');
CREATE TYPE import_batch_status AS ENUM ('pending', 'processing', 'complete', 'failed');
CREATE TYPE metrics_job_status AS ENUM ('pending', 'running', 'complete', 'failed');
CREATE TYPE metrics_job_trigger AS ENUM ('import', 'round_save', 'manual', 'nightly');
CREATE TYPE insight_status AS ENUM ('active', 'dismissed', 'expired');
CREATE TYPE practice_plan_status AS ENUM ('active', 'completed', 'archived');

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id          TEXT UNIQUE,
  email             TEXT,
  display_name      TEXT NOT NULL,
  subscription_status TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE users IS 'App users; MVP seeds one row (ADR-007). clerk_id/email reserved post-MVP.';
COMMENT ON COLUMN users.clerk_id IS 'Clerk subject; unique when set (post-MVP).';
COMMENT ON COLUMN users.subscription_status IS 'Stripe-derived status; post-MVP.';

-- ---------------------------------------------------------------------------
-- import_batches
-- ---------------------------------------------------------------------------
CREATE TABLE import_batches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  filename          TEXT,
  source_format     TEXT NOT NULL DEFAULT 'birdieiq_csv_v1',
  status            import_batch_status NOT NULL DEFAULT 'pending',
  rows_total        INTEGER NOT NULL DEFAULT 0,
  rounds_created    INTEGER NOT NULL DEFAULT 0,
  error_message     TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at      TIMESTAMPTZ
);

CREATE INDEX idx_import_batches_user_created
  ON import_batches (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- rounds
-- ---------------------------------------------------------------------------
CREATE TABLE rounds (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  import_batch_id   UUID REFERENCES import_batches (id) ON DELETE SET NULL,
  external_round_id TEXT,
  played_at         DATE NOT NULL,
  course_name       TEXT NOT NULL,
  tee_name          TEXT,
  round_type        SMALLINT NOT NULL CHECK (round_type IN (9, 18)),
  total_score       SMALLINT CHECK (total_score IS NULL OR total_score > 0),
  source            round_source NOT NULL DEFAULT 'manual',
  raw_payload       JSONB,
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_rounds_user_external
    UNIQUE (user_id, external_round_id)
);

CREATE INDEX idx_rounds_user_played_at
  ON rounds (user_id, played_at DESC);

CREATE INDEX idx_rounds_import_batch
  ON rounds (import_batch_id)
  WHERE import_batch_id IS NOT NULL;

COMMENT ON COLUMN rounds.external_round_id IS 'Importer round_id (CSV); dedup per user.';
COMMENT ON COLUMN rounds.raw_payload IS 'Upstream blob for Phase 2 sync (e.g. 18Birdies export).';
COMMENT ON COLUMN rounds.total_score IS 'Optional denormalized total; may be computed from holes.';

-- ---------------------------------------------------------------------------
-- holes
-- ---------------------------------------------------------------------------
CREATE TABLE holes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  round_id          UUID NOT NULL REFERENCES rounds (id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  hole_number       SMALLINT NOT NULL CHECK (hole_number BETWEEN 1 AND 18),
  par               SMALLINT NOT NULL CHECK (par BETWEEN 3 AND 6),
  score             SMALLINT CHECK (score IS NULL OR score >= 1),
  putts             SMALLINT CHECK (putts IS NULL OR putts >= 0),
  fairway_hit       TEXT CHECK (fairway_hit IN ('Y', 'N', 'NA')),
  gir               BOOLEAN,
  penalty_strokes   SMALLINT NOT NULL DEFAULT 0 CHECK (penalty_strokes >= 0),
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_holes_round_number UNIQUE (round_id, hole_number)
);

CREATE INDEX idx_holes_round_id ON holes (round_id);
CREATE INDEX idx_holes_user_id ON holes (user_id);

COMMENT ON COLUMN holes.fairway_hit IS 'Y=yes, N=no, NA=not applicable (par 3 / no fairway).';
COMMENT ON COLUMN holes.score IS 'NULL = picked up or incomplete hole.';

-- ---------------------------------------------------------------------------
-- shots (optional per hole — MVP schema only)
-- ---------------------------------------------------------------------------
CREATE TABLE shots (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hole_id           UUID NOT NULL REFERENCES holes (id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  shot_number       SMALLINT NOT NULL CHECK (shot_number >= 1),
  club              TEXT,
  lie               TEXT,
  distance_yards    INTEGER CHECK (distance_yards IS NULL OR distance_yards >= 0),
  result            TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_shots_hole_number UNIQUE (hole_id, shot_number)
);

CREATE INDEX idx_shots_hole_id ON shots (hole_id);
CREATE INDEX idx_shots_user_id ON shots (user_id);

-- ---------------------------------------------------------------------------
-- metrics_jobs (ADR-002)
-- ---------------------------------------------------------------------------
CREATE TABLE metrics_jobs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  status            metrics_job_status NOT NULL DEFAULT 'pending',
  trigger           metrics_job_trigger NOT NULL,
  error             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at        TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ
);

CREATE INDEX idx_metrics_jobs_user_created
  ON metrics_jobs (user_id, created_at DESC);

CREATE INDEX idx_metrics_jobs_status_pending
  ON metrics_jobs (status)
  WHERE status IN ('pending', 'running');

-- ---------------------------------------------------------------------------
-- trend_snapshots
-- ---------------------------------------------------------------------------
CREATE TABLE trend_snapshots (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  metric_key        TEXT NOT NULL,
  window_label      TEXT NOT NULL,
  value_numeric     NUMERIC,
  value_json        JSONB,
  as_of_date        DATE NOT NULL,
  computed_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_trend_snapshots_user_metric_window_date
    UNIQUE (user_id, metric_key, window_label, as_of_date)
);

CREATE INDEX idx_trend_snapshots_user_metric
  ON trend_snapshots (user_id, metric_key, as_of_date DESC);

COMMENT ON COLUMN trend_snapshots.metric_key IS 'e.g. scoring_avg, fir_pct, gir_pct (see CP-4).';
COMMENT ON COLUMN trend_snapshots.window_label IS 'e.g. last_5, last_10, last_20, last_90d.';

-- ---------------------------------------------------------------------------
-- insights
-- ---------------------------------------------------------------------------
CREATE TABLE insights (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  rule_id           TEXT NOT NULL,
  title             TEXT NOT NULL,
  body              TEXT NOT NULL,
  priority          SMALLINT NOT NULL DEFAULT 50,
  status            insight_status NOT NULL DEFAULT 'active',
  fired_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  cooldown_until    TIMESTAMPTZ,
  context           JSONB,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_insights_user_status
  ON insights (user_id, status, fired_at DESC);

CREATE INDEX idx_insights_user_rule
  ON insights (user_id, rule_id, fired_at DESC);

-- ---------------------------------------------------------------------------
-- practice_plans
-- ---------------------------------------------------------------------------
CREATE TABLE practice_plans (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  source_insight_id UUID REFERENCES insights (id) ON DELETE SET NULL,
  title             TEXT NOT NULL,
  status            practice_plan_status NOT NULL DEFAULT 'active',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at      TIMESTAMPTZ
);

CREATE INDEX idx_practice_plans_user_status
  ON practice_plans (user_id, status, created_at DESC);

-- ---------------------------------------------------------------------------
-- practice_plan_items
-- ---------------------------------------------------------------------------
CREATE TABLE practice_plan_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  practice_plan_id  UUID NOT NULL REFERENCES practice_plans (id) ON DELETE CASCADE,
  sort_order        SMALLINT NOT NULL DEFAULT 0,
  drill_template_id TEXT,
  title             TEXT NOT NULL,
  description       TEXT,
  duration_minutes  SMALLINT CHECK (duration_minutes IS NULL OR duration_minutes > 0),
  is_completed      BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_practice_plan_items_plan
  ON practice_plan_items (practice_plan_id, sort_order);

-- ---------------------------------------------------------------------------
-- updated_at trigger (rounds, holes, users)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_rounds_updated_at
  BEFORE UPDATE ON rounds
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_holes_updated_at
  BEFORE UPDATE ON holes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;

-- ---------------------------------------------------------------------------
-- Dev seed (run manually after migration — CP-6 wires into .env.example)
-- ---------------------------------------------------------------------------
-- INSERT INTO users (id, display_name)
-- VALUES ('00000000-0000-4000-8000-000000000001', 'Demo Golfer');
-- Set BIRDIEIQ_DEFAULT_USER_ID to the same UUID in apps/web/.env.local
