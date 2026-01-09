-- These will be run after the main database (POSTGRES_DB) is created
-- and after the user (POSTGRES_USER) is created with password (POSTGRES_PASSWORD)

-- Create additional databases for Solid adapters
CREATE DATABASE oroshi_production_cache;
CREATE DATABASE oroshi_production_queue;
CREATE DATABASE oroshi_production_cable;

-- Grant all privileges to our user for these additional databases
GRANT ALL PRIVILEGES ON DATABASE oroshi_production_cache TO oroshi;
GRANT ALL PRIVILEGES ON DATABASE oroshi_production_queue TO oroshi;
GRANT ALL PRIVILEGES ON DATABASE oroshi_production_cable TO oroshi;
