# EVENT_MAP.md (Living Doc)

## OrderOpened
Publisher: Orders
Listeners: (none yet)

## OrderItemsAdded
Publisher: Orders
Listeners:
- Printing: QueuePrintJob (AUTO mode)
- Stations: UpdateQueue

## OrderItemStatusUpdated
Publisher: Stations
Listeners:
- Notifications (optional later)

## PaymentReceived
Publisher: Payments
Listeners:
- Notifications: notify manager/owner
