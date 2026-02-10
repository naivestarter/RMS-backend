# CODEX_TASKS_BACKEND.md — Alpine RMS (rms-backend) Codex Task Pack v2

This task pack incorporates:
- branch header standard: `X-Branch-Id`
- tenancy header standard: `X-Restaurant-Code`
- printing Option A (executor polling)
- package policy in `docs/BACKEND_PACKAGES.md`
- realtime strategy in `docs/REALTIME.md` (polling now, Reverb later)

## How to run
Run tasks sequentially until tenancy+auth are stable. After Task 6, tasks can be parallelized on separate branches/worktrees.

---

## Task 0 — Sync docs and enforce policies (Kickoff)

Paste into Codex:

```text
TASK: Backend kickoff & doc policy enforcement

Repo: rms-backend

1) Create /PLANS.md describing implementation sequence (Tasks 1–10).
2) Create /docs/CONVENTIONS.md:
   - Headers: X-Restaurant-Code, X-Branch-Id
   - Response envelopes and error shapes (422/401/403/409)
   - Pagination rules
3) Add /docs/BACKEND_PACKAGES.md exactly matching project policy:
   - Required: laravel/sanctum, spatie/laravel-permission, spatie/laravel-activitylog
   - Forbidden: tenancy packages (stancl/tenancy, spatie/laravel-multitenancy)
4) Add /docs/REALTIME.md describing polling now and Reverb later (push refresh).
5) Ensure existing docs are consistent (TENANCY.md, API_MAP.md, DOMAIN_MAP.md, EVENT_MAP.md, PRINTING.md).
6) Do not implement features yet.

Deliverables: PLANS.md + docs/CONVENTIONS.md + docs/BACKEND_PACKAGES.md + docs/REALTIME.md.
```

---

## Task 1 — Install required packages (MVP baseline)

```text
TASK: Install and configure required MVP packages.

1) Install:
   - laravel/sanctum
   - spatie/laravel-permission
   - spatie/laravel-activitylog

2) Configure:
   - Sanctum for API token authentication (Flutter/API clients).
   - Spatie permission tables must live in tenant DB migrations (not master).
   - Activitylog tables must live in tenant DB migrations.

3) Update docs/BACKEND_PACKAGES.md with any config notes (no policy changes).
4) Add minimal smoke tests to confirm packages load and migrations publish.

Constraints:
- Do NOT install any tenancy package.
- Do NOT add broadcasting/reverb now.
```

---

## Task 2 — Master DB schema + Admin API (tenant registry)

```text
TASK: Implement rms_master schema and admin tenant management.

1) Master migrations:
   - franchise_groups
   - tenants (restaurant_code unique, status, db connection fields; encrypt secrets)
   - tenant_domains (optional)
   - master_users (super_admin)

2) Admin auth (Sanctum tokens acceptable for admin too):
   - POST /api/admin/auth/login
   - GET /api/admin/auth/me
   - POST /api/admin/auth/logout

3) Admin tenant endpoints (match docs/API_MAP.md):
   - GET /api/admin/tenants
   - POST /api/admin/tenants (create master record only)
   - GET /api/admin/tenants/{id}
   - PUT /api/admin/tenants/{id}
   - POST /api/admin/tenants/{id}/suspend
   - POST /api/admin/tenants/{id}/activate

4) Tests: admin auth + tenant CRUD basics
5) Docs: update DOMAIN_MAP.md and API_MAP.md only if necessary.
```

---

## Task 3 — Tenant resolve + middleware DB switching (custom tenancy)

```text
TASK: Implement tenant resolution and tenant DB switching middleware.

1) Public endpoint:
   - POST /api/public/tenant/resolve (restaurant_code -> tenant_slug/status)

2) ResolveTenantMiddleware:
   - reads X-Restaurant-Code
   - looks up tenant in rms_master.tenants (cache results)
   - validates status active
   - configures database.connections.tenant dynamically
   - DB::purge('tenant') and reconnect
   - binds CurrentTenant context

3) Apply middleware to all /api/v1/* routes.

4) Docs: TENANCY.md must match actual behavior.
5) Tests: missing header rejection + active tenant switching happy path.

Constraints:
- No tenancy packages.
```

---

## Task 4 — Tenant provisioning tooling (create DB + migrate + seed defaults)

```text
TASK: Implement tenant provisioning.

1) Artisan commands:
   - tenant:provision --tenant=<id|slug>
   - tenant:migrate --tenant=<slug>
   - tenant:migrate --all
   - tenant:seed --tenant=<slug>

2) Provision steps:
   - create DB `rms_tenant_{slug}` (prefix configurable)
   - run tenant migrations
   - seed defaults:
     - restaurant_settings (kds_mode=READY_ONLY, enable_split_bill=false, business_day_starts_at=05:00:00, vat_mode=INCLUSIVE)
     - default branch "Main"
     - default stations (Kitchen/Bar/BBQ) + station_configs (KDS on, printing off, send_mode MANUAL)

3) Docs: update TENANCY.md provisioning section.
4) Tests: provisioning creates required rows (integration if MySQL available; otherwise mock DB creation and test seeding against sqlite tenant connection).
```

---

## Task 5 — Tenant DB migrations (core) + Branch middleware (X-Branch-Id)

```text
TASK: Create tenant DB migrations and enforce branch context.

1) Tenant migrations (minimum):
   - branches
   - users
   - branch_user (branch roles)
   - restaurant_settings
   - stations, station_configs
   - printers
   - devices
   - tables
   - menu_categories, menu_items
   - modifier_groups, modifier_items, menu_item_modifier_groups

2) EnsureBranchContextMiddleware:
   - requires X-Branch-Id for branch-scoped routes
   - validates branch exists & active
   - binds CurrentBranch context

3) Docs: TENANCY.md and DOMAIN_MAP.md updated.
4) Tests: missing X-Branch-Id returns 422 with standard errors shape.
```

---

## Task 6 — Tenant Auth + RBAC (branch roles + Spatie permission registry)

```text
TASK: Implement tenant auth and authorization.

Endpoints:
- POST /api/v1/auth/login
- GET /api/v1/auth/me
- POST /api/v1/auth/logout

Login response includes:
- token
- user
- branches + role per branch (from branch_user.role)
- default_branch_id
- settings snapshot

RBAC Rule:
- branch_user.role defines branch role.
- Spatie permissions define what each role can do.
- Authorization check = branch membership + permission for role.

Deliverables:
- Seed roles->permissions mapping (tenant seeder)
- Gates/Policies/middleware for modules:
  - owner/manager: settings/menu/stations/printers/staff
  - cashier/waiter: orders/payments
  - station roles: station queue + item status (respect kds_mode)

Docs:
- DOMAIN_MAP.md roles model
- API_MAP.md response example for /auth/me (optional)

Tests:
- forbidden actions blocked
```

---

## Task 7 — POS core: Orders + Items + Payments (409 conflicts)

```text
TASK: Implement orders, items, payments.

Migrations:
- orders, order_items, order_item_modifiers, payments

Rules:
- One open order per table -> 409 TABLE_HAS_OPEN_ORDER
- Server-side totals and VAT logic
- Modifier validation (required/min/max)

Endpoints:
- POST /api/v1/orders
- POST /api/v1/orders/{id}/items
- GET /api/v1/orders/{id}
- POST /api/v1/orders/{id}/payments
- POST /api/v1/orders/{id}/close

Events:
- OrderOpened, OrderItemsAdded, PaymentReceived, OrderClosed

Docs:
- EVENT_MAP.md updated with events
- API_MAP.md query params if added

Tests:
- 409 conflict test
- modifier validation test
```

---

## Task 8 — Stations & KDS queue + item status updates (kds_mode aware)

```text
TASK: Implement station queue and item status updates.

Endpoints:
- GET /api/v1/stations/{station_id}/queue
- POST /api/v1/order-items/{id}/status

Rules:
- Respect restaurant_settings.kds_mode and station_configs.enable_kds.
- Transitions:
  - READY_ONLY: queued -> preparing -> ready
  - READY_AND_SERVED: queued -> preparing -> ready -> served

Event:
- OrderItemStatusUpdated

Docs:
- REALTIME.md: ensure polling endpoints are used for KDS
- EVENT_MAP.md updated

Tests:
- kds off blocks status update
- invalid transition rejected
```

---

## Task 9 — Printing Option A (KOT tickets + print_jobs + executor polling)

```text
TASK: Implement printing Option A.

Migrations:
- kot_tickets, kot_ticket_items
- print_jobs
- print_executors (mapping device->stations optional)

Endpoints:
- POST /api/v1/printing/executor/register
- GET /api/v1/printing/jobs/next
- POST /api/v1/printing/jobs/{id}/printed
- POST /api/v1/printing/jobs/{id}/failed

Rules:
- On AUTO send_mode: OrderItemsAdded triggers KOT + print_jobs
- On MANUAL: /send-to-stations triggers KOT + print_jobs
- Executor polling locks job to avoid double print; retry attempts max N

Docs:
- PRINTING.md must match implementation
- EVENT_MAP.md include PrintJobQueued

Tests:
- auto printing creates print_jobs
- executor poll lock and mark printed works
```

---

## Task 10 — Notifications + Reports

```text
TASK: Implement notifications and reports.

Notifications:
- rules CRUD
- inbox + read
- device push tokens
- event-driven notification creation

Reports:
- daily/monthly/item-wise
- respect business_day_starts_at
- branch scoped

Docs:
- DOMAIN_MAP.md updates
- API_MAP.md response examples (optional)
- REALTIME.md: note that notifications can be polled and later broadcasted

Tests:
- report window test
- notification recipient test
```
