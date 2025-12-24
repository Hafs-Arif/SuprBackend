# Clean Home Services Migrations - Fresh Start

## Overview

Complete replacement of messy migrations (000025-000041) with clean, well-structured slug-based migrations (000050-000055).

## Why This Was Needed

The old migrations were:
- ❌ Duplicated (multiple files with same purpose)
- ❌ Incomplete (mixing old ID-based with new slug-based schemas)
- ❌ Conflicting (foreign key constraints to wrong tables)
- ❌ Hard to maintain (unclear dependencies)

## New Architecture: Slug-Based Relations

Instead of database foreign keys by ID, the new schema uses **slug strings** for relationships:
- Services are identified by `service_slug` (not ID)
- Addons are identified by `addon_slug` (not ID)
- Categories are identified by `category_slug` (not ID)

**Advantages:**
- ✅ Slugs are human-readable
- ✅ No database FK constraints needed
- ✅ Can change data without broken references
- ✅ Easier to migrate/update content
- ✅ Application logic handles validation

## Clean Migrations (000050-000055)

### 000050: Service Provider Profiles
**Tables Created:**
- `service_provider_profiles` - Provider accounts with business info

**Key Features:**
- UUID primary key
- FK to `users` table for authentication
- All provider metadata (rating, availability, services)

### 000051: Services & Add-ons
**Tables Created:**
- `services` - Individual service offerings
- `addons` - Optional additions to services

**Key Features:**
- Uses `service_slug` and `addon_slug` (not ID-based FKs)
- Uses `category_slug` (text reference, not FK)
- Service duration, pricing, active status
- Sort order and featured flag

### 000052: Service Orders
**Tables Created:**
- `service_orders` - Customer orders

**Key Features:**
- ✅ CORRECT FK: `assigned_provider_id` → `service_provider_profiles.id`
- Uses JSONB for flexible data storage:
  - `customer_info` - Customer snapshot
  - `booking_info` - Booking details
  - `selected_services` - Services ordered
  - `selected_addons` - Addons ordered
  - `payment_info` - Payment details
- Triggers for `order_number` generation and `updated_at`
- Status tracking with history
- Ratings for both customer and provider

### 000053: Order Status History
**Tables Created:**
- `order_status_histories` - Status change log

**Key Features:**
- Tracks every status change
- Records who changed it and why
- FK to `service_orders` and `users`

### 000054: Provider Service Categories
**Tables Created:**
- `provider_service_categories` - Categories a provider offers

**Key Features:**
- FK to `service_provider_profiles` (UUID)
- `category_slug` text reference (not FK)
- Unique constraint: provider can't add same category twice

### 000055: Provider Qualified Services
**Tables Created:**
- `provider_qualified_services` - Specific services a provider can perform

**Key Features:**
- FK to `service_provider_profiles` (UUID)
- FK to `services` (UUID)
- Unique constraint: no duplicate assignments
- Tracks availability status

## Migration Strategy

### Clean Up Old Migrations
The following old migrations should be deleted (they're replaced):
```
000025_new_service_tables_migrate_full.*
000026_create_services_table.*
000027_create_addons_table.*
000028_create_service_orders_table.*
000029_create_order_status_history_table.*
000030_create_provider_service_categories.*
000031_fix_service_table.*
000032_update_user_table_constraint.*
000033_create_provider_qualified_services.*
000033_create_service_providers_table.*
000034_create_provider_qualified_services.*
000034_create_service_providers_table.*
000035_add_fk_provider_service_categories.*
000035_create_service_providers_table.*
000036_add_fk_provider_service_categories.*
000036_remove_invalid_fk_from_provider_service_categories.*
000037_remove_invalid_fk_from_provider_service_categories.*
000038_ensure_provider_qualified_services_exists.*
000039_create_service_provider_profiles.*
000040_fix_service_provider_profiles_schema.*
000041_fix_provider_qualified_services_fk.*
```

### How to Deploy

**Option 1: Fresh Database**
```bash
# Just run the new migrations
migrate -path ./migrations -database "postgres://..." up
```

**Option 2: Existing Database**
```bash
# First rollback to migration 000024
migrate -path ./migrations -database "postgres://..." down 26

# Then run new migrations
migrate -path ./migrations -database "postgres://..." up
```

## Schema Diagram

```
users (existing)
  ↓
service_provider_profiles (000050)
  ├─→ provider_service_categories (000054)
  │     └─ uses category_slug (text reference)
  └─→ provider_qualified_services (000055)
       └─→ services (000051) via FK

services (000051)
  └─ uses service_slug, category_slug (text references)

addons (000051)
  └─ uses addon_slug, category_slug (text references)

service_orders (000052)
  ├─→ users (customer_id FK)
  ├─→ service_provider_profiles (assigned_provider_id FK) ← KEY: Fixed FK!
  ├─ uses category_slug (text reference)
  └─→ order_status_histories (000053) via order_id FK
```

## Key Fixes Applied

### 1. Foreign Key Constraint (FK)
**Before (Broken):**
```sql
assigned_provider_id UUID REFERENCES users(id)  -- ❌ WRONG!
```

**After (Fixed):**
```sql
assigned_provider_id UUID REFERENCES service_provider_profiles(id)  -- ✅ CORRECT!
```

### 2. Slug-Based Relations
**Before:**
- Services referenced by ID with multiple FK constraints

**After:**
- Services identified by slug
- Categories identified by slug
- Relationships managed by application logic

### 3. Clear Separation of Concerns
- Provider tables (provider_service_categories, provider_qualified_services)
- Service tables (services, addons)
- Order tables (service_orders, order_status_histories)

## Testing the New Migrations

```bash
# Test up migration
migrate -path ./migrations -database "postgres://localhost:5432/go_backend?sslmode=disable" up

# Verify tables created
psql -U go_backend_admin -d go_backend -c "\dt" | grep -E "service_|provider_|order_status"

# Test down migration
migrate -path ./migrations -database "postgres://localhost:5432/go_backend?sslmode=disable" down 6

# Verify tables dropped
psql -U go_backend_admin -d go_backend -c "\dt" | grep -E "service_|provider_|order_status"
```

## Important Notes

1. **No ID-Based FKs for Slug References**
   - `category_slug` is NOT a FK - it's a text reference
   - Application validates that slug exists before using it
   - This provides flexibility for content management

2. **UUID Primary Keys**
   - All tables use UUID primary keys
   - Consistent with rest of application

3. **Soft Deletes**
   - `service_provider_profiles`, `services`, `addons` have `deleted_at` timestamp
   - Orders and history are hard-deleted (cascading)

4. **JSONB Storage**
   - Service orders use JSONB for flexible data (customer_info, booking_info, etc.)
   - Allows storing variable data without schema changes

5. **Indexes**
   - Comprehensive indexes for filtering and searching
   - Composite indexes for common query patterns

## Rollback Safety

Each migration has a corresponding `.down.sql` file:
- Creates table → Down drops table
- Adds constraint → Down removes constraint
- Triggers created → Down drops triggers

All rollbacks are tested and safe.
