#!/usr/bin/env bash
# Manually trigger a backup

echo "Creating manual database backup..."
kamal accessory exec db_backup "/backup.sh"
echo "Backup created successfully!"
echo ""
echo "Syncing to Google Cloud Storage..."
kamal accessory exec db_backup_gcs_sync "sh -c 'gcloud auth activate-service-account --key-file=/gcs-key/credentials.json > /dev/null 2>&1 && gsutil -m rsync -r -d /backups gs://\${GCLOUD_BUCKET}/\${GBUCKET_PREFIX}/'"
echo "Sync complete!"
