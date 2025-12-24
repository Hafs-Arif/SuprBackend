# Fix: Provider Has No Qualified Services

## Problem
Provider `749bd875-2336-41fa-a67d-06a511fe3213` has NO entries in `provider_qualified_services` table, so they can't see any orders.

## Root Causes
1. Provider registered before the fix was applied (old registration didn't assign services)
2. Service assignment failed during registration (FK constraint or other error)
3. Provider was created manually in DB without service assignments

## Solution: Re-assign Services to Provider

### Option 1: Re-register the Provider (Recommended)
1. Get the list of all services the provider should handle
2. Call the registration endpoint again with those service IDs
3. This will ensure proper setup

### Option 2: Manually Assign Services (SQL)

First, identify which services the provider should handle:

```sql
-- Check all available services in DB
SELECT id, title, category_slug FROM services LIMIT 20;
```

Then assign services to the provider:

```sql
-- Example: Assign cleaning services to provider
INSERT INTO provider_qualified_services (provider_id, service_id)
SELECT 
  '749bd875-2336-41fa-a67d-06a511fe3213' as provider_id,
  s.id as service_id
FROM services s
WHERE s.category_slug = 'cleaning-services'  -- or any other category
  AND s.is_active = true
ON CONFLICT DO NOTHING;
```

### Option 3: Create a Bulk Fix SQL Script

Run this to assign ALL ACTIVE SERVICES to the provider:

```sql
-- Assign all active services to provider
INSERT INTO provider_qualified_services (provider_id, service_id)
SELECT 
  '749bd875-2336-41fa-a67d-06a511fe3213' as provider_id,
  s.id as service_id
FROM services s
WHERE s.is_active = true
  AND s.is_available = true
ON CONFLICT DO NOTHING;

-- Verify assignment
SELECT COUNT(*) as assigned_services FROM provider_qualified_services
WHERE provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';

-- Verify provider can now see orders
SELECT DISTINCT s.category_slug FROM services s
JOIN provider_qualified_services pqs ON s.id = pqs.service_id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';
```

## Verification

After running the fix, the API call should:

1. Return provider's qualified categories in metadata
2. Show available orders matching those categories
3. Return `"ordersFound": true` with actual order data

### Check with SQL:
```sql
-- Provider's categories (should not be empty)
SELECT DISTINCT s.category_slug 
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213';

-- Orders in those categories (should show available orders)
SELECT id, order_number, category_slug FROM service_orders
WHERE category_slug IN (
  SELECT DISTINCT s.category_slug 
  FROM provider_qualified_services pqs
  JOIN services s ON pqs.service_id = s.id
  WHERE pqs.provider_id = '749bd875-2336-41fa-a67d-06a511fe3213'
)
AND status IN ('pending', 'searching_provider')
AND assigned_provider_id IS NULL;
```

## Prevention for Future

To prevent this issue for new registrations:

1. **Add validation** in registration endpoint to confirm services were assigned
2. **Add error handling** to fail registration if service assignment fails  
3. **Add automated testing** to verify provider can see orders after registration
4. **Add health check endpoint** to verify provider data consistency

Current logging has been enhanced to show:
- `"attempting to assign service to provider"` - when assignment starts
- `"failed to assign service to provider"` - if FK constraint fails
- `"service assigned successfully"` - confirmation with rowsAffected count

Check logs when registering new providers to ensure services are being assigned.
