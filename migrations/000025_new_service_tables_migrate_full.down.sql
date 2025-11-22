-- +goose Down
ALTER TABLE service_orders
    DROP COLUMN IF EXISTS wallet_hold,
    DROP COLUMN IF EXISTS wallet_hold_id;

-- -- +goose Down
-- DROP TABLE IF EXISTS ratings CASCADE;
-- DROP TABLE IF EXISTS order_add_ons CASCADE;
-- DROP TABLE IF EXISTS order_items CASCADE;
-- DROP TABLE IF EXISTS service_orders CASCADE;
-- DROP TABLE IF EXISTS service_providers CASCADE;
-- DROP TABLE IF EXISTS service_option_choices CASCADE;
-- DROP TABLE IF EXISTS service_options CASCADE;
-- DROP TABLE IF EXISTS addon_services CASCADE;
-- DROP TABLE IF EXISTS services CASCADE;
-- DROP TABLE IF EXISTS service_tabs CASCADE;
-- DROP TABLE IF EXISTS service_categories CASCADE;
-- DROP TABLE IF EXISTS surge_zones CASCADE;
