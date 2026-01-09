#!/usr/bin/env bash
# Restore from latest backup

DB_NAME="${POSTGRES_DB:-oroshi_production}"
DB_HOST="${DB_HOST:-oroshi-db}"
DB_USER="${POSTGRES_USER:-oroshi}"
DB_PORT="${DB_PORT:-5432}"

echo "⚠️  WARNING: This will DESTROY your current database!"
echo "Current database: ${DB_NAME}"
echo ""
read -p "Type 'RESTORE' to confirm: " -r
echo

if [[ $REPLY == "RESTORE" ]]; then
    echo "Restoring from latest backup..."
    kamal accessory exec db_backup "zcat /backups/last/${DB_NAME}-latest.sql.gz | psql --host=${DB_HOST} --port=${DB_PORT} --username=${DB_USER} --dbname=${DB_NAME}"
    echo "✓ Database restore complete!"
    echo ""
    echo "Syncing EC product settings from production..."
    bundle exec rake settings:sync_from_production
    echo ""
    echo "✅ Restore and settings sync complete!"
else
    echo "Restore cancelled."
fi
