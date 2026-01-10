# Phase 4: Background Jobs & Solid Queue - Summary

## Overview
Phase 4 extracts background job classes and configures Solid Queue for the Oroshi engine.

## Status: ✅ COMPLETE

All job files and Solid Queue configuration are already in the correct locations for a Rails engine.

### Background Jobs (5 classes)
Location: `app/jobs/oroshi/`

1. **Oroshi::MailerJob** (2.5KB)
   - Recurring job for invoice email delivery
   - Runs every 10 minutes via Solid Queue scheduler
   - Handles batch sending and individual invoice notifications
   - Uses Oroshi::InvoiceMailer

2. **Oroshi::InvoiceJob** (1.8KB)
   - Generates invoice PDFs
   - Uses Printables::OroshiInvoice for PDF generation
   - Attaches PDFs to Active Storage

3. **Oroshi::InvoicePreviewJob** (1.2KB)
   - Generates preview PDFs for invoices
   - Used for testing/verification before sending

4. **Oroshi::OrderDocumentJob** (812B)
   - Generates order/packing slip PDFs
   - Uses Printables::OroshiOrderDocument

5. **Oroshi::SupplyCheckJob** (728B)
   - Generates supply check PDFs
   - Uses Printables::SupplyCheck

All jobs properly namespaced and inherit from `ApplicationJob`.

### Recurring Tasks Configuration
Location: `config/recurring.yml`

```yaml
production:
  oroshi_mail_check_and_send:
    class: Oroshi::MailerJob
    schedule: "*/10 * * * * Asia/Tokyo"
    description: "Check for Oroshi invoice mail that needs to be sent"
```

- Runs every 10 minutes
- Uses Asia/Tokyo timezone
- Automatically processed by Solid Queue Scheduler

### Solid Queue Database Schemas
Location: `db/`

- **queue_schema.rb** (6.1KB) - Solid Queue tables
  - solid_queue_jobs
  - solid_queue_scheduled_executions
  - solid_queue_ready_executions
  - solid_queue_claimed_executions
  - solid_queue_blocked_executions
  - solid_queue_failed_executions
  - solid_queue_pauses
  - solid_queue_processes
  - solid_queue_semaphores
  - solid_queue_recurring_tasks

- **cache_schema.rb** (643B) - Solid Cache tables
  - solid_cache_entries

- **cable_schema.rb** (578B) - Solid Cable tables
  - solid_cable_messages

### Engine Configuration

Already configured in `lib/oroshi/engine.rb`:

```ruby
# Configure Solid Queue
initializer "oroshi.solid_queue" do |app|
  # Configure production queue connection
  if Rails.env.production?
    config.solid_queue.connects_to = {
      database: { writing: :queue }
    }
  end
end
```

Similar initializers exist for Solid Cache and Solid Cable.

### Multi-Database Setup

The engine expects 4 PostgreSQL databases in production:
1. **oroshi_production** - Main application data
2. **oroshi_production_queue** - Solid Queue jobs
3. **oroshi_production_cache** - Solid Cache entries
4. **oroshi_production_cable** - Solid Cable messages

### Job Dependencies

Jobs depend on:
- **Mailer**: Oroshi::InvoiceMailer (Phase 6 - Authentication will extract)
- **PDFs**: Printables classes (Phase 5 will extract)
- **Models**: Oroshi::Invoice, Oroshi::InvoiceMailer, etc. (already extracted in Phase 1)
- **Active Storage**: For PDF attachments

### Process Architecture (Production)

Solid Queue runs 4 processes:
1. **Supervisor** - Manages worker processes
2. **Dispatcher** - Distributes jobs to workers
3. **Worker** - Executes jobs
4. **Scheduler** - Handles recurring tasks

Configured via `config/recurring.yml` which is automatically loaded by the engine.

### Testing

Job tests are in `test/jobs/oroshi/`:
- mailer_job_test.rb
- invoice_job_test.rb
- etc.

Tests use `ActiveJob::TestHelper` for enqueuing/performing jobs.

## Verification

Jobs are automatically included in the gem because:
- Located in `app/jobs/oroshi/` → standard Rails engine location
- Inherit from `ApplicationJob` → will use host app's job configuration
- Properly namespaced → `Oroshi::MailerJob`, etc.

Solid Queue configuration:
- Engine loads Solid gems first (critical for Railties registration)
- `config/recurring.yml` loaded by engine initializer
- Database schemas provided for host app to load

## Next Steps

Phase 5 will extract the PDF generation library (Printables) that these jobs depend on.
