#!/bin/bash

# Run Laundry Service migrations
# This script assumes your database is already running and accessible

# Set database URL (modify these values to match your database)
# Format: postgres://user:password@host:port/database?sslmode=disable

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-supr_backend}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

# Construct the database URL for migrate
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

echo "==================================="
echo "Laundry Service Migration Script"
echo "==================================="
echo ""
echo "Database URL: postgres://${DB_USER}:***@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"
echo ""

# Run migrations
echo "Running migrations..."
migrate -path ./migrations -database "$DB_URL" up

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migrations completed successfully!"
    echo ""
    echo "Tables created:"
    echo "  - laundry_service_catalog"
    echo "  - laundry_service_products"
    echo "  - laundry_orders"
    echo "  - laundry_order_items"
    echo "  - laundry_pickups"
    echo "  - laundry_deliveries"
    echo "  - laundry_issues"
else
    echo ""
    echo "❌ Migration failed!"
    echo "Please check your database connection and try again."
    exit 1
fi
