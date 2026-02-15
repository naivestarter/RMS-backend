# API_MAP.md (Living Doc)

## Public (no tenant header)
- POST /api/public/tenant/resolve

## Admin (master DB)
- POST /api/admin/auth/login
- GET  /api/admin/auth/me
- POST /api/admin/auth/logout
- CRUD /api/admin/tenants ...

## Tenant (tenant DB) — requires X-Restaurant-Code
Auth
- POST /api/v1/auth/login
- GET  /api/v1/auth/me
- POST /api/v1/auth/logout

Core (MVP)
- branches
- tables
- menu
- orders
- stations/KDS
- printing executor
- reports
- notifications
