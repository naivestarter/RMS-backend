# REALTIME.md — Alpine RMS Realtime Strategy (Polling → Reverb)

This document defines how Alpine RMS delivers "live" updates to clients (React KDS, POS web, Flutter).
**MVP uses polling**, Phase 2 can add **Laravel Reverb** broadcasting without breaking APIs.

> Design principle: **Transport is swappable.**
> Business logic emits domain events; delivery can be polling, Reverb, or both.

---

## 0) Scope & Non-Goals

### MVP scope (Phase 1)
- Polling-based refresh for:
  - KDS station queue
  - open orders list
  - notifications inbox / unread count
  - print job status (executor)

### Phase 2 scope
- Add Reverb broadcasting as **push refresh**
- Keep polling endpoints as fallback (network issues, background mobile limits)

### Non-goals (Phase 1)
- Perfect sub-second realtime guarantees
- Offline-first conflict-free KDS (separate initiative)

---

## 1) Polling Rules (MVP)

### 1.1 Default polling intervals
- KDS station queue: 2–5 seconds
- Orders list (cashier/waiter): 3–8 seconds
- Notifications: 10–30 seconds (or fetch on screen open)
- Print executor job polling: 1–3 seconds (executor only)

Intervals must be configurable client-side.

### 1.2 Efficient polling parameters (required in API design)
All list endpoints that are used in polling should support at least one of:
- `updated_after=<ISO8601>` (recommended)
- `since_id=<int>` (optional)
- Pagination + `meta.last_updated_at`

**Do not** return huge payloads every poll if client can request deltas.

### 1.3 Stable resources (single source of truth)
Polling endpoints remain canonical even after Reverb is enabled:
- KDS queue still comes from `GET /api/v1/stations/{station_id}/queue`
- Orders still come from `GET /api/v1/orders`
- Notifications still come from `GET /api/v1/notifications`

Realtime never replaces these endpoints; it only reduces the need to poll.

---

## 2) Reverb Strategy (Phase 2)

Laravel supports broadcasting drivers including **Laravel Reverb** and provides config in `config/broadcasting.php`. citeturn0search8

### 2.1 Reverb is used for "push refresh"
Broadcast events should be coarse-grained:
- "order updated" with id and changed fields summary
- "station queue updated" with station_id
- "notification created" with id

Clients then:
- update local cache OR
- call existing polling endpoint to fetch fresh state (recommended first)

This avoids event storms and keeps payload stable.

### 2.2 When to broadcast
Broadcast from domain event listeners, not controllers.

Examples:
- On `OrderItemsAdded` → broadcast `orders.updated` and `stations.queue.updated` for affected stations
- On `OrderItemStatusUpdated` → broadcast `stations.queue.updated` and possibly `orders.updated`
- On `PaymentReceived` → broadcast `orders.updated` and `notifications.created` for managers

---

## 3) Channel Naming (Multi-tenant & Branch-safe)

### 3.1 Naming rules
Channels must isolate:
- tenant
- branch
- station and/or user

**Canonical naming pattern:**
- Tenant + branch:
  - `tenant.{tenantId}.branch.{branchId}.orders`
  - `tenant.{tenantId}.branch.{branchId}.stations.{stationId}`
  - `tenant.{tenantId}.branch.{branchId}.notifications.user.{userId}`

### 3.2 Privacy classification
- Order/station channels are **private** (auth required)
- User notifications channels are **private** (auth required)

Public channels are not used for operational data.

---

## 4) Authentication & Authorization for Reverb

### 4.1 Auth middleware for broadcasting
Broadcast auth route must require authentication (Sanctum tokens for API clients).

Typical approach:
- `Broadcast::routes(['middleware' => ['auth:sanctum']]);` citeturn0search20

### 4.2 Authorization checks (must be enforced)
When authorizing subscription:
- Tenant context MUST be resolved first (`X-Restaurant-Code`)
- User MUST belong to the branch in `X-Branch-Id`
- For station channels: user must have station role OR be manager/owner
- For user notifications channel: channel userId must match authenticated user

All channel authorization functions must be deterministic and tested.

---

## 5) Mobile & Background Constraints (Flutter)

Important reality:
- iOS may suspend background sockets
- Android may kill background processes
Therefore:
- Do not depend solely on Reverb for critical events.
- Keep polling fallback.
- Use push notifications for:
  - order ready
  - payment received
  - printer failures (Phase 2/3)

---

## 6) Implementation Checklist (Phase 2)

1) Enable Reverb driver and broadcasting configuration. citeturn0search8
2) Define Broadcast events:
   - `OrderUpdated`
   - `StationQueueUpdated`
   - `NotificationCreated`
3) Add listeners on domain events to broadcast.
4) Add channel definitions and authorization rules.
5) Client changes:
   - Subscribe to relevant channels
   - On event: refresh from existing endpoints (first iteration)
6) Keep polling as fallback.

---

## 7) Testing Requirements

- Channel authorization tests:
  - cannot subscribe across branches
  - cannot subscribe across tenants
  - station channel requires station role (or manager)
  - user notifications channel requires matching userId
- Broadcast event emitted when:
  - order items added
  - item status updated
  - payment received
