DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'service_categories'
          AND column_name = 'highlights'
    ) THEN
        ALTER TABLE service_categories
            ADD COLUMN highlights text[];
    END IF;
END $$;
