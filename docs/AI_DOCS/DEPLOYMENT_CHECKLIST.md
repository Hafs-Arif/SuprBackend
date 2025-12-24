# ✅ Deployment Checklist

Use this checklist when deploying to a new machine.

---

## Pre-Deployment (Local Machine)

- [ ] Clone repository: `git clone https://github.com/Hafs-Arif/SuprBackend.git`
- [ ] Navigate to project: `cd supr-backend-go`
- [ ] Verify migrations directory exists: `ls migrations/`
- [ ] Check that old migrations (000025-000042) are NOT present
- [ ] Verify clean migrations (000049-000055) exist:
  - [ ] 000049_cleanup_old_service_tables.*
  - [ ] 000050_clean_service_provider_profiles.*
  - [ ] 000051_clean_services_addons.*
  - [ ] 000052_clean_service_orders.*
  - [ ] 000053_clean_order_status_history.*
  - [ ] 000054_clean_provider_service_categories.*
  - [ ] 000055_clean_provider_qualified_services.*

---

## Software Installation

- [ ] PostgreSQL 12+ installed and running
- [ ] Go 1.19+ installed: `go version`
- [ ] migrate CLI installed: `migrate -version`
  - [ ] If not, install: `choco install migrate` (Windows)
  - [ ] Or: `brew install golang-migrate` (Mac)

---

## Database Setup

- [ ] PostgreSQL service is running
- [ ] Create database user:
  ```sql
  CREATE USER go_backend_admin WITH PASSWORD 'goPass';
  ```
- [ ] Create database:
  ```sql
  CREATE DATABASE go_backend OWNER go_backend_admin;
  ```
- [ ] Grant privileges:
  ```sql
  GRANT ALL PRIVILEGES ON DATABASE go_backend TO go_backend_admin;
  ```
- [ ] Test connection works

---

## Environment Configuration

- [ ] Set DB_URL environment variable:
  ```powershell
  $env:DB_URL = "postgres://go_backend_admin:goPass@localhost:5432/go_backend?sslmode=disable"
  ```
- [ ] Verify connection string by testing:
  ```powershell
  migrate -path ./migrations -database $env:DB_URL version
  # Should show: 0 (no migrations applied yet) or current version if redeploying
  ```

---

## Migration Deployment

- [ ] Check current version: `migrate -path ./migrations -database $env:DB_URL version`
- [ ] If version > 24 and not 55, force to 24: `migrate -path ./migrations -database $env:DB_URL force 24`
- [ ] Run migrations: `migrate -path ./migrations -database $env:DB_URL up`
- [ ] Expected output shows all 7 migrations applied:
  ```
  49/u cleanup_old_service_tables (ms)
  50/u clean_service_provider_profiles (ms)
  51/u clean_services_addons (ms)
  52/u clean_service_orders (ms)
  53/u clean_order_status_history (ms)
  54/u clean_provider_service_categories (ms)
  55/u clean_provider_qualified_services (ms)
  ```
- [ ] Verify final version: `migrate -path ./migrations -database $env:DB_URL version`
  - [ ] Should show: `55`

---

## Database Verification

- [ ] Connect to database: `psql -U go_backend_admin -h localhost -d go_backend`
- [ ] List tables: `\dt`
- [ ] Verify service tables exist:
  - [ ] service_provider_profiles
  - [ ] services
  - [ ] addons
  - [ ] service_orders
  - [ ] order_status_history
  - [ ] provider_service_categories
  - [ ] provider_qualified_services
- [ ] Check FK constraint:
  ```sql
  SELECT constraint_name, table_name, referenced_table_name
  FROM information_schema.referential_constraints
  WHERE table_name = 'service_orders';
  ```
  - [ ] Verify `assigned_provider_id` references `service_provider_profiles(id)` ✅
- [ ] Test trigger exists:
  ```sql
  SELECT * FROM information_schema.triggers 
  WHERE event_object_table = 'service_orders';
  ```
  - [ ] `trigger_generate_order_number` exists
  - [ ] `trigger_service_orders_updated_at` exists

---

## Code Deployment

- [ ] Pull latest code: `git pull origin main`
- [ ] Verify code changes are in place:
  - [ ] `internal/models/service_order.go` - FK type corrected
  - [ ] `internal/modules/homeservices/provider/handler.go` - Helper method added
  - [ ] `internal/modules/homeservices/provider/service.go` - Conversion method added
  - [ ] `internal/modules/homeservices/provider/repository.go` - Lookup method added
- [ ] Build application:
  ```powershell
  go build -o api.exe ./cmd/api
  ```
  - [ ] Build succeeds with no errors
  - [ ] `api.exe` created
- [ ] Set environment variables:
  - [ ] `DB_URL` set correctly
  - [ ] `PORT` set (default 8080)
  - [ ] `REDIS_URL` set if needed
- [ ] Run application: `./api.exe`
  - [ ] Application starts without errors
  - [ ] Listens on configured port

---

## API Verification

- [ ] API health check works:
  ```bash
  curl http://localhost:8080/health
  ```
- [ ] Database connection works (check logs for connection success)
- [ ] No FK constraint errors in logs

---

## Provider Workflow Testing

### Test 1: Provider Registration
- [ ] User registers with email and phone
- [ ] Provider profile created successfully
- [ ] 8 services auto-assigned to provider
- [ ] Check database: `SELECT * FROM service_provider_profiles LIMIT 1;`
- [ ] Check service assignments: `SELECT COUNT(*) FROM provider_qualified_services;`
  - [ ] Should be 8 for new provider

### Test 2: Customer Creates Order
- [ ] Customer searches for "cleaning" service
- [ ] Available services shown with slug and pricing
- [ ] Customer selects service + optional addon
- [ ] Order created in database
- [ ] Check: `SELECT * FROM service_orders ORDER BY created_at DESC LIMIT 1;`

### Test 3: Provider Accepts Order ⚠️ KEY TEST
- [ ] Provider sees available order
- [ ] Provider clicks accept
- [ ] **NO FK constraint error** ✅
- [ ] Order status changes to "accepted"
- [ ] Check: `SELECT * FROM order_status_history WHERE order_id = 'xxx';`
  - [ ] Should show: pending → accepted transitions

### Test 4: Order Lifecycle
- [ ] Provider starts order → status "started"
- [ ] Provider completes order → status "completed"
- [ ] All status changes logged in order_status_history
- [ ] Timestamps auto-updated

---

## Final Verification

- [ ] Database version is 55
- [ ] All 7 service tables exist
- [ ] FK constraint is correct (service_provider_profiles, not users)
- [ ] Triggers generate order numbers correctly
- [ ] Provider workflows complete without errors
- [ ] Logs show no FK constraint violations

---

## Rollback Plan (If Needed)

If something goes wrong:

1. Stop application
2. Check error in logs
3. If migration failed:
   ```powershell
   migrate -path ./migrations -database $env:DB_URL force 24
   ```
4. Review the DEPLOYMENT_GUIDE.md troubleshooting section
5. Restore from backup if needed

---

## Success Criteria

✅ **You're ready for production when:**

- Database is at version 55
- All 7 new tables exist with correct schema
- FK constraint points to `service_provider_profiles(id)`
- All triggers and indexes created
- Application starts and connects to database
- Provider can accept orders without FK errors
- All status changes tracked in history table
- No errors in application logs

---

## Common Issues

| Issue | Solution |
|-------|----------|
| `Dirty database version` | Run `migrate force 24`, then `migrate up` |
| `Foreign key constraint already exists` | Cleanup migration didn't run; run it manually |
| `Cannot connect to database` | Check PostgreSQL running, credentials correct, DB exists |
| `migrate command not found` | Install: `choco install migrate` |
| `FK error when accepting order` | Verify FK points to service_provider_profiles, not users |
| `Order number not generating` | Check trigger exists: `\dt` then search for trigger |

---

## Support Resources

- **Detailed Guide:** See `DEPLOYMENT_GUIDE.md`
- **Architecture:** See `CLEAN_MIGRATIONS_README.md`
- **Quick Reference:** See `MIGRATIONS_QUICK_REFERENCE.md`
- **Code Changes:** See `CODE_CHANGES_REFERENCE.md`

---

## Deployment Time Estimate

- Database setup: 5 min
- Migrations apply: 1 min
- Code build: 2 min
- Testing: 10 min
- **Total: ~20 minutes**

---

## Questions?

Refer to:
- DEPLOYMENT_GUIDE.md - Detailed instructions
- CLEAN_MIGRATIONS_README.md - Schema details
- MIGRATIONS_QUICK_REFERENCE.md - Common queries
