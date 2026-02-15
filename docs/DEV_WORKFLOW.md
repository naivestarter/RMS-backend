# DEV_WORKFLOW.md — Offline Codex + Local/CI Testing

## Why
Codex cannot run composer/artisan/tests in its environment. We use it to write code; we run commands locally/CI.

## Per-task loop
1) Run Codex task prompt
2) Review diffs
3) Run locally:
   - composer install/update (if composer.json changed)
   - php artisan test
4) Paste failures back to Codex:
   - full output
   - failing test + stacktrace
   - relevant laravel.log lines
5) Repeat until green
6) Merge PR

## Tenancy checks before merge
- `/api/v1/*` requires X-Restaurant-Code
- branch routes require X-Branch-Id
- no tenant tables in master migrations
