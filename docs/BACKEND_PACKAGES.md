# BACKEND_PACKAGES.md — Alpine RMS Backend Package Policy

This file defines which third-party packages are allowed, required, or forbidden in `rms-backend`.
Codex and human devs must follow this policy.

---

## 0) Principles

- Prefer native Laravel features first.
- Add packages only when they:
  - reduce risk (security/audit)
  - reduce long-term maintenance
  - are widely adopted and actively maintained
- Any new package requires:
  1) update this file
  2) document why it is needed
  3) list security considerations

---

## 1) Required (MVP)

### 1.1 Authentication
- `laravel/sanctum` citeturn0search4
  - Used for token auth for Flutter and API clients.

### 1.2 RBAC / Permissions
- `spatie/laravel-permission` citeturn0search1
  - Used as the permission registry and for role→permission mapping.
  - Branch-specific role assignment remains in `branch_user.role`.
  - Do NOT rely on Spatie "teams" in MVP. citeturn0search21

### 1.3 Audit logging
- `spatie/laravel-activitylog` citeturn0search5turn0search7
  - Used for auditing critical operations:
    - discounts
    - voids
    - menu price changes
    - settings changes
    - printer/station config changes

---

## 2) Allowed Later (Phase 2+)

- `maatwebsite/excel` — exports
- `spatie/laravel-backup` — backups per tenant DB
- Broadcasting (Phase 2):
  - Laravel Reverb (built-in driver) + standard Laravel broadcasting stack citeturn0search8

---

## 3) Forbidden (until explicitly approved)

### 3.1 Tenancy packages
Forbidden because we implement custom header-based DB-per-tenant tenancy:
- `stancl/tenancy`
- `spatie/laravel-multitenancy`
- any other automatic tenancy framework

### 3.2 CQRS / event-store frameworks
- No event-store frameworks in MVP (overkill).
We use simple domain events + listeners.

---

## 4) Package Integration Rules (Non-negotiable)

- All packages must operate within the tenant DB context for tenant routes.
- Never store tenant data in master DB due to package defaults.
- All config must be documented in `/docs/*`.
- Add tests for any security-sensitive package behaviors (RBAC, audit).

---

## 5) RBAC Implementation Rule (Branch-first)

Authorization checks must always follow:
1) Resolve tenant by `X-Restaurant-Code`
2) Validate branch membership by `X-Branch-Id`
3) Apply permission checks for the user's branch role

Do not create global tenant roles that ignore branch context.
