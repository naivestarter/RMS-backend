# Alpine RMS – Backend Coding Standards (Laravel)

> NOTE for AI assistants (Codex, etc.):  
> - You are working in the `rms-backend` Laravel API repo for Alpine RMS.  
> - Always follow the standards in this file when generating or modifying code.  
> - When you add or change domains, endpoints, or events, you must also update the docs under `/docs`  
>   (`DOMAIN_MAP.md`, `API_MAP.md`, `EVENT_MAP.md`) to keep the high-level view accurate.

These standards apply to the `rms-backend` Laravel API project for **Alpine RMS**, a multi-tenant restaurant management system.

The backend is:

- A single Laravel app instance.  
- Multi-tenant via multiple databases:  
  - Master DB: `rms_master`  
  - Tenant DBs: `rms_tenant_{slug}`  
- The canonical API for:  
  - `rms-frontend` (React web)  
  - `rms-flutter` (Flutter apps)

All new backend code must follow these rules.

---

## 1. General Principles

- Prefer clarity over cleverness.  
- Use PHP 8+ and follow PSR-12 coding style.  
- Use type hints and return types wherever reasonable.  
- Do not put business logic in:
  - Routes
  - Views (if any)
  - Global helpers  
- Organize code by domain/feature, not just by framework layer.

---

## 2. Project Structure

Use a domain/feature-based, modular monolith layout:

app/  
  Domain/  
    Tenants/  
      Models/  
      Actions/  
      Services/  
      Repositories/  
      Events/  
      Listeners/  
      Policies/  
      DTOs/  
    Orders/  
      Models/  
      Actions/  
      Repositories/  
      Events/  
      Listeners/  
      Policies/  
      DTOs/  
    Menu/  
    Inventory/  
    Billing/  
    Staff/  
    ...  
  Http/  
    Controllers/  
      Api/  
        V1/  
      Admin/  
    Middleware/  
    Requests/  
  ...

Guidelines:

- `app/Domain/<Domain>/` is the home for that domain’s logic:
  - Eloquent models
  - Actions (use cases)
  - Repositories (where used)
  - Events & Listeners
  - Policies
  - Domain DTOs if needed
- `app/Http/Controllers` are thin HTTP adapters:
  - Validate input via FormRequests
  - Call Actions
  - Return API Resources

---

## 3. Controllers, Requests & Resources

### 3.1 Controllers

Responsibilities:

- Receive HTTP requests.  
- Use FormRequest classes for validation.  
- Call Actions/Services with validated data.  
- Return Resources (JSON responses).

Controllers must NOT:

- Contain complex business logic.  
- Build complex queries directly.  
- Touch multiple domains directly (let Actions/Events coordinate).

Example controller pattern (conceptual):

- `CreateOrderRequest` → validates input  
- `CreateOrderAction` → performs business logic  
- `OrderResource` → shapes the JSON response

### 3.2 FormRequests

- All non-trivial endpoints use a FormRequest class for validation.  
- Place them under `app/Http/Requests/...`.  
- Use explicit validation rules:
  - `email`, `url`, `numeric`, `exists`, `unique`, `in`, etc.  
- Keep validation logic in FormRequests, not in controllers or Actions.

### 3.3 API Resources

- Use JsonResource / ResourceCollection for all API responses.  
- Place them under `app/Http/Resources/...`.  
- Resources must:
  - Hide sensitive/internal fields.  
  - Present a stable JSON contract for the frontend.  
  - Use consistent field naming across the API.

---

## 4. Design Patterns (Actions, Repositories, Queries, Events)

We use a pragmatic, modular monolith approach:

- Actions (use cases) for business flows.  
- Repositories only where they add real value.  
- Queries for read-only operations.  
- Domain Events for cross-module communication.

### 4.1 Actions

- Every non-trivial business operation must have an Action in the relevant domain.

Location pattern:

- `app/Domain/<Domain>/Actions/<Verb><Noun>Action.php`

Examples:

- `CreateTenantAction`  
- `ProvisionTenantDatabaseAction`  
- `CreateOrderAction`  
- `CloseOrderAction`  
- `AdjustStockAction`

Actions:

- Receive validated data (arrays/DTOs).  
- Contain orchestration/business logic:
  - Transactions
  - Calling repositories / models
  - Emitting events  
- Return domain objects (Eloquent models) or DTOs.

Controllers should normally call one Action per endpoint.

### 4.2 Repositories

We do NOT automatically create repositories for every model.

Use a Repository when at least one of these is true:

- The model has complex query logic reused in multiple places.  
- The model belongs to a core domain (Orders, Inventory, Payments) with rich behavior.  
- We want to unit-test Actions without hitting the DB (mock the repository).  
- We may want to change or augment the data source later (e.g., caching, reporting DB).

Location pattern:

- Interface: `app/Domain/<Domain>/Repositories/<Model>Repository.php`  
- Implementation: `app/Domain/<Domain>/Repositories/Eloquent<Model>Repository.php`

Inject the interface into Actions via constructor dependency injection.

For simple config CRUD (e.g., Branches, RestaurantSettings), Actions may use Eloquent models directly without a repository.

### 4.3 Queries (Read-Only Operations)

- For non-trivial reads, create dedicated Query classes instead of putting large query logic in controllers.

Examples:

- `ListOrdersQuery`  
- `OrderDetailsQuery`  
- `SalesSummaryQuery`

Location: under `app/Domain/<Domain>/Actions/` (or a `Queries/` subfolder if preferred).

Rules:

- Queries must NOT mutate state; they are read-only.  
- Prefer suffixing with `Query` to make intent clear.

### 4.4 Domain Events

- Important state changes should emit domain events:

  - `TenantCreated`  
  - `OrderCreated`  
  - `OrderClosed`  
  - `StockAdjusted`

Locations:

- Events: `app/Domain/<Domain>/Events/`  
- Listeners: `app/Domain/<Domain>/Listeners/`

Examples:

- `OrderClosed` → Inventory listens (`ConsumeStockOnOrderClosed`) → adjusts stock.  
- `OrderClosed` → Billing listens (`FinalizeInvoiceOnOrderClosed`) → finalizes invoice.

Use events instead of hard-coding cross-domain calls inside Actions wherever practical.

---

## 5. Multi-DB Tenancy

### 5.1 Master DB: `rms_master`

Stores:

- `tenants` table:
  - `name`, `slug`, `subdomain`
  - `plan`, `status`
  - `db_name`, `db_host`, `db_port`, `db_username`, `db_password` (encrypted)  
- Master-level users (e.g. `super_admin`) for SaaS administration.  
- Other global/system-wide meta as needed.

### 5.2 Tenant DBs: `rms_tenant_{slug}`

Each restaurant has its own DB, containing:

- `users`, `branches`, `tables`, `menu_items`, `orders`, `order_items`, `payments`, `stock_movements`, etc.

Rule:

- Do NOT include a `tenant_id` column inside tenant DB tables.  
  The database itself is the tenancy boundary.

### 5.3 Tenant Resolution Middleware

- A single, central middleware is responsible for tenant resolution.

Behavior:

1. Determine tenant identifier:
   - From subdomain (e.g., `bbqhouse.alpine-rms.com`) for web.  
   - Or from a `tenant_slug` / `restaurant_code` parameter for mobile when needed.  

2. Look up tenant in `rms_master.tenants`.  
3. Verify tenant `status` is `active`.  
4. Configure and connect to the tenant DB:
   - Update `database.connections.tenant`.  
   - Purge and reconnect that connection.  

5. All tenant-scoped code uses the `tenant` connection (or equivalent).

Usage:

- All tenant-level API routes (`/api/v1/...`) must be behind this middleware.  
- Queued jobs that touch tenant data must store a tenant identifier and re-apply tenant context in `handle()`.

---

## 6. API Design

- All APIs must be versioned under `/api/v1/...`.

### 6.1 Route Segmentation

Tenant-level (inside tenant DB):

- `/api/v1/auth/login`  
- `/api/v1/auth/me`  
- `/api/v1/restaurant/profile`  
- `/api/v1/branches`  
- `/api/v1/orders`  
- `/api/v1/menu-items`  
- etc.

Master-level (using `rms_master`):

- `/api/admin/auth/login`  
- `/api/admin/tenants`  
- `/api/admin/tenants/{id}`  
- etc.

### 6.2 Response Shape

Success response shape:

- `data`: payload (object/array)  
- `meta`: optional, pagination or extra info  
- `errors`: null

Error response shape:

- `data`: null  
- `errors`:
  - `message`: human-readable message  
  - `details`: optional field→messages map for validation or detailed errors  

Use appropriate HTTP status codes:

- 200/201 for success  
- 400/422 for validation errors  
- 401/403 for auth/permission errors  
- 404 for not found  
- 500 for unexpected server errors  

---

## 7. Auth & Security

- Use Sanctum (or a similar token-based solution) for API authentication.  
- Passwords must always be hashed (bcrypt/argon2).  
- Never:
  - Log plaintext passwords or tokens.  
  - Return sensitive data (passwords, secrets, DB info) in responses.

### 7.1 Authorization

Master-level:

- `super_admin` role for managing tenants and system configuration.

Tenant-level:

- Roles like `owner`, `manager`, `cashier`, `waiter`, `kitchen`, etc.  
- Use Policies or Gates instead of scattered `if ($user->role === 'owner')` checks.

### 7.2 Rate Limiting & Security

- Implement rate limiting on:
  - Login
  - Password reset
  - Other critical endpoints  
- Do not expose stack traces in production.  
- Assume HTTPS in production; API should be served over TLS.

---

## 8. Validation

- All external input must be validated via FormRequest classes.  
- Always validate:
  - IDs with `exists` rules.  
  - Enum-like fields with `in` rules.  
  - Unique fields with `unique` rules, scoped per tenant DB where necessary.  

Keep validation logic in FormRequests, not scattered across controllers and Actions.

---

## 9. Database & Migrations

- All schema changes must go through migrations; never manually edit production schemas.

### 9.1 Separation

Prefer clear separation between master and tenant migrations, e.g.:

- `database/migrations/master/*` for `rms_master`  
- `database/migrations/tenant/*` for tenant DBs (`rms_tenant_*`)

Tenant provisioning logic is responsible for:

- Creating the tenant DB.  
- Running all tenant migrations on that DB.

### 9.2 Naming

- Tables: plural snake_case (e.g., `menu_items`, `order_items`, `stock_movements`).  
- Columns: snake_case.

Always:

- Add `timestamps()` where relevant.  
- Use `softDeletes()` on entities where logical delete is needed (orders, users, menu items, etc.).

### 9.3 Indexing

- Index all foreign key columns (`*_id`).  
- Index frequently filtered columns (`status`, `branch_id`, `order_date`, etc.).  
- Add composite indexes where needed for performance (e.g., `(branch_id, status)`).

---

## 10. Error Handling & Logging

- Use Laravel’s global exception handler to:
  - Convert exceptions into consistent JSON error responses.  
  - Avoid raw stack traces in production.

Map:

- Validation errors → 422 with error details.  
- Not found → 404 with a clean message.  
- Auth/permission issues → 401/403.  
- Unexpected errors → 500 with a generic message (“Something went wrong”).  

Logging:

- Log unexpected exceptions with context (tenant, user, route where applicable).  
- Log critical flows:
  - Tenant provisioning failures.  
  - Payment processing errors.  
  - Significant stock adjustments or voided orders.  

Use structured logging where possible (consistent formats, optionally JSON).

---

## 11. Caching & Queues

- Use cache (e.g., Redis) for:
  - Tenant lookup by slug/subdomain.  
  - Heavy read endpoints when appropriate (with clear invalidation rules).

- Use queues for:
  - Long-running or async tasks (emails, heavy reports, external integrations).  
  - Tenant jobs must carry the tenant identifier and re-apply tenant context before DB access.

Queue workers must:

- Use the correct DB connection for tenant jobs.  
- Fail safely if a tenant is missing or inactive.

---

## 12. Testing

- Use Pest or PHPUnit for automated tests.

Minimum coverage:

- Tenant provisioning:
  - Creates `tenants` row in `rms_master`.  
  - Creates tenant DB and runs tenant migrations.  
  - Seeds owner user and initial branch.  

- Tenant resolution middleware:
  - Correct tenant DB selected for a given subdomain or tenant slug.  
  - Suspended tenant blocked with appropriate error.  

- Auth:
  - Master admin login.  
  - Tenant owner login.  
  - Protected routes require authentication and correct roles.  

- Core business flows (as they are implemented), such as:
  - Creating orders.  
  - Closing orders/bills.  
  - Adjusting stock.  

Write tests close to the domain (Actions/Repositories), not just controller tests.

---

## 13. High-Level Documentation (“Site Map” for Devs)

The `rms-backend` repo must always contain up-to-date high-level docs under `/docs`.  
These docs give new developers a bird’s-eye view of the system and how modules connect.

### 13.1 Required Docs

We maintain at least these three core docs:

1. `docs/DOMAIN_MAP.md`  
2. `docs/API_MAP.md`  
3. `docs/EVENT_MAP.md`  

#### 1) DOMAIN_MAP.md

Purpose: overview of each domain/module and its responsibilities.

For each domain (Tenants, Orders, Menu, Inventory, Billing, Staff, etc.), include:

- Responsibility: what this domain owns.  
- Key models: main Eloquent models.  
- Key actions: important Actions/Queries.  
- Exposed APIs: main endpoints this domain serves.  
- Events: events published and/or listened to.

#### 2) API_MAP.md

Purpose: quick sitemap of the API endpoints.

- Group endpoints by feature/domain.  
- For each endpoint, include:
  - Method + path  
  - Short description  
  - Auth scope (admin vs tenant, roles)

#### 3) EVENT_MAP.md

Purpose: show how domains talk to each other via events.

For each event, list:

- Who publishes it.  
- Which listeners handle it.  
- Short description of what they do.  

### 13.2 Rule for Changes

Whenever you:

- Add a new domain or major feature,  
- Add or modify API endpoints,  
- Introduce or change domain events,

you must:

- Update `docs/DOMAIN_MAP.md` with the new/changed domain info.  
- Update `docs/API_MAP.md` with the new/changed endpoints.  
- Update `docs/EVENT_MAP.md` with the new/changed events and listeners.  

These docs are part of the deliverable for any substantial backend feature.

---

## 14. Git & PR Practices

- Keep PRs small and focused on a single feature or bugfix.  
- Use clear commit messages, e.g.:
  - `feat: add tenant provisioning API`  
  - `feat: implement order closing with stock adjustment`  
  - `fix: handle suspended tenants on login`  

Never commit:

- `.env` files  
- Secrets (keys, passwords)  
- Build artifacts  

---