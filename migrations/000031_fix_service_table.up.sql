DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'services'
          AND column_name = 'highlights'
    ) THEN
        ALTER TABLE services
            ALTER COLUMN highlights SET DATA TYPE text;
    END IF;
END $$;