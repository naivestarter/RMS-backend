# CONVENTIONS.md (LOCKED POLICY)

## Header rules
- `X-Restaurant-Code` is required for all `/api/v1/*` tenant routes (except `/api/public/*`).
- `X-Branch-Id` is required for all branch-scoped routes.

## Standard response envelopes
Success:
```json
{ "data": {}, "meta": {} }
```

Validation error (422):
```json
{ "message": "Validation failed", "errors": { "field": ["error"] } }
```

Auth error (401/403):
```json
{ "message": "Unauthorized" }
```

Conflict (409):
```json
{ "message": "Conflict", "errors": { "code": "SOME_CONFLICT_CODE", "details": {} } }
```

## Pagination
- Params: `page`, `per_page`
- Default `per_page`: 20
- Max `per_page`: 100

## Endpoint governance
- Do not invent endpoints.
- Implement only endpoints listed in `docs/API_MAP.md` (unless a task explicitly adds + updates docs).
