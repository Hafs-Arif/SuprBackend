-- Addons table for service add-ons
CREATE TABLE IF NOT EXISTS addons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    addon_slug VARCHAR(255) UNIQUE NOT NULL,
    category_slug VARCHAR(255) NOT NULL,
    
    -- Content
    description TEXT,
    whats_included TEXT[],
    notes TEXT[],
    
    -- Media
    image VARCHAR(500),
    
    -- Pricing
    price DECIMAL(10,2) NOT NULL,
    strikethrough_price DECIMAL(10,2),
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_addons_category_slug ON addons(category_slug);
CREATE INDEX idx_addons_addon_slug ON addons(addon_slug);
CREATE INDEX idx_addons_is_active ON addons(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_addons_is_available ON addons(is_available) WHERE deleted_at IS NULL;
CREATE INDEX idx_addons_deleted_at ON addons(deleted_at);
CREATE INDEX idx_addons_sort_order ON addons(sort_order);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_addons_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_addons_updated_at
    BEFORE UPDATE ON addons
    FOR EACH ROW
    EXECUTE FUNCTION update_addons_updated_at();