# 📋 New Machine Deployment - Complete Guide

## For Impatient People (5 minutes)

👉 **Read:** `QUICKSTART_DEPLOYMENT.md`

Copy-paste commands, done! ✅

---

## For Everyone Else (10-20 minutes)

👉 **Read:** `DEPLOYMENT_GUIDE.md`

Then use: `DEPLOYMENT_CHECKLIST.md` while deploying

---

## The Story: What Happened?

### The Problem
1. Providers registered but couldn't see available orders
2. When they tried to accept orders, got FK constraint error
3. Old migrations were messy and conflicting (17 files!)

### The Root Causes
**Bug #1 - Code Layer:**
- Auth provides UserID (from users table)
- Provider profile has ProviderID (from service_provider_profiles table)
- Handler was using UserID where ProviderID was needed
- Result: Database queries returned 0 rows

**Bug #2 - Database Layer:**
- FK constraint incorrectly referenced `users(id)` 
- Should reference `service_provider_profiles(id)`
- Result: FK violation when accepting orders

**Bug #3 - Migration Layer:**
- 17 messy migrations (000025-000042) with conflicts
- Old schema still in database
- New clean migrations couldn't apply

### The Solution

**Code Fix:**
```
Auth: UserID
  ↓
Handler helper: getProviderIDFromContext()
  ↓
Service method: GetProviderIDByUserID()
  ↓
Repository query: SELECT id FROM service_provider_profiles WHERE user_id = ?
  ↓
Result: ProviderID
  ↓
Use ProviderID for all queries ✅
```

**Database Fix:**
```
Old FK: assigned_provider_id REFERENCES users(id) ❌
New FK: assigned_provider_id REFERENCES service_provider_profiles(id) ✅
```

**Migration Fix:**
```
Old migrations (000025-000042): DELETED
New migrations (000049-000055): CREATED
Cleanup migration (000049): Drops old tables first
Result: Clean, working schema ✅
```

---

## Deployment Overview

### Files Modified (Code Changes)
| File | Change |
|------|--------|
| `internal/models/service_order.go` | Fixed FK type to ServiceProviderProfile |
| `internal/modules/homeservices/provider/handler.go` | Added UserID→ProviderID helper |
| `internal/modules/homeservices/provider/service.go` | Added GetProviderIDByUserID() |
| `internal/modules/homeservices/provider/repository.go` | Added GetProviderByUserID() |

### Files Deleted (Old Migrations)
```
000025_new_service_tables_migrate_full.*
000026_create_services_table.*
000027_create_addons_table.*
... (17 total files)
000042_fix_service_orders_provider_fk.*
```

### Files Created (New Migrations)
```
000049_cleanup_old_service_tables.* (drop old tables)
000050_clean_service_provider_profiles.* (provider profiles)
000051_clean_services_addons.* (services + add-ons)
000052_clean_service_orders.* (orders with correct FK!)
000053_clean_order_status_history.* (audit trail)
000054_clean_provider_service_categories.* (provider→category)
000055_clean_provider_qualified_services.* (provider→service)
```

---

## Migration Structure

```
Before (Messy):
000001 - 000024 (base schema)
000025 - 000042 (messy service attempts) ❌ DELETED
  ├─ Duplicate tables
  ├─ Wrong FK constraints
  ├─ Conflicting definitions
  └─ Unclear dependencies

After (Clean):
000001 - 000024 (base schema)
000049 (cleanup old tables)
000050 - 000055 (clean service schema)
  ├─ Clear separation of concerns
  ├─ Correct FK constraints
  ├─ Slug-based relations
  └─ Full triggers & indexes
```

---

## How to Deploy on New Machine

### Step 1: Prerequisites
```powershell
# Install required software
choco install git golang migrate postgresql

# Verify installations
git --version
go version
migrate -version
psql --version
```

### Step 2: Clone & Setup
```powershell
git clone https://github.com/Hafs-Arif/SuprBackend.git
cd supr-backend-go

# Set environment variable
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
```

### Step 3: Database
```sql
-- Create in PostgreSQL
CREATE USER go_backend_admin WITH PASSWORD 'goPass';
CREATE DATABASE go_backend OWNER go_backend_admin;
GRANT ALL PRIVILEGES ON DATABASE go_backend TO go_backend_admin;
```

### Step 4: Migrate
```powershell
migrate -path ./migrations -database $env:DB_URL up

# Verify (should show 55)
migrate -path ./migrations -database $env:DB_URL version
```

### Step 5: Build & Run
```powershell
go build -o api.exe ./cmd/api
./api.exe
```

**Done! ✅**

---

## Verification Steps

### After Migrations
```powershell
# Check version is 55
migrate -path ./migrations -database $env:DB_URL version

# In PostgreSQL, verify tables exist
\dt service*
\dt provider*
\dt order*

# Check FK is correct
SELECT constraint_name FROM information_schema.table_constraints 
WHERE table_name='service_orders' AND constraint_type='FOREIGN KEY';
```

### After API Starts
```bash
# Health check
curl http://localhost:8080/health

# Check logs for:
# ✓ Connected to database
# ✓ No FK constraint errors
# ✓ Providers can be registered
```

### Provider Workflow Test
1. Register provider ✅
2. Create order ✅
3. Provider accepts order → **NO FK ERROR** ✅
4. Order completes ✅

---

## Documentation Map

Start here based on your needs:

### 🏃 I'm in a hurry (5 min)
→ `QUICKSTART_DEPLOYMENT.md`

### 👷 I'm deploying now (20 min)
→ `DEPLOYMENT_GUIDE.md` + `DEPLOYMENT_CHECKLIST.md`

### 🔍 I want details (30 min)
→ `CLEAN_MIGRATIONS_README.md`
→ `MIGRATIONS_QUICK_REFERENCE.md`

### 💻 I want code details (15 min)
→ `CODE_CHANGES_REFERENCE.md`
→ `FIX_USERID_PROVIDERID_BUG.md`
→ `FIX_FOREIGN_KEY_CONSTRAINT.md`

### 🆘 Something broke (varies)
→ `DEPLOYMENT_GUIDE.md` (Troubleshooting section)
→ `VALIDATION_GUIDE.md`

---

## Key Points to Remember

### ✅ What Was Fixed

| Problem | Solution | Status |
|---------|----------|--------|
| Code uses UserID instead of ProviderID | Added conversion helper in handler | ✅ Done |
| FK constraint points to wrong table | Changed to service_provider_profiles | ✅ Done |
| 17 messy conflicting migrations | Replaced with 7 clean migrations | ✅ Done |
| Providers can't see orders | Fixed by using correct ProviderID | ✅ Done |
| FK error on order acceptance | Fixed by correcting FK constraint | ✅ Done |

### ⚠️ Important Notes

- Old migrations (000025-000042) are **permanently deleted**
- Cannot migrate old databases using old file names
- **Always backup before deploying**
- Use `DEPLOYMENT_CHECKLIST.md` for step-by-step verification

### 🔄 Rollback Capability

Each new migration has a `.down.sql` file:
```powershell
# Rollback one migration
migrate -path ./migrations -database $env:DB_URL down 1

# Rollback to version 24
migrate -path ./migrations -database $env:DB_URL down 31
```

---

## Timeline

**What happened when:**

- **Phase 1:** Discovered provider can't see orders
- **Phase 2:** Found UserID vs ProviderID bug
- **Phase 3:** Found FK constraint pointing to wrong table
- **Phase 4:** Created 6 new clean migrations
- **Phase 5:** Deployed and tested on local machine
- **Phase 6:** Created deployment documentation
- **Now:** Ready for new machine deployment

---

## Expected Results

After successful deployment:

✅ Database version: 55
✅ 7 new service tables exist
✅ FK constraint correct
✅ All triggers and indexes present
✅ Application starts without errors
✅ Provider registration works
✅ Order creation works
✅ Provider accepts orders without FK errors
✅ Order status tracked in history
✅ No errors in logs

---

## Need Help?

### Quick Questions
- **How long does it take?** ~5-20 minutes depending on setup
- **What if something fails?** See troubleshooting section in DEPLOYMENT_GUIDE.md
- **Can I rollback?** Yes, each migration has a .down.sql file
- **What if DB is dirty?** Use `migrate force 24` then `migrate up`

### Detailed Questions
- See `DEPLOYMENT_GUIDE.md` for comprehensive guide
- See `CLEAN_MIGRATIONS_README.md` for schema details
- See `CODE_CHANGES_REFERENCE.md` for code changes

### Emergency Help
1. Stop the application
2. Check logs for specific error
3. Review troubleshooting section in DEPLOYMENT_GUIDE.md
4. Restore from backup if needed

---

## Summary

**You now have:**
- ✅ Clean migration structure (7 migrations instead of 17)
- ✅ Correct database schema (FK points to right table)
- ✅ Fixed code (UserID→ProviderID conversion)
- ✅ Full deployment documentation
- ✅ Verification checklists
- ✅ Troubleshooting guides

**Ready to deploy on any new machine!** 🚀

---

## Files Overview

| File | Purpose | Time |
|------|---------|------|
| **QUICKSTART_DEPLOYMENT.md** | Fast deployment guide | 5 min |
| **DEPLOYMENT_GUIDE.md** | Comprehensive guide | 20 min |
| **DEPLOYMENT_CHECKLIST.md** | Step-by-step checklist | 20 min |
| **CLEAN_MIGRATIONS_README.md** | Schema details | 30 min |
| **MIGRATIONS_QUICK_REFERENCE.md** | Query examples | 10 min |
| **CODE_CHANGES_REFERENCE.md** | Code modifications | 15 min |
| **FIX_USERID_PROVIDERID_BUG.md** | Why bug happened | 5 min |
| **FIX_FOREIGN_KEY_CONSTRAINT.md** | Why FK failed | 5 min |
| **VALIDATION_GUIDE.md** | Testing procedures | 15 min |
| **COMPLETE_FIX_SUMMARY.md** | Full deployment plan | 10 min |
| **DOCUMENTATION_INDEX.md** | Master index | 5 min |

**Start with:** `QUICKSTART_DEPLOYMENT.md` or `DEPLOYMENT_GUIDE.md`

---

## Go Forth and Deploy! 🚀

Pick your starting point above and follow the guide. You've got this! ✅
