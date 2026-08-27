-- Bynovix AI: Enable required PostgreSQL extensions
-- Safe to run multiple times

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
