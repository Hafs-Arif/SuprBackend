-- Drop tables in reverse order (respecting foreign key constraints)
DROP TABLE IF EXISTS provider_qualified_services;
DROP TABLE IF EXISTS surge_zones;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS order_add_ons;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS service_orders;
DROP TABLE IF EXISTS service_providers;
DROP TABLE IF EXISTS service_option_choices;
DROP TABLE IF EXISTS service_options;
DROP TABLE IF EXISTS addon_services;
DROP TABLE IF EXISTS service_tabs;

-- Remove columns from services (if you want to revert)
ALTER TABLE services DROP COLUMN IF EXISTS tab_id;
ALTER TABLE services DROP COLUMN IF EXISTS discount_percentage;
ALTER TABLE services DROP COLUMN IF EXISTS is_featured;
ALTER TABLE services DROP COLUMN IF EXISTS sort_order;
ALTER TABLE services DROP COLUMN IF EXISTS deleted_at;

-- Remove columns from service_categories
ALTER TABLE service_categories DROP COLUMN IF EXISTS sort_order;
ALTER TABLE service_categories DROP COLUMN IF EXISTS deleted_at;

-- Drop enum types
DROP TYPE IF EXISTS provider_status;
DROP TYPE IF EXISTS service_order_status;
DROP TYPE IF EXISTS service_option_type;
DROP TYPE IF EXISTS pricing_model;