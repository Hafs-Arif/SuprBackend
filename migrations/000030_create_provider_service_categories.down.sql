-- migrations/XXXXXX_create_provider_service_categories.down.sql

-- Drop trigger first
DROP TRIGGER IF EXISTS trigger_provider_service_categories_updated_at 
    ON provider_service_categories;

-- Drop function
DROP FUNCTION IF EXISTS update_provider_service_categories_updated_at();

-- Drop table (this will also drop indexes and constraints)
DROP TABLE IF EXISTS provider_service_categories;