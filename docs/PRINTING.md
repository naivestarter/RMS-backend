# PRINTING.md (Living Doc)

## Strategy
Option A: Backend queues print_jobs; executors poll and print to local printers.

## Key rules
- AUTO mode: print job queued automatically when items added
- MANUAL mode: explicit "send to station" action queues print jobs

## Endpoints (planned)
- POST /api/v1/printing/executor/register
- GET  /api/v1/printing/jobs/next
- POST /api/v1/printing/jobs/{id}/printed
- POST /api/v1/printing/jobs/{id}/failed
