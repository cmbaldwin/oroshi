# frozen_string_literal: true

namespace :backup do
  desc 'Create manual database backup'
  task :create do
    sh '.kamal/hooks/backup-create.sh'
  end

  desc 'List available backups'
  task :list do
    sh '.kamal/hooks/backup-list.sh'
  end

  desc 'Restore from latest local backup (DANGEROUS!)'
  task :restore do
    sh '.kamal/hooks/backup-restore.sh'
  end

  desc 'Restore from GCS backup (DANGEROUS!)'
  task :restore_from_gcs do
    sh '.kamal/hooks/backup-restore-from-gcs.sh'
  end

  desc 'Check backup service status'
  task :status do
    sh '.kamal/hooks/backup-status.sh'
  end

  desc 'Restart backup services'
  task :restart do
    puts 'Restarting backup services...'
    sh 'kamal accessory reboot db_backup'
    sh 'kamal accessory reboot db_backup_gcs_sync'
    puts 'Services restarted!'
  end

  desc 'Download latest backup to local machine'
  task :download do
    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    filename = "funabiki-backup-#{timestamp}.sql.gz"

    puts 'Downloading latest backup...'
    sh "kamal accessory exec db_backup 'cat /backups/last/*-latest.sql.gz' > #{filename}"
    puts "Backup saved to: #{filename}"
  end

  desc 'Sync backups to GCS now'
  task :sync_now do
    puts 'Syncing backups to GCS...'
    sh %(kamal accessory exec db_backup_gcs_sync "sh -c 'gcloud auth activate-service-account --key-file=/gcs-key/credentials.json > /dev/null 2>&1 && gsutil -m rsync -r -d /backups gs://\\${GCLOUD_BUCKET}/\\${GBUCKET_PREFIX}/'")
    puts 'Sync complete!'
  end
end
