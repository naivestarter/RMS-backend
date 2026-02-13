# BACKEND_PACKAGES.md (LOCKED POLICY)

## Required in MVP
- `laravel/sanctum`
- `spatie/laravel-permission`
- `spatie/laravel-activitylog`

## Allowed later (Phase 2+)
- `maatwebsite/excel`
- `spatie/laravel-backup`
- Laravel Reverb broadcasting

## Forbidden until explicitly approved
- Tenancy packages (`stancl/tenancy`, `spatie/laravel-multitenancy`, etc.)
- CQRS/event-store frameworks

## Integration rules
- All RBAC and activity log tables live in TENANT DB migrations (not master).
- Any new package requires updating this file + explaining why.

## RBAC rule (branch-first)
1) Resolve tenant by `X-Restaurant-Code`
2) Validate branch membership by `X-Branch-Id`
3) Apply permission checks for the user's branch role
