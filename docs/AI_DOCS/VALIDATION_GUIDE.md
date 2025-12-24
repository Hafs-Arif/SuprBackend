# UserID vs ProviderID Fix - Validation Guide

## Quick Summary

**What was broken:** New providers couldn't see available orders after registration
**Root cause:** Handler was using UserID instead of ProviderID when querying database
**Solution:** Added service method `GetProviderIDByUserID()` and helper in handler to convert IDs before service calls

---

## Step-by-Step Validation

### Step 1: Register a New Provider

```bash
curl -X POST http://localhost:8080/api/v1/services/provider/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <NEW_USER_TOKEN>" \
  -d '{
    "service_categories": ["cleaning", "plumbing", "electrical", "repairs", "painting", "carpentry"]
  }'
```

**Expected Response:**
```json
{
  "status": 201,
  "message": "Provider registered successfully",
  "data": {
    "id": "fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9",
    "user_id": "59e0d332-133b-4d41-8db1-3a363c74b744",
    "name": "Provider Name",
    "email": "provider@example.com",
    "services": 8,
    "categories": [
      "cleaning",
      "plumbing",
      "electrical",
      "repairs",
      "painting",
      "carpentry"
    ]
  }
}
```

**Key Points:**
- Note the `id` (ProviderID): This is what should be used for queries
- Note the `user_id` (UserID): This comes from the auth token
- 8 services should be assigned during registration

---

### Step 2: Fetch Provider Profile

```bash
curl -X GET http://localhost:8080/api/v1/provider/profile \
  -H "Authorization: Bearer <NEW_USER_TOKEN>"
```

**Expected Response:**
```json
{
  "status": 200,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9",
    "user_id": "59e0d332-133b-4d41-8db1-3a363c74b744",
    "name": "Provider Name",
    "email": "provider@example.com",
    "phone": "+1234567890",
    "is_verified": false,
    "is_available": true,
    "service_categories": [
      {
        "slug": "cleaning",
        "name": "Cleaning",
        "is_active": true
      },
      {
        "slug": "plumbing",
        "name": "Plumbing",
        "is_active": true
      },
      // ... 6 categories total
    ],
    "statistics": {
      "total_orders": 0,
      "completed_orders": 0,
      "rating": 0,
      "response_time": 0
    }
  }
}
```

**What to verify:**
- ✅ Shows 6 service categories
- ✅ Profile data is correct
- ✅ No 401 Unauthorized errors
- ✅ No null values for service_categories

---

### Step 3: Fetch Available Orders (CRITICAL TEST)

```bash
curl -X GET "http://localhost:8080/api/v1/provider/orders/available?page=1&limit=100" \
  -H "Authorization: Bearer <NEW_USER_TOKEN>"
```

**Expected Response:**
```json
{
  "status": 200,
  "message": "Available orders retrieved successfully",
  "data": [
    {
      "id": "order-uuid-1",
      "customer_name": "John Doe",
      "category_slug": "cleaning",
      "category_name": "Cleaning",
      "service_name": "House Cleaning",
      "booking_date": "2025-12-20T10:00:00Z",
      "estimated_duration": 120,
      "price": 150.00,
      "location": "123 Main St, City, State",
      "distance": 5.2,
      "created_at": "2025-12-17T10:30:00Z"
    },
    // ... more orders
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 2,
    "total_items": 8,
    "per_page": 100
  }
}
```

**Critical Checks:**
- ✅ Status 200 (NOT 401 or 500)
- ✅ Returns 8+ orders (NOT 0)
- ✅ Orders have category_slug matching registered categories
- ✅ No "qualifiedServices: null" message in logs
- ✅ No "provider has no active categories" error

---

### Step 4: Accept an Order

```bash
curl -X POST "http://localhost:8080/api/v1/provider/orders/{order_id}/accept" \
  -H "Authorization: Bearer <NEW_USER_TOKEN>"
```

**Expected Response:**
```json
{
  "status": 200,
  "message": "Order accepted successfully",
  "data": {
    "id": "order-uuid-1",
    "status": "accepted_by_provider",
    "customer_name": "John Doe",
    "assigned_provider_id": "fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9",
    // ... order details
  }
}
```

---

### Step 5: Get My Orders

```bash
curl -X GET "http://localhost:8080/api/v1/provider/orders?page=1&limit=100" \
  -H "Authorization: Bearer <NEW_USER_TOKEN>"
```

**Expected Response:**
```json
{
  "status": 200,
  "message": "Orders retrieved successfully",
  "data": [
    {
      "id": "order-uuid-1",
      "status": "accepted_by_provider",
      "customer_name": "John Doe",
      "category_slug": "cleaning",
      "booking_date": "2025-12-20T10:00:00Z",
      "accepted_at": "2025-12-17T11:45:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_items": 1,
    "per_page": 100
  }
}
```

---

## Database Verification

### Check Provider Qualified Services

```sql
-- Verify services were assigned to the PROVIDER_ID (not USER_ID)
SELECT 
  pqs.provider_id,
  COUNT(*) as service_count,
  s.name as sample_service
FROM provider_qualified_services pqs
JOIN service_orders s ON pqs.service_id = s.id
WHERE pqs.provider_id = 'fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9'
GROUP BY pqs.provider_id;

-- Expected: 1 row with service_count = 8
```

### Check ServiceProviderProfile

```sql
-- Verify the relationship between UserID and ProviderID
SELECT 
  id as provider_id,
  user_id,
  service_type,
  is_verified
FROM service_provider_profiles
WHERE user_id = '59e0d332-133b-4d41-8db1-3a363c74b744';

-- Expected: 1 row with matching IDs
```

---

## Common Issues and Solutions

### Issue: Still getting "provider has no active categories"

**Check 1:** Verify the provider was found
```sql
SELECT * FROM service_provider_profiles 
WHERE id = 'fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9';
-- Should return 1 row
```

**Check 2:** Verify services are assigned
```sql
SELECT COUNT(*) FROM provider_qualified_services 
WHERE provider_id = 'fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9';
-- Should return 8
```

**Check 3:** Verify categories are marked active
```sql
SELECT * FROM provider_service_categories 
WHERE provider_id = 'fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9' 
AND is_active = true;
-- Should return 6 rows
```

### Issue: Still getting 0 orders

**Check 1:** Look at application logs for the actual provider ID being used
```
grep "queried provider_service_categories" app.log
```
Should show: `providerID: fce4ac06-...` (NOT `59e0d332-...`)

**Check 2:** Verify available orders exist
```sql
SELECT COUNT(*) FROM service_orders 
WHERE category_slug IN ('cleaning', 'plumbing', 'electrical', 'repairs', 'painting', 'carpentry')
AND status = 'pending';
-- Should return multiple orders
```

---

## Before/After Comparison

### BEFORE FIX

Handler code:
```go
func (h *Handler) GetAvailableOrders(c *gin.Context) {
	providerID, _ := c.Get("userID")  // ❌ WRONG: Using UserID
	orders, _, err := h.service.GetAvailableOrders(ctx, providerID.(string), ...)  // Queries with UserID
}
```

Result:
```
userID: 59e0d332-133b-4d41-8db1-3a363c74b744
Query: SELECT * FROM provider_qualified_services WHERE provider_id = '59e0d332-...'
Result: 0 rows (because 8 services are assigned to 'fce4ac06-...' not '59e0d332-...')
Response: Available orders: 0
```

### AFTER FIX

Handler code:
```go
func (h *Handler) GetAvailableOrders(c *gin.Context) {
	providerID, err := h.getProviderIDFromContext(c)  // ✅ RIGHT: Convert UserID to ProviderID
	orders, _, err := h.service.GetAvailableOrders(ctx, providerID, ...)  // Queries with ProviderID
}

func (h *Handler) getProviderIDFromContext(c *gin.Context) (string, error) {
	userID, _ := c.Get("userID")  // Get UserID from context: 59e0d332-...
	providerID, err := h.service.GetProviderIDByUserID(ctx, userID.(string))  // Look up: 59e0d332-... → fce4ac06-...
	return providerID, nil  // Return ProviderID: fce4ac06-...
}
```

Result:
```
userID: 59e0d332-133b-4d41-8db1-3a363c74b744
Lookup: SELECT id FROM service_provider_profiles WHERE user_id = '59e0d332-...'
Found ProviderID: fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9
Query: SELECT * FROM provider_qualified_services WHERE provider_id = 'fce4ac06-...'
Result: 8 rows (all 8 services)
Response: Available orders: 8 ✅
```

---

## Summary

The fix ensures that **all provider handler methods** now correctly:

1. Extract UserID from auth token
2. Query database to find associated ProviderID
3. Use ProviderID for all subsequent database queries
4. Return correct data to the provider

This resolves the systematic bug that prevented new providers from seeing orders despite having services correctly assigned during registration.
