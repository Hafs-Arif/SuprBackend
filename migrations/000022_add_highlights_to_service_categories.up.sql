-- 20250222_add_highlights_to_service_categories.sql

ALTER TABLE service_categories
    ADD COLUMN IF NOT EXISTS highlights TEXT[];
