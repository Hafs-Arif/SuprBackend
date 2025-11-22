-- Add new user status for service provider approval
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('active', 'suspended', 'banned', 'pending_verification');
    END IF;
END $$;

ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'pending_approval';

-- Add service provider wallet type
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wallet_type') THEN
        CREATE TYPE wallet_type AS ENUM ('rider', 'driver');
    END IF;
END $$;

ALTER TYPE wallet_type ADD VALUE IF NOT EXISTS 'service_provider';

-- Create service provider profiles table
CREATE TABLE IF NOT EXISTS service_provider_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255),
    description TEXT,
    service_category VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending_approval',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_docs JSONB,
    rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    working_hours JSONB,
    service_areas JSONB,
    hourly_rate DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE INDEX idx_sp_user_id ON service_provider_profiles(user_id);
CREATE INDEX idx_sp_category ON service_provider_profiles(service_category);
CREATE INDEX idx_sp_status ON service_provider_profiles(status);
CREATE INDEX idx_sp_is_available ON service_provider_profiles(is_available);