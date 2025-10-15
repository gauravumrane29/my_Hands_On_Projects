-- Create users table
CREATE TABLE users (
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
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Insert sample data
INSERT INTO users (username, email, first_name, last_name, is_active) VALUES
('admin', 'admin@example.com', 'Admin', 'User', true),
('john_doe', 'john.doe@example.com', 'John', 'Doe', true),
('jane_smith', 'jane.smith@example.com', 'Jane', 'Smith', true),
('bob_wilson', 'bob.wilson@example.com', 'Bob', 'Wilson', false),
('alice_brown', 'alice.brown@example.com', 'Alice', 'Brown', true);