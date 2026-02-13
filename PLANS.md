# PLANS.md — Alpine RMS Backend Execution Plan

This file is plan-only. It intentionally excludes implementation details and code.

## Task 1 — Baseline packages & config
- Add packages (policy already defined):
  - laravel/sanctum
  - spatie/laravel-permission
  - spatie/laravel-activitylog
- Configure & document publish commands in docs/SETUP_LOCAL.md (to be created).
- Create tenant migrations structure (database/migrations/tenant and master split).

## Task 2 — Master DB schema + admin endpoints
- Master tables: tenants, franchise_groups, master_users
- Admin auth endpoints
- Tenant lifecycle endpoints (activate/suspend, view/update)

## Task 3 — Tenant resolution middleware (X-Restaurant-Code)
- Resolve tenant from rms_master
- Configure runtime tenant connection
- Cache tenant lookups safely

## Task 4 — Branch context middleware (X-Branch-Id)
- Require branch for branch-scoped routes
- Validate membership and active branch

## Task 5 — Tenant provisioning (create DB, migrate, seed)
- Provision commands: create db, run tenant migrations, seed defaults
- Default branch + default stations + default settings

## Task 6 — Tenant auth + RBAC (branch-first)
- Tenant login/me/logout
- Branch membership, branch_user.role
- Permission registry mapping (Spatie) + policies/middleware

## Task 7 — Menu + tables + stations + printers
- CRUD endpoints aligned with docs/API_MAP.md
- Pagination and validation via FormRequests

## Task 8 — Orders + payments (409 conflicts)
- One open order per table
- Totals on server, VAT rules, modifiers validation

## Task 9 — Printing Option A (executor polling)
- print_jobs + executor registration
- auto vs manual send_mode

## Task 10 — Notifications + Reports
- Notification rules + inbox
- Reports: daily/monthly/item-wise
- Business day boundary support
