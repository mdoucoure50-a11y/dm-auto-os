# DM Auto OS — Development Roadmap

Primary currency: **XAF**

## Current Phase: Rental Operations Core

Focus on rental fleet management, cash tracking, and period closing before expanding into workshop and trading workflows.

---

## Module Priority

### Phase 1 — Primary (active development)

| Priority | Module | Data model | Status |
|----------|--------|------------|--------|
| 1 | **Rentals** | `rentals`, `vehicles` | Scaffolded |
| 2 | **Cashbook** | `transactions`, `cashbook_entries` (view) | Schema ready |
| 3 | **Rental Period Closing** | `rental_periods`, `rental_period_closings`, `close_rental_period()` | Schema ready |
| 4 | **Vehicle Profitability** | `vehicle_profitability` (view), `expenses` | Schema ready |
| 5 | **Customers** | `customers` | Scaffolded |
| 6 | **Drivers** | `drivers` | Schema ready |
| 7 | **Documents** | `documents` | Schema ready |

### Phase 2 — Secondary (available, not prioritized)

| Module | Data model | Notes |
|--------|------------|-------|
| **Workshop** | `service_orders` (optional) | Vehicle link is optional; module accessible from drawer |
| **Trading** | `vehicle_sales` | Vehicle sales; deferred UI focus |
| **Fleet** | `vehicles` | Supports rentals & profitability |
| **Reports** | `reports` | Generated exports |

### Phase 3 — Administration

| Module | Data model |
|--------|------------|
| **Users** | `profiles` |
| **Settings** | App configuration |

---

## Phase 1 Deliverables

### 1. Rentals
- [ ] CRUD rental agreements
- [ ] Link rentals to vehicles, customers, drivers, rental periods
- [ ] Rental status workflow: pending → active → completed / cancelled

### 2. Cashbook
- [ ] Income & expense entry UI
- [ ] Chronological ledger with running XAF balance
- [ ] Filter by date, category, customer, vehicle
- [ ] Link entries to rentals and rental periods

### 3. Rental Period Closing
- [ ] Create and manage rental periods
- [ ] Group rentals under a period
- [ ] Close period via `close_rental_period()` — locks period, records totals
- [ ] Attach closing documents to period

### 4. Vehicle Profitability
- [ ] Per-vehicle income vs expense dashboard
- [ ] Net profit (XAF) from `vehicle_profitability` view
- [ ] Drill-down to transactions and expenses

### 5. Customers
- [ ] Customer CRUD
- [ ] Rental history per customer
- [ ] Document attachments

### 6. Drivers
- [ ] Driver CRUD with license tracking
- [ ] Assign drivers to rentals
- [ ] License expiry alerts

### 7. Documents
- [ ] Upload to Supabase Storage
- [ ] Attach to vehicles, customers, rentals, transactions, rental periods
- [ ] Document type classification

---

## Workshop Module (optional)

`service_orders` is retained in the schema but is **not a primary navigation item** during Phase 1.

- `vehicle_id` is optional — workshop jobs can exist without a fleet vehicle
- Accessible from the **More** menu as "Workshop"
- Full workshop UI planned for Phase 2

---

## Database Migrations

Run in order:

```
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_financial_operations_schema.sql
   supabase/migrations/003_module_priorities.sql
   supabase/migrations/004_schema_grants_and_comments.sql
   ```

---

## Architecture Notes

- All monetary values stored as **INTEGER** (XAF, no decimals)
- Soft deletes on all business tables (`deleted_at`)
- RLS hides deleted records from non-administrators
- Views (`cashbook_entries`, `vehicle_profitability`) are read-only reporting layers
