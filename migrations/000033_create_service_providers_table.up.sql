-- Create service_providers table for home services
CREATE TABLE IF NOT EXISTS service_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    photo VARCHAR(500),
    rating DECIMAL(3,2) DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'offline',
    location GEOMETRY(Point, 4326),
    is_verified BOOLEAN DEFAULT false,
    total_jobs INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    last_active TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_provider_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_service_providers_user_id ON service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_status ON service_providers(status);
CREATE INDEX IF NOT EXISTS idx_service_providers_is_verified ON service_providers(is_verified);
CREATE INDEX IF NOT EXISTS idx_service_providers_rating ON service_providers(rating DESC);
CREATE INDEX IF NOT EXISTS idx_service_providers_location ON service_providers USING GIST(location);
