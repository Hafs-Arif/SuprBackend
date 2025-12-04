#!/bin/bash

#===============================================================================
# Home Services Module - Complete API Test Script
# 
# Usage: ./test_homeservices.sh [options]
# 
# Options:
#   -h, --host       API host (default: http://localhost:8080)
#   -a, --admin      Admin token
#   -c, --customer   Customer token
#   -p, --provider   Provider token
#   --skip-admin     Skip admin tests
#   --skip-customer  Skip customer tests
#   --skip-provider  Skip provider tests
#   --only-admin     Run only admin tests
#   --only-customer  Run only customer tests
#   --only-provider  Run only provider tests
#   --help           Show this help message
#===============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default configuration
API_HOST="${API_HOST:-http://localhost:8080}"
API_VERSION="v1"
BASE_URL="${API_HOST}/api/${API_VERSION}"

# Tokens (should be provided via arguments or environment)
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
CUSTOMER_TOKEN="${CUSTOMER_TOKEN:-}"
PROVIDER_TOKEN="${PROVIDER_TOKEN:-}"

# Test control flags
SKIP_ADMIN=false
SKIP_CUSTOMER=false
SKIP_PROVIDER=false

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Store created resource IDs for cleanup/chaining
CREATED_SERVICE_SLUG=""
CREATED_ADDON_SLUG=""
CREATED_ORDER_ID=""
CREATED_ORDER_NUMBER=""
PROVIDER_CATEGORY_SLUG=""

#===============================================================================
# Helper Functions
#===============================================================================

print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE} $1${PURPLE}$(printf '%*s' $((67 - ${#1})) '')║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test() {
    echo -e "${BLUE}▶ Testing:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓ PASSED:${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_failure() {
    echo -e "${RED}✗ FAILED:${NC} $1"
    echo -e "${RED}  Error:${NC} $2"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

print_skip() {
    echo -e "${YELLOW}○ SKIPPED:${NC} $1"
    ((SKIPPED_TESTS++))
}

print_info() {
    echo -e "${WHITE}  ℹ${NC} $1"
}

print_response() {
    if [ -n "$1" ]; then
        echo -e "${WHITE}  Response:${NC}"
        echo "$1" | head -20
        if [ $(echo "$1" | wc -l) -gt 20 ]; then
            echo "  ... (truncated)"
        fi
    fi
}

# Make HTTP request and capture response
# Usage: make_request METHOD URL [DATA] [TOKEN]
make_request() {
    local method="$1"
    local url="$2"
    local data="$3"
    local token="$4"
    
    local -a curl_args=(-s -w $'\n%{http_code}' -H "Content-Type: application/json")
    
    if [ -n "$token" ]; then
        curl_args+=(-H "Authorization: Bearer $token")
    fi
    
    case "$method" in
        GET)
            curl "${curl_args[@]}" "$url"
            ;;
        POST)
            if [ -n "$data" ]; then
                curl "${curl_args[@]}" -X POST -d "$data" "$url"
            else
                curl "${curl_args[@]}" -X POST "$url"
            fi
            ;;
        PUT)
            curl "${curl_args[@]}" -X PUT -d "$data" "$url"
            ;;
        PATCH)
            curl "${curl_args[@]}" -X PATCH -d "$data" "$url"
            ;;
        DELETE)
            curl "${curl_args[@]}" -X DELETE "$url"
            ;;
    esac
}
# Parse response and http code
parse_response() {
    local response="$1"
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    echo "$http_code|$body"
}

# Check if response is successful (2xx)
is_success() {
    local http_code="$1"
    [[ "$http_code" =~ ^2[0-9][0-9]$ ]]
}

# Extract JSON field (simple extraction without jq)
extract_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | grep -o "\"$field\":[^,}]*" | head -1 | sed "s/\"$field\"://" | tr -d '"' | tr -d ' '
}

# Extract nested JSON field
extract_nested_field() {
    local json="$1"
    local field="$2"
    # Simple extraction for data.field pattern
    echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | head -1 | sed "s/\"$field\":\"//" | tr -d '"'
}

# Generate unique slug
generate_slug() {
    echo "test-$(date +%s)-$RANDOM"
}

#===============================================================================
# Parse Command Line Arguments
#===============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                API_HOST="$2"
                BASE_URL="${API_HOST}/api/${API_VERSION}"
                shift 2
                ;;
            -a|--admin)
                ADMIN_TOKEN="$2"
                shift 2
                ;;
            -c|--customer)
                CUSTOMER_TOKEN="$2"
                shift 2
                ;;
            -p|--provider)
                PROVIDER_TOKEN="$2"
                shift 2
                ;;
            --skip-admin)
                SKIP_ADMIN=true
                shift
                ;;
            --skip-customer)
                SKIP_CUSTOMER=true
                shift
                ;;
            --skip-provider)
                SKIP_PROVIDER=true
                shift
                ;;
            --only-admin)
                SKIP_CUSTOMER=true
                SKIP_PROVIDER=true
                shift
                ;;
            --only-customer)
                SKIP_ADMIN=true
                SKIP_PROVIDER=true
                shift
                ;;
            --only-provider)
                SKIP_ADMIN=true
                SKIP_CUSTOMER=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Home Services Module - API Test Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST       API host (default: http://localhost:8080)"
    echo "  -a, --admin TOKEN     Admin JWT token"
    echo "  -c, --customer TOKEN  Customer JWT token"
    echo "  -p, --provider TOKEN  Provider JWT token"
    echo "  --skip-admin          Skip admin tests"
    echo "  --skip-customer       Skip customer tests"
    echo "  --skip-provider       Skip provider tests"
    echo "  --only-admin          Run only admin tests"
    echo "  --only-customer       Run only customer tests"
    echo "  --only-provider       Run only provider tests"
    echo "  --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  API_HOST              API host URL"
    echo "  ADMIN_TOKEN           Admin JWT token"
    echo "  CUSTOMER_TOKEN        Customer JWT token"
    echo "  PROVIDER_TOKEN        Provider JWT token"
    echo ""
    echo "Examples:"
    echo "  $0 --admin \"eyJhbG...\" --customer \"eyJhbG...\" --provider \"eyJhbG...\""
    echo "  $0 --only-admin --admin \"eyJhbG...\""
    echo "  API_HOST=http://api.example.com $0"
}

#===============================================================================
# Admin Service Management Tests (Module 2)
#===============================================================================

test_admin_services() {
    print_section "Admin Service Management Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Admin tests - No admin token provided"
        return
    fi
    
    local service_slug=$(generate_slug)
    CREATED_SERVICE_SLUG="$service_slug"
    
    # Test: Create Service
    print_test "Create Service"
    local create_data='{
        "title": "Test Pest Control Service",
        "serviceSlug": "'$service_slug'",
        "categorySlug": "pest-control",
        "description": "Professional pest control service for testing",
        "whatsIncluded": ["Inspection", "Treatment", "Follow-up"],
        "duration": 60,
        "basePrice": 150.00,
        "isActive": true,
        "isAvailable": true
    }'
    
    local response=$(make_request POST "${BASE_URL}/admin/homeservices/services" "$create_data" "$ADMIN_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Create Service (HTTP $http_code)"
        print_info "Created service with slug: $service_slug"
    else
        print_failure "Create Service" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Services
    print_test "List Services"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/services?page=1&limit=10" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Services (HTTP $http_code)"
    else
        print_failure "List Services" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Service by Slug
    print_test "Get Service by Slug"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/services/${service_slug}" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Service by Slug (HTTP $http_code)"
    else
        print_failure "Get Service by Slug" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Service
    print_test "Update Service"
    local update_data='{
        "title": "Updated Pest Control Service",
        "description": "Updated description for testing",
        "basePrice": 175.00
    }'
    
    response=$(make_request PUT "${BASE_URL}/admin/homeservices/services/${service_slug}" "$update_data" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Service (HTTP $http_code)"
    else
        print_failure "Update Service" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Service Status
    print_test "Update Service Status"
    local status_data='{"isActive": false}'
    
    response=$(make_request PATCH "${BASE_URL}/admin/homeservices/services/${service_slug}/status" "$status_data" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Service Status (HTTP $http_code)"
    else
        print_failure "Update Service Status" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Re-activate for other tests
    status_data='{"isActive": true, "isAvailable": true}'
    make_request PATCH "${BASE_URL}/admin/homeservices/services/${service_slug}/status" "$status_data" "$ADMIN_TOKEN" > /dev/null 2>&1
}

test_admin_addons() {
    print_section "Admin Addon Management Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Admin addon tests - No admin token provided"
        return
    fi
    
    local addon_slug=$(generate_slug)
    CREATED_ADDON_SLUG="$addon_slug"
    
    # Test: Create Addon
    print_test "Create Addon"
    local create_data='{
        "title": "Test Deep Cleaning Addon",
        "addonSlug": "'$addon_slug'",
        "categorySlug": "pest-control",
        "description": "Deep cleaning after pest treatment",
        "whatsIncluded": ["Floor cleaning", "Surface sanitization"],
        "price": 50.00,
        "strikethroughPrice": 75.00,
        "isActive": true,
        "isAvailable": true
    }'
    
    local response=$(make_request POST "${BASE_URL}/admin/homeservices/addons" "$create_data" "$ADMIN_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Create Addon (HTTP $http_code)"
        print_info "Created addon with slug: $addon_slug"
    else
        print_failure "Create Addon" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Addons
    print_test "List Addons"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/addons?page=1&limit=10" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Addons (HTTP $http_code)"
    else
        print_failure "List Addons" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Addon by Slug
    print_test "Get Addon by Slug"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/addons/${addon_slug}" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Addon by Slug (HTTP $http_code)"
    else
        print_failure "Get Addon by Slug" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Addon
    print_test "Update Addon"
    local update_data='{
        "title": "Updated Deep Cleaning Addon",
        "price": 55.00
    }'
    
    response=$(make_request PUT "${BASE_URL}/admin/homeservices/addons/${addon_slug}" "$update_data" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Addon (HTTP $http_code)"
    else
        print_failure "Update Addon" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Addon Status
    print_test "Update Addon Status"
    local status_data='{"isActive": true, "isAvailable": true}'
    
    response=$(make_request PATCH "${BASE_URL}/admin/homeservices/addons/${addon_slug}/status" "$status_data" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Addon Status (HTTP $http_code)"
    else
        print_failure "Update Addon Status" "HTTP $http_code"
        print_response "$body"
    fi
}

test_admin_categories() {
    print_section "Admin Category Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Admin category tests - No admin token provided"
        return
    fi
    
    # Test: Get All Categories
    print_test "Get All Categories"
    local response=$(make_request GET "${BASE_URL}/admin/homeservices/categories" "" "$ADMIN_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get All Categories (HTTP $http_code)"
    else
        print_failure "Get All Categories" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Category Details
    print_test "Get Category Details (pest-control)"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/categories/pest-control" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Category Details (HTTP $http_code)"
    else
        print_failure "Get Category Details" "HTTP $http_code"
        print_response "$body"
    fi
}

#===============================================================================
# Customer Service Discovery Tests (Module 3)
#===============================================================================

test_customer_discovery() {
    print_section "Customer Service Discovery Tests (Public)"
    
    # Test: Get All Categories (Public)
    print_test "Get All Categories (Public)"
    local response=$(make_request GET "${BASE_URL}/homeservices/categories")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get All Categories (HTTP $http_code)"
    else
        print_failure "Get All Categories" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Category Details (Public)
    print_test "Get Category Details (Public)"
    response=$(make_request GET "${BASE_URL}/homeservices/categories/pest-control")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Category Details (HTTP $http_code)"
    else
        print_failure "Get Category Details" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Services
    print_test "List Services"
    response=$(make_request GET "${BASE_URL}/homeservices/services?page=1&limit=10")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Services (HTTP $http_code)"
    else
        print_failure "List Services" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Services with Filters
    print_test "List Services with Filters"
    response=$(make_request GET "${BASE_URL}/homeservices/services?category=pest-control&minPrice=100&maxPrice=500")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Services with Filters (HTTP $http_code)"
    else
        print_failure "List Services with Filters" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Frequent Services
    print_test "Get Frequent Services"
    response=$(make_request GET "${BASE_URL}/homeservices/services/frequent?limit=5")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Frequent Services (HTTP $http_code)"
    else
        print_failure "Get Frequent Services" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Service by Slug
    if [ -n "$CREATED_SERVICE_SLUG" ]; then
        print_test "Get Service by Slug"
        response=$(make_request GET "${BASE_URL}/homeservices/services/${CREATED_SERVICE_SLUG}")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Service by Slug (HTTP $http_code)"
        else
            print_failure "Get Service by Slug" "HTTP $http_code"
            print_response "$body"
        fi
    fi
    
    # Test: List Addons
    print_test "List Addons"
    response=$(make_request GET "${BASE_URL}/homeservices/addons?page=1&limit=10")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Addons (HTTP $http_code)"
    else
        print_failure "List Addons" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Discounted Addons
    print_test "Get Discounted Addons"
    response=$(make_request GET "${BASE_URL}/homeservices/addons/discounted?limit=10")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Discounted Addons (HTTP $http_code)"
    else
        print_failure "Get Discounted Addons" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Search Services
    print_test "Search Services"
    response=$(make_request GET "${BASE_URL}/homeservices/search?q=pest")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Search Services (HTTP $http_code)"
    else
        print_failure "Search Services" "HTTP $http_code"
        print_response "$body"
    fi
}

#===============================================================================
# Customer Order Management Tests (Module 4)
#===============================================================================

test_customer_orders() {
    print_section "Customer Order Management Tests"
    
    if [ -z "$CUSTOMER_TOKEN" ]; then
        print_skip "Customer order tests - No customer token provided"
        return
    fi
    
    # Need a valid service slug
    local service_slug="${CREATED_SERVICE_SLUG:-general-pest-control}"
    local addon_slug="${CREATED_ADDON_SLUG:-deep-cleaning}"
    
    # Calculate future date (3 days from now)
    local booking_date=$(date -d "+3 days" +%Y-%m-%d 2>/dev/null || date -v+3d +%Y-%m-%d 2>/dev/null || echo "2024-12-25")
    
    # Test: Create Order
    print_test "Create Order"
    local create_data='{
        "customerInfo": {
            "name": "Test Customer",
            "phone": "+1234567890",
            "email": "test@example.com",
            "address": "123 Test Street, Test City, TC 12345",
            "lat": 40.7128,
            "lng": -74.0060
        },
        "bookingInfo": {
            "date": "'$booking_date'",
            "time": "14:30",
            "preferredTime": "afternoon"
        },
        "categorySlug": "pest-control",
        "selectedServices": [
            {
                "serviceSlug": "'$service_slug'",
                "quantity": 1
            }
        ],
        "selectedAddons": [
            {
                "addonSlug": "'$addon_slug'",
                "quantity": 1
            }
        ],
        "specialNotes": "Please call before arriving",
        "paymentMethod": "wallet"
    }'
    
    local response=$(make_request POST "${BASE_URL}/homeservices/orders" "$create_data" "$CUSTOMER_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Create Order (HTTP $http_code)"
        # Extract order ID and number from response
        CREATED_ORDER_ID=$(echo "$body" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//' | tr -d '"')
        CREATED_ORDER_NUMBER=$(echo "$body" | grep -o '"orderNumber":"[^"]*"' | head -1 | sed 's/"orderNumber":"//' | tr -d '"')
        print_info "Created order: $CREATED_ORDER_NUMBER (ID: $CREATED_ORDER_ID)"
    else
        print_failure "Create Order" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Orders
    print_test "List My Orders"
    response=$(make_request GET "${BASE_URL}/homeservices/orders?page=1&limit=10" "" "$CUSTOMER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List My Orders (HTTP $http_code)"
    else
        print_failure "List My Orders" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Order Details
    if [ -n "$CREATED_ORDER_ID" ]; then
        print_test "Get Order Details"
        response=$(make_request GET "${BASE_URL}/homeservices/orders/${CREATED_ORDER_ID}" "" "$CUSTOMER_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Order Details (HTTP $http_code)"
        else
            print_failure "Get Order Details" "HTTP $http_code"
            print_response "$body"
        fi
        
        # Test: Get Cancellation Preview
        print_test "Get Cancellation Preview"
        response=$(make_request GET "${BASE_URL}/homeservices/orders/${CREATED_ORDER_ID}/cancel/preview" "" "$CUSTOMER_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Cancellation Preview (HTTP $http_code)"
        else
            print_failure "Get Cancellation Preview" "HTTP $http_code"
            print_response "$body"
        fi
    fi
}

#===============================================================================
# Provider Order Management Tests (Module 5)
#===============================================================================

test_provider_profile() {
    print_section "Provider Profile Management Tests"
    
    if [ -z "$PROVIDER_TOKEN" ]; then
        print_skip "Provider profile tests - No provider token provided"
        return
    fi
    
    # Test: Get Profile
    print_test "Get Provider Profile"
    local response=$(make_request GET "${BASE_URL}/provider/profile" "" "$PROVIDER_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Provider Profile (HTTP $http_code)"
    else
        print_failure "Get Provider Profile" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Availability
    print_test "Update Availability"
    local update_data='{
        "isAvailable": true,
        "latitude": 40.7128,
        "longitude": -74.0060
    }'
    
    response=$(make_request PATCH "${BASE_URL}/provider/availability" "$update_data" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Availability (HTTP $http_code)"
    else
        print_failure "Update Availability" "HTTP $http_code"
        print_response "$body"
    fi
}

test_provider_categories() {
    print_section "Provider Service Categories Tests"
    
    if [ -z "$PROVIDER_TOKEN" ]; then
        print_skip "Provider category tests - No provider token provided"
        return
    fi
    
    PROVIDER_CATEGORY_SLUG="pest-control"
    
    # Test: Add Service Category
    print_test "Add Service Category"
    local add_data='{
        "categorySlug": "'$PROVIDER_CATEGORY_SLUG'",
        "expertiseLevel": "expert",
        "yearsOfExperience": 5
    }'
    
    local response=$(make_request POST "${BASE_URL}/provider/categories" "$add_data" "$PROVIDER_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Add Service Category (HTTP $http_code)"
    else
        # May already exist, which is okay
        if echo "$body" | grep -q "already"; then
            print_info "Category already exists (expected if running multiple times)"
            print_success "Add Service Category - Already exists (HTTP $http_code)"
        else
            print_failure "Add Service Category" "HTTP $http_code"
            print_response "$body"
        fi
    fi
    
    # Test: Get Service Categories
    print_test "Get Service Categories"
    response=$(make_request GET "${BASE_URL}/provider/categories" "" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Service Categories (HTTP $http_code)"
    else
        print_failure "Get Service Categories" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Update Service Category
    print_test "Update Service Category"
    local update_data='{
        "expertiseLevel": "expert",
        "yearsOfExperience": 6,
        "isActive": true
    }'
    
    response=$(make_request PUT "${BASE_URL}/provider/categories/${PROVIDER_CATEGORY_SLUG}" "$update_data" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Update Service Category (HTTP $http_code)"
    else
        print_failure "Update Service Category" "HTTP $http_code"
        print_response "$body"
    fi
}

test_provider_orders() {
    print_section "Provider Order Management Tests"
    
    if [ -z "$PROVIDER_TOKEN" ]; then
        print_skip "Provider order tests - No provider token provided"
        return
    fi
    
    # Test: Get Available Orders
    print_test "Get Available Orders"
    local response=$(make_request GET "${BASE_URL}/provider/orders/available?page=1&limit=10" "" "$PROVIDER_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Available Orders (HTTP $http_code)"
    else
        print_failure "Get Available Orders" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get My Orders
    print_test "Get My Orders"
    response=$(make_request GET "${BASE_URL}/provider/orders?page=1&limit=10" "" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get My Orders (HTTP $http_code)"
    else
        print_failure "Get My Orders" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Statistics
    print_test "Get Provider Statistics"
    response=$(make_request GET "${BASE_URL}/provider/statistics" "" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Provider Statistics (HTTP $http_code)"
    else
        print_failure "Get Provider Statistics" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Earnings
    print_test "Get Provider Earnings"
    local from_date=$(date -d "-30 days" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "2024-01-01")
    local to_date=$(date +%Y-%m-%d)
    
    response=$(make_request GET "${BASE_URL}/provider/earnings?fromDate=${from_date}&toDate=${to_date}" "" "$PROVIDER_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Provider Earnings (HTTP $http_code)"
    else
        print_failure "Get Provider Earnings" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test order flow if we have an order
    if [ -n "$CREATED_ORDER_ID" ]; then
        # Test: Accept Order
        print_test "Accept Order"
        response=$(make_request POST "${BASE_URL}/provider/orders/${CREATED_ORDER_ID}/accept" "" "$PROVIDER_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Accept Order (HTTP $http_code)"
            
            # Test: Start Order
            print_test "Start Order"
            response=$(make_request POST "${BASE_URL}/provider/orders/${CREATED_ORDER_ID}/start" "" "$PROVIDER_TOKEN")
            parsed=$(parse_response "$response")
            http_code=$(echo "$parsed" | cut -d'|' -f1)
            body=$(echo "$parsed" | cut -d'|' -f2-)
            
            if is_success "$http_code"; then
                print_success "Start Order (HTTP $http_code)"
                
                # Test: Complete Order
                print_test "Complete Order"
                local complete_data='{"notes": "Service completed successfully"}'
                response=$(make_request POST "${BASE_URL}/provider/orders/${CREATED_ORDER_ID}/complete" "$complete_data" "$PROVIDER_TOKEN")
                parsed=$(parse_response "$response")
                http_code=$(echo "$parsed" | cut -d'|' -f1)
                body=$(echo "$parsed" | cut -d'|' -f2-)
                
                if is_success "$http_code"; then
                    print_success "Complete Order (HTTP $http_code)"
                    
                    # Test: Rate Customer
                    print_test "Rate Customer"
                    local rate_data='{"rating": 5, "review": "Great customer, very cooperative"}'
                    response=$(make_request POST "${BASE_URL}/provider/orders/${CREATED_ORDER_ID}/rate" "$rate_data" "$PROVIDER_TOKEN")
                    parsed=$(parse_response "$response")
                    http_code=$(echo "$parsed" | cut -d'|' -f1)
                    body=$(echo "$parsed" | cut -d'|' -f2-)
                    
                    if is_success "$http_code"; then
                        print_success "Rate Customer (HTTP $http_code)"
                    else
                        print_failure "Rate Customer" "HTTP $http_code"
                    fi
                else
                    print_failure "Complete Order" "HTTP $http_code"
                fi
            else
                print_failure "Start Order" "HTTP $http_code"
            fi
        else
            print_info "Could not accept order (may already be assigned or not available)"
        fi
    fi
}

#===============================================================================
# Admin Order Management Tests (Module 6)
#===============================================================================

test_admin_orders() {
    print_section "Admin Order Management Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Admin order tests - No admin token provided"
        return
    fi
    
    # Test: Get Dashboard
    print_test "Get Admin Dashboard"
    local response=$(make_request GET "${BASE_URL}/admin/homeservices/dashboard" "" "$ADMIN_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Admin Dashboard (HTTP $http_code)"
    else
        print_failure "Get Admin Dashboard" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Orders
    print_test "List All Orders"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/orders?page=1&limit=10" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List All Orders (HTTP $http_code)"
    else
        print_failure "List All Orders" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: List Orders with Filters
    print_test "List Orders with Filters"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/orders?status=completed&category=pest-control&page=1&limit=10" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "List Orders with Filters (HTTP $http_code)"
    else
        print_failure "List Orders with Filters" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Order by ID
    if [ -n "$CREATED_ORDER_ID" ]; then
        print_test "Get Order by ID"
        response=$(make_request GET "${BASE_URL}/admin/homeservices/orders/${CREATED_ORDER_ID}" "" "$ADMIN_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Order by ID (HTTP $http_code)"
        else
            print_failure "Get Order by ID" "HTTP $http_code"
            print_response "$body"
        fi
        
        # Test: Get Order History
        print_test "Get Order History"
        response=$(make_request GET "${BASE_URL}/admin/homeservices/orders/${CREATED_ORDER_ID}/history" "" "$ADMIN_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Order History (HTTP $http_code)"
        else
            print_failure "Get Order History" "HTTP $http_code"
            print_response "$body"
        fi
    fi
    
    # Test: Get Order by Number
    if [ -n "$CREATED_ORDER_NUMBER" ]; then
        print_test "Get Order by Number"
        response=$(make_request GET "${BASE_URL}/admin/homeservices/orders/number/${CREATED_ORDER_NUMBER}" "" "$ADMIN_TOKEN")
        parsed=$(parse_response "$response")
        http_code=$(echo "$parsed" | cut -d'|' -f1)
        body=$(echo "$parsed" | cut -d'|' -f2-)
        
        if is_success "$http_code"; then
            print_success "Get Order by Number (HTTP $http_code)"
        else
            print_failure "Get Order by Number" "HTTP $http_code"
            print_response "$body"
        fi
    fi
}

test_admin_analytics() {
    print_section "Admin Analytics Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Admin analytics tests - No admin token provided"
        return
    fi
    
    local from_date=$(date -d "-30 days" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "2024-01-01")
    local to_date=$(date +%Y-%m-%d)
    
    # Test: Get Overview Analytics
    print_test "Get Overview Analytics"
    local response=$(make_request GET "${BASE_URL}/admin/homeservices/analytics/overview?fromDate=${from_date}&toDate=${to_date}&groupBy=day" "" "$ADMIN_TOKEN")
    local parsed=$(parse_response "$response")
    local http_code=$(echo "$parsed" | cut -d'|' -f1)
    local body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Overview Analytics (HTTP $http_code)"
    else
        print_failure "Get Overview Analytics" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Provider Analytics
    print_test "Get Provider Analytics"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/analytics/providers?fromDate=${from_date}&toDate=${to_date}&sortBy=earnings&limit=10" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Provider Analytics (HTTP $http_code)"
    else
        print_failure "Get Provider Analytics" "HTTP $http_code"
        print_response "$body"
    fi
    
    # Test: Get Revenue Report
    print_test "Get Revenue Report"
    response=$(make_request GET "${BASE_URL}/admin/homeservices/analytics/revenue?fromDate=${from_date}&toDate=${to_date}&groupBy=week" "" "$ADMIN_TOKEN")
    parsed=$(parse_response "$response")
    http_code=$(echo "$parsed" | cut -d'|' -f1)
    body=$(echo "$parsed" | cut -d'|' -f2-)
    
    if is_success "$http_code"; then
        print_success "Get Revenue Report (HTTP $http_code)"
    else
        print_failure "Get Revenue Report" "HTTP $http_code"
        print_response "$body"
    fi
}

#===============================================================================
# Cleanup Tests
#===============================================================================

test_cleanup() {
    print_section "Cleanup Tests"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_skip "Cleanup tests - No admin token provided"
        return
    fi
    
    # Delete created addon
    if [ -n "$CREATED_ADDON_SLUG" ]; then
        print_test "Delete Test Addon"
        local response=$(make_request DELETE "${BASE_URL}/admin/homeservices/addons/${CREATED_ADDON_SLUG}" "" "$ADMIN_TOKEN")
        local parsed=$(parse_response "$response")
        local http_code=$(echo "$parsed" | cut -d'|' -f1)
        
        if is_success "$http_code"; then
            print_success "Delete Test Addon (HTTP $http_code)"
        else
            print_failure "Delete Test Addon" "HTTP $http_code"
        fi
    fi
    
    # Delete created service
    if [ -n "$CREATED_SERVICE_SLUG" ]; then
        print_test "Delete Test Service"
        local response=$(make_request DELETE "${BASE_URL}/admin/homeservices/services/${CREATED_SERVICE_SLUG}" "" "$ADMIN_TOKEN")
        local parsed=$(parse_response "$response")
        local http_code=$(echo "$parsed" | cut -d'|' -f1)
        
        if is_success "$http_code"; then
            print_success "Delete Test Service (HTTP $http_code)"
        else
            print_failure "Delete Test Service" "HTTP $http_code"
        fi
    fi
    
    # Delete provider category (optional, might want to keep)
    if [ -n "$PROVIDER_CATEGORY_SLUG" ] && [ -n "$PROVIDER_TOKEN" ]; then
        print_test "Delete Provider Category"
        local response=$(make_request DELETE "${BASE_URL}/provider/categories/${PROVIDER_CATEGORY_SLUG}" "" "$PROVIDER_TOKEN")
        local parsed=$(parse_response "$response")
        local http_code=$(echo "$parsed" | cut -d'|' -f1)
        
        if is_success "$http_code"; then
            print_success "Delete Provider Category (HTTP $http_code)"
        else
            print_info "Could not delete provider category (may be in use)"
        fi
    fi
}

#===============================================================================
# Print Summary
#===============================================================================

print_summary() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                        TEST SUMMARY                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Total Tests:   ${WHITE}$TOTAL_TESTS${NC}$(printf '%*s' $((50 - ${#TOTAL_TESTS})) '')${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${GREEN}Passed:${NC}        ${GREEN}$PASSED_TESTS${NC}$(printf '%*s' $((50 - ${#PASSED_TESTS})) '')${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${RED}Failed:${NC}        ${RED}$FAILED_TESTS${NC}$(printf '%*s' $((50 - ${#FAILED_TESTS})) '')${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${YELLOW}Skipped:${NC}       ${YELLOW}$SKIPPED_TESTS${NC}$(printf '%*s' $((50 - ${#SKIPPED_TESTS})) '')${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"
    
    if [ $FAILED_TESTS -eq 0 ] && [ $TOTAL_TESTS -gt 0 ]; then
        echo -e "${PURPLE}║${NC}  ${GREEN}✓ ALL TESTS PASSED!${NC}$(printf '%*s' 46 '')${PURPLE}║${NC}"
    elif [ $FAILED_TESTS -gt 0 ]; then
        local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "${PURPLE}║${NC}  ${YELLOW}Pass Rate: ${pass_rate}%${NC}$(printf '%*s' $((52 - ${#pass_rate})) '')${PURPLE}║${NC}"
    fi
    
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    parse_args "$@"
    
    print_header "Home Services Module - API Test Suite"
    
    echo -e "${WHITE}Configuration:${NC}"
    echo -e "  API Host:        ${CYAN}$API_HOST${NC}"
    echo -e "  Base URL:        ${CYAN}$BASE_URL${NC}"
    echo -e "  Admin Token:     ${CYAN}$([ -n "$ADMIN_TOKEN" ] && echo "Provided" || echo "Not provided")${NC}"
    echo -e "  Customer Token:  ${CYAN}$([ -n "$CUSTOMER_TOKEN" ] && echo "Provided" || echo "Not provided")${NC}"
    echo -e "  Provider Token:  ${CYAN}$([ -n "$PROVIDER_TOKEN" ] && echo "Provided" || echo "Not provided")${NC}"
    
    # Check if API is reachable
    echo ""
    echo -e "${WHITE}Checking API connectivity...${NC}"
    if curl -s --connect-timeout 5 "$API_HOST/health" > /dev/null 2>&1 || curl -s --connect-timeout 5 "$API_HOST" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is reachable${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify API connectivity (will proceed anyway)${NC}"
    fi
    
    # Run tests based on flags
    if [ "$SKIP_ADMIN" != "true" ]; then
        test_admin_services
        test_admin_addons
        test_admin_categories
    fi
    
    if [ "$SKIP_CUSTOMER" != "true" ]; then
        test_customer_discovery
        test_customer_orders
    fi
    
    if [ "$SKIP_PROVIDER" != "true" ]; then
        test_provider_profile
        test_provider_categories
        test_provider_orders
    fi
    
    if [ "$SKIP_ADMIN" != "true" ]; then
        test_admin_orders
        test_admin_analytics
    fi
    
    # Cleanup
    test_cleanup
    
    # Print summary
    print_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    fi
    exit 0
}

# Run main function
main "$@"