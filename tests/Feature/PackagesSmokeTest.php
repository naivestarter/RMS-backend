<?php

namespace Tests\Feature;

use Laravel\Sanctum\Sanctum;
use Spatie\Activitylog\Models\Activity;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

class PackagesSmokeTest extends TestCase
{
    public function test_required_package_classes_are_loadable(): void
    {
        $this->assertTrue(class_exists(Sanctum::class));
        $this->assertTrue(class_exists(Permission::class));
        $this->assertTrue(class_exists(Activity::class));
    }
}
