#!/bin/bash

# Home Services Database Seeding Script
# Usage: ./seed_home_services.sh [database_url]
# Example: ./seed_home_services.sh "postgresql://user:password@localhost:5432/dbname"

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database connection
DB_URL="${1:-${DATABASE_URL}}"

if [ -z "$DB_URL" ]; then
    echo -e "${RED}Error: Database URL not provided${NC}"
    echo "Usage: $0 [database_url]"
    echo "Or set DATABASE_URL environment variable"
    exit 1
fi

echo -e "${GREEN}Starting database seeding...${NC}\n"

# Function to execute SQL
execute_sql() {
    psql "$DB_URL" -c "$1" > /dev/null 2>&1
}

# Function to execute SQL from heredoc
execute_sql_block() {
    psql "$DB_URL" <<EOF
$1
EOF
}

echo -e "${YELLOW}[1/6] Seeding Services...${NC}"
execute_sql_block "
-- AC Services
INSERT INTO services (title, long_title, service_slug, category_slug, description, long_description, 
    highlights, whats_included, base_price, duration, is_frequent, frequency, sort_order, is_active, is_available,
    banner_image, thumbnail)
VALUES 
('AC Installation', 'Professional AC Installation Service', 'ac-installation', 'ac-services',
    'Expert installation of split and window AC units',
    'Our certified technicians provide professional AC installation with proper mounting, electrical connections, and testing.',
    ARRAY['Certified technicians', 'Same-day service available', '90-day warranty'],
    ARRAY['Unit mounting', 'Electrical wiring', 'Gas charging', 'Performance testing', 'Warranty certificate'],
    4500.00, 180, false, null, 1, true, true,
    'https://example.com/ac-installation.jpg', 'https://example.com/ac-installation-thumb.jpg'),

('AC Repair', 'AC Repair & Maintenance', 'ac-repair', 'ac-services',
    'Complete AC repair and troubleshooting',
    'Fix all types of AC problems including cooling issues, water leakage, noise, and electrical faults.',
    ARRAY['Quick diagnosis', 'Genuine spare parts', '30-day service warranty'],
    ARRAY['Problem diagnosis', 'Repair work', 'Gas refilling if needed', 'Performance check'],
    800.00, 90, true, 'Monthly during summer', 2, true, true,
    'https://example.com/ac-repair.jpg', 'https://example.com/ac-repair-thumb.jpg'),

('AC Service', 'AC Deep Cleaning & Service', 'ac-service', 'ac-services',
    'Comprehensive AC cleaning and servicing',
    'Deep cleaning of AC unit including filters, coils, and drainage with foam jet technology.',
    ARRAY['Foam jet cleaning', 'Anti-bacterial treatment', 'Improves cooling efficiency'],
    ARRAY['Filter cleaning', 'Coil cleaning', 'Drain cleaning', 'Gas pressure check', 'Cooling test'],
    599.00, 60, true, 'Every 3 months', 3, true, true,
    'https://example.com/ac-service.jpg', 'https://example.com/ac-service-thumb.jpg'),

-- Plumbing Services
('Tap Repair', 'Tap Installation & Repair', 'tap-repair', 'plumbing',
    'Fix leaky taps and install new ones',
    'Professional tap repair and installation service for kitchen and bathroom.',
    ARRAY['Same-day service', 'Quality replacement parts', 'Leak-free guarantee'],
    ARRAY['Tap inspection', 'Washer replacement', 'Installation if needed', 'Water flow test'],
    299.00, 30, true, 'As needed', 1, true, true,
    'https://example.com/tap-repair.jpg', 'https://example.com/tap-repair-thumb.jpg'),

('Pipe Repair', 'Pipeline Repair & Replacement', 'pipe-repair', 'plumbing',
    'Fix leaking or broken pipes',
    'Expert repair and replacement of water supply and drainage pipes.',
    ARRAY['Emergency service', 'Minimal wall damage', 'Durable repairs'],
    ARRAY['Leak detection', 'Pipe repair/replacement', 'Wall restoration', 'Pressure testing'],
    899.00, 120, false, null, 2, true, true,
    'https://example.com/pipe-repair.jpg', 'https://example.com/pipe-repair-thumb.jpg'),

('Bathroom Fitting', 'Complete Bathroom Fitting Service', 'bathroom-fitting', 'plumbing',
    'Install bathroom fixtures and fittings',
    'Professional installation of all bathroom fixtures including sink, toilet, shower, and accessories.',
    ARRAY['Expert installation', 'Quality fittings', 'Waterproofing included'],
    ARRAY['Fixture installation', 'Plumbing connections', 'Drainage setup', 'Leak testing'],
    2500.00, 240, false, null, 3, true, true,
    'https://example.com/bathroom-fitting.jpg', 'https://example.com/bathroom-fitting-thumb.jpg'),

-- Electrical Services
('Fan Installation', 'Ceiling & Wall Fan Installation', 'fan-installation', 'electrical',
    'Professional fan installation service',
    'Safe and secure installation of ceiling fans, exhaust fans, and wall-mounted fans.',
    ARRAY['Certified electricians', 'Proper wiring', 'Balance testing'],
    ARRAY['Fan mounting', 'Electrical wiring', 'Switch installation', 'Balance check'],
    399.00, 45, false, null, 1, true, true,
    'https://example.com/fan-installation.jpg', 'https://example.com/fan-installation-thumb.jpg'),

('Wiring Repair', 'Electrical Wiring & Circuit Repair', 'wiring-repair', 'electrical',
    'Fix electrical wiring issues',
    'Professional repair of faulty wiring, short circuits, and electrical connections.',
    ARRAY['Safety certified', 'Emergency available', 'Quality materials'],
    ARRAY['Circuit diagnosis', 'Wire replacement', 'Connection repair', 'Safety testing'],
    799.00, 90, false, null, 2, true, true,
    'https://example.com/wiring-repair.jpg', 'https://example.com/wiring-repair-thumb.jpg'),

('Switch & Socket', 'Switch & Socket Installation/Repair', 'switch-socket', 'electrical',
    'Install or repair switches and sockets',
    'Installation and repair of electrical switches, sockets, and modular plates.',
    ARRAY['Modern switches', 'Safe installation', 'Neat finish'],
    ARRAY['Old switch removal', 'New installation', 'Wiring check', 'Testing'],
    249.00, 30, true, 'As needed', 3, true, true,
    'https://example.com/switch-socket.jpg', 'https://example.com/switch-socket-thumb.jpg'),

-- Painting Services  
('Interior Painting', 'Professional Interior Painting', 'interior-painting', 'painting',
    'Transform your home with fresh paint',
    'Professional interior painting service with premium paints and expert application.',
    ARRAY['Premium paints', 'Furniture covering', 'Clean finish'],
    ARRAY['Surface preparation', 'Primer application', '2 coats of paint', 'Cleanup'],
    15000.00, 480, false, 'Every 2-3 years', 1, true, true,
    'https://example.com/interior-painting.jpg', 'https://example.com/interior-painting-thumb.jpg'),

('Exterior Painting', 'Exterior Wall Painting Service', 'exterior-painting', 'painting',
    'Protect and beautify your exterior walls',
    'Weather-resistant exterior painting with proper surface preparation and quality paints.',
    ARRAY['Weather-proof paints', 'Surface treatment', 'Long-lasting finish'],
    ARRAY['Wall cleaning', 'Crack filling', 'Primer coat', '2 finish coats', 'Cleanup'],
    20000.00, 600, false, 'Every 3-5 years', 2, true, true,
    'https://example.com/exterior-painting.jpg', 'https://example.com/exterior-painting-thumb.jpg'),

-- Cleaning Services
('Deep Cleaning', 'Complete Home Deep Cleaning', 'deep-cleaning', 'cleaning',
    'Thorough deep cleaning of your entire home',
    'Comprehensive cleaning service covering all rooms, surfaces, and hard-to-reach areas.',
    ARRAY['Eco-friendly products', 'Trained staff', 'Detailed cleaning'],
    ARRAY['All room cleaning', 'Kitchen deep clean', 'Bathroom sanitization', 'Dusting & mopping'],
    2999.00, 240, true, 'Monthly', 1, true, true,
    'https://example.com/deep-cleaning.jpg', 'https://example.com/deep-cleaning-thumb.jpg'),

('Bathroom Cleaning', 'Bathroom Deep Cleaning Service', 'bathroom-cleaning', 'cleaning',
    'Complete bathroom cleaning and sanitization',
    'Professional cleaning and sanitization of bathroom fixtures, tiles, and surfaces.',
    ARRAY['Anti-bacterial', 'Tile scrubbing', 'Odor removal'],
    ARRAY['Toilet cleaning', 'Tile & grout cleaning', 'Fixture polishing', 'Drain cleaning'],
    599.00, 60, true, 'Weekly/Monthly', 2, true, true,
    'https://example.com/bathroom-cleaning.jpg', 'https://example.com/bathroom-cleaning-thumb.jpg'),

('Kitchen Cleaning', 'Kitchen Deep Cleaning Service', 'kitchen-cleaning', 'cleaning',
    'Professional kitchen cleaning',
    'Deep cleaning of kitchen including cabinets, appliances, countertops, and floors.',
    ARRAY['Grease removal', 'Appliance cleaning', 'Cabinet cleaning'],
    ARRAY['Counter cleaning', 'Appliance exterior', 'Cabinet cleaning', 'Floor mopping'],
    899.00, 90, true, 'Monthly', 3, true, true,
    'https://example.com/kitchen-cleaning.jpg', 'https://example.com/kitchen-cleaning-thumb.jpg')
ON CONFLICT (service_slug) DO NOTHING;
"

echo -e "${GREEN}✓ Services seeded${NC}\n"

echo -e "${YELLOW}[2/6] Seeding Addons...${NC}"
execute_sql_block "
-- AC Service Addons
INSERT INTO addons (title, addon_slug, category_slug, description, whats_included, price, strikethrough_price, sort_order, is_active, is_available, image)
VALUES
('Gas Refilling', 'ac-gas-refilling', 'ac-services', 'R32/R410A gas refilling for optimal cooling', 
    ARRAY['Gas leak check', 'Vacuum process', 'Gas charging', 'Pressure test'], 
    1200.00, 1500.00, 1, true, true, 'https://example.com/gas-refilling.jpg'),

('Stabilizer Installation', 'ac-stabilizer', 'ac-services', 'Install voltage stabilizer to protect AC',
    ARRAY['Stabilizer mounting', 'Wiring connection', 'Testing'],
    800.00, null, 2, true, true, 'https://example.com/stabilizer.jpg'),

('Anti-Rust Treatment', 'ac-anti-rust', 'ac-services', 'Anti-corrosion treatment for outdoor unit',
    ARRAY['Rust removal', 'Anti-rust coating', 'Protection spray'],
    500.00, null, 3, true, true, 'https://example.com/anti-rust.jpg'),

-- Plumbing Addons
('Tap Replacement', 'tap-replacement', 'plumbing', 'Replace old tap with new one',
    ARRAY['Old tap removal', 'New tap installation', 'Leak testing'],
    400.00, null, 1, true, true, 'https://example.com/tap-replacement.jpg'),

('Drain Cleaning', 'drain-cleaning', 'plumbing', 'Clear blocked drains and pipes',
    ARRAY['Drain inspection', 'Blockage removal', 'Water flow test'],
    350.00, null, 2, true, true, 'https://example.com/drain-cleaning.jpg'),

('Water Tank Cleaning', 'water-tank-cleaning', 'plumbing', 'Clean and sanitize water storage tank',
    ARRAY['Tank draining', 'Interior scrubbing', 'Sanitization', 'Refilling'],
    1200.00, 1500.00, 3, true, true, 'https://example.com/tank-cleaning.jpg'),

-- Electrical Addons
('MCB Installation', 'mcb-installation', 'electrical', 'Install miniature circuit breaker',
    ARRAY['MCB mounting', 'Circuit wiring', 'Testing'],
    600.00, null, 1, true, true, 'https://example.com/mcb.jpg'),

('Earthing Installation', 'earthing', 'electrical', 'Proper electrical earthing system',
    ARRAY['Earth pit', 'Connection to mains', 'Testing'],
    1500.00, null, 2, true, true, 'https://example.com/earthing.jpg'),

-- Painting Addons
('Wall Putty', 'wall-putty', 'painting', 'Smooth wall surface preparation',
    ARRAY['2 coats of putty', 'Sanding', 'Surface smoothing'],
    50.00, null, 1, true, true, 'https://example.com/putty.jpg'),

('Waterproofing', 'waterproofing', 'painting', 'Waterproof coating for walls',
    ARRAY['Chemical treatment', 'Waterproof coating', 'Drying time included'],
    80.00, null, 2, true, true, 'https://example.com/waterproofing.jpg'),

-- Cleaning Addons
('Sofa Cleaning', 'sofa-cleaning', 'cleaning', 'Deep cleaning of sofas and upholstery',
    ARRAY['Vacuum cleaning', 'Stain removal', 'Fabric protection'],
    799.00, 999.00, 1, true, true, 'https://example.com/sofa-cleaning.jpg'),

('Carpet Cleaning', 'carpet-cleaning', 'cleaning', 'Professional carpet cleaning',
    ARRAY['Vacuum', 'Shampoo wash', 'Stain treatment', 'Drying'],
    599.00, null, 2, true, true, 'https://example.com/carpet-cleaning.jpg'),

('Appliance Cleaning', 'appliance-cleaning', 'cleaning', 'Clean refrigerator, oven, microwave',
    ARRAY['Interior cleaning', 'Exterior polishing', 'Odor removal'],
    450.00, null, 3, true, true, 'https://example.com/appliance-cleaning.jpg')
ON CONFLICT (addon_slug) DO NOTHING;
"

echo -e "${GREEN}✓ Addons seeded${NC}\n"

echo -e "${YELLOW}[3/6] Creating test users (customers & providers)...${NC}"
execute_sql_block "
-- Insert test customers (assuming you have a users table)
-- Note: Adjust this based on your actual users table structure
INSERT INTO users (email, phone, full_name, role, is_verified, created_at)
VALUES
('customer1@test.com', '+923001234567', 'Ahmed Ali', 'customer', true, NOW() - INTERVAL '30 days'),
('customer2@test.com', '+923001234568', 'Fatima Khan', 'customer', true, NOW() - INTERVAL '45 days'),
('customer3@test.com', '+923001234569', 'Hassan Raza', 'customer', true, NOW() - INTERVAL '60 days'),
('customer4@test.com', '+923001234570', 'Ayesha Malik', 'customer', true, NOW() - INTERVAL '20 days'),
('customer5@test.com', '+923001234571', 'Usman Ahmed', 'customer', true, NOW() - INTERVAL '10 days')
ON CONFLICT (email) DO NOTHING;

-- Insert test providers
INSERT INTO users (email, phone, full_name, role, is_verified, created_at)
VALUES
('provider1@test.com', '+923002234567', 'Muhammad Saleem', 'provider', true, NOW() - INTERVAL '180 days'),
('provider2@test.com', '+923002234568', 'Rashid Mehmood', 'provider', true, NOW() - INTERVAL '200 days'),
('provider3@test.com', '+923002234569', 'Imran Sheikh', 'provider', true, NOW() - INTERVAL '150 days'),
('provider4@test.com', '+923002234570', 'Tariq Hussain', 'provider', true, NOW() - INTERVAL '120 days'),
('provider5@test.com', '+923002234571', 'Kamran Ali', 'provider', true, NOW() - INTERVAL '90 days')
ON CONFLICT (email) DO NOTHING;
"

echo -e "${GREEN}✓ Test users created${NC}\n"

echo -e "${YELLOW}[4/6] Linking providers to service categories...${NC}"
execute_sql_block "
-- Link providers to their service categories
INSERT INTO provider_service_categories (provider_id, category_slug, expertise_level, years_of_experience, completed_jobs, average_rating, total_ratings, is_active)
SELECT 
    u.id,
    'ac-services',
    'expert',
    5,
    45,
    4.7,
    42,
    true
FROM users u WHERE u.email = 'provider1@test.com'
ON CONFLICT (provider_id, category_slug) DO NOTHING;

INSERT INTO provider_service_categories (provider_id, category_slug, expertise_level, years_of_experience, completed_jobs, average_rating, total_ratings, is_active)
SELECT 
    u.id,
    'plumbing',
    'intermediate',
    3,
    67,
    4.5,
    60,
    true
FROM users u WHERE u.email = 'provider2@test.com'
ON CONFLICT (provider_id, category_slug) DO NOTHING;

INSERT INTO provider_service_categories (provider_id, category_slug, expertise_level, years_of_experience, completed_jobs, average_rating, total_ratings, is_active)
SELECT 
    u.id,
    'electrical',
    'expert',
    7,
    120,
    4.8,
    115,
    true
FROM users u WHERE u.email = 'provider3@test.com'
ON CONFLICT (provider_id, category_slug) DO NOTHING;

INSERT INTO provider_service_categories (provider_id, category_slug, expertise_level, years_of_experience, completed_jobs, average_rating, total_ratings, is_active)
SELECT 
    u.id,
    'painting',
    'intermediate',
    4,
    25,
    4.3,
    22,
    true
FROM users u WHERE u.email = 'provider4@test.com'
ON CONFLICT (provider_id, category_slug) DO NOTHING;

INSERT INTO provider_service_categories (provider_id, category_slug, expertise_level, years_of_experience, completed_jobs, average_rating, total_ratings, is_active)
SELECT 
    u.id,
    'cleaning',
    'beginner',
    1,
    15,
    4.2,
    12,
    true
FROM users u WHERE u.email = 'provider5@test.com'
ON CONFLICT (provider_id, category_slug) DO NOTHING;
"

echo -e "${GREEN}✓ Providers linked to categories${NC}\n"

echo -e "${YELLOW}[5/6] Creating sample service orders...${NC}"
execute_sql_block "
-- Create completed order
INSERT INTO service_orders (
    customer_id,
    customer_info,
    booking_info,
    category_slug,
    selected_services,
    selected_addons,
    special_notes,
    services_total,
    addons_total,
    subtotal,
    platform_commission,
    total_price,
    payment_info,
    assigned_provider_id,
    provider_accepted_at,
    provider_started_at,
    provider_completed_at,
    status,
    customer_rating,
    customer_review,
    customer_rated_at,
    completed_at,
    created_at
)
SELECT
    c.id,
    jsonb_build_object(
        'name', c.full_name,
        'phone', c.phone,
        'email', c.email
    ),
    jsonb_build_object(
        'date', (CURRENT_DATE - INTERVAL '5 days')::text,
        'time_slot', '10:00 AM - 12:00 PM',
        'address', jsonb_build_object(
            'street', 'House 123, Block A',
            'area', 'Model Town',
            'city', 'Bahawalpur',
            'landmark', 'Near City School'
        )
    ),
    'ac-services',
    jsonb_build_array(
        jsonb_build_object(
            'service_slug', 'ac-service',
            'title', 'AC Deep Cleaning & Service',
            'quantity', 2,
            'price', 599.00
        )
    ),
    jsonb_build_array(
        jsonb_build_object(
            'addon_slug', 'ac-gas-refilling',
            'title', 'Gas Refilling',
            'quantity', 1,
            'price', 1200.00
        )
    ),
    'Please call before arriving',
    1198.00,
    1200.00,
    2398.00,
    239.80,
    2637.80,
    jsonb_build_object(
        'method', 'cash',
        'status', 'paid'
    ),
    p.id,
    NOW() - INTERVAL '5 days 1 hour',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '4 days 22 hours',
    'completed',
    5,
    'Excellent service! Very professional and thorough.',
    NOW() - INTERVAL '4 days 20 hours',
    NOW() - INTERVAL '4 days 22 hours',
    NOW() - INTERVAL '5 days 2 hours'
FROM users c, users p
WHERE c.email = 'customer1@test.com' AND p.email = 'provider1@test.com';

-- Create in-progress order
INSERT INTO service_orders (
    customer_id,
    customer_info,
    booking_info,
    category_slug,
    selected_services,
    services_total,
    subtotal,
    platform_commission,
    total_price,
    payment_info,
    assigned_provider_id,
    provider_accepted_at,
    provider_started_at,
    status,
    created_at
)
SELECT
    c.id,
    jsonb_build_object(
        'name', c.full_name,
        'phone', c.phone,
        'email', c.email
    ),
    jsonb_build_object(
        'date', CURRENT_DATE::text,
        'time_slot', '02:00 PM - 04:00 PM',
        'address', jsonb_build_object(
            'street', 'Flat 45, Building 7',
            'area', 'Satellite Town',
            'city', 'Bahawalpur',
            'landmark', 'Behind Metro Cash & Carry'
        )
    ),
    'plumbing',
    jsonb_build_array(
        jsonb_build_object(
            'service_slug', 'tap-repair',
            'title', 'Tap Installation & Repair',
            'quantity', 3,
            'price', 299.00
        )
    ),
    897.00,
    897.00,
    89.70,
    986.70,
    jsonb_build_object(
        'method', 'online',
        'status', 'paid'
    ),
    p.id,
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '30 minutes',
    'in_progress',
    NOW() - INTERVAL '3 hours'
FROM users c, users p
WHERE c.email = 'customer2@test.com' AND p.email = 'provider2@test.com';

-- Create pending order
INSERT INTO service_orders (
    customer_id,
    customer_info,
    booking_info,
    category_slug,
    selected_services,
    selected_addons,
    services_total,
    addons_total,
    subtotal,
    platform_commission,
    total_price,
    status,
    created_at
)
SELECT
    c.id,
    jsonb_build_object(
        'name', c.full_name,
        'phone', c.phone,
        'email', c.email
    ),
    jsonb_build_object(
        'date', (CURRENT_DATE + INTERVAL '1 day')::text,
        'time_slot', '09:00 AM - 11:00 AM',
        'address', jsonb_build_object(
            'street', 'House 567',
            'area', 'Gulberg',
            'city', 'Bahawalpur',
            'landmark', 'Near Punjab University'
        )
    ),
    'electrical',
    jsonb_build_array(
        jsonb_build_object(
            'service_slug', 'fan-installation',
            'title', 'Ceiling & Wall Fan Installation',
            'quantity', 2,
            'price', 399.00
        )
    ),
    jsonb_build_array(
        jsonb_build_object(
            'addon_slug', 'mcb-installation',
            'title', 'MCB Installation',
            'quantity', 1,
            'price', 600.00
        )
    ),
    798.00,
    600.00,
    1398.00,
    139.80,
    1537.80,
    'pending',
    NOW() - INTERVAL '30 minutes'
FROM users c
WHERE c.email = 'customer3@test.com';

-- Create cancelled order
INSERT INTO service_orders (
    customer_id,
    customer_info,
    booking_info,
    category_slug,
    selected_services,
    services_total,
    subtotal,
    platform_commission,
    total_price,
    status,
    cancellation_info,
    created_at
)
SELECT
    c.id,
    jsonb_build_object(
        'name', c.full_name,
        'phone', c.phone,
        'email', c.email
    ),
    jsonb_build_object(
        'date', (CURRENT_DATE - INTERVAL '2 days')::text,
        'time_slot', '03:00 PM - 05:00 PM',
        'address', jsonb_build_object(
            'street', 'House 890',
            'area', 'Johar Town',
            'city', 'Bahawalpur'
        )
    ),
    'cleaning',
    jsonb_build_array(
        jsonb_build_object(
            'service_slug', 'deep-cleaning',
            'title', 'Complete Home Deep Cleaning',
            'quantity', 1,
            'price', 2999.00
        )
    ),
    2999.00,
    2999.00,
    299.90,
    3298.90,
    'cancelled',
    jsonb_build_object(
        'cancelled_by', 'customer',
        'reason', 'Schedule conflict',
        'cancelled_at', (NOW() - INTERVAL '2 days 1 hour')::text
    ),
    NOW() - INTERVAL '2 days 3 hours'
FROM users c
WHERE c.email = 'customer4@test.com';
"

echo -e "${GREEN}✓ Sample orders created${NC}\n"

echo -e "${YELLOW}[6/6] Creating order status history...${NC}"
execute_sql_block "
-- Add status history for completed order
INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, changed_by_role, created_at)
SELECT 
    so.id,
    NULL,
    'pending',
    so.customer_id,
    'customer',
    so.created_at
FROM service_orders so
WHERE so.status = 'completed' AND so.customer_rating IS NOT NULL
LIMIT 1;

INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, changed_by_role, created_at)
SELECT 
    so.id,
    'pending',
    'accepted',
    so.assigned_provider_id,
    'provider',
    so.provider_accepted_at
FROM service_orders so
WHERE so.status = 'completed' AND so.customer_rating IS NOT NULL
LIMIT 1;

INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, changed_by_role, created_at)
SELECT 
    so.id,
    'accepted',
    'in_progress',
    so.assigned_provider_id,
    'provider',
    so.provider_started_at
FROM service_orders so
WHERE so.status = 'completed' AND so.customer_rating IS NOT NULL
LIMIT 1;

INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, changed_by_role, created_at)
SELECT 
    so.id,
    'in_progress',
    'completed',
    so.assigned_provider_id,
    'provider',
    so.provider_completed_at
FROM service_orders so
WHERE so.status = 'completed' AND so.customer_rating IS NOT NULL
LIMIT 1;
"

echo -e "${GREEN}✓ Order status history created${NC}\n"

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Database seeding completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "Summary:"
echo "- Services: 14 records"
echo "- Addons: 13 records"
echo "- Users: 10 records (5 customers + 5 providers)"
echo "- Provider Categories: 5 records"
echo "- Service Orders: 4 records"
echo "- Order Status History: 4 records"

echo -e "\nTest Credentials:"
echo "Customers: customer1@test.com to customer5@test.com"
echo "Providers: provider1@test.com to provider5@test.com"
echo -e "\n${YELLOW}Note: Adjust passwords and other user fields based on your schema${NC}"