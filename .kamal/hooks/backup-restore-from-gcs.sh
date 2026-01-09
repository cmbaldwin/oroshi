#!/usr/bin/env bash
# Restore from GCS backup (useful if local backups are lost)

DB_NAME="${POSTGRES_DB:-oroshi_production}"
DB_HOST="${DB_HOST:-oroshi-db}"
DB_USER="${POSTGRES_USER:-oroshi}"
DB_PORT="${DB_PORT:-5432}"

echo "⚠️  WARNING: This will DESTROY your current database!"
echo ""

# List available backups from GCS
echo "Available backups in GCS:"
kamal accessory exec db_backup_gcs_sync "sh -c 'gcloud auth activate-service-account --key-file=/gcs-key/credentials.json > /dev/null 2>&1 && gsutil ls gs://\${GCLOUD_BUCKET}/\${GBUCKET_PREFIX}/last/'"
echo ""

read -p "Enter backup filename to restore (e.g., ${DB_NAME}-20251012-120000.sql.gz): " BACKUP_FILE
echo ""
read -p "Type 'RESTORE' to confirm: " -r
echo

if [[ $REPLY == "RESTORE" ]]; then
    echo "Downloading backup from GCS..."
    kamal accessory exec db_backup_gcs_sync "sh -c 'gcloud auth activate-service-account --key-file=/gcs-key/credentials.json > /dev/null 2>&1 && gsutil cp gs://\${GCLOUD_BUCKET}/\${GBUCKET_PREFIX}/last/$BACKUP_FILE /backups/restore-temp.sql.gz'"

    echo "Restoring database..."
    kamal accessory exec db_backup "zcat /backups/restore-temp.sql.gz | psql --host=${DB_HOST} --port=${DB_PORT} --username=${DB_USER} --dbname=${DB_NAME}"

    echo "Cleaning up temp file..."
    kamal accessory exec db_backup "rm /backups/restore-temp.sql.gz"

    echo "✓ Database restore complete!"
    echo ""
    echo "Syncing EC product settings from production..."
    bundle exec rake settings:sync_from_production
    echo ""
    echo "✅ Restore and settings sync complete!"
else
    echo "Restore cancelled."
fi
