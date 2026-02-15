# TODO: Tenant Migration Split Plan

## Master vs Tenant Migrations

We will maintain separate migration paths:

- `database/migrations/master/` for master database schema only (`rms_master`)
- `database/migrations/tenant/` for tenant database schema (`rms_tenant_{slug}`)

Master database migrations must only contain global/platform data.
Tenant database migrations must contain tenant business data and tenant-scoped package tables.

## Package Tables Placement Rule

The following package tables **must be created in each tenant database**, not in master:

- Spatie Permission tables
- Spatie Activitylog tables

## Task 5 Migration Action

When we reach Task 5, we will:

1. Move/publish package migrations for Spatie Permission and Spatie Activitylog into `database/migrations/tenant/`.
2. Ensure these migrations run on the tenant connection.
3. Keep master migrations free of tenant RBAC/activity tables.
