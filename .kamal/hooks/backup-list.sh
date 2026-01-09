#!/usr/bin/env bash
# List backups (both local and GCS)

echo "=== Local Backups ==="
kamal accessory exec db_backup "ls -lh /backups/last/"
echo ""
echo "=== GCS Backups ==="
kamal accessory exec db_backup_gcs_sync "sh -c 'gcloud auth activate-service-account --key-file=/gcs-key/credentials.json > /dev/null 2>&1 && gsutil ls gs://\${GCLOUD_BUCKET}/\${GBUCKET_PREFIX}/last/'"
