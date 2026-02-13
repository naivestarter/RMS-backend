# ENGINEERING_STANDARDS.md — Alpine RMS Backend (Laravel 12)

This file contains coding standards for humans and Codex.

## Principles
- Clarity over cleverness
- PSR-12, PHP 8.2+ style
- Type hints and return types
- No business logic in controllers/routes

## Structure (Domain-first)
app/
  Domain/<Domain>/{Models,Actions,Events,Listeners,Policies,DTOs,Repositories}
  Http/{Controllers,Requests,Middleware,Resources}

## Controllers
- Thin adapters
- Use FormRequests
- Call Actions
- Return API Resources

## Validation
- All non-trivial endpoints must have a FormRequest
- Use exists/unique/in rules explicitly

## API Resources
- Stable JSON contract
- Never expose sensitive data

## Events
- Use domain events for cross-domain integration

## Multi-DB Tenancy
- Master migrations vs tenant migrations separation
- Tenant DB is the boundary (no tenant_id fields)

## Testing (offline Codex)
- Codex writes tests
- Developers/CI execute tests
- Every task must include LOCAL COMMANDS TO RUN and EXPECTED RESULTS
