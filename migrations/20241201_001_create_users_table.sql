-- Example Migration: Create Users Table
-- File: 20241201_001_create_users_table.sql
-- Created: 2024-12-01

BEGIN;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Record migration
INSERT INTO schema_migrations (version) VALUES ('20241201_001_create_users_table');

COMMIT;