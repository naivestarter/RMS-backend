# DOMAIN_MAP.md — Alpine RMS Backend Domain (Bird’s-Eye)

This document describes the domain entities and their relationships.
It should remain high-level and stable; link out to detailed docs as needed.

## 1) Master Domain (`rms_master`)

### FranchiseGroup
- Purpose: umbrella grouping for analytics across multiple tenants (franchise/holding group).
- Has many Tenants.

### Tenant
- Purpose: a legal entity / isolated operational database.
- Identified by `restaurant_code` (apps) and optionally `domain`.
- Holds DB connection info (encrypted).
- Has status lifecycle (active/suspended/closed).

Relationships:
- FranchiseGroup (1) → (N) Tenants
- Tenant (1) → (N) TenantDomains

## 2) Tenant Domain (`rms_tenant_{slug}`)

### Branch
- Outlet/location within same legal entity.
- Branch is the core operational boundary for tables, printers, stations, inventory, reports.

### User
- Staff account within tenant.
- Branch access is via `branch_user` pivot with role.

### Station
- Dynamic preparation station (Kitchen/Bar/BBQ/Other).
- Belongs to a Branch.

### StationConfig
- Per-station workflow config:
  - KDS on/off
  - Printing on/off
  - Send mode (AUTO/MANUAL)
  - Printer mapping
  - KDS mode override

### Printer
- Network ESC/POS printer definition (MVP: network only).
- Belongs to Branch.

### MenuCategory / MenuItem
- Menu structure.
- MenuItem may map to a Station (default station).

### ModifierGroup / ModifierItem
- ModifierGroup defines rules (required, min/max).
- ModifierItem defines choices (price_delta).
- Many-to-many between MenuItem and ModifierGroup.

### Table
- Table inside Branch.
- Has 0 or 1 open Order at a time (MVP policy).

### Order
- POS order header.
- Belongs to Branch; optionally linked to Table.
- Types: dine_in, counter, takeaway, delivery.
- Status: open, closed, void.
- Payment status: unpaid, partial, paid.

### OrderItem
- Line items; each item belongs to an Order.
- Has station snapshot and status lifecycle:
  - queued → preparing → (ready/served) depending on KDS mode

### Payment
- Belongs to Order.
- Method: cash/card/fonepay/esewa/other.

### SplitBill (conditional)
- Enabled via restaurant_settings.enable_split_bill.
- Keep one Order header; split into sub-bills.

### Printing (Option A)
- KOT tickets are created on send-to-station.
- `print_jobs` are queued for a print executor device.

### Notifications
- Event-driven notifications stored in DB and optionally sent via push.

## 3) Global Rules & Invariants

- Every tenant request MUST be resolved by `X-Restaurant-Code`.
- Every branch-scoped request MUST provide `X-Branch-Id`.
- One open order per table (MVP).
- Station workflow is configurable per station and globally via `kds_mode`.
- Printing can be enabled per station and runs via print executor polling (Option A).
