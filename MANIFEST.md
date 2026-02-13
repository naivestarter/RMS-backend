# RMS Backend Guardrails Pack — Manifest

This zip contains all non-Laravel-skeleton files needed to kick off `rms-backend` safely with an OFFLINE Codex workflow.

## Files included

### Codex control
- `.codex/context.md`
  Purpose: Operating rules for Codex in offline environment, docs governance, tenancy/RBAC invariants, required output format.

### Policy docs (LOCKED)
- `docs/CONVENTIONS.md`
  Purpose: Standard headers, envelopes, pagination, endpoint governance.
- `docs/BACKEND_PACKAGES.md`
  Purpose: Package allow/deny policy. Required MVP packages; forbidden tenancy packages.
- `docs/TENANCY.md`
  Purpose: Multi-DB tenancy rules and invariants.

### Living docs (must be kept in sync with code)
- `docs/API_MAP.md`
  Purpose: API sitemap; source-of-truth for endpoints.
- `docs/DOMAIN_MAP.md`
  Purpose: Bird’s-eye module ownership map.
- `docs/EVENT_MAP.md`
  Purpose: Cross-module event integration map.
- `docs/PRINTING.md`
  Purpose: Printing strategy (executor polling, auto/manual send).
- `docs/REALTIME.md`
  Purpose: Polling-first realtime plan; Reverb later as push refresh.

### Engineering + workflow
- `docs/ENGINEERING_STANDARDS.md`
  Purpose: Coding standards and project structure.
- `docs/DEV_WORKFLOW.md`
  Purpose: Offline Codex loop (Codex writes, you run tests locally/CI).
- `docs/README.md`
  Purpose: Index of docs and what they mean.

### Planning
- `PLANS.md`
  Purpose: Task roadmap (Task 1–10) to keep work ordered.

### CI / repo protections
- `.github/workflows/ci.yml`
  Purpose: Run tests in GitHub Actions since Codex cannot run them.
- `.github/CODEOWNERS`
  Purpose: Require your review for locked policy docs (replace username).

## Next steps
1) Unzip into the root of `rms-backend` (empty repo is fine).
2) Edit `.github/CODEOWNERS` and set @YOUR_GITHUB_USERNAME.
3) Scaffold Laravel 12 locally (per Laravel docs), then commit scaffold.
4) Continue with Codex Task 1 (offline-safe prompts).
