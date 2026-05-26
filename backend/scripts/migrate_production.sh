#!/bin/bash
# Production Database Migration Script
# Usage: ./scripts/migrate_production.sh <DATABASE_URL>
# Example: ./scripts/migrate_production.sh "postgresql://user:pass@host:port/dbname"

if [ -z "$1" ]; then
  echo "❌ Usage: ./scripts/migrate_production.sh <DATABASE_URL>"
  echo ""
  echo "Get DATABASE_URL from Railway Dashboard:"
  echo "  1. Login to railway.app"
  echo "  2. Select your project → PostgreSQL service"
  echo "  3. Variables tab → Copy DATABASE_URL"
  echo ""
  echo "Example: ./scripts/migrate_production.sh \"postgresql://postgres:abc123@postgres-production-d291.up.railway.app:5432/railway\""
  exit 1
fi

PROD_DATABASE_URL="$1"

echo "🔄 Running migrations on production database..."
echo "   Host: $(echo "$PROD_DATABASE_URL" | sed 's/.*@\(.*\):.*/\1/')"
echo ""

cd "$(dirname "$0")/.."

DATABASE_URL="$PROD_DATABASE_URL" npx knex migrate:latest --knexfile knexfile.js --env production

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Production migrations completed successfully!"
else
  echo ""
  echo "❌ Migration failed. Check the error above."
  echo ""
  echo "If migration 18 (user_roles) fails, you may need to rollback first:"
  echo "  DATABASE_URL=\"$PROD_DATABASE_URL\" npx knex migrate:rollback --knexfile knexfile.js --env production"
  exit 1
fi
