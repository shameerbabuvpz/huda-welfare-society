-- Production Database Migration SQL
-- Run this directly on Railway PostgreSQL if knex migrations fail
-- 
-- Usage: psql <DATABASE_URL> -f scripts/migrate_production.sql
-- Example: psql "postgresql://postgres:pass@postgres-production-d291.up.railway.app:5432/railway" -f scripts/migrate_production.sql

-- ============================================
-- Migration 18: Add user_roles table & current_role column
-- ============================================

-- Add current_role column to users table (if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'current_role') THEN
    ALTER TABLE users ADD COLUMN current_role TEXT DEFAULT 'admin';
    -- Set current_role = role for existing users
    UPDATE users SET current_role = role WHERE current_role IS NULL OR current_role = 'admin';
  END IF;
END $$;

-- Create user_roles table (if not exists)
CREATE TABLE IF NOT EXISTS user_roles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'member')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, organization_id, role)
);

-- ============================================
-- Migration 19: Add member login code columns
-- ============================================

-- Add login_code column to members table (if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'members' AND column_name = 'login_code') THEN
    ALTER TABLE members ADD COLUMN login_code VARCHAR(255) NOT NULL DEFAULT '6789';
  END IF;
END $$;

-- Add code_changed column to members table (if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'members' AND column_name = 'code_changed') THEN
    ALTER TABLE members ADD COLUMN code_changed BOOLEAN NOT NULL DEFAULT false;
  END IF;
END $$;

-- ============================================
-- Verify
-- ============================================
SELECT 'users.current_role' as check_item, 
       EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'current_role') as exists;

SELECT 'user_roles table' as check_item,
       EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') as exists;

SELECT 'members.login_code' as check_item,
       EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'members' AND column_name = 'login_code') as exists;

SELECT 'members.code_changed' as check_item,
       EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'members' AND column_name = 'code_changed') as exists;

SELECT '✅ All migrations applied successfully!' as status;
