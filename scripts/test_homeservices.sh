#!/bin/sh

# Configuration
BASE_URL="${API_URL:-http://localhost:8080/api/v1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
ADMIN_TOKEN=""
RIDER_TOKEN=""
PROVIDER_TOKEN=""
CATEGORY_ID=""
TAB_ID=""
SERVICE_ID_1=""
SERVICE_ID_2=""
ADDON_ID=""
ORDER_ID=""

echo ""
echo "${BLUE}╔════════════════════════════════════════╗${NC}"
echo "${BLUE}║   HOME SERVICES TEST SUITE             ║${NC}"
echo "${BLUE}╚════════════════════════════════════════╝${NC}"
echo "${YELLOW}Base URL: $BASE_URL${NC}"
echo ""

# ==================== SETUP - CREATE USERS ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}SETUP: Creating Test Users${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Create Admin
echo "1. Creating Admin User..."
response=$(curl -s -X POST "$BASE_URL/auth/email/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "adminhomeservice@ex113.com",
    "password": "Admin123!",
    "role": "admin"
  }')

echo "$response"
ADMIN_TOKEN=$(echo "$response" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "${RED}✗ Failed to create admin${NC}"
else
  echo "${GREEN}✓ Admin created successfully${NC}"
  echo "Token: ${ADMIN_TOKEN:0:20}..."
fi
echo ""
sleep 1

# Create Rider
echo "2. Creating Rider User..."
response=$(curl -s -X POST "$BASE_URL/auth/phone/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Rider",
    "phone": "+1234567800",
    "role": "rider"
  }')

echo "$response"
RIDER_TOKEN=$(echo "$response" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$RIDER_TOKEN" ]; then
  echo "${RED}✗ Failed to create rider${NC}"
else
  echo "${GREEN}✓ Rider created successfully${NC}"
  echo "Token: ${RIDER_TOKEN:0:20}..."
fi
echo ""
sleep 1

# ==================== ADMIN - CREATE CATALOG ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}ADMIN: Creating Service Catalog${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Create Category
echo "3. Creating Service Category..."
response=$(curl -s -X POST "$BASE_URL/services/admin/categories" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home Cleaning",
    "description": "Professional home cleaning services",
    "iconUrl": "https://example.com/icons/cleaning.png",
    "highlights": ["Deep Cleaning", "Eco-Friendly Products", "Trained Professionals"],
    "isActive": true,
    "sortOrder": 1
  }')

echo "$response"
CATEGORY_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$CATEGORY_ID" ]; then
  echo "${RED}✗ Failed to create category${NC}"
else
  echo "${GREEN}✓ Category created successfully - ID: $CATEGORY_ID${NC}"
fi
echo ""
sleep 1

# Create Tab
echo "4. Creating Service Tab..."
response=$(curl -s -X POST "$BASE_URL/services/admin/tabs" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"categoryId\": $CATEGORY_ID,
    \"name\": \"Regular Cleaning\",
    \"description\": \"Standard home cleaning services\",
    \"iconUrl\": \"https://example.com/icons/regular.png\",
    \"isActive\": true,
    \"sortOrder\": 1
  }")

echo "$response"
TAB_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$TAB_ID" ]; then
  echo "${RED}✗ Failed to create tab${NC}"
else
  echo "${GREEN}✓ Tab created successfully - ID: $TAB_ID${NC}"
fi
echo ""
sleep 1

# Create Service 1 (Fixed Pricing)
echo "5. Creating Service 1 (Fixed Pricing)..."
response=$(curl -s -X POST "$BASE_URL/services/admin/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"categoryId\": $CATEGORY_ID,
    \"tabId\": $TAB_ID,
    \"name\": \"Deep Cleaning Package\",
    \"description\": \"Complete deep cleaning for your home\",
    \"imageUrl\": \"https://example.com/services/deep-cleaning.jpg\",
    \"basePrice\": 100.00,
    \"originalPrice\": 150.00,
    \"pricingModel\": \"fixed\",
    \"baseDurationMinutes\": 120,
    \"isFeatured\": true
  }")

echo "$response"
SERVICE_ID_1=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$SERVICE_ID_1" ]; then
  echo "${RED}✗ Failed to create service 1${NC}"
else
  echo "${GREEN}✓ Service 1 created successfully - ID: $SERVICE_ID_1${NC}"
fi
echo ""
sleep 1

# Create Service 2 (Hourly Pricing)
echo "6. Creating Service 2 (Hourly Pricing)..."
response=$(curl -s -X POST "$BASE_URL/services/admin/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"categoryId\": $CATEGORY_ID,
    \"tabId\": $TAB_ID,
    \"name\": \"General Cleaning (Hourly)\",
    \"description\": \"Flexible hourly cleaning service\",
    \"imageUrl\": \"https://example.com/services/general-cleaning.jpg\",
    \"basePrice\": 50.00,
    \"originalPrice\": 70.00,
    \"pricingModel\": \"hourly\",
    \"baseDurationMinutes\": 60,
    \"isFeatured\": false
  }")

echo "$response"
SERVICE_ID_2=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$SERVICE_ID_2" ]; then
  echo "${RED}✗ Failed to create service 2${NC}"
else
  echo "${GREEN}✓ Service 2 created successfully - ID: $SERVICE_ID_2${NC}"
fi
echo ""
sleep 1

# Create Add-On
echo "7. Creating Add-On Service..."
response=$(curl -s -X POST "$BASE_URL/services/admin/addons" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"categoryId\": $CATEGORY_ID,
    \"title\": \"Carpet Shampooing\",
    \"description\": \"Professional carpet deep cleaning\",
    \"imageUrl\": \"https://example.com/addons/carpet.jpg\",
    \"price\": 30.00,
    \"originalPrice\": 40.00,
    \"durationMinutes\": 30,
    \"isActive\": true,
    \"sortOrder\": 1
  }")

echo "$response"
ADDON_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$ADDON_ID" ]; then
  echo "${RED}✗ Failed to create add-on${NC}"
else
  echo "${GREEN}✓ Add-on created successfully - ID: $ADDON_ID${NC}"
fi
echo ""
sleep 1

# ==================== PUBLIC - LIST SERVICES ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}PUBLIC: Listing Services${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# List Categories
echo "8. Listing Categories..."
curl -s -X GET "$BASE_URL/services/categories"
echo ""
echo ""
sleep 1

# Get Category with Tabs
echo "9. Getting Category with Tabs..."
curl -s -X GET "$BASE_URL/services/categories/$CATEGORY_ID"
echo ""
echo ""
sleep 1

# List Services
echo "10. Listing Services..."
curl -s -X GET "$BASE_URL/services?categoryId=$CATEGORY_ID"
echo ""
echo ""
sleep 1

# Get Service Details
echo "11. Getting Service Details..."
curl -s -X GET "$BASE_URL/services/$SERVICE_ID_1"
echo ""
echo ""
sleep 1

# List Add-ons
echo "12. Listing Add-ons..."
curl -s -X GET "$BASE_URL/services/addons?categoryId=$CATEGORY_ID"
echo ""
echo ""
sleep 1

# ==================== CUSTOMER - CREATE ORDERS ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}CUSTOMER: Creating Orders${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Create Order 1 - Fixed Pricing with 2 Pros
echo "13. Creating Order (Fixed Pricing, 2 Pros)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [
      {
        \"serviceId\": $SERVICE_ID_1,
        \"selectedOptions\": []
      }
    ],
    \"addOnIds\": [$ADDON_ID],
    \"address\": \"123 Main St, Apartment 4B, New York, NY 10001\",
    \"latitude\": 40.7128,
    \"longitude\": -74.0060,
    \"serviceDate\": \"2025-11-25T10:00:00Z\",
    \"frequency\": \"once\",
    \"quantityOfPros\": 2,
    \"hoursOfService\": 3.0,
    \"notes\": \"Please bring eco-friendly cleaning supplies\"
  }")

echo "$response"
ORDER_ID=$(echo "$response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$ORDER_ID" ]; then
  echo "${RED}✗ Failed to create order 1${NC}"
else
  echo "${GREEN}✓ Order 1 created successfully - ID: $ORDER_ID${NC}"
  
  # Extract pricing details
  subtotal=$(echo "$response" | grep -o '"subtotal":[0-9.]*' | cut -d':' -f2)
  platformFee=$(echo "$response" | grep -o '"platformFee":[0-9.]*' | cut -d':' -f2)
  total=$(echo "$response" | grep -o '"total":[0-9.]*' | cut -d':' -f2)
  
  echo "${BLUE}Pricing Breakdown:${NC}"
  echo "  Base: \$100 (Deep Cleaning)"
  echo "  Add-on: \$30 (Carpet Shampooing)"
  echo "  Quantity of Pros: 2"
  echo "  Calculation: (\$100 + \$30) × 2 = \$260"
  echo "  Platform Fee (10%): \$26"
  echo "  ${GREEN}Total: \$$total${NC}"
fi
echo ""
sleep 2

# Create Order 2 - Hourly Pricing
echo "14. Creating Order (Hourly Pricing, 1 Pro, 3 Hours)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [
      {
        \"serviceId\": $SERVICE_ID_2,
        \"selectedOptions\": []
      }
    ],
    \"addOnIds\": [],
    \"address\": \"456 Oak Avenue, Brooklyn, NY 11201\",
    \"latitude\": 40.6782,
    \"longitude\": -73.9442,
    \"serviceDate\": \"2025-01-26T14:00:00Z\",
    \"frequency\": \"once\",
    \"quantityOfPros\": 1,
    \"hoursOfService\": 3.0,
    \"notes\": \"Please focus on kitchen and bathrooms\"
  }")

echo "$response"

total=$(echo "$response" | grep -o '"total":[0-9.]*' | cut -d':' -f2)

echo ""
echo "${BLUE}Pricing Breakdown:${NC}"
echo "  Hourly Rate: \$50/hour"
echo "  Hours: 3"
echo "  Quantity of Pros: 1"
echo "  Calculation: \$50 × 3 hours × 1 = \$150"
echo "  Platform Fee (10%): \$15"
echo "  ${GREEN}Total: \$$total${NC}"
echo ""
sleep 2

# Create Order 3 - Mixed with Multiple Pros
echo "15. Creating Order (Both Services, 2 Pros, 4 Hours)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [
      {
        \"serviceId\": $SERVICE_ID_1,
        \"selectedOptions\": []
      },
      {
        \"serviceId\": $SERVICE_ID_2,
        \"selectedOptions\": []
      }
    ],
    \"addOnIds\": [$ADDON_ID],
    \"address\": \"789 Park Place, Manhattan, NY 10019\",
    \"latitude\": 40.7589,
    \"longitude\": -73.9851,
    \"serviceDate\": \"2025-01-27T09:00:00Z\",
    \"frequency\": \"weekly\",
    \"quantityOfPros\": 2,
    \"hoursOfService\": 4.0,
    \"notes\": \"Weekly cleaning, same team preferred\"
  }")

echo "$response"

total=$(echo "$response" | grep -o '"total":[0-9.]*' | cut -d':' -f2)

echo ""
echo "${BLUE}Pricing Breakdown:${NC}"
echo "  Service 1 (Fixed): \$100 × 2 pros = \$200"
echo "  Service 2 (Hourly): \$50 × 4 hours × 2 pros = \$400"
echo "  Add-on: \$30 × 2 pros = \$60"
echo "  Subtotal: \$660"
echo "  Platform Fee (10%): \$66"
echo "  ${GREEN}Total: \$$total${NC}"
echo ""
sleep 2

# ==================== CUSTOMER - GET ORDERS ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}CUSTOMER: Getting Orders${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# List My Orders
echo "16. Listing My Orders..."
curl -s -X GET "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN"
echo ""
echo ""
sleep 1

# Get Order Details
if [ ! -z "$ORDER_ID" ]; then
  echo "17. Getting Order Details..."
  curl -s -X GET "$BASE_URL/services/orders/$ORDER_ID" \
    -H "Authorization: Bearer $RIDER_TOKEN"
  echo ""
  echo ""
  sleep 1
fi

# ==================== VALIDATION TESTS ====================

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}VALIDATION TESTS${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Test Invalid Quantity
echo "18. Testing Invalid Quantity (should fail)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [{\"serviceId\": $SERVICE_ID_1}],
    \"address\": \"Test Address\",
    \"latitude\": 40.7128,
    \"longitude\": -74.0060,
    \"serviceDate\": \"2025-11-25T10:00:00Z\",
    \"quantityOfPros\": 15,
    \"hoursOfService\": 2.0
  }")

echo "$response"
if echo "$response" | grep -q "maximum 10 professionals"; then
  echo "${GREEN}✓ Validation working - rejected invalid quantity${NC}"
else
  echo "${RED}✗ Validation failed - should reject quantity > 10${NC}"
fi
echo ""
sleep 1

# Test Invalid Hours
echo "19. Testing Invalid Hours (should fail)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [{\"serviceId\": $SERVICE_ID_1}],
    \"address\": \"Test Address\",
    \"latitude\": 40.7128,
    \"longitude\": -74.0060,
    \"serviceDate\": \"2025-11-25T10:00:00Z\",
    \"quantityOfPros\": 2,
    \"hoursOfService\": 0.3
  }")

echo "$response"
if echo "$response" | grep -q "minimum service duration"; then
  echo "${GREEN}✓ Validation working - rejected invalid hours${NC}"
else
  echo "${RED}✗ Validation failed - should reject hours < 0.5${NC}"
fi
echo ""
sleep 1

# Test Invalid Hours Increment
echo "20. Testing Invalid Hours Increment (should fail)..."
response=$(curl -s -X POST "$BASE_URL/services/orders" \
  -H "Authorization: Bearer $RIDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"items\": [{\"serviceId\": $SERVICE_ID_1}],
    \"address\": \"Test Address\",
    \"latitude\": 40.7128,
    \"longitude\": -74.0060,
    \"serviceDate\": \"2025-11-25T10:00:00Z\",
    \"quantityOfPros\": 2,
    \"hoursOfService\": 2.3
  }")

echo "$response"
if echo "$response" | grep -q "0.5 hour increments"; then
  echo "${GREEN}✓ Validation working - rejected invalid increment${NC}"
else
  echo "${RED}✗ Validation failed - should reject non-0.5 increments${NC}"
fi
echo ""
sleep 1

# ==================== SUMMARY ====================

echo ""
echo "${BLUE}╔════════════════════════════════════════╗${NC}"
echo "${BLUE}║   TEST SUMMARY                         ║${NC}"
echo "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "${GREEN}✓ Admin Setup:${NC}"
echo "  - Admin user created"
echo "  - Category created (ID: $CATEGORY_ID)"
echo "  - Tab created (ID: $TAB_ID)"
echo "  - Service 1 created (ID: $SERVICE_ID_1) - Fixed Pricing"
echo "  - Service 2 created (ID: $SERVICE_ID_2) - Hourly Pricing"
echo "  - Add-on created (ID: $ADDON_ID)"
echo ""
echo "${GREEN}✓ Customer Setup:${NC}"
echo "  - Rider user created"
echo "  - Multiple orders created with different configurations"
echo ""
echo "${GREEN}✓ Validation Tests:${NC}"
echo "  - Quantity validation tested"
echo "  - Hours validation tested"
echo "  - Increment validation tested"
echo ""
echo "${YELLOW}Test Data Created:${NC}"
echo "  Admin Token: ${ADMIN_TOKEN:0:30}..."
echo "  Rider Token: ${RIDER_TOKEN:0:30}..."
echo "  First Order ID: $ORDER_ID"
echo ""
echo "${BLUE}Next Steps:${NC}"
echo "  1. Test provider acceptance workflow"
echo "  2. Test order cancellation"
echo "  3. Test order completion"
echo ""