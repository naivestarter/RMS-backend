# REALTIME.md

## MVP canonical polling endpoints
Polling endpoints remain canonical forever for:
- KDS queue
- orders list
- notifications

## Polling interval guidance
- KDS: `2–5s`
- orders: `3–8s`
- notifications: `10–30s`

## Delta-friendly list params
- Prefer: `updated_after` (ISO8601)

## Reverb Phase 2 role
- Reverb is push refresh only (coarse events like `order updated` / `queue updated`).

## Multi-tenant channel naming
- `tenant.{tenantId}.branch.{branchId}.orders`
- `tenant.{tenantId}.branch.{branchId}.stations.{stationId}`
- `tenant.{tenantId}.branch.{branchId}.notifications.user.{userId}`

## Channel auth rules
- Private channel auth uses Sanctum.
- Channel authorization must enforce tenant + branch isolation.

## Mobile constraint
- iOS/Android background sockets are unreliable.
- Polling + push fallback remains required.
