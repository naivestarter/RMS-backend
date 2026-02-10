# PRINTING.md — Alpine RMS Printing (Option A)

This is the authoritative printing design for Alpine RMS.

## 0) Summary

- Backend does NOT print directly to printers.
- Backend **creates KOT tickets** and **queues print jobs**.
- A **Print Executor** (a POS device / app instance) polls the backend and prints automatically.
- Supports stations with:
  - printer only (no device at station)
  - KDS only
  - both printer + KDS

## 1) Why Option A (Client-Side Printing)

- Works across Android/iOS/Windows/macOS without server LAN constraints.
- Avoids exposing printers to the internet or requiring server in restaurant LAN.
- Allows printing to USB/Bluetooth via local OS capabilities later.

## 2) Entities

### 2.1 Printer
A network ESC/POS printer (MVP: network only).
Fields:
- branch_id, name, ip_address, port, is_active

### 2.2 StationConfig
Controls station workflow:
- enable_printing
- enable_kds
- send_mode (AUTO/MANUAL)
- printer_id (nullable)
- kds_mode_override (optional)

### 2.3 KOT Ticket
A logical ticket created when items are sent to a station.
Used for:
- printing
- reprint/audit
- grouping items per station

### 2.4 Print Job
A queued task to print a specific ticket to a specific printer.
Fields:
- kot_ticket_id, printer_id, station_id, status, attempts, last_error

### 2.5 Print Executor
A device registered to handle printing for a branch (or specific stations).
Executors:
- poll for jobs
- print
- mark results

## 3) Workflow Rules

### 3.1 Auto vs Manual Send
- If station send_mode == AUTO:
  - On item add, KOT ticket + print job created immediately
- If MANUAL:
  - Items are created but not "sent" until `/orders/{id}/send-to-stations`

### 3.2 Printer-only Station
- enable_kds = false
- enable_printing = true
- send_mode can be AUTO or MANUAL
- executor prints automatically; station staff only receives paper

### 3.3 KDS-only Station
- enable_kds = true
- enable_printing = false
- KDS queue endpoints provide the station list

### 3.4 Both
- enable_kds = true
- enable_printing = true

## 4) API Contract

### Register executor
`POST /api/v1/printing/executor/register`

Payload:
```json
{ "branch_id": 1, "device_uid": "uuid", "stations": [2,3] }
```

Rules:
- If stations omitted, executor handles all stations in that branch.
- Only 1 active executor per branch is recommended (can be expanded later).

### Fetch next job
`GET /api/v1/printing/jobs/next`

Rules:
- Returns one job assigned to this executor
- Marks job as `printing` with a short lock timeout
- If no jobs, return 204 or {data:null}

### Mark printed / failed
- `POST /api/v1/printing/jobs/{id}/printed`
- `POST /api/v1/printing/jobs/{id}/failed` with error text

Retry rules:
- Backend may re-queue failed jobs up to N attempts (e.g., 3)
- After max retries, status becomes `failed` and visible in admin UI

## 5) Security & Safety Rules

- Executors must be authenticated and branch-scoped.
- Do not allow printing without branch access.
- Do not include secrets in print payloads.
- All printing endpoints require:
  - X-Restaurant-Code
  - X-Branch-Id
  - Authorization

## 6) Operational Notes

- If no executor is online:
  - jobs remain queued
  - POS should show warning (future UI)
- Reprint:
  - create a new print job for the existing kot_ticket

## 7) Testing

- Creating an order item with AUTO printing must create:
  - kot_ticket + print_job
- Polling returns the job and locks it
- Mark printed transitions status properly
