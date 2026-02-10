# EVENT_MAP.md — Alpine RMS Backend Events & Side Effects

This document lists domain events and what listens to them.
Events are used to keep business logic modular, testable, and extensible (printing, notifications, audits).

## 1) Event Guidelines (Rules)

- Events must be **domain-focused**, not UI-focused.
- Event payloads must include:
  - `branch_id` (when relevant)
  - entity IDs (order_id, station_id, etc.)
- Events must not leak sensitive data.
- Listeners must be idempotent whenever possible.

## 2) Core Events (Tenant)

### OrderOpened
Triggered when an order is created.
Payload: order_id, branch_id, table_id (nullable), order_type.

Listeners:
- Notification dispatch (optional: waiter/manager)
- Audit log (optional)

### OrderItemsAdded
Triggered after items are added to an order.
Payload: order_id, branch_id, item_ids.

Listeners:
- If station send_mode == AUTO:
  - Create KOT ticket(s)
  - Queue print jobs (if printing enabled)
  - Notify station (if KDS enabled)

### OrderSentToStations
Triggered when manual send is invoked.
Payload: order_id, branch_id, station_ids, kot_ticket_ids.

Listeners:
- Queue print jobs
- Notify station roles/devices

### OrderItemStatusUpdated
Triggered when station updates item status.
Payload: order_item_id, order_id, station_id, branch_id, new_status.

Listeners:
- Determine if station/order is now "ready"
- Notify waiter/FOH if order ready
- Optional audit

### PaymentReceived
Triggered on successful payment creation.
Payload: payment_id, order_id, branch_id, amount, method.

Listeners:
- Notify manager/owner
- Update reporting aggregates (if using materialized stats later)

### OrderClosed
Triggered when order is closed.
Payload: order_id, branch_id.

Listeners:
- Notify cashier/manager (optional)
- Audit log

### PrintJobQueued
Triggered when a print job is created.
Payload: print_job_id, branch_id, station_id, printer_id.

Listeners:
- (Usually none; executor polls)
- Optional notification to POS if printer offline (future)

### NotificationCreated
Triggered when notifications are persisted.
Payload: notification_id, branch_id, recipients_count.

Listeners:
- Push dispatch (FCM/APNS) if enabled and tokens exist

## 3) Print Executor Polling (Not Event Driven)

Option A printing is primarily polling-based:
- Executor calls `/printing/jobs/next`
- Marks printed/failed via API

Nevertheless, the creation of jobs is event-driven (OrderSentToStations/OrderItemsAdded).

## 4) Testing Requirements

For each event:
- unit test the event is dispatched
- unit test listeners create expected side effects (print_jobs, notifications)
- ensure idempotency where applicable
