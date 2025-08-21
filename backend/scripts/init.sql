-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create database if it doesn't exist
-- (This is handled by POSTGRES_DB environment variable)

-- Set timezone
SET timezone = 'Asia/Tashkent';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE wedy_dev TO dev;