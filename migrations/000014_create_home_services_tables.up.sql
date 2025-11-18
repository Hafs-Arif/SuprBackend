-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Ensure wallet enum types exist (they should from your existing system)
-- If they don't exist, create them
DO $$ BEGIN
    CREATE TYPE wallet_type AS ENUM ('rider', 'driver', 'platform', 'service_provider');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type AS ENUM ('credit', 'debit', 'refund', 'hold', 'release', 'transfer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled', 'held', 'released');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


-- Service Categories (Main categories like Women's Salon, Men's Salon)
CREATE TABLE IF NOT EXISTS service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    banner_image VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    highlights TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service Tabs (Subcategories like Bestsellers, Hair, Nails)
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_services_category ON "services"("category_id");
CREATE INDEX idx_services_active ON "services"("is_active");

-- Services (Individual services)
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    tab_id INTEGER NOT NULL REFERENCES service_tabs(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image_url VARCHAR(500),
    base_price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    discount_percentage INTEGER DEFAULT 0,
    pricing_model VARCHAR(50) NOT NULL DEFAULT 'fixed',
    base_duration_minutes INTEGER NOT NULL,
    max_quantity INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_pricing_model CHECK (pricing_model IN ('fixed', 'hourly', 'per_unit'))
);

-- Service Add-ons (Optional extras)
CREATE TABLE IF NOT EXISTS service_addons (
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service Options (Customization options for services)
CREATE TABLE IF NOT EXISTS service_options (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_option_type CHECK (type IN ('select_single', 'select_multiple', 'quantity', 'text'))
);
CREATE INDEX idx_service_options_service ON "service_options"("service_id");

-- Service Option Choices
CREATE TABLE IF NOT EXISTS service_option_choices (
    id SERIAL PRIMARY KEY,
    option_id INTEGER NOT NULL REFERENCES service_options(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    price_modifier DECIMAL(10,2) DEFAULT 0,
    duration_modifier_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_service_option_choices_option ON "service_option_choices"("option_id");


-- SERVICE PROVIDERS --
CREATE TABLE IF NOT EXISTS service_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    photo VARCHAR(500),
    rating DECIMAL(3,2) DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'offline',
    location GEOGRAPHY(Point, 4326),
    is_verified BOOLEAN DEFAULT FALSE,
    total_jobs INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_provider_status CHECK (status IN ('available', 'busy', 'offline'))
);
CREATE INDEX idx_service_providers_user ON "service_providers"("user_id");
CREATE INDEX idx_service_providers_status ON "service_providers"("status");
CREATE INDEX idx_service_providers_location ON "service_providers" USING GIST ("location");

CREATE TABLE IF NOT EXISTS provider_qualified_services (
    provider_id UUID NOT NULL REFERENCES service_providers(id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (provider_id, service_id)
);
CREATE INDEX idx_pqs_service ON "provider_qualified_services"("service_id");


-- Service Orders
CREATE TABLE IF NOT EXISTS service_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    address TEXT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    service_date TIMESTAMP NOT NULL,
    frequency VARCHAR(50) DEFAULT 'once',
    subtotal DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    surge_fee DECIMAL(10,2) DEFAULT 0,
    platform_fee DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    coupon_code VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    CONSTRAINT check_order_status CHECK (status IN ('pending', 'searching', 'accepted', 'in_progress', 'completed', 'cancelled', 'rejected')),
    CONSTRAINT check_frequency CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly'))
);
CREATE INDEX idx_service_orders_user ON "service_orders"("user_id");
CREATE INDEX idx_service_orders_provider ON "service_orders"("provider_id");
CREATE INDEX idx_service_orders_status ON "service_orders"("status");
CREATE INDEX idx_service_orders_created ON "service_orders"("created_at");

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    service_name VARCHAR(255) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    calculated_price DECIMAL(10,2) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    selected_options JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_order_items_order ON "order_items"("order_id");

CREATE TABLE IF NOT EXISTS order_addons (
    id SERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    addon_id INTEGER NOT NULL REFERENCES service_addons(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- RATINGS --
CREATE TABLE "ratings" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "order_id" UUID NOT NULL UNIQUE,
    "user_id" UUID NOT NULL,
    "provider_id" UUID NOT NULL,
    "score" INT NOT NULL CHECK (score >= 1 AND score <= 5),
    "comment" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_order FOREIGN KEY("order_id") REFERENCES "service_orders"("id"),
    CONSTRAINT fk_user FOREIGN KEY("user_id") REFERENCES "users"("id"),
    CONSTRAINT fk_provider FOREIGN KEY("provider_id") REFERENCES "service_providers"("id")
);
CREATE INDEX idx_ratings_provider ON "ratings"("provider_id");
CREATE INDEX idx_ratings_user ON "ratings"("user_id");


-- SURGE ZONES (optional) --
CREATE TABLE "surge_zones" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL,
    "zone" GEOGRAPHY(Polygon, 4326) NOT NULL,
    "surge_multiplier" DECIMAL(3, 2) NOT NULL DEFAULT 1.00,
    "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
    "valid_from" TIMESTAMPTZ,
    "valid_to" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_surge_zones_zone ON "surge_zones" USING GIST ("zone");
CREATE INDEX idx_surge_zones_active ON "surge_zones"("is_active");
-- Create Indexes for better performance
CREATE INDEX idx_service_tabs_category ON service_tabs(category_id);
CREATE INDEX idx_services_category ON services(category_id);
CREATE INDEX idx_services_tab ON services(tab_id);
CREATE INDEX idx_services_active_featured ON services(is_active, is_featured);
CREATE INDEX idx_service_addons_category ON service_addons(category_id);
CREATE INDEX idx_service_options_service ON service_options(service_id);
CREATE INDEX idx_service_option_choices_option ON service_option_choices(option_id);
CREATE INDEX idx_service_providers_status ON service_providers(status);
CREATE INDEX idx_service_providers_location ON service_providers USING GIST(location);
CREATE INDEX idx_service_orders_user ON service_orders(user_id);
CREATE INDEX idx_service_orders_provider ON service_orders(provider_id);
CREATE INDEX idx_service_orders_status ON service_orders(status);
CREATE INDEX idx_service_orders_date ON service_orders(service_date);
CREATE INDEX idx_service_order_items_order ON service_order_items(order_id);
CREATE INDEX idx_order_addons_order ON order_addons(order_id);

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON service_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_tabs_updated_at BEFORE UPDATE ON service_tabs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_addons_updated_at BEFORE UPDATE ON service_addons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_options_updated_at BEFORE UPDATE ON service_options FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_option_choices_updated_at BEFORE UPDATE ON service_option_choices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_providers_updated_at BEFORE UPDATE ON service_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample Data (Optional - for testing)
INSERT INTO service_categories (name, description, icon_url, banner_image, highlights, sort_order) VALUES
('Women''s Salon', 'Professional beauty services for women', '/icons/womens-salon.svg', '/banners/womens-salon.jpg', '{"Professional", "Quality Products", "Experienced Staff"}', 1),
('Men''s Salon', 'Grooming services for men', '/icons/mens-salon.svg', '/banners/mens-salon.jpg', '{"Quick Service", "Expert Barbers"}', 2),
('Spa & Massage', 'Relaxation and wellness services', '/icons/spa.svg', '/banners/spa.jpg', '{"Relaxing", "Therapeutic"}', 3);

INSERT INTO service_tabs (category_id, name, description, banner_title, sort_order) VALUES
(1, 'Bestsellers', 'Most popular women''s salon services', 'Iconic Favorites', 1),
(1, 'Hair', 'Hair care and styling', 'Beautiful Hair', 2),
(1, 'Nails', 'Manicure and pedicure services', 'Perfect Nails', 3),
(2, 'Haircut', 'Men''s haircuts and styling', 'Fresh Look', 1),
(2, 'Beard', 'Beard grooming services', 'Perfect Trim', 2);

INSERT INTO services (category_id, tab_id, name, description, base_price, original_price, discount_percentage, base_duration_minutes) VALUES
(1, 1, 'Classic Mani-Pedi', 'Professional manicure and pedicure combo', 109.00, 180.00, 39, 60),
(1, 2, 'Hair Coloring', 'Full hair color with premium products', 1500.00, 2000.00, 25, 120),
(1, 3, 'Gel Polish', 'Long-lasting gel nail polish', 599.00, 799.00, 25, 45),
(2, 4, 'Classic Haircut', 'Professional men''s haircut', 299.00, 399.00, 25, 30),
(2, 5, 'Beard Trim & Style', 'Expert beard grooming', 199.00, 299.00, 33, 20);

INSERT INTO service_addons (category_id, title, description, price, duration_minutes, sort_order) VALUES
(1, 'Hair Spa Treatment', 'Deep conditioning hair treatment', 99.00, 15, 1),
(1, 'Nail Art', 'Custom nail art design', 149.00, 20, 2),
(2, 'Head Massage', 'Relaxing head and scalp massage', 99.00, 10, 1);