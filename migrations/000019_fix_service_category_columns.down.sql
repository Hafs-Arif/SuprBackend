-- Remove added columns
ALTER TABLE service_categories DROP COLUMN IF EXISTS highlights;
ALTER TABLE service_categories DROP COLUMN IF EXISTS banner_image;
ALTER TABLE service_categories DROP COLUMN IF EXISTS icon_url;

ALTER TABLE service_tabs DROP COLUMN IF EXISTS banner_title;
ALTER TABLE service_tabs DROP COLUMN IF EXISTS banner_desc;
ALTER TABLE service_tabs DROP COLUMN IF EXISTS banner_image;

ALTER TABLE services DROP COLUMN IF EXISTS max_quantity;
ALTER TABLE services DROP COLUMN IF EXISTS sort_order;

ALTER TABLE service_orders DROP COLUMN IF EXISTS quantity_of_pros;
ALTER TABLE service_orders DROP COLUMN IF EXISTS hours_of_service;

-- Remove constraints
ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_quantity_of_pros;
ALTER TABLE service_orders DROP CONSTRAINT IF EXISTS check_hours_of_service;