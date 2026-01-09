#!/usr/bin/env bash
# Check backup service status

echo "=== Backup Service Status ==="
kamal accessory details db_backup
echo ""
echo "=== GCS Sync Service Status ==="
kamal accessory details db_backup_gcs_sync
echo ""
echo "=== Recent Backups ==="
kamal accessory exec db_backup "ls -lht /backups/last/ | head -10"
