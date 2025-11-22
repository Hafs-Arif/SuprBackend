ALTER TABLE services DROP COLUMN IF EXISTS original_price;
ALTER TABLE services DROP COLUMN IF EXISTS discount_percentage;
ALTER TABLE services DROP COLUMN IF EXISTS pricing_model;
ALTER TABLE services DROP COLUMN IF EXISTS base_duration_minutes;
ALTER TABLE services DROP COLUMN IF EXISTS max_quantity;