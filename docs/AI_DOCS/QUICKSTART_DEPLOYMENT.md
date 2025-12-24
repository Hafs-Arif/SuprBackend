# 🚀 Quick Start - Deploy on New Machine (5 min guide)

## TL;DR - The Fast Way

### 1. Setup Database (2 min)
```powershell
# Create user and database
psql -U postgres
# In PostgreSQL:
CREATE USER go_backend_admin WITH PASSWORD 'goPass';
CREATE DATABASE go_backend OWNER go_backend_admin;
GRANT ALL PRIVILEGES ON DATABASE go_backend TO go_backend_admin;
\q
```

### 2. Setup Environment (1 min)
```powershell
# Clone repo
git clone https://github.com/Hafs-Arif/SuprBackend.git
cd supr-backend-go

# Install migrate CLI (if not already installed)
choco install migrate

# Set environment variable
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
```

### 3. Run Migrations (1 min)
```powershell
# Apply all migrations
migrate -path ./migrations -database $env:DB_URL up

# Verify
migrate -path ./migrations -database $env:DB_URL version
# Should show: 55
```

### 4. Build & Run (1 min)
```powershell
# Build
go build -o api.exe ./cmd/api

# Run (set env var first if not already set)
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
./api.exe
```

**Done! ✅** API is running on http://localhost:8080

---

## Verify Everything Works

### Test 1: Database Connected
Check application logs for:
```
✓ Connected to database
✓ Running migrations...
```

### Test 2: Provider Workflow
1. Register provider
2. Create customer order  
3. Provider accepts order → **Should succeed with NO errors** ✅

---

## If Something Goes Wrong

| Problem | Fix |
|---------|-----|
| `migrate not found` | `choco install migrate` |
| `Cannot connect to database` | Check PostgreSQL running, DB exists, credentials correct |
| `Dirty database version` | `migrate -path ./migrations -database $env:DB_URL force 24` |
| `FK constraint error` | Verify FK points to `service_provider_profiles`, not `users` |

---

## Environment Variables (Windows)

### Permanent Setup
```powershell
# Set system environment variable
[Environment]::SetEnvironmentVariable("DB_URL", "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable", "User")

# Restart PowerShell, then verify:
$env:DB_URL
```

### Per-Session Setup
```powershell
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
```

---

## For Remote Database

Replace connection string in `$env:DB_URL`:

```powershell
# Example: AWS RDS
$env:DB_URL = "postgres://admin:password@mydb.c3kjd.us-east-1.rds.amazonaws.com:5432/go_backend?sslmode=require"

migrate -path ./migrations -database $env:DB_URL up
```

---

## Using Make Commands (if available)

```powershell
make migrate-up      # Apply all migrations
make migrate-version # Check version
make migrate-down    # Rollback one migration
```

If `make` not installed: `choco install make`

---

## What Gets Created

After migrations:
- ✅ `service_provider_profiles` - Provider accounts
- ✅ `services` - Available services (with slugs)
- ✅ `addons` - Optional add-ons
- ✅ `service_orders` - Customer orders (with correct FK!)
- ✅ `order_status_history` - Order status audit trail
- ✅ `provider_service_categories` - Provider → category mapping
- ✅ `provider_qualified_services` - Provider → service mapping

---

## Key Fixes Deployed

✅ **Code:**
- UserID → ProviderID conversion in handler
- Added service method for ID lookup
- Added repository method for database query

✅ **Database:**
- FK constraint: `assigned_provider_id` → `service_provider_profiles.id` (correct!)
- Auto-generated order numbers: `HS-YYYY-XXXXXX`
- Order status audit trail with timestamps

✅ **Result:**
- Providers can see available orders
- Providers can accept orders without FK errors
- All workflows complete successfully

---

## Troubleshooting

### Check Database Tables Exist
```sql
psql -U go_backend_admin -d go_backend -c "\dt service"
-- Should show 7 service-related tables
```

### Check FK Constraint
```sql
psql -U go_backend_admin -d go_backend -c "SELECT constraint_name FROM information_schema.table_constraints WHERE table_name='service_orders' AND constraint_type='FOREIGN KEY';"
```

### Check Triggers
```sql
psql -U go_backend_admin -d go_backend -c "SELECT * FROM information_schema.triggers WHERE event_object_table='service_orders';"
```

---

## Next Steps

1. ✅ Database setup
2. ✅ Run migrations
3. ✅ Build application
4. ✅ Test provider workflow
5. ✅ Monitor logs for errors
6. ✅ Deploy to production

---

## Need Help?

See detailed guides:
- `DEPLOYMENT_GUIDE.md` - Full deployment instructions
- `DEPLOYMENT_CHECKLIST.md` - Detailed checklist
- `CLEAN_MIGRATIONS_README.md` - Schema details
- `MIGRATIONS_QUICK_REFERENCE.md` - Query examples

---

## Quick Command Reference

```powershell
# Setup
git clone https://github.com/Hafs-Arif/SuprBackend.git
cd supr-backend-go
$env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"

# Migrate
migrate -path ./migrations -database $env:DB_URL up

# Verify
migrate -path ./migrations -database $env:DB_URL version

# Build
go build -o api.exe ./cmd/api

# Run
./api.exe

# Test (in another terminal)
curl http://localhost:8080/health
```

**Total time: ~5 minutes** ⏱️
