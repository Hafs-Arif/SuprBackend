-- Add missing columns to service_categories if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='service_categories' AND column_name='banner_image') THEN
        ALTER TABLE service_categories ADD COLUMN banner_image VARCHAR(500);
    END IF;
END $$;

-- Add missing columns to service_orders if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='service_orders' AND column_name='quantity_of_pros') THEN
        ALTER TABLE service_orders ADD COLUMN quantity_of_pros INTEGER NOT NULL DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='service_orders' AND column_name='hours_of_service') THEN
        ALTER TABLE service_orders ADD COLUMN hours_of_service DECIMAL(5,2) NOT NULL DEFAULT 1.0;
    END IF;
END $$;

-- Add constraints if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_quantity_of_pros') THEN
        ALTER TABLE service_orders 
        ADD CONSTRAINT check_quantity_of_pros CHECK (quantity_of_pros >= 1 AND quantity_of_pros <= 10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_hours_of_service') THEN
        ALTER TABLE service_orders 
        ADD CONSTRAINT check_hours_of_service CHECK (hours_of_service >= 0.5 AND hours_of_service <= 24);
    END IF;
END $$;