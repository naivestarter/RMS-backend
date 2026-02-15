# Local Setup

## Install dependencies

```bash
composer install
npm install
```

## Publish vendor configs

```bash
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider"
```

## Run tests

```bash
php artisan test
```
