ALTER TABLE service_categories DROP COLUMN IF EXISTS banner_image;
ALTER TABLE service_orders DROP COLUMN IF EXISTS quantity_of_pros;
ALTER TABLE service_orders DROP COLUMN IF EXISTS hours_of_service;
ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_quantity_of_pros;
ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_hours_of_service;