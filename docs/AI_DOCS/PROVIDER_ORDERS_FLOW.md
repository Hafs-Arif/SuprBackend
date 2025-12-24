# Provider Orders Fetching - Complete Flow Analysis

## Current Status
Provider calling `GET /api/v1/provider/orders/available` gets **0 orders** even though **8 orders exist in the database**.

## The Flow (Step by Step)

### Step 1: Provider Registration
```
POST /api/v1/provider/register
{
  "serviceIds": ["uuid1", "uuid2", "uuid3"],
  "categorySlug": "cleaning-services",
  ...
}
```

**What happens:**
- Creates `ServiceProviderProfile` with `ServiceType = "cleaning-services"`
- Stores in `provider_qualified_services`:
  - provider_id: 749bd875-2336-41fa-a67d-06a511fe3213
  - service_id: uuid1, uuid2, uuid3 (each as separate row)

**Example Data in DB:**
```
provider_qualified_services:
- provider_id: 749bd875-2336-41fa-a67d-06a511fe3213, service_id: abc123 (home-cleaning service)
- provider_id: 749bd875-2336-41fa-a67d-06a511fe3213, service_id: def456 (carpet-cleaning service)
```

---

### Step 2: Customer Places Order
```
POST /api/v1/customer/orders
{
  "items": [{ "serviceId": "abc123", ... }],
  ...
}
```

**What happens in CreateOrder:**
```go
svc := s.repo.GetServiceNewByID(ctx, "abc123")  // Fetch service
// Service has: id="abc123", categorySlug="cleaning-services", title="Home Cleaning"
order.CategorySlug = svc.CategorySlug  // Set to "cleaning-services"
order.Status = "searching_provider"
s.repo.CreateOrder(ctx, order)
```

**Created Order in DB:**
```
service_orders:
- id: 2563c103-17b0-42d6-930a-1205b75963c7
- category_slug: "cleaning-services"
- status: "searching_provider"
- selected_services: [{"serviceSlug": "home-cleaning", ...}]
```

---

### Step 3: Provider Fetches Available Orders
```
GET /api/v1/provider/orders/available?page=1&limit=100
```

**Current Implementation:**

#### 3a. Get Provider's Category Slugs
```go
GetProviderCategorySlugs(providerID) 
```

**Query 1: From provider_service_categories table**
```sql
SELECT DISTINCT category_slug FROM provider_service_categories
WHERE provider_id = '749bd875-2336-41fa-a67d-06a511fe3213'
  AND is_active = true
```
❌ **Returns: EMPTY** (provider_service_categories is empty!)

**Query 2 (Fallback): Derive from qualified services**
```sql
SELECT DISTINCT s.category_slug 
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213'
```

✅ **Should return: ["cleaning-services"]**

If this step works correctly, continue to Step 3b...

#### 3b. Query for Available Orders
```go
GetAvailableOrders(categorySlugs=["cleaning-services"], ...)
```

**SQL Query:**
```sql
SELECT * FROM service_orders
WHERE status IN ('pending', 'searching_provider')
  AND category_slug IN ('cleaning-services')
  AND assigned_provider_id IS NULL
  AND (expires_at IS NULL OR expires_at > NOW())
```

✅ **Should return: All 4 cleaning-services orders**

---

## Possible Issues (In Order of Likelihood)

### Issue #1: Provider has NO qualified services
**Symptom:** `qualified_services` array is empty
**Root Cause:** 
- Provider registered with `serviceIds: []` (empty list)
- OR registered with UUIDs that don't exist in services table
- OR service IDs were never assigned to provider

**Check:**
```sql
SELECT * FROM provider_qualified_services 
WHERE provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';
```
Expected: Should have rows. If empty → **This is the problem!**

---

### Issue #2: Services have DIFFERENT category_slug than orders
**Symptom:** Orders have `category_slug = "women-spa"` but services have `category_slug = "spa-women"`
**Root Cause:** Mismatch between service definitions and order category assignments

**Check:**
```sql
-- What services is provider qualified for?
SELECT DISTINCT s.category_slug, s.title FROM services s
JOIN provider_qualified_services pqs ON s.id = pqs.service_id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';

-- What categories do orders have?
SELECT DISTINCT category_slug FROM service_orders;
```
Expected: Category slugs should match. If different → **This is the problem!**

---

### Issue #3: Orders' status is NOT in the expected list
**Symptom:** Orders exist but all have status `"searching_provider"` and query filters for `['pending', 'searching_provider']`
**Root Cause:** Status field mismatch

**Check:**
```sql
SELECT DISTINCT status FROM service_orders;
```
Expected: Should include `'pending'` or `'searching_provider'`. If neither → **Check status constants!**

---

### Issue #4: Orders are already assigned
**Symptom:** `assigned_provider_id` is NOT NULL for matching orders
**Root Cause:** Another provider already accepted the order

**Check:**
```sql
SELECT id, assigned_provider_id FROM service_orders 
WHERE category_slug IN (provider's categories);
```
Expected: `assigned_provider_id` should be NULL. If not → Order is already taken.

---

## Debug Steps (Run These SQL Queries)

### Query 1: Check Provider's Qualified Services
```sql
SELECT pqs.provider_id, s.id, s.title, s.category_slug
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213'
ORDER BY s.category_slug;
```

### Query 2: Check Available Orders
```sql
SELECT id, order_number, category_slug, status, assigned_provider_id
FROM service_orders
WHERE status IN ('pending', 'searching_provider')
  AND assigned_provider_id IS NULL
  AND expires_at > NOW()
ORDER BY category_slug;
```

### Query 3: Compare Categories
```sql
-- Provider's categories (from qualified services)
SELECT DISTINCT s.category_slug as provider_category
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';

-- Order categories (available orders)
SELECT DISTINCT category_slug as order_category
FROM service_orders
WHERE status IN ('pending', 'searching_provider')
  AND assigned_provider_id IS NULL;
```

Expected: Both queries should return same categories. If different → **Category mismatch!**

---

## API Response Flow (With New Metadata)

### Success Case (Orders Found)
```json
{
  "success": true,
  "message": "Found 4 available orders matching your qualifications",
  "data": {
    "orders": [/* 4 orders */],
    "metadata": {
      "providerId": "749bd875-2336-41fa-a67d-06a511fe3213",
      "qualifiedCategories": ["cleaning-services"],
      "totalCategoriesCount": 1,
      "ordersFound": true,
      "message": "Found 4 available orders matching your qualifications",
      "searchFilters": { "page": 1, "limit": 100, ... }
    },
    "totalCount": 4,
    "pageCount": 1
  }
}
```

### Failure Case (No Categories)
```json
{
  "success": true,
  "message": "No orders available for your qualified services",
  "data": {
    "orders": [],
    "metadata": {
      "providerId": "749bd875-2336-41fa-a67d-06a511fe3213",
      "qualifiedCategories": [],  // EMPTY - THIS IS THE PROBLEM!
      "totalCategoriesCount": 0,
      "ordersFound": false,
      "message": "No orders available for your qualified services"
    },
    "totalCount": 0,
    "pageCount": 0
  }
}
```

---

## Logs to Check

When you call the endpoint, check for these log lines:

```
{"msg":"queried provider_service_categories","providerID":"...","foundCategories":[],"count":0}
{"msg":"no provider_service_categories found, deriving from qualified services","providerID":"..."}
{"msg":"provider qualified services","providerID":"...","qualifiedServices":[...]}  ← Check this!
{"msg":"derived provider categories from services","providerID":"...","derivedCategories":["cleaning-services"],"count":1}
{"msg":"GetAvailableOrders query filters","categorySlugs":["cleaning-services"],"statusFilters":["pending","searching_provider"]}
{"msg":"counted available orders","total":4,"categorySlugs":["cleaning-services"]}
```

---

## Solution

**To fix "no orders fetched" issue:**

1. **Run the debug queries above** to identify which step is failing
2. **Check logs** from the endpoint call to see what categories were detected
3. **Based on findings:**
   - If qualified_services is empty → Re-register provider with correct service IDs
   - If category_slug mismatch → Update services or fix order creation
   - If orders have wrong status → Check order creation logic
   - If provider_id mismatch → Verify you're using correct provider ID

4. **Then test again** - orders should appear!
