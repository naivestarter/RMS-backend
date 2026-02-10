# API_MAP.md — Alpine RMS Backend Endpoints

This document maps all HTTP endpoints in `rms-backend`.

## Conventions

### Headers
- `X-Restaurant-Code` — REQUIRED for all `/api/v1/*` tenant requests.
- `X-Branch-Id` — REQUIRED for all branch-scoped endpoints.
- `Authorization: Bearer <token>` — REQUIRED for authenticated routes.

### Response Envelope (Standard)
Success:
```json
{ "data": { ... }, "meta": { ... } }
```

Validation error (422):
```json
{ "message": "Validation error", "errors": { "field": ["error..."] } }
```

Auth error (401):
```json
{ "message": "Unauthenticated" }
```

Forbidden (403):
```json
{ "message": "Forbidden" }
```

Conflict (409) — table already has open order, ticket already converted, etc.:
```json
{ "message": "Conflict", "errors": { "code": "TABLE_HAS_OPEN_ORDER", "existing_order_id": 55 } }
```

### Pagination
List endpoints should support:
- `page`, `per_page` (default 20, max 100)
- respond with `meta.pagination`

---

## 1) Public (No Auth)

### Tenant resolve
- `POST /api/public/tenant/resolve`

---

## 2) Admin (Master DB)

### Auth
- `POST /api/admin/auth/login`
- `GET /api/admin/auth/me`
- `POST /api/admin/auth/logout`

### Tenants
- `GET /api/admin/tenants`
- `POST /api/admin/tenants` (creates tenant + provisions DB)
- `GET /api/admin/tenants/{id}`
- `PUT /api/admin/tenants/{id}`
- `POST /api/admin/tenants/{id}/suspend`
- `POST /api/admin/tenants/{id}/activate`

### Franchise Groups
- `GET /api/admin/franchise-groups`
- `POST /api/admin/franchise-groups`
- `GET /api/admin/franchise-groups/{id}`
- `PUT /api/admin/franchise-groups/{id}`

---

## 3) Tenant (Tenant DB) — `/api/v1/*`

### Auth
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`

### Restaurant Settings (owner/manager)
- `GET /api/v1/restaurant/settings`
- `PUT /api/v1/restaurant/settings`

### Branches (owner/manager)
- `GET /api/v1/branches`
- `POST /api/v1/branches`
- `GET /api/v1/branches/{id}`
- `PUT /api/v1/branches/{id}`

### Staff (owner/manager)
- `GET /api/v1/staff`
- `POST /api/v1/staff`
- `PUT /api/v1/staff/{id}`
- `POST /api/v1/staff/{id}/assign-branch`

### Stations (owner/manager)
- `GET /api/v1/branches/{branch_id}/stations`
- `POST /api/v1/branches/{branch_id}/stations`
- `PUT /api/v1/stations/{id}`
- `GET /api/v1/stations/{id}/config`
- `PUT /api/v1/stations/{id}/config`

### Tables (owner/manager)
- `GET /api/v1/branches/{branch_id}/tables`
- `POST /api/v1/branches/{branch_id}/tables`
- `PUT /api/v1/tables/{id}`

### Printers (owner/manager)
- `GET /api/v1/branches/{branch_id}/printers`
- `POST /api/v1/branches/{branch_id}/printers`
- `PUT /api/v1/printers/{id}`

### Menu
- `GET /api/v1/menu/categories`
- `POST /api/v1/menu/categories`
- `PUT /api/v1/menu/categories/{id}`
- `GET /api/v1/menu/items`
- `POST /api/v1/menu/items`
- `PUT /api/v1/menu/items/{id}`
- `POST /api/v1/menu/modifier-groups`
- `PUT /api/v1/menu/modifier-groups/{id}`
- `POST /api/v1/menu/modifier-items`
- `PUT /api/v1/menu/modifier-items/{id}`
- `POST /api/v1/menu/items/{id}/modifier-groups`

### Orders (POS)
- `GET /api/v1/orders`
- `POST /api/v1/orders`
- `GET /api/v1/orders/{id}`
- `POST /api/v1/orders/{id}/items`
- `POST /api/v1/orders/{id}/send-to-stations`
- `POST /api/v1/orders/{id}/payments`
- `POST /api/v1/orders/{id}/close`

### Order Items (Stations)
- `GET /api/v1/stations/{station_id}/queue`
- `POST /api/v1/order-items/{id}/status`

### Split Bill (if enabled in settings)
- `POST /api/v1/orders/{id}/splits`
- `POST /api/v1/orders/{id}/splits/{split_id}/assign-item`
- `POST /api/v1/orders/{id}/splits/{split_id}/pay`

### Printing (Option A)
- `POST /api/v1/printing/executor/register`
- `GET /api/v1/printing/jobs/next`
- `POST /api/v1/printing/jobs/{id}/printed`
- `POST /api/v1/printing/jobs/{id}/failed`

### Notifications
- `GET /api/v1/notifications/rules`
- `POST /api/v1/notifications/rules`
- `PUT /api/v1/notifications/rules/{id}`
- `DELETE /api/v1/notifications/rules/{id}`
- `GET /api/v1/notifications`
- `POST /api/v1/notifications/{id}/read`
- `POST /api/v1/devices/push-token`

### Reports
- `GET /api/v1/reports/sales/daily`
- `GET /api/v1/reports/sales/monthly`
- `GET /api/v1/reports/sales/items`

---

## Endpoint Ownership Rules

- `/api/admin/*` uses master DB only.
- `/api/v1/*` uses tenant DB only.
- Any cross-tenant aggregation is performed in `/api/admin/*` or a future `/api/group/*` layer (master-driven).
