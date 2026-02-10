# CONVENTIONS.md

## Header rules
- `X-Restaurant-Code` is required for all `/api/v1/*` tenant routes.
- `X-Branch-Id` is required for all branch-scoped routes.

## Standard response envelopes
- Success: `{ data: ..., meta?: ... }`
- Validation `422`: `{ message, errors }`
- `401` / `403`: `{ message }`
- `409` conflict: `{ message: "Conflict", errors: { code: "...", ... } }`

## Pagination rules
- Query params: `page`, `per_page`
- Default `per_page`: `20`
- Maximum `per_page`: `100`

## Endpoint governance
- Do not invent endpoints.
- Endpoints must match `docs/API_MAP.md` when implemented.
