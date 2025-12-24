# Step-by-Step: Apply Foreign Key Fix

## Quick Fix (Recommended - 2 minutes)

### Connect to Database
```bash
# PowerShell
$env:PGPASSWORD = "your_password"
psql -U go_backend_admin -d go_backend -h localhost -p 5432
```

Or use your database GUI (DBeaver, pgAdmin, etc.) and run the following SQL:

### Copy and Paste These Commands

```sql
-- Step 1: Drop the old foreign key constraint that references users table
ALTER TABLE service_orders 
DROP CONSTRAINT IF EXISTS fk_service_orders_provider;

-- Step 2: Add the new foreign key constraint that references service_provider_profiles table
ALTER TABLE service_orders 
ADD CONSTRAINT fk_service_orders_provider 
    FOREIGN KEY (assigned_provider_id) REFERENCES service_provider_profiles(id) ON DELETE SET NULL;

-- Step 3: Verify the constraint was created correctly (optional)
SELECT constraint_name, table_name, column_name, referenced_table_name
FROM information_schema.referential_constraints
WHERE constraint_name = 'fk_service_orders_provider';
```

### Expected Output from Verification

```
 constraint_name    | table_name    | column_name         | referenced_table_name
--------------------+---------------+---------------------+-----------------------
 fk_service_orders_provider | service_orders | assigned_provider_id | service_provider_profiles
(1 row)
```

---

## Verification Queries

After applying the fix, run these queries to verify:

### 1. Check the constraint exists
```sql
SELECT 
    constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE constraint_name = 'fk_service_orders_provider';
```

**Expected:** 1 row showing `service_provider_profiles` as referenced table

### 2. Verify no existing orphaned records
```sql
SELECT COUNT(*) as orphaned_orders
FROM service_orders
WHERE assigned_provider_id IS NOT NULL
AND assigned_provider_id NOT IN (
    SELECT id FROM service_provider_profiles
);
```

**Expected:** 0 rows (no orphaned records)

### 3. Check that service_provider_profiles exist
```sql
SELECT COUNT(*) as provider_count, 
       COUNT(DISTINCT user_id) as unique_users
FROM service_provider_profiles;
```

**Expected:** At least 1 row with provider data

### 4. Check that orders can be inserted with valid provider IDs
```sql
-- This should succeed (test query, doesn't actually insert)
SELECT assigned_provider_id 
FROM service_orders 
WHERE assigned_provider_id IN (SELECT id FROM service_provider_profiles)
LIMIT 5;
```

**Expected:** If there are orders accepted by providers, they will appear here

---

## If Something Goes Wrong

### Rollback to Previous State
```sql
-- Undo: Change back to referencing users table
ALTER TABLE service_orders 
DROP CONSTRAINT IF EXISTS fk_service_orders_provider;

ALTER TABLE service_orders 
ADD CONSTRAINT fk_service_orders_provider 
    FOREIGN KEY (assigned_provider_id) REFERENCES users(id) ON DELETE SET NULL;
```

### Check Current Constraints
```sql
-- See all foreign keys on service_orders table
SELECT 
    constraint_name,
    table_name,
    column_name,
    referenced_table_name
FROM information_schema.key_column_usage
WHERE table_name = 'service_orders' 
AND referenced_table_name IS NOT NULL;
```

### See All Constraints on the Table
```sql
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'service_orders';
```

---

## Database Connection Strings

### For Different Tools

**psql (Command Line):**
```bash
psql -U go_backend_admin -d go_backend -h localhost -p 5432
```

**DBeaver:**
```
Server Host: localhost
Port: 5432
Database: go_backend
Username: go_backend_admin
Password: (your_password)
```

**pgAdmin:**
```
Name: localhost
Host name: localhost
Port: 5432
Username: go_backend_admin
Database: go_backend
```

**Python psycopg2:**
```python
import psycopg2
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="go_backend",
    user="go_backend_admin",
    password="your_password"
)
```

---

## After Fixing the Database

### Restart the Application
```bash
# Stop current instance
# Then restart
make run
# or
make dev
```

### Test the Fix

```bash
# 1. Provider accepts an order
curl -X POST http://localhost:8080/api/v1/provider/orders/bab3f882-87f4-4886-b512-4a2d84ea2682/accept \
  -H "Authorization: Bearer <PROVIDER_TOKEN>"

# Expected: 200 OK (not 500 FK constraint error)
```

---

## Troubleshooting

### "constraint fk_service_orders_provider does not exist"
This is OK - it means you're running the fix a second time. The constraint was already dropped.

### "relation service_provider_profiles does not exist"
Make sure you have run all previous migrations that create the `service_provider_profiles` table. Check migration `000039_create_service_provider_profiles.up.sql`.

### "ERROR: insert or update on table service_orders violates foreign key constraint"
After fixing, this error should go away. If it persists:
1. Verify the constraint was created: `SELECT * FROM information_schema.referential_constraints WHERE constraint_name = 'fk_service_orders_provider';`
2. Verify provider IDs exist: `SELECT COUNT(*) FROM service_provider_profiles;`
3. Restart the application

### "insufficient privilege"
Make sure you're connected as `go_backend_admin` or a role with ALTER TABLE permissions.

---

## Summary

✅ **Simple Fix:** Run 2 SQL commands
⏱️ **Time Required:** ~30 seconds
🔄 **Rollback Available:** Yes (provided in "If Something Goes Wrong" section)
✔️ **Testing:** Simple verification queries provided
📊 **Impact:** No application downtime if done during off-peak hours
