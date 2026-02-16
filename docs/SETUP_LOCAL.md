# Local Setup

## Prerequisites
- PHP 8.2+
- Composer 2+
- MySQL 8+

## Initial install
```bash
composer install
cp .env.example .env
php artisan key:generate
```

## Run tests
```bash
php artisan test
```

## Quick compliance check
```bash
chmod +x scripts/task-check.sh
./scripts/task-check.sh
```

## Notes
- Codex runs offline in this workflow; run setup and test commands locally or in CI.
- Update `.github/CODEOWNERS` by replacing `@YOUR_GITHUB_USERNAME` with your real GitHub handle.
