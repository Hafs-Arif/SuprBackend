# Migration Transition Guide

## From Messy Migrations → Clean Migrations

### Current State (Before)
- 17 messy migration files (000025-000041)
- Multiple conflicts and duplicates
- Wrong FK constraints
- Mixed ID-based and slug-based schemas

### New State (After)
- 6 clean migration files (000050-000055)
- Clear structure and dependencies
- ✅ Correct FK to `service_provider_profiles`
- Consistent slug-based relationships

---

## Files to Delete

**Complete Migration Cleanup Required:**

```powershell
# Remove these files from migrations/ directory:
Remove-Item migrations/000025_new_service_tables_migrate_full.*
Remove-Item migrations/000026_create_services_table.*
Remove-Item migrations/000027_create_addons_table.*
Remove-Item migrations/000028_create_service_orders_table.*
Remove-Item migrations/000029_create_order_status_history_table.*
Remove-Item migrations/000030_create_provider_service_categories.*
Remove-Item migrations/000031_fix_service_table.*
Remove-Item migrations/000032_update_user_table_constraint.*
Remove-Item migrations/000033_*
Remove-Item migrations/000034_*
Remove-Item migrations/000035_*
Remove-Item migrations/000036_*
Remove-Item migrations/000037_*
Remove-Item migrations/000038_*
Remove-Item migrations/000039_*
Remove-Item migrations/000040_*
Remove-Item migrations/000041_*
Remove-Item migrations/000042_*  # This was our FK fix for old schema
```

---

## Files to Keep

**These are old and needed for base setup:**
- 000001 - Create user table
- 000002 - Create todo table
- 000003 - Create wallet table
- 000004 - Create rider profiles
- ... (all pre-service setup)
- 000024 and earlier: Keep all

---

## Deployment Strategy

### Option 1: Fresh Start (Recommended)
**Use when:** Starting with empty database or can drop service tables

```bash
# 1. Make backup of any existing data
pg_dump -U go_backend_admin -d go_backend > backup.sql

# 2. Reset to migration 000024
migrate -path ./migrations -database "postgres://..." down 26

# 3. Run new clean migrations
migrate -path ./migrations -database "postgres://..." up

# 4. Re-populate service data if needed
psql -U go_backend_admin -d go_backend < service_data.sql
```

### Option 2: Keep Existing Data
**Use when:** You have production data to preserve

```bash
# 1. Export existing service data
SELECT * FROM services INTO OUTFILE 'services_backup.sql';
SELECT * FROM addons INTO OUTFILE 'addons_backup.sql';
SELECT * FROM provider_service_categories INTO OUTFILE 'psc_backup.sql';
SELECT * FROM provider_qualified_services INTO OUTFILE 'pqs_backup.sql';

# 2. Drop old tables in order
DROP TABLE provider_qualified_services;
DROP TABLE provider_service_categories;
DROP TABLE order_status_histories;
DROP TABLE service_orders;
DROP TABLE addons;
DROP TABLE services;
DROP TABLE service_provider_profiles;

# 3. Run new clean migrations
migrate -path ./migrations -database "postgres://..." up

# 4. Re-import data (with slug generation if needed)
# ... use custom script to transform old data to new schema
```

---

## Verification Checklist

After running migrations:

```sql
-- Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'service_provider_profiles',
    'services',
    'addons',
    'service_orders',
    'order_status_histories',
    'provider_service_categories',
    'provider_qualified_services'
);

-- Verify FK constraint is correct (KEY CHECK!)
SELECT constraint_name, table_name, column_name, referenced_table_name
FROM information_schema.referential_constraints
WHERE constraint_name = 'service_orders_assigned_provider_id_fkey';
-- Should reference: service_provider_profiles

-- Verify columns exist
\d service_orders
-- Should show: assigned_provider_id UUID REFERENCES service_provider_profiles(id)

-- Verify triggers
SELECT trigger_name FROM information_schema.triggers
WHERE table_name = 'service_orders';
-- Should show: trigger_generate_order_number, trigger_service_orders_updated_at
```

---

## Rollback Plan

If anything goes wrong:

```bash
# Rollback all new migrations
migrate -path ./migrations -database "postgres://..." down 6

# Restore from backup if needed
psql -U go_backend_admin -d go_backend < backup.sql
```

Each `.down.sql` file is carefully written to safely rollback all changes.

---

## Testing the New Migrations

### Unit Test: Migration Execution
```bash
# Test going up
migrate -path ./migrations -database "postgres://localhost:5432/go_backend?sslmode=disable" up

# Verify
psql -U go_backend_admin -d go_backend -c "\dt"

# Test going down
migrate -path ./migrations -database "postgres://localhost:5432/go_backend?sslmode=disable" down 6

# Verify back to original
psql -U go_backend_admin -d go_backend -c "\dt"

# Go back up again
migrate -path ./migrations -database "postgres://localhost:5432/go_backend?sslmode=disable" up
```

### Integration Test: Application
```bash
# 1. Start application
make run

# 2. Register a provider
POST /api/v1/services/provider/register

# 3. Create an order
POST /api/v1/services/orders

# 4. Provider accepts order
POST /api/v1/provider/orders/{id}/accept

# All should work without FK constraint errors
```

---

## Before/After Comparison

### FK Constraint (THE KEY FIX)

**Before (Broken - 000028):**
```sql
CONSTRAINT fk_service_orders_provider 
    FOREIGN KEY (assigned_provider_id) REFERENCES users(id) ON DELETE SET NULL
```
❌ Error: ProviderID doesn't exist in users table

**After (Fixed - 000052):**
```sql
assigned_provider_id UUID REFERENCES service_provider_profiles(id) ON DELETE SET NULL
```
✅ Success: ProviderID matches service_provider_profiles

### Schema Organization

**Before:**
- 17 files with overlapping concerns
- Duplicate provider table definitions
- Multiple attempts at order table schema

**After:**
- 6 files with clear purpose
- One provider table (000050)
- One order table (000052)
- Clean separation of concerns

### Slug References

**Before:**
- Mixed ID-based FK constraints
- Inconsistent relationships

**After:**
- Slug-based text references
- No FK constraints on category_slug, service_slug
- Application validates relationships

---

## Next Steps

1. **Delete old migration files** (000025-000042)
2. **Run new clean migrations** (000050-000055)
3. **Verify database schema**
4. **Test application flows**
5. **Update data seeding scripts** if needed

See `CLEAN_MIGRATIONS_README.md` for detailed information about the new schema.
