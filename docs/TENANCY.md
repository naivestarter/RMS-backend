# TENANCY.md (LOCKED POLICY)

## Model
- Single Laravel app instance
- Master DB: `rms_master`
- Tenant DBs: `rms_tenant_{slug}`

## Tenant resolution
- Tenant is resolved ONLY by request header: `X-Restaurant-Code`
- The restaurant_code is mapped in `rms_master.tenants`

## DB switching
- Middleware:
  1) Reads `X-Restaurant-Code`
  2) Looks up tenant in `rms_master`
  3) Verifies status=active
  4) Configures runtime DB connection `tenant`
  5) Purges and reconnects DB
  6) Binds CurrentTenant context

## Branch context
- Branch is selected by header: `X-Branch-Id`
- Branch must exist in tenant DB and user must have membership.

## Hard rules
- Never store tenant business data in master DB.
- Never cross-join master and tenant DB.
- Tenant DB tables do NOT include `tenant_id` (database boundary is tenancy).
