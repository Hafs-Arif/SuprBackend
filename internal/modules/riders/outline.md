## Riders Module – Full Outline & Review

### Purpose in the Uber-like Platform
The **riders module** is the **rider-side counterpart** to the drivers module.  
It manages everything a rider needs after signing up with their phone:

- Auto-created rider profile (during phone signup → `auth.service` calls `riderService.CreateProfile`)
- Home / Work saved locations
- Preferred vehicle type
- Rating & trip count
- Wallet integration
- Stats dashboard

It is intentionally **lightweight** because riders don't need real-time location broadcasting like drivers do.

### Folder Structure (perfect modular pattern)

```
internal/modules/riders/
├── dto/          → Request/response DTOs + ToResponse helpers
├── handler.go    → 3 protected endpoints
├── repository.go → GORM operations + Preload User/Wallet
├── routes.go     → /riders/* group
├── service.go    → Business logic + internal methods used by auth & rides
```

### API Endpoints (All require Bearer token)

| Method | Path                | Purpose                                | Response Type                  |
|-------|---------------------|----------------------------------------|--------------------------------|
| GET   | `/riders/profile`   | Get full rider profile + wallet        | RiderProfileResponse           |
| PUT   | `/riders/profile`   | Update home/work address, preferred vehicle | RiderProfileResponse           |
| GET   | `/riders/stats`     | Quick stats (rides, rating, balance)   | RiderStatsResponse             |

**Missing but not critical right now**:  
- Favorite locations list (you only have home/work)  
- Ride history endpoint (will likely live in a future `rides` module)

### Service Interface – All Methods Correctly Used?

| Method               | Called From?                         | Used? | Cache? | Notes |
|----------------------|---------------------------------------|-------|--------|-------|
| `GetProfile`         | Handler ✓                             | Yes   | Yes (5 min) | Perfect |
| `UpdateProfile`      | Handler ✓                             | Yes   | Invalidates | Perfect |
| `GetStats`           | Handler ✓                             | Yes   | No     | Lightweight, no need |
| `CreateProfile`      | **auth module** during phone signup  | Yes   | —      | Critical & correctly wired |
| `IncrementRides`     | Will be called from **rides module** after trip completion | Yes (future) | Invalidates profile cache | Ready |
| `UpdateRating`       | Will be called from **rides module** after driver rates rider | Yes (future) | Invalidates profile cache | Ready |
