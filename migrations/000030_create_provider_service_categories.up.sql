-- migrations/XXXXXX_create_provider_service_categories.up.sql

CREATE TABLE IF NOT EXISTS provider_service_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL,
    category_slug VARCHAR(255) NOT NULL,
    expertise_level VARCHAR(50) DEFAULT 'beginner',
    years_of_experience INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Statistics
    completed_jobs INT DEFAULT 0,
    total_earnings DECIMAL(12,2) DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INT DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key constraint
    CONSTRAINT fk_provider_service_categories_provider
        FOREIGN KEY (provider_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE,
    
    -- Prevent duplicate category assignments per provider
    CONSTRAINT uq_provider_category 
        UNIQUE (provider_id, category_slug),
    
    -- Validate expertise level
    CONSTRAINT chk_expertise_level 
        CHECK (expertise_level IN ('beginner', 'intermediate', 'expert')),
    
    -- Validate ratings
    CONSTRAINT chk_average_rating 
        CHECK (average_rating >= 0 AND average_rating <= 5),
    
    CONSTRAINT chk_total_ratings 
        CHECK (total_ratings >= 0),
    
    CONSTRAINT chk_completed_jobs 
        CHECK (completed_jobs >= 0),
    
    CONSTRAINT chk_total_earnings 
        CHECK (total_earnings >= 0),
    
    CONSTRAINT chk_years_of_experience 
        CHECK (years_of_experience >= 0)
);

-- Indexes for common queries
CREATE INDEX idx_provider_service_categories_provider_id 
    ON provider_service_categories(provider_id);

CREATE INDEX idx_provider_service_categories_category_slug 
    ON provider_service_categories(category_slug);

CREATE INDEX idx_provider_service_categories_is_active 
    ON provider_service_categories(is_active);

-- Composite index for finding active providers by category
CREATE INDEX idx_provider_service_categories_category_active 
    ON provider_service_categories(category_slug, is_active) 
    WHERE is_active = TRUE;

-- Index for sorting by rating (finding best providers)
CREATE INDEX idx_provider_service_categories_rating 
    ON provider_service_categories(category_slug, average_rating DESC) 
    WHERE is_active = TRUE;

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_provider_service_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_provider_service_categories_updated_at
    BEFORE UPDATE ON provider_service_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_provider_service_categories_updated_at();

-- Add comments for documentation
COMMENT ON TABLE provider_service_categories IS 'Links service providers to categories they can handle';
COMMENT ON COLUMN provider_service_categories.expertise_level IS 'Provider skill level: beginner, intermediate, expert';
COMMENT ON COLUMN provider_service_categories.average_rating IS 'Average rating from 0-5 for this category';