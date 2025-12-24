# 🚀 Deployment Guide for New Machines

## Overview

This guide explains how to deploy the clean home services schema on a new machine. The migration structure has been cleaned up and simplified.

**Current State:**
- ✅ 7 migrations in place (migrations 000001-000024 + cleanup + new schema 000049-000055)
- ✅ All old messy migrations (000025-000042) have been deleted
- ✅ Local database successfully migrated to version 55
- ✅ Code deployed with UserID→ProviderID conversion fixes

---

## Prerequisites

### Required Software
- **PostgreSQL 12+** (installed and running)
- **Go 1.19+** (for building the application)
- **migrate CLI** (for database migrations)
- **Git** (for cloning the repository)

### Installing migrate CLI

**Windows (using Chocolatey):**
```powershell
choco install migrate
```

**Windows (manual):**
1. Download from: https://github.com/golang-migrate/migrate/releases
2. Extract to a folder in PATH (e.g., `C:\Program Files\migrate`)

**Linux/Mac:**
```bash
brew install golang-migrate
```

### Database Setup

Create PostgreSQL user and database:
```sql
-- Connect as postgres superuser
CREATE USER go_backend_admin WITH PASSWORD 'goPass';
CREATE DATABASE go_backend OWNER go_backend_admin;

-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE go_backend TO go_backend_admin;
```

---

## Deployment Steps

### Step 1: Clone Repository
```powershell
git clone https://github.com/Hafs-Arif/SuprBackend.git
cd supr-backend-go
```

### Step 2: Verify PostgreSQL Connection

Test database connection:
```powershell
# On Windows
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"

# On Linux/Mac
export DB_URL="postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
```

**For remote database:**
```powershell
$env:DB_URL = "postgres://user:password@hostname:5432/database?sslmode=require"
```

### Step 3: Run Migrations

**Apply all migrations:**
```powershell
cd f:\supr-services\supr-backend-go
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
migrate -path ./migrations -database $env:DB_URL up
```

**Expected Output:**
```
49/u cleanup_old_service_tables (24.8141ms)
50/u clean_service_provider_profiles (46.9765ms)
51/u clean_services_addons (111.3047ms)
52/u clean_service_orders (159.4296ms)
53/u clean_order_status_history (176.8155ms)
54/u clean_provider_service_categories (189.9264ms)
55/u clean_provider_qualified_services (203.1815ms)
```

### Step 4: Verify Migration Success

Check migration version:
```powershell
migrate -path ./migrations -database $env:DB_URL version
# Should output: 55
```

---

## Using the Makefile

We've created convenient `make` commands for deployment:

### Available Commands

```bash
# Run migrations up
make migrate-up

# Roll back one migration
make migrate-down

# Run specific number of migrations
make migrate-up-n  # Will prompt for N

# View current migration version
make migrate-version

# Create new migration
make migrate-create NAME=your_migration_name

# Force a specific version (use with caution)
make migrate-force  # Will prompt for version number
```

### Using make on Windows

If you don't have `make` installed:

1. **Install using Chocolatey:**
   ```powershell
   choco install make
   ```

2. **Or use individual commands directly:**
   ```powershell
   migrate -path ./migrations -database $env:DB_URL up
   migrate -path ./migrations -database $env:DB_URL down
   ```

---

## Migration Structure

### What Gets Created

After running migrations, your database will have:

**Base Tables (pre-existing):**
- `users` - User accounts
- `wallets` - Payment wallets
- `todos` - Todo items
- etc.

**Clean Service Tables (000049-000055):**

1. **000049 - Cleanup** 
   - Drops any leftover tables from old migrations

2. **000050 - service_provider_profiles**
   ```
   - id (UUID)
   - user_id (UUID FK → users.id)
   - Document with provider details (JSONB)
   - Soft delete support
   ```

3. **000051 - services & addons**
   ```
   services:
   - id (UUID)
   - service_slug (VARCHAR UNIQUE) - Identifier
   - category_slug (VARCHAR) - Text reference (NOT FK)
   - pricing, duration, etc.
   
   addons:
   - id (UUID)
   - addon_slug (VARCHAR UNIQUE)
   - category_slug (VARCHAR)
   - pricing
   ```

4. **000052 - service_orders**
   ```
   - id (UUID)
   - order_number (VARCHAR UNIQUE) - Auto-generated
   - customer_id (UUID FK → users.id)
   - assigned_provider_id (UUID FK → service_provider_profiles.id) ✅ CORRECT!
   - selected_services (JSONB)
   - selected_addons (JSONB)
   - status (pending → accepted → started → completed)
   - Pricing breakdown
   - Rating fields
   ```

5. **000053 - order_status_history**
   ```
   - Audit trail of order status changes
   - Tracks: previous_status → new_status, who changed it, when
   ```

6. **000054 - provider_service_categories**
   ```
   - Links providers to service categories they offer
   - Composite key: (provider_id, category_slug)
   ```

7. **000055 - provider_qualified_services**
   ```
   - Links providers to specific services they can perform
   - Composite key: (provider_id, service_id)
   ```

### Key Design Features

✅ **Slug-Based Relations:**
- Services referenced by `service_slug` (text), not database FK
- Categories referenced by `category_slug` (text), not database FK
- More flexible, avoids rigid FK constraints

✅ **Correct Foreign Keys:**
- `assigned_provider_id` → `service_provider_profiles(id)` ✅
- NOT `users(id)` ❌

✅ **Auto-Generated Order Numbers:**
- Format: `HS-YYYY-000001` (e.g., `HS-2025-000042`)
- Automatically generated on insert

✅ **Audit Trail:**
- `order_status_history` tracks all status changes
- Useful for support and debugging

✅ **Soft Deletes:**
- `deleted_at` columns on providers and services
- Preserve data while hiding from queries

---

## Troubleshooting

### Issue: "Dirty database version"

**Cause:** A migration failed partway through

**Solution:**
```powershell
# Force to the last known good version
migrate -path ./migrations -database $env:DB_URL force 24

# Then try again
migrate -path ./migrations -database $env:DB_URL up
```

### Issue: "Foreign key constraint already exists"

**Cause:** Migrations ran twice or tables weren't cleaned up

**Solution:**
```powershell
# Force to version before migrations
migrate -path ./migrations -database $env:DB_URL force 24

# Run cleanup migration manually
migrate -path ./migrations -database $env:DB_URL up 1

# Then continue
migrate -path ./migrations -database $env:DB_URL up
```

### Issue: "Cannot connect to database"

**Check:**
1. PostgreSQL is running: `Get-Service | Where-Object {$_.Name -like "Postgres*"}`
2. Database exists: Connect to postgres and run `\l`
3. User has access: Check user permissions
4. Connection string is correct: `$env:DB_URL`

### Issue: Migration fails with permission error

**Cause:** User doesn't have ALTER TABLE permissions

**Solution:**
```sql
-- As superuser, grant full permissions
GRANT ALL PRIVILEGES ON DATABASE go_backend TO go_backend_admin;
GRANT USAGE ON SCHEMA public TO go_backend_admin;
GRANT CREATE ON SCHEMA public TO go_backend_admin;
```

---

## Rollback Procedures

### Rollback Last Migration
```powershell
migrate -path ./migrations -database $env:DB_URL down 1
```

### Rollback to Specific Version
```powershell
# To rollback to version 24 (before service migrations)
migrate -path ./migrations -database $env:DB_URL down 31
```

### Force Rollback (if stuck)
```powershell
# Force to a known version
migrate -path ./migrations -database $env:DB_URL force 24

# Then manually rollback
migrate -path ./migrations -database $env:DB_URL down
```

---

## Verifying Deployment

### 1. Check Tables Exist

```sql
-- Connect to database
\dt service*
\dt provider*
\dt order*

-- Should show:
-- - service_provider_profiles
-- - services
-- - addons
-- - service_orders
-- - order_status_history
-- - provider_service_categories
-- - provider_qualified_services
```

### 2. Verify Foreign Key

```sql
-- Check FK constraint is correct
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE table_name = 'service_orders' 
AND constraint_type = 'FOREIGN KEY';

-- Should show:
-- fk_service_orders_customer_id (→ users.id)
-- fk_service_orders_provider_id (→ service_provider_profiles.id) ✅
```

### 3. Check Indexes Exist

```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'service_orders';

-- Should have multiple indexes:
-- idx_service_orders_customer_id
-- idx_service_orders_provider_id
-- idx_service_orders_status
-- etc.
```

### 4. Test Triggers

```sql
-- Check order_number trigger exists
SELECT * FROM information_schema.triggers 
WHERE event_object_table = 'service_orders';

-- Should show:
-- trigger_generate_order_number
-- trigger_service_orders_updated_at
```

---

## Application Deployment

### 1. Build Application

```powershell
cd f:\supr-services\supr-backend-go
go build -o api.exe ./cmd/api
```

### 2. Environment Variables

Create `.env` file or set system variables:
```env
DB_URL=postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable
PORT=8080
REDIS_URL=localhost:6379
```

### 3. Run Application

```powershell
./api.exe
# Or with environment variable
$env:DB_URL="postgres://..."; ./api.exe
```

### 4. Verify API Works

```powershell
# Test health check (adjust endpoint based on your API)
curl http://localhost:8080/health

# Should return: {"status":"ok"}
```

---

## Summary of Changes

| File | Change | Status |
|------|--------|--------|
| `migrations/000025-000042/*` | Deleted old messy migrations | ✅ Done |
| `migrations/000049_cleanup_old_service_tables.*` | New cleanup migration | ✅ Created |
| `migrations/000050-000055/*` | New clean migrations | ✅ Created |
| `internal/modules/homeservices/provider/handler.go` | Added `getProviderIDFromContext()` helper | ✅ Done |
| `internal/modules/homeservices/provider/service.go` | Added `GetProviderIDByUserID()` method | ✅ Done |
| `internal/modules/homeservices/provider/repository.go` | Added `GetProviderByUserID()` method | ✅ Done |
| `internal/models/service_order.go` | Fixed FK type to `ServiceProviderProfile` | ✅ Done |

---

## Post-Deployment Verification

After deploying on a new machine, verify these workflows work:

### 1. Provider Registration ✅
```
- User registers with email/phone
- Provider profile created with UUID
- 8 services auto-assigned to provider
- Provider sees categories they can serve
```

### 2. Service Discovery ✅
```
- Customer creates order
- Searches for "cleaning" service
- Gets list of services with slugs
```

### 3. Order Creation ✅
```
- Customer creates order with selected services
- Order stored with all details
- order_status_history records "pending" status
```

### 4. Provider Accepts Order ✅
```
- Provider sees available order
- Provider accepts order
- NO FK constraint error ✅
- order_status_history records "accepted" status
```

### 5. Order Completion ✅
```
- Provider starts order → status "started"
- Provider completes order → status "completed"
- Both update order_status_history
- Timestamps auto-updated
```

---

## Important Notes

### ⚠️ Data Loss Warning
- Migrations 000025-000042 have been **deleted**
- Old databases cannot be migrated using old files
- **Always backup before deploying to production**

### ✅ Safe to Deploy
- Non-breaking code changes (handler helpers, service methods)
- No API endpoint changes
- Backward compatible with existing functionality

### 🔄 Rollback Always Available
- Each migration has a `.down.sql` file
- Can rollback to any previous version
- Keep database backups for emergency rollback

---

## Next Steps

1. ✅ Clone repository
2. ✅ Install migrate CLI
3. ✅ Create PostgreSQL database
4. ✅ Set DB_URL environment variable
5. ✅ Run migrations: `migrate -path ./migrations -database $env:DB_URL up`
6. ✅ Verify tables created: `\dt service*`
7. ✅ Build application: `go build -o api.exe ./cmd/api`
8. ✅ Run application
9. ✅ Test workflows

---

## Support

If you encounter issues:

1. Check the **Troubleshooting** section above
2. Verify PostgreSQL is running and accessible
3. Check migration version: `migrate -path ./migrations -database $env:DB_URL version`
4. Review logs for specific error messages
5. Check that all code changes are deployed (handler, service, repository updates)

**Success Criteria:**
- Database at version 55 ✅
- All 7 new tables exist ✅
- FK constraint points to correct table ✅
- Triggers exist and work ✅
- Application starts without errors ✅
- Provider workflows complete without FK errors ✅
