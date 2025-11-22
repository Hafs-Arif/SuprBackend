-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- ========================================
-- STEP 1: CREATE ENUM TYPES
-- ========================================

-- Pricing model enum
DO $$ BEGIN
    CREATE TYPE pricing_model AS ENUM ('fixed', 'hourly', 'per_unit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Service option type enum
DO $$ BEGIN
    CREATE TYPE service_option_type AS ENUM ('select_single', 'select_multiple', 'quantity', 'text');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Service order status enum
DO $$ BEGIN
    CREATE TYPE service_order_status AS ENUM (
        'pending',
        'searching_provider', 
        'accepted', 
        'in_progress', 
        'completed', 
        'cancelled'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Service provider status enum
DO $$ BEGIN
    CREATE TYPE provider_status AS ENUM ('offline', 'available', 'busy');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ========================================
-- STEP 2: UPDATE service_categories TABLE
-- ========================================

-- Add missing columns to service_categories
ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE service_categories ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_service_categories_active ON service_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_service_categories_sort ON service_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_service_categories_deleted ON service_categories(deleted_at);

-- ========================================
-- STEP 3: CREATE service_tabs TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS service_tabs (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    banner_title VARCHAR(255),
    banner_desc VARCHAR(500),
    banner_image VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_tabs_category ON service_tabs(category_id);
CREATE INDEX IF NOT EXISTS idx_service_tabs_active ON service_tabs(is_active);
CREATE INDEX IF NOT EXISTS idx_service_tabs_sort ON service_tabs(sort_order);

-- ========================================
-- STEP 4: UPDATE/CREATE services TABLE
-- ========================================

-- Add missing columns to services table if it exists
ALTER TABLE services ADD COLUMN IF NOT EXISTS tab_id INTEGER;
ALTER TABLE services ADD COLUMN IF NOT EXISTS discount_percentage INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE services ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

-- Add foreign key constraint for tab_id
DO $$ BEGIN
    ALTER TABLE services ADD CONSTRAINT fk_services_tab 
    FOREIGN KEY (tab_id) REFERENCES service_tabs(id) ON DELETE SET NULL;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_tab ON services(tab_id);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_featured ON services(is_featured);
CREATE INDEX IF NOT EXISTS idx_services_deleted ON services(deleted_at);

-- ========================================
-- STEP 5: CREATE addon_services TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS addon_services (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    duration_minutes INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_addon_services_category ON addon_services(category_id);
CREATE INDEX IF NOT EXISTS idx_addon_services_active ON addon_services(is_active);
CREATE INDEX IF NOT EXISTS idx_addon_services_sort ON addon_services(sort_order);
CREATE INDEX IF NOT EXISTS idx_addon_services_deleted ON addon_services(deleted_at);

-- ========================================
-- STEP 6: CREATE service_options TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS service_options (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type service_option_type NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_options_service ON service_options(service_id);
CREATE INDEX IF NOT EXISTS idx_service_options_type ON service_options(type);

-- ========================================
-- STEP 7: CREATE service_option_choices TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS service_option_choices (
    id SERIAL PRIMARY KEY,
    option_id INTEGER NOT NULL REFERENCES service_options(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    price_modifier DECIMAL(10,2) DEFAULT 0,
    duration_modifier_minutes INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_option_choices_option ON service_option_choices(option_id);

-- ========================================
-- STEP 8: CREATE service_providers TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS service_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    photo VARCHAR(500),
    rating DECIMAL(3,2) DEFAULT 0,
    status provider_status DEFAULT 'offline',
    is_verified BOOLEAN DEFAULT FALSE,
    total_jobs INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    last_active TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_service_providers_user ON service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_status ON service_providers(status);
CREATE INDEX IF NOT EXISTS idx_service_providers_verified ON service_providers(is_verified);
CREATE INDEX IF NOT EXISTS idx_service_providers_rating ON service_providers(rating);

-- ========================================
-- STEP 9: CREATE service_orders TABLE  
-- ========================================

CREATE TABLE IF NOT EXISTS service_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(id) ON DELETE SET NULL,
    status service_order_status DEFAULT 'pending',
    address TEXT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    service_date TIMESTAMP NOT NULL,
    frequency VARCHAR(50) DEFAULT 'once',
    quantity_of_pros INTEGER NOT NULL DEFAULT 1,
    hours_of_service DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    subtotal DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    surge_fee DECIMAL(10,2) DEFAULT 0,
    platform_fee DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    coupon_code VARCHAR(50),
    notes TEXT,
    wallet_hold DECIMAL(10,2) DEFAULT 0,
    wallet_hold_id UUID,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add constraints
ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_quantity_of_pros;
ALTER TABLE service_orders ADD CONSTRAINT check_quantity_of_pros 
CHECK (quantity_of_pros >= 1 AND quantity_of_pros <= 10);

ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_hours_of_service;
ALTER TABLE service_orders ADD CONSTRAINT check_hours_of_service 
CHECK (hours_of_service >= 0.5 AND hours_of_service <= 24);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_service_orders_user ON service_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_service_orders_provider ON service_orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_service_orders_status ON service_orders(status);
CREATE INDEX IF NOT EXISTS idx_service_orders_date ON service_orders(service_date);
CREATE INDEX IF NOT EXISTS idx_service_orders_code ON service_orders(code);

-- ========================================
-- STEP 10: CREATE order_items TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(id),
    service_name VARCHAR(255) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    calculated_price DECIMAL(10,2) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    selected_options JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_service ON order_items(service_id);

-- ========================================
-- STEP 11: CREATE order_add_ons TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS order_add_ons (
    id SERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    addon_id INTEGER NOT NULL REFERENCES addon_services(id),
    title VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_add_ons_order ON order_add_ons(order_id);
CREATE INDEX IF NOT EXISTS idx_order_add_ons_addon ON order_add_ons(addon_id);

-- ========================================
-- STEP 12: CREATE ratings TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL UNIQUE REFERENCES service_orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES service_providers(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ratings_order ON ratings(order_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_provider ON ratings(provider_id);
CREATE INDEX IF NOT EXISTS idx_ratings_score ON ratings(score);

-- ========================================
-- STEP 13: CREATE surge_zones TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS surge_zones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surge_multiplier DECIMAL(3,2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_surge_zones_active ON surge_zones(is_active);
CREATE INDEX IF NOT EXISTS idx_surge_zones_valid ON surge_zones(valid_from, valid_to);

-- ========================================
-- STEP 14: CREATE provider_qualified_services JUNCTION TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS provider_qualified_services (
    provider_id UUID NOT NULL REFERENCES service_providers(id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (provider_id, service_id)
);

CREATE INDEX IF NOT EXISTS idx_pqs_provider ON provider_qualified_services(provider_id);
CREATE INDEX IF NOT EXISTS idx_pqs_service ON provider_qualified_services(service_id);

-- ========================================
-- STEP 15: ADD COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON TABLE service_categories IS 'Main service categories (e.g., Cleaning, Plumbing, etc.)';
COMMENT ON TABLE service_tabs IS 'Sub-categories/tabs under main categories';
COMMENT ON TABLE services IS 'Individual services offered';
COMMENT ON TABLE addon_services IS 'Optional add-on services';
COMMENT ON TABLE service_options IS 'Configurable options for services (e.g., room size)';
COMMENT ON TABLE service_option_choices IS 'Available choices for service options';
COMMENT ON TABLE service_providers IS 'Service provider profiles';
COMMENT ON TABLE service_orders IS 'Service booking orders';
COMMENT ON TABLE order_items IS 'Services included in an order';
COMMENT ON TABLE order_add_ons IS 'Add-ons included in an order';
COMMENT ON TABLE ratings IS 'Service ratings and reviews';
COMMENT ON TABLE surge_zones IS 'Dynamic surge pricing zones';
COMMENT ON TABLE provider_qualified_services IS 'Services that providers are qualified to perform';

COMMENT ON COLUMN service_orders.quantity_of_pros IS 'Number of professionals/workers needed (1-10)';
COMMENT ON COLUMN service_orders.hours_of_service IS 'Duration in hours (0.5-24)';