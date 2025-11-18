## Home Services Feature – Outline & Short Documentation

**Purpose**:  
The Home Services feature extends your Uber-like platform into on-demand home maintenance/repair bookings (e.g., plumbing, cleaning, electrical work). It connects customers with qualified providers, handles complex service configurations (options, add-ons), dynamic pricing (surge, discounts), and integrates with existing wallet for secure holds/captures. This creates a unified "super app" for mobility + home needs.

### Core Features

| Feature                        | Description                                                                                   | Who Uses It                  |
|-------------------------------|-----------------------------------------------------------------------------------------------|------------------------------|
| Category & Tab Navigation      | Hierarchical browsing: Categories (e.g., Cleaning) with Tabs (e.g., Regular, Deep).           | Customers (discovery)        |
| Service Catalog                | Detailed services with pricing models (fixed/hourly/per_unit), options (select/text/quantity), and add-ons. | Customers (selection)        |
| Order Booking                  | Multi-item orders with address, date, frequency (once/recurring), notes, coupons.             | Customers                    |
| Pricing Calculation            | Base + options + add-ons + surge + platform fee (10%); discounts via coupons.                 | System (real-time)           |
| Provider Matching              | Geo-based search for nearest qualified providers; cascading offers with 60s timeout.          | System (async)               |
| Order Lifecycle                | Searching → Accepted → In Progress → Completed/Cancelled; with wallet holds.                 | Providers + Customers        |
| Admin Management               | CRUD for categories/tabs/services/options/add-ons; provider qualification.                    | Admins                       |
| Wallet Integration             | Holds on booking; capture on complete; transfer earnings to provider.                         | System (payments)            |

### Folder Structure (Modular Design)

```
internal/modules/homeservices/
├── dto/              → Requests/responses + validation/converters
├── handler.go        → Gin handlers for customer/provider/admin
├── repository.go     → GORM + PostGIS for geo-matching
├── routes.go         → /services group with role middleware
├── service.go        → Business logic (pricing, matching, async offers)
└── interfaces        → Repository & Service
```

### API Endpoints Summary

#### Public/Customer Routes
| Method | Path                        | Auth? | Description                              |
|-------|-----------------------------|-------|------------------------------------------|
| GET   | `/services/categories`      | No    | List active categories                   |
| GET   | `/services/categories/{id}` | No    | Category details with tabs               |
| GET   | `/services`                 | No    | Paginated services (filter by cat/tab)   |
| GET   | `/services/{id}`            | No    | Service details with options             |
| GET   | `/services/addons`          | No    | Add-ons for category                     |
| POST  | `/services/orders`          | Yes   | Create order (customer)                  |
| GET   | `/services/orders`          | Yes   | List my orders                           |
| GET   | `/services/orders/{id}`     | Yes   | Order details                            |
| POST  | `/services/orders/{id}/cancel` | Yes | Cancel order                             |

#### Provider Routes (Role: provider)
| Method | Path                             | Description                              |
|-------|----------------------------------|------------------------------------------|
| GET   | `/services/provider/orders`      | List assigned orders                     |
| POST  | `/services/provider/orders/{id}/accept` | Accept job                          |
| POST  | `/services/provider/orders/{id}/reject` | Reject job                          |
| POST  | `/services/provider/orders/{id}/start`  | Start job                           |
| POST  | `/services/provider/orders/{id}/complete` | Complete job                      |

#### Admin Routes (Role: admin)
| Method | Path                             | Description                              |
|-------|----------------------------------|------------------------------------------|
| POST  | `/services/admin/categories`     | Create category                          |
| POST  | `/services/admin/tabs`           | Create tab                               |
| POST  | `/services/admin/services`       | Create service                           |
| PUT   | `/services/admin/services/{id}`  | Update service                           |
| POST  | `/services/admin/addons`         | Create add-on                            |

### Key Design Decisions & Highlights

- **Hierarchical Catalog**: Categories → Tabs → Services → Options/Choices → Add-ons; enables complex configs (e.g., "Deep Cleaning" with "Rooms: 3" option + "Carpet Shampoo" add-on).
- **Dynamic Pricing**: Base + modifiers; surge by time/location; 10% platform fee; coupons for discounts.
- **Provider Matching**: Cascading (one-by-one with timeout); geo-search (15km default) for qualified providers (must handle all order services).
- **Order States**: Searching_provider → Accepted → In_progress → Completed/Cancelled; integrated with wallet holds (24h expiry).
- **Async Operations**: Provider search/notify in goroutines; timeout checks via time.AfterFunc.
- **Security**: Role middleware (customer/provider/admin); ownership checks on orders.
- **Wallet Flow**: Hold on create; capture on complete; transfer earnings (total - fee) to provider.
- **Scalability**: Cache for catalogs; PostGIS for geo; async for matching to not block API.
- **Extensibility**: Frequency for recurring; notes for custom instructions.

### Dependencies Used

- Gin + binding/validation
- GORM + PostGIS (geo)
- Redis (cache for offers/rejected)
- Existing: Wallet (holds/capture/transfer), Config, Logger, Response
- Utils: UUID, time parsing

