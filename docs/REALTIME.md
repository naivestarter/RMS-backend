# REALTIME.md — Polling First, Reverb Later (Living Doc)

## MVP (Phase 1): Polling
Polling remains canonical forever for:
- KDS queue
- orders list
- notifications

Recommended intervals:
- KDS: 2–5 seconds
- Orders: 3–8 seconds
- Notifications: 10–30 seconds

Delta-friendly params:
- Prefer: `updated_after` (ISO8601)

## Phase 2: Reverb as "push refresh"
- Realtime never replaces polling endpoints.
- Broadcast coarse events (e.g., "order updated", "queue updated").
- Clients refresh from canonical endpoints after receiving events.

## Channel naming (multi-tenant + branch)
- `tenant.{tenantId}.branch.{branchId}.orders`
- `tenant.{tenantId}.branch.{branchId}.stations.{stationId}`
- `tenant.{tenantId}.branch.{branchId}.notifications.user.{userId}`

## Auth rules
- Private channels
- Sanctum auth for subscription
- Channel authorization must enforce tenant + branch isolation

## Mobile constraints
- Background sockets unreliable on iOS/Android
- Keep polling + push fallback for critical events
