# Code Changes Reference

## 1. Model Change - `internal/models/service_order.go`

### Lines 212-215: Foreign Key Reference

**BEFORE:**
```go
// Provider
AssignedProviderID  *string    `gorm:"type:uuid;index" json:"assignedProviderId"`
AssignedProvider    *User      `gorm:"foreignKey:AssignedProviderID" json:"assignedProvider,omitempty"`
ProviderAcceptedAt  *time.Time `json:"providerAcceptedAt"`
```

**AFTER:**
```go
// Provider
AssignedProviderID  *string                 `gorm:"type:uuid;index" json:"assignedProviderId"`
AssignedProvider    *ServiceProviderProfile `gorm:"foreignKey:AssignedProviderID;references:ID" json:"assignedProvider,omitempty"`
ProviderAcceptedAt  *time.Time              `json:"providerAcceptedAt"`
```

**Why:** The `AssignedProviderID` stores ProviderProfile IDs, not User IDs. The foreign key should reference `ServiceProviderProfile` table.

---

## 2. Service Layer - `internal/modules/homeservices/provider/service.go`

### Lines 23-24: Interface Update

**ADDED:**
```go
type Service interface {
	// User ID to Provider ID conversion
	GetProviderIDByUserID(ctx context.Context, userID string) (string, error)
	
	// ... rest of interface
}
```

### Lines 70-82: Implementation

**ADDED:**
```go
// GetProviderIDByUserID retrieves the provider ID from a user ID
func (s *service) GetProviderIDByUserID(ctx context.Context, userID string) (string, error) {
	// Query the provider repository to find provider by user ID
	provider, err := s.repo.GetProviderByUserID(ctx, userID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return "", response.NotFoundError("Provider not found for this user")
		}
		logger.Error("failed to get provider by user ID", "error", err, "userID", userID)
		return "", response.InternalServerError("Failed to retrieve provider", err)
	}
	return provider.ID, nil
}
```

**Why:** Provides a way to convert UserID (from auth) to ProviderID (needed for queries).

---

## 3. Repository Layer - `internal/modules/homeservices/provider/repository.go`

### Lines 17-18: Interface Update

**ADDED:**
```go
type Repository interface {
	// Provider profile
	GetProvider(ctx context.Context, providerID string) (*models.ServiceProviderProfile, error)
	GetProviderByUserID(ctx context.Context, userID string) (*models.ServiceProviderProfile, error)
	
	// ... rest of interface
}
```

### Lines 107-115: Implementation

**ADDED:**
```go
func (r *repository) GetProviderByUserID(ctx context.Context, userID string) (*models.ServiceProviderProfile, error) {
	var provider models.ServiceProviderProfile
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Preload("User").
		First(&provider).Error
	return &provider, err
}
```

**Why:** Allows looking up a ServiceProviderProfile by UserID.

---

## 4. Handler Layer - `internal/modules/homeservices/provider/handler.go`

### Lines 19-29: Helper Method Added

**ADDED:**
```go
// getProviderIDFromContext extracts userID and converts it to providerID
func (h *Handler) getProviderIDFromContext(c *gin.Context) (string, error) {
	userID, _ := c.Get("userID")
	providerID, err := h.service.GetProviderIDByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		return "", err
	}
	return providerID, nil
}
```

**Why:** Centralizes the UserID → ProviderID conversion logic.

---

### All Handler Methods Updated - Pattern

Every handler method was updated to use the helper. Here's the pattern:

**BEFORE:**
```go
func (h *Handler) SomeMethod(c *gin.Context) {
	providerID, _ := c.Get("userID")  // ❌ WRONG: Using UserID directly
	
	result, err := h.service.SomeMethod(c.Request.Context(), providerID.(string), ...)
	// ...
}
```

**AFTER:**
```go
func (h *Handler) SomeMethod(c *gin.Context) {
	providerID, err := h.getProviderIDFromContext(c)  // ✅ RIGHT: Convert UserID to ProviderID
	if err != nil {
		c.Error(err)
		return
	}
	
	result, err := h.service.SomeMethod(c.Request.Context(), providerID, ...)
	// ...
}
```

### Methods Updated (17 total):

1. ✅ GetProfile
2. ✅ UpdateAvailability
3. ✅ GetServiceCategories
4. ✅ AddServiceCategory
5. ✅ UpdateServiceCategory
6. ✅ DeleteServiceCategory
7. ✅ GetAvailableOrders
8. ✅ GetAvailableOrderDetail
9. ✅ GetMyOrders
10. ✅ GetMyOrderDetail
11. ✅ AcceptOrder
12. ✅ RejectOrder
13. ✅ StartOrder
14. ✅ CompleteOrder
15. ✅ RateCustomer
16. ✅ GetStatistics
17. ✅ GetEarnings

---

## 5. Database Migration - `migrations/000042_fix_service_orders_provider_fk.up.sql`

**NEW FILE - UP Migration:**
```sql
-- Fix foreign key constraint for assigned_provider_id
-- Change from referencing users table to service_provider_profiles table

ALTER TABLE service_orders 
DROP CONSTRAINT fk_service_orders_provider;

ALTER TABLE service_orders 
ADD CONSTRAINT fk_service_orders_provider 
    FOREIGN KEY (assigned_provider_id) REFERENCES service_provider_profiles(id) ON DELETE SET NULL;
```

---

## 6. Database Migration Rollback - `migrations/000042_fix_service_orders_provider_fk.down.sql`

**NEW FILE - DOWN Migration (Rollback):**
```sql
-- Rollback: Revert foreign key constraint for assigned_provider_id
-- Change from service_provider_profiles back to users table

ALTER TABLE service_orders 
DROP CONSTRAINT fk_service_orders_provider;

ALTER TABLE service_orders 
ADD CONSTRAINT fk_service_orders_provider 
    FOREIGN KEY (assigned_provider_id) REFERENCES users(id) ON DELETE SET NULL;
```

---

## Summary of Changes

| Category | Type | Count | Status |
|----------|------|-------|--------|
| Code Files Modified | Go Source | 4 | ✅ Compiled |
| Handler Methods Updated | Methods | 17 | ✅ Complete |
| New Service Methods | Methods | 1 | ✅ Added |
| New Repository Methods | Methods | 1 | ✅ Added |
| Database Migrations | Migrations | 2 | ⏳ Need to Run |
| New SQL Scripts | Files | 1 | 📄 Manual Alternative |
| Documentation Files | Docs | 4 | ✅ Created |

---

## Testing the Changes

### Unit-Level Test: UserID Conversion
```go
// Test that GetProviderIDByUserID works
userID := "59e0d332-133b-4d41-8db1-3a363c74b744"
providerID, err := service.GetProviderIDByUserID(ctx, userID)
// Expected: providerID = "fce4ac06-1dd2-48fb-bb4a-8b8ae99830f9"
// Expected: err = nil
```

### Integration Test: Provider Accepts Order
```bash
# 1. Provider with UserID gets providerID via helper
# 2. Handler uses correct providerID
# 3. Database accepts order with valid FK reference
# 4. No constraint violation
# 5. Order marked as accepted
```

---

## Deployment Checklist

- [ ] Code compiled successfully: ✅
- [ ] No breaking changes to API
- [ ] No new dependencies added
- [ ] Database migration created
- [ ] Migration tested in dev environment
- [ ] Rollback plan documented (in .down.sql)
- [ ] Code changes deployed
- [ ] Database migration run
- [ ] Application restarted
- [ ] Smoke tests passed (see VALIDATION_GUIDE.md)
