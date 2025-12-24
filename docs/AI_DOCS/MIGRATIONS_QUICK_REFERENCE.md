# Quick Reference: Clean Migrations

## Migration File Structure

```
000050_clean_service_provider_profiles
├── .up.sql
│   └── CREATE TABLE service_provider_profiles (provider accounts)
└── .down.sql
    └── DROP TABLE service_provider_profiles

000051_clean_services_addons
├── .up.sql
│   ├── CREATE TABLE services (using service_slug)
│   └── CREATE TABLE addons (using addon_slug)
└── .down.sql
    ├── DROP TABLE addons
    └── DROP TABLE services

000052_clean_service_orders
├── .up.sql
│   ├── CREATE TABLE service_orders
│   ├── ADD CONSTRAINT assigned_provider_id → service_provider_profiles.id ✅
│   ├── CREATE TRIGGER generate_order_number
│   └── CREATE TRIGGER update_service_orders_updated_at
└── .down.sql
    ├── DROP TRIGGER generate_order_number
    ├── DROP TRIGGER update_service_orders_updated_at
    └── DROP TABLE service_orders

000053_clean_order_status_history
├── .up.sql
│   └── CREATE TABLE order_status_histories
└── .down.sql
    └── DROP TABLE order_status_histories

000054_clean_provider_service_categories
├── .up.sql
│   └── CREATE TABLE provider_service_categories
└── .down.sql
    └── DROP TABLE provider_service_categories

000055_clean_provider_qualified_services
├── .up.sql
│   └── CREATE TABLE provider_qualified_services
└── .down.sql
    └── DROP TABLE provider_qualified_services
```

## Key Tables & Their Purpose

### service_provider_profiles (000050)
**What:** Provider account information
**Relationships:** 
- FK to `users.id`
- Referenced by service orders
- Referenced by provider categories
**Example Query:**
```sql
SELECT * FROM service_provider_profiles 
WHERE user_id = '59e0d332-...' LIMIT 1;
```

### services (000051)
**What:** Individual service offerings
**Unique On:** `service_slug`
**References:** Uses `category_slug` (text, not FK)
**Example Query:**
```sql
SELECT * FROM services 
WHERE category_slug = 'cleaning' AND is_active = true;
```

### service_orders (000052)
**What:** Customer orders
**Key FK:** `assigned_provider_id` → `service_provider_profiles.id` ✅
**Uses Slugs For:** `category_slug`, `selected_services[].serviceSlug`
**Example Query:**
```sql
SELECT * FROM service_orders 
WHERE assigned_provider_id = 'fce4ac06-...' 
AND status = 'pending';
```

### provider_qualified_services (000055)
**What:** Which services each provider can perform
**FK1:** `provider_id` → `service_provider_profiles.id`
**FK2:** `service_id` → `services.id`
**Example Query:**
```sql
SELECT COUNT(*) FROM provider_qualified_services 
WHERE provider_id = 'fce4ac06-...' AND is_available = true;
-- Result: 8 (provider can do 8 services)
```

## Common Query Patterns

### Get provider's available orders (BEFORE vs AFTER)

**BEFORE (Broken - old migrations):**
```sql
-- This would fail with FK error because:
-- - Orders stored userID instead of providerID
-- - FK referenced users.id instead of service_provider_profiles.id
SELECT * FROM service_orders 
WHERE assigned_provider_id = 'wrong-id' AND status = 'pending';
```

**AFTER (Fixed - clean migrations):**
```sql
-- Get provider profile from user ID
SELECT id FROM service_provider_profiles 
WHERE user_id = '59e0d332-...';  -- Result: fce4ac06-...

-- Get provider's pending orders
SELECT * FROM service_orders 
WHERE assigned_provider_id = 'fce4ac06-...' AND status = 'pending';  -- ✅ Works!
```

### Get services in a category

**Slug-Based (New):**
```sql
SELECT * FROM services 
WHERE category_slug = 'cleaning' 
AND is_active = true
ORDER BY sort_order;
```

### Get provider's qualified services

```sql
SELECT s.*, pqs.is_available
FROM provider_qualified_services pqs
JOIN services s ON pqs.service_id = s.id
WHERE pqs.provider_id = 'fce4ac06-...'
AND pqs.is_available = true;
-- Result: 8 rows (services provider can perform)
```

## The Critical FK Fix

### In 000052_clean_service_orders.up.sql

```sql
-- ✅ CORRECT - References service_provider_profiles
assigned_provider_id UUID REFERENCES service_provider_profiles(id) ON DELETE SET NULL,

-- vs

-- ❌ WRONG (old way) - References users table
-- assigned_provider_id UUID REFERENCES users(id) ON DELETE SET NULL,
```

**Why This Matters:**
- Provider gets ProviderID when registered (service_provider_profiles.id)
- Services assigned to that ProviderID
- Orders must reference ProviderID, not UserID
- Old migrations referenced wrong table → FK errors

## Data Flow in New Schema

```
1. User Registers as Provider
   └─→ service_provider_profiles created with UUID
       └─→ ProviderID = 'fce4ac06-...'

2. Provider Selects Categories
   └─→ provider_service_categories created
       └─→ provider_id = 'fce4ac06-...'
           └─→ category_slug = 'cleaning'

3. Provider Auto-Assigned Services
   └─→ provider_qualified_services created (8 rows)
       └─→ provider_id = 'fce4ac06-...'
           └─→ service_id references services.id

4. Customer Creates Order
   └─→ service_orders created
       └─→ category_slug = 'cleaning'
           └─→ selected_services uses service_slug
           └─→ assigned_provider_id = NULL (pending)

5. System Offers Order to Provider
   └─→ Provider accepts
       └─→ assigned_provider_id = 'fce4ac06-...' ✅ WORKS!
           └─→ order_status_histories recorded
```

## Rollback Safety

Each migration has paired .down.sql:

| Up | Down |
|----|------|
| CREATE TABLE | DROP TABLE |
| ADD CONSTRAINT | DROP CONSTRAINT |
| CREATE TRIGGER | DROP TRIGGER |
| CREATE FUNCTION | DROP FUNCTION |

**Safe to rollback** - no data loss if done sequentially.

## File Locations

```
migrations/
├── 000001-000024/  (Keep - base setup)
├── 000025-000042/  (DELETE - messy old ones)
├── 000050_clean_service_provider_profiles.*  ← NEW
├── 000051_clean_services_addons.*  ← NEW
├── 000052_clean_service_orders.*  ← NEW (FK FIXED!)
├── 000053_clean_order_status_history.*  ← NEW
├── 000054_clean_provider_service_categories.*  ← NEW
└── 000055_clean_provider_qualified_services.*  ← NEW
```

## Summary

✅ 6 clean migrations
✅ Slug-based relationships (no ID FKs)
✅ Correct service_orders FK (→ service_provider_profiles, not users)
✅ Complete triggers & indexes
✅ Safe rollback with .down.sql files
✅ Clear, maintainable schema
