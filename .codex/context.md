# Alpine RMS Backend — Codex Context (OFFLINE + Multi-DB Tenancy)

You are working in the `rms-backend` Laravel API repo for Alpine RMS.

## 0) Absolute architecture
- Single Laravel app instance.
- Multi-tenant via multiple DBs:
  - Master DB: `rms_master`
  - Tenant DBs: `rms_tenant_{slug}`
- Tenant is resolved ONLY via header: `X-Restaurant-Code`
- Branch context via header: `X-Branch-Id`
- Backend supports:
  - rms-frontend (React web)
  - rms-flutter (Flutter apps)
- No tenancy packages.

---

## 1) OFFLINE CODEX EXECUTION (CRITICAL)
This Codex environment has no outbound network and cannot run:
- composer install/require/update
- php artisan *
- phpunit/pest
- any network calls

Rules:
- Codex MUST NOT attempt these commands.
- Codex MUST NOT claim “tests passed” or “commands executed”.

Every Codex response MUST end with:

### LOCAL COMMANDS TO RUN
(list exact commands for the developer)

### EXPECTED RESULTS
(what should happen; which files should exist; which tests should pass)

### IF FAILURE, PASTE BACK
- full terminal output
- failing test name + stacktrace
- relevant `storage/logs/laravel.log` excerpt

---

## 2) Docs governance (NO rule erosion)

### 2.1 Policy docs are LOCKED (do not change unless prompt explicitly says so)
- docs/CONVENTIONS.md
- docs/BACKEND_PACKAGES.md
- docs/TENANCY.md

Rule: Treat the above as immutable policy. Do not rewrite/reformat for style.

If Codex believes a locked policy doc must change:
- STOP and output EXACTLY: `POLICY CHANGE REQUIRED`
- include short justification + proposed diff only
- do nothing else.

### 2.2 Living docs MUST be kept in sync with code
- docs/API_MAP.md
- docs/DOMAIN_MAP.md
- docs/EVENT_MAP.md
- docs/PRINTING.md
- docs/REALTIME.md

Rule: If endpoints/entities/events/workflows are added or changed, update living docs in the same PR.

---

## 3) Package policy enforcement
Follow docs/BACKEND_PACKAGES.md.
- Required in MVP: sanctum, spatie-permission, spatie-activitylog
- Forbidden: tenancy packages; CQRS/event-store frameworks

No "*" version constraints in composer.json.

---

## 4) Tenancy + branch invariants (HARD RULES)
- All tenant routes `/api/v1/*` MUST require tenant context resolved via `X-Restaurant-Code`.
- All branch-scoped routes MUST require `X-Branch-Id` and validate membership.
- No tenant business data in master DB.
- No cross-DB joins master↔tenant.
- Cache keys must be tenant-prefixed if caching is introduced.

---

## 5) RBAC (BRANCH-FIRST)
- Branch membership + `branch_user.role` is the primary role boundary.
- Spatie Permission is used as a permission registry (role → permissions mapping).
- Do NOT assign global tenant roles that ignore branch context.

Authorization order:
1) resolve tenant (X-Restaurant-Code)
2) validate branch membership (X-Branch-Id)
3) authorize action based on branch role → permissions

---

## 6) Engineering standards
Full engineering standards live in:
- docs/ENGINEERING_STANDARDS.md
Codex must follow them.
