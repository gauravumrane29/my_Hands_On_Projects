#!/bin/bash
# Database initialization script
set -e

# This script runs when PostgreSQL starts for the first time

echo "🗄️  Initializing database..."

# Create database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create extensions
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Create users table (if not exists via Flyway)
    CREATE TABLE IF NOT EXISTS users (
        id BIGSERIAL PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Create indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
    CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

    -- Insert sample data only if table is empty
    INSERT INTO users (username, email, first_name, last_name, is_active)
    SELECT * FROM (VALUES 
        ('admin', 'admin@example.com', 'Admin', 'User', true),
        ('john_doe', 'john.doe@example.com', 'John', 'Doe', true),
        ('jane_smith', 'jane.smith@example.com', 'Jane', 'Smith', true),
        ('bob_wilson', 'bob.wilson@example.com', 'Bob', 'Wilson', false),
        ('alice_brown', 'alice.brown@example.com', 'Alice', 'Brown', true)
    ) AS new_users(username, email, first_name, last_name, is_active)
    WHERE NOT EXISTS (SELECT 1 FROM users LIMIT 1);

    -- Create audit table for tracking changes
    CREATE TABLE IF NOT EXISTS user_audit (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT,
        action VARCHAR(20) NOT NULL,
        old_data JSONB,
        new_data JSONB,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50)
    );

    -- Grant permissions
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$POSTGRES_USER";
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$POSTGRES_USER";
EOSQL

echo "✅ Database initialization complete"