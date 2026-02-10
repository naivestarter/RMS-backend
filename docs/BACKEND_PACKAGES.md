# BACKEND_PACKAGES.md

## Required in MVP
- `laravel/sanctum`
- `spatie/laravel-permission`
- `spatie/laravel-activitylog`

## Allowed later (Phase 2+)
- `maatwebsite/excel`
- `spatie/laravel-backup`
- Laravel Reverb broadcasting

## Forbidden until explicitly approved
- tenancy packages (`stancl/tenancy`, `spatie/laravel-multitenancy`, etc.)
- CQRS/event-store frameworks

## Integration rules
- All RBAC and activity log tables live in TENANT DB (not master)
- Any new package requires updating this file + explaining why

## RBAC rule (branch-first)
1) resolve tenant by `X-Restaurant-Code`
2) validate branch membership by `X-Branch-Id`
3) apply permission checks for user’s branch role

## Configuration notes (Task 1 baseline)
- Dependency declarations were added to `composer.json` for Laravel + required MVP packages.
- Full package installation and publish steps are pending until Packagist access and Laravel application structure are available.
- Sanctum API middleware wiring and package migration publishing will be completed when the framework scaffold exists.
- Permission/activitylog migrations are designated for tenant migration scope only (never master DB).
