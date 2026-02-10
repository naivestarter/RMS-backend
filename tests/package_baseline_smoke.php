<?php

declare(strict_types=1);

$composerFile = __DIR__ . '/../composer.json';
$payload = json_decode((string) file_get_contents($composerFile), true, 512, JSON_THROW_ON_ERROR);
$required = [
    'laravel/sanctum',
    'spatie/laravel-permission',
    'spatie/laravel-activitylog',
];

foreach ($required as $package) {
    if (!array_key_exists($package, $payload['require'] ?? [])) {
        fwrite(STDERR, "Missing required package declaration: {$package}\n");
        exit(1);
    }
}

echo "Package baseline declarations are present.\n";
