-- =============================================
-- CLEAN MIGRATION: REPLACE OLD HOME SERVICES SCHEMA WITH NEW ONE
-- =============================================

-- 1. Enable required extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Drop all old home-services related tables (safe order + CASCADE)
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS service_orders CASCADE;
DROP TABLE IF EXISTS provider_qualified_services CASCADE;
DROP TABLE IF EXISTS service_option_choices CASCADE;
DROP TABLE IF EXISTS service_options CASCADE;
DROP TABLE IF EXISTS service_providers CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS service_categories CASCADE;
-- DROP TABLE IF EXISTS surge_zones CASCADE;  -- uncomment if you ever created it

-- 3. Create the new clean services table
CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    long_title VARCHAR(500),
    service_slug VARCHAR(255) UNIQUE NOT NULL,
    category_slug VARCHAR(255) NOT NULL,
    
    -- Content
    description TEXT,
    long_description TEXT,
    highlights TEXT[],
    whats_included TEXT[] NOT NULL DEFAULT '{}',
    terms_and_conditions TEXT[],
    
    -- Media
    banner_image VARCHAR(500),
    thumbnail VARCHAR(500),
    
    -- Metadata
    duration INTEGER, -- in minutes
    is_frequent BOOLEAN DEFAULT false,
    frequency VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    
    -- Pricing
    base_price DECIMAL(10,2),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_services_category_slug ON services(category_slug);
CREATE INDEX idx_services_service_slug ON services(service_slug);
CREATE INDEX idx_services_is_active ON services(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_services_is_available ON services(is_available) WHERE deleted_at IS NULL;
CREATE INDEX idx_services_deleted_at ON services(deleted_at);
CREATE INDEX idx_services_sort_order ON services(sort_order);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_services_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_services_updated_at ON services;
CREATE TRIGGER trigger_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW
    EXECUTE FUNCTION update_services_updated_at();