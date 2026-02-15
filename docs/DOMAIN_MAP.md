# DOMAIN_MAP.md (Living Doc)

## Tenants (master)
Owns:
- tenant registry (rms_master)
- provisioning metadata

## Auth (tenant)
Owns:
- tenant users
- branch membership
- tokens

## Menu
Owns:
- categories, items, modifiers

## POS / Orders
Owns:
- orders, order items, payments
- one-open-order-per-table rule

## Stations / KDS
Owns:
- station queue
- item status transitions

## Printing
Owns:
- KOT tickets
- print jobs (executor polling)

## Reports
Owns:
- daily/monthly/item-wise summaries
