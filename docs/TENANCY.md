# TENANCY.md — Alpine RMS (Multi-DB Tenancy)

This document is the **source of truth** for how tenancy works in `rms-backend`.

## 0) Tenancy Goals

- **Single application instance** serving many restaurants.
- **Hard isolation** at the database level for legal entities (tenants).
- Maintain **high performance** by using caching and minimal per-request overhead.
- Keep developer experience predictable: all tenant-scoped code behaves the same way.

## 1) Database Topology

### 1.1 Master Database: `rms_master`
Contains global entities and tenant connection metadata.

Key tables:
- `franchise_groups` — umbrella group for aggregating multiple tenants (franchise / holding group).
- `tenants` — tenant registry + DB connection info + restaurant_code.
- `tenant_domains` — optional mapping of domains/subdomains to tenants.
- `master_users` — super admin users (SaaS operator).

### 1.2 Tenant Database: `rms_tenant_{slug}`
Contains all operational data for a restaurant legal entity (may contain multiple branches).

Key concepts inside a tenant DB:
- `branches` — outlets / locations inside the same legal entity.
- `restaurant_settings` — flow settings (service mode, kds_mode, split bill toggle).
- `stations` + `station_configs` — dynamic kitchen/bar/bbq stations + KDS/printing behavior.
- `orders`, `order_items`, `payments` — POS core.
- `print_jobs` — printing queue (Option A).
- `notifications` — in-app notifications.

## 2) Tenant Resolution Sources (Priority Order)

Tenant must be resolved for **all** `/api/v1/*` requests.

Resolution order:
1) `X-Restaurant-Code` header (mobile/desktop/web API clients)
2) Domain/subdomain mapping (`tenant_domains.domain`) (web multi-domain, optional)
3) Reject request (401/403 depending on auth state)

> Canonical header for tenancy:
> - `X-Restaurant-Code: <restaurant_code>`

## 3) Branch Context (Mandatory)

Most tenant data is branch-scoped. For clarity and correctness, branch context is canonical via header:

- `X-Branch-Id: <branch_id>`

Rules:
- All branch-scoped endpoints MUST require `X-Branch-Id`.
- Endpoints that do not require branch context must be explicitly documented (rare).

If `X-Branch-Id` is missing:
- respond `422` with `{ errors: { branch_id: ["X-Branch-Id header is required."] } }`

## 4) Public Tenant Resolve Endpoint

Used for apps that only know a `restaurant_code`.

- `POST /api/public/tenant/resolve`
Payload:
```json
{ "restaurant_code": "BBQ123" }
```

Response:
```json
{ "data": { "tenant_slug": "bbqhouse", "status": "active" } }
```

Rules:
- Does **not** reveal DB credentials.
- Returns only minimal info.
- If tenant is not active: return 404 or 403 with safe message.

## 5) Middleware Responsibilities

### 5.1 `ResolveTenantMiddleware`
Applied to `/api/v1/*` and any tenant routes.

Responsibilities:
1) Read `X-Restaurant-Code` (or resolve domain mapping)
2) Lookup tenant in `rms_master.tenants`
3) Validate tenant `status == active`
4) Configure tenant connection:
   - set `database.connections.tenant` dynamically
   - `DB::purge('tenant')` and reconnect
5) Store tenant context in a request-scoped container:
   - `app()->instance(CurrentTenant::class, ...)`

Performance rules:
- Cache tenant lookup by `restaurant_code` (e.g., 5–30 minutes)
- Cache invalidation on tenant update (admin operation)

### 5.2 `EnsureBranchContextMiddleware`
Applied to branch-scoped endpoints.

Responsibilities:
- Validate `X-Branch-Id` header exists
- Validate branch belongs to this tenant DB and is active
- Store `CurrentBranch` in container for easy access

## 6) Cross-DB Safety Rules (Non-Negotiable)

- Never join tenant tables to master tables in SQL.
- No tenant connection access in master admin routes unless explicitly required.
- Never accept DB host/user/password from clients.
- Never expose tenant DB name or credentials in API responses.

## 7) Seeding & Provisioning Rules

When provisioning a new tenant DB:
- Run all tenant migrations
- Seed:
  - `restaurant_settings` (single row)
  - at least 1 `branch` (default)
  - optionally default `stations` (Kitchen/Bar/BBQ) + `station_configs` (printing off, manual send)
  - default roles via `branch_user` for the initial owner
  - optionally default notification rules

## 8) Local Dev Notes

Recommended env:
- `DB_CONNECTION=master` for master
- `TENANT_DB_PREFIX=rms_tenant_`
- One MySQL instance with multiple databases.

Command conventions:
- `php artisan tenant:provision` (admin-only tooling)
- `php artisan tenant:migrate --tenant=<slug>` (for ops)

---

**Checklist for any new endpoint**
- Is it tenant-scoped? If yes, ensure `ResolveTenantMiddleware` applies.
- Is it branch-scoped? If yes, require `X-Branch-Id` and validate branch.
