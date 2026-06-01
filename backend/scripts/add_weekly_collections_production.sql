-- ============================================================
-- Weekly Ayalkoottam Collections — Production Migration SQL
-- Run this directly on Railway PostgreSQL (Query/Data tab) if
-- `npm run migrate` cannot be run.
--
-- Safe to run multiple times (uses IF NOT EXISTS).
-- ============================================================

-- ── Create weekly_collections table ──
CREATE TABLE IF NOT EXISTS weekly_collections (
  id              SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ayalkoottam_id  INTEGER NOT NULL REFERENCES ayalkoottams(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  deposit         NUMERIC(12,2) NOT NULL DEFAULT 0,
  withdrawal      NUMERIC(12,2) NOT NULL DEFAULT 0,
  loan            NUMERIC(12,2) NOT NULL DEFAULT 0,
  loan_repayment  NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_total       NUMERIC(12,2) NOT NULL DEFAULT 0,
  note            TEXT,
  created_by      INTEGER REFERENCES users(id),
  updated_by      INTEGER REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT weekly_collections_unique_week
    UNIQUE (organization_id, ayalkoottam_id, week_start_date)
);

CREATE INDEX IF NOT EXISTS weekly_collections_org_week_idx
  ON weekly_collections (organization_id, week_start_date);

-- ── Record the migration in knex log so `npm run migrate` won't re-run it ──
-- (knex stores applied migrations in the knex_migrations table)
DO $$
DECLARE
  next_batch INTEGER;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'knex_migrations') THEN
    IF NOT EXISTS (
      SELECT 1 FROM knex_migrations
      WHERE name = '20260601000001_add_weekly_collections.js'
    ) THEN
      SELECT COALESCE(MAX(batch), 0) + 1 INTO next_batch FROM knex_migrations;
      INSERT INTO knex_migrations (name, batch, migration_time)
      VALUES ('20260601000001_add_weekly_collections.js', next_batch, CURRENT_TIMESTAMP);
    END IF;
  END IF;
END $$;

-- ── Verify ──
SELECT 'weekly_collections table' AS check_item,
       EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'weekly_collections') AS exists;

SELECT '✅ weekly_collections migration applied' AS status;
