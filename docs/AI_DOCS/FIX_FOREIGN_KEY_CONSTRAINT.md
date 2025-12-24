# Fix Update: Foreign Key Constraint Issue

## Problem

When a provider tried to accept an order, the system failed with:
```
ERROR: insert or update on table "service_orders" violates foreign key constraint "fk_service_orders_provider"
```

## Root Cause

The `ServiceOrderNew` model had an incorrect foreign key relationship:

```go
// WRONG - Before
AssignedProvider *User `gorm:"foreignKey:AssignedProviderID" json:"assignedProvider,omitempty"`
```

This told GORM to create a foreign key constraint from `service_orders.assigned_provider_id` to the `users` table. However:
- `AssignedProviderID` stores **ProviderIDs** (from `ServiceProviderProfile.id`)
- The constraint was looking for these IDs in the **users** table
- ProviderIDs don't exist in the users table → constraint violation

## Solution

Fixed the foreign key to reference the correct table:

```go
// CORRECT - After
AssignedProvider *ServiceProviderProfile `gorm:"foreignKey:AssignedProviderID;references:ID" json:"assignedProvider,omitempty"`
```

**File:** `internal/models/service_order.go` (line 212-215)

### Changes Made
- Changed `AssignedProvider` type from `*User` to `*ServiceProviderProfile`
- Added explicit `references:ID` to be clear about which column we reference
- Now GORM correctly creates foreign key constraint: `assigned_provider_id` → `service_provider_profiles.id`

## Testing

```bash
# Accept an order as provider
POST /api/v1/provider/orders/{order_id}/accept

# Expected: 200 OK (not 500 foreign key error)
```

## Why This Works Now

1. Provider registers → Gets ProviderID: `fce4ac06-...`
2. Services assigned to ProviderID in database
3. Provider accepts order → `assigned_provider_id = fce4ac06-...`
4. Database checks: Does `fce4ac06-...` exist in `service_provider_profiles.id`? ✅ YES
5. Foreign key constraint passes
6. Order accepted successfully

## Files Modified

1. `internal/models/service_order.go` - Fixed foreign key relationship

## Build Status

✅ **Build successful** - No compile errors
