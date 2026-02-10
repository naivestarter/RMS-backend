# PLANS.md — Alpine RMS Backend Execution Plan

This file is plan-only. It intentionally excludes implementation details and code.

## Task 2 — Master DB schema + admin endpoints
1. Finalize master database schema for tenants, restaurants, and provisioning metadata.
2. Define admin-only endpoints for tenant lifecycle operations.
3. Add API contract checks against `docs/API_MAP.md` before implementation.

## Task 3 — Tenant resolution middleware (`X-Restaurant-Code`)
1. Implement middleware to require and validate `X-Restaurant-Code` for tenant routes.
2. Resolve tenant context and attach it to request scope.
3. Return standardized errors when header is missing/invalid.

## Task 4 — Branch context middleware (`X-Branch-Id`)
1. Implement middleware to require and validate `X-Branch-Id` for branch-scoped routes.
2. Enforce branch existence within resolved tenant context.
3. Return standardized errors for unauthorized branch access.

## Task 5 — Tenant provisioning (create DB, migrate, seed)
1. Create provisioning workflow: tenant DB creation, connection registration, migration run, seed run.
2. Add idempotency and rollback safeguards for failed provisioning.
3. Add operational logging for provisioning state transitions.

## Task 6 — Tenant auth + RBAC (branch role + permissions registry)
1. Implement tenant-scoped auth flow with Sanctum tokens.
2. Enforce branch membership and role assignment.
3. Wire branch-role permissions via registry and policy checks.

## Task 7 — Menu + tables + stations + printers
1. Implement CRUD and listing endpoints aligned to `docs/API_MAP.md`.
2. Enforce tenant + branch scoping and validation rules.
3. Add pagination/filtering envelopes from conventions.

## Task 8 — Orders (one open order per table; `409` conflict)
1. Implement order lifecycle endpoints with branch-scoped access.
2. Enforce one-open-order-per-table invariant.
3. Return `409 Conflict` envelope with deterministic conflict codes.

## Task 9 — Printing Option A (executor polling)
1. Implement print job queue endpoints for executor polling model.
2. Add status transitions and retry/error handling.
3. Keep polling APIs as canonical source even after realtime phase.

## Task 10 — Notifications + Reports
1. Implement notifications rules engine inputs + inbox delivery endpoints.
2. Implement reports endpoints: daily, monthly, item-wise.
3. Support configurable business day start for report boundaries.

## Migration split note (master vs tenant)
- Master DB migrations will only include global/control-plane tables.
- Tenant DB migrations will include domain tables plus package tables for:
  - `spatie/laravel-permission`
  - `spatie/laravel-activitylog`
- If tenant migration structure does not yet exist at implementation time, create `database/migrations/tenant` and route package migrations there.
