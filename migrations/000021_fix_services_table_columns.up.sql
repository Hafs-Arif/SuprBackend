-- Add all missing columns to services table
ALTER TABLE services ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2);
ALTER TABLE services ADD COLUMN IF NOT EXISTS discount_percentage INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS pricing_model VARCHAR(50) NOT NULL DEFAULT 'fixed';
ALTER TABLE services ADD COLUMN IF NOT EXISTS base_duration_minutes INTEGER;
ALTER TABLE services ADD COLUMN IF NOT EXISTS max_quantity INTEGER DEFAULT 1;

-- Update existing null pricing_model to 'fixed'
UPDATE services SET pricing_model = 'fixed' WHERE pricing_model IS NULL;

-- Add check constraint for pricing_model
DO $$ 
BEGIN
    ALTER TABLE services DROP CONSTRAINT IF EXISTS check_pricing_model;
    ALTER TABLE services ADD CONSTRAINT check_pricing_model 
    CHECK (pricing_model IN ('fixed', 'hourly', 'per_unit'));
EXCEPTION
    WHEN others THEN null;
END $$;

-- Add comments
COMMENT ON COLUMN services.original_price IS 'Original price before discount';
COMMENT ON COLUMN services.discount_percentage IS 'Discount percentage (0-100)';
COMMENT ON COLUMN services.pricing_model IS 'Pricing model: fixed, hourly, or per_unit';
COMMENT ON COLUMN services.base_duration_minutes IS 'Base service duration in minutes';
COMMENT ON COLUMN services.max_quantity IS 'Maximum quantity that can be ordered';