# Provider ID Reference Guide

## Important: USER ID vs PROVIDER ID

When working with the provider system, always distinguish between:

- **USER ID**: Assigned when user registers as a regular user
- **PROVIDER ID**: Generated when user registers as a service provider (creates ServiceProviderProfile)

---

## Current Provider IDs in Database

### Production Providers

| Provider ID | User ID | Name | Service Type | Services | Orders | Status |
|---|---|---|---|---|---|---|
| `995adb5b-5cc1-43ce-8d87-27a4cb30b2e2` | `749bd875-2336-41fa-a67d-06a511fe3213` | Provider 1 | men-salon | 43 | 8 | ✅ Active |
| `f0b376dc-37ff-432c-b61b-e57275ea4271` | `34d15106-7285-42b8-b27f-80c5fc2eb55e` | Provider 2 | men-spa | 43 | 8 | ✅ Active |
| `19ed9d7b-b193-4ade-aa64-c611e46c191a` | `560e71ee-10ad-441e-a2e9-94c51068088c` | Provider 3 | men-spa | 43 | 8 | ✅ Active |
| `8943f1a0-7139-4d82-a7d0-d25a83e8ac9f` | `a4bf38df-3866-4b77-8b5a-0f6bdbc090d2` | Provider 4 | pest-control | 43 | 8 | ✅ Active |
| `4b4f8116-9634-4922-ab43-6d1e514e810c` | `442e39f1-8243-4433-888f-bac6a20d3a03` | Provider 5 | men-salon | 43 | 8 | ✅ Active |

---

## API Usage Examples

### Getting Provider Profile

```bash
curl -X GET "http://localhost:8080/api/v1/provider/profile" \
  -H "Authorization: Bearer <user-token>" \
  -H "Content-Type: application/json"
```

**Response** (uses USER ID in auth header, returns PROVIDER ID in response):
```json
{
  "success": true,
  "data": {
    "providerId": "995adb5b-5cc1-43ce-8d87-27a4cb30b2e2",
    "userId": "749bd875-2336-41fa-a67d-06a511fe3213",
    "serviceType": "men-salon",
    "qualifiedServices": 43,
    "availableOrders": 8
  }
}
```

### Fetching Available Orders

```bash
curl -X GET "http://localhost:8080/api/v1/provider/orders/available?page=1&limit=10" \
  -H "Authorization: Bearer <user-token>" \
  -H "Content-Type: application/json"
```

**Query Parameters**:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `categorySlug`: Filter by category (optional)
- `sortBy`: Sort field (default: created_at)
- `sortDesc`: Sort descending (default: true)

**Response**:
```json
{
  "success": true,
  "message": "Found 8 available orders matching your qualifications",
  "data": {
    "orders": [
      {
        "id": "431122ad-555d-4c01-91c6-cecb928d2196",
        "orderNumber": "HS-2025-881302",
        "categorySlug": "men-salon",
        "status": "searching_provider",
        "totalPrice": 398.00
      }
    ],
    "metadata": {
      "providerId": "995adb5b-5cc1-43ce-8d87-27a4cb30b2e2",
      "qualifiedCategories": [
        "cleaning-services",
        "men-salon",
        "men-spa",
        "women-spa"
      ],
      "totalCategoriesCount": 4,
      "ordersFound": true,
      "message": "Provider has access to 4 categories with 8 matching orders"
    },
    "totalCount": 8,
    "pageCount": 1
  }
}
```

---

## Database Queries for Reference

### Get All Provider Info with Services Count

```sql
SELECT 
  spp.id as provider_id,
  spp.user_id,
  spp.service_type,
  COUNT(DISTINCT pqs.service_id) as qualified_services_count,
  COUNT(DISTINCT so.id) as available_orders_count
FROM service_provider_profiles spp
LEFT JOIN provider_qualified_services pqs ON spp.id = pqs.provider_id
LEFT JOIN services s ON pqs.service_id = s.id
LEFT JOIN service_orders so ON so.category_slug = s.category_slug
  AND so.status IN ('pending', 'searching_provider')
  AND so.assigned_provider_id IS NULL
GROUP BY spp.id, spp.user_id, spp.service_type
ORDER BY spp.created_at DESC;
```

### Get Specific Provider Details (by USER ID)

```sql
SELECT 
  spp.id as provider_id,
  spp.user_id,
  spp.service_type,
  COUNT(DISTINCT pqs.service_id) as qualified_services,
  COUNT(DISTINCT CASE WHEN so.id IS NOT NULL THEN so.id END) as available_orders,
  STRING_AGG(DISTINCT s.category_slug, ', ') as available_categories
FROM service_provider_profiles spp
LEFT JOIN provider_qualified_services pqs ON spp.id = pqs.provider_id
LEFT JOIN services s ON pqs.service_id = s.id
LEFT JOIN service_orders so ON so.category_slug = s.category_slug
  AND so.status IN ('pending', 'searching_provider')
  AND so.assigned_provider_id IS NULL
WHERE spp.user_id = '749bd875-2336-41fa-a67d-06a511fe3213'
GROUP BY spp.id, spp.user_id, spp.service_type;
```

---

## Troubleshooting

### Issue: "Provider not found" error

**Solution**: Verify you're using the correct PROVIDER ID, not USER ID

```sql
-- Find provider by USER ID
SELECT id as provider_id FROM service_provider_profiles 
WHERE user_id = '749bd875-2336-41fa-a67d-06a511fe3213';
```

### Issue: Provider sees 0 orders

**Check 1**: Does provider have qualified services?
```sql
SELECT COUNT(*) FROM provider_qualified_services
WHERE provider_id = '995adb5b-5cc1-43ce-8d87-27a4cb30b2e2';
-- Should return > 0
```

**Check 2**: Do orders exist in provider's categories?
```sql
SELECT DISTINCT s.category_slug
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = '995adb5b-5cc1-43ce-8d87-27a4cb30b2e2';
-- Should return category list
```

**Check 3**: Do orders exist in those categories?
```sql
SELECT COUNT(*) FROM service_orders
WHERE category_slug IN (
  SELECT DISTINCT s.category_slug
  FROM provider_qualified_services pqs
  JOIN services s ON pqs.service_id = s.id
  WHERE pqs.provider_id = '995adb5b-5cc1-43ce-8d87-27a4cb30b2e2'
)
AND status IN ('pending', 'searching_provider')
AND assigned_provider_id IS NULL;
-- Should return > 0
```

---

## Adding a New Service to a Provider

### Option 1: During Registration (Recommended)

The registration flow automatically assigns selected services:

```bash
POST /api/v1/provider/register
Body:
{
  "serviceIds": ["uuid-1", "uuid-2", "uuid-3"],
  "serviceType": "men-salon",
  ...
}
```

Services are automatically inserted into `provider_qualified_services`.

### Option 2: Manual SQL (if needed)

```sql
INSERT INTO provider_qualified_services (provider_id, service_id)
VALUES ('995adb5b-5cc1-43ce-8d87-27a4cb30b2e2', 'uuid-of-service')
ON CONFLICT DO NOTHING;
```

---

## Available Service Categories

All providers have access to these 6 categories:

| Category Slug | Display Name | Service Count |
|---|---|---|
| `cleaning-services` | Cleaning Services | 1 |
| `men-salon` | Men's Salon | 5+ |
| `men-spa` | Men's Spa | 3+ |
| `pest-control` | Pest Control | 8+ |
| `women-salon` | Women's Salon | 10+ |
| `women-spa` | Women's Spa | 2+ |

---

**Last Updated**: 2025-12-17
**Version**: 1.0
**Status**: Production Ready ✅
