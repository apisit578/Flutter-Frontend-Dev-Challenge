# Solutions — Rescu Assessment

## RES-103 · Requests pile up the longer you browse

### 1. Root Cause Analysis
In `DealDetailsController.onInit()`, a GetX worker listener `ever(cartService.itemCount, ...)` was registered to re-check stock availability whenever cart items changed.
However:
1. `CartService` is an app-wide singleton (`GetxService`) that lives for the entire user session.
2. The `Worker` instance returned by `ever(...)` was never stored or disposed in `DealDetailsController.onClose()`.

Because `cartService` is long-lived, its `itemCount` Rx variable retained active stream subscriptions for every `DealDetailsController` instance ever created during the app session. Every time the user tapped "Add to bag", `cartService.itemCount` changed, triggering `_recheckAvailability()` (a `GET /deals/:id` request) for ALL historical deal screens viewed earlier in the session—even those that had been closed long ago.

### 2. Why this fix is the right one
- Stored the worker reference in `Worker? _cartWorker`.
- Overrode `onClose()` in `DealDetailsController` to invoke `_cartWorker?.dispose()`, cleanly tearing down the stream subscription when the deal details screen route is popped/closed.

#### Alternative Considered & Rejected
- **Alternative:** Removing `ever(cartService.itemCount, ...)` completely and checking availability only on manual pull-to-refresh or initial load.
- **Why Rejected:** Real-time stock update on the active deal details screen when adding items to the bag is a desired feature. Storing and disposing the worker ensures real-time updates work on the active screen without leaking listeners after navigation.

### 3. Edge Cases Considered
- **Deep links & direct navigation:** Any navigation creating a `DealDetailsController` will register a worker, and popping that route will invoke `onClose()`, ensuring 100% cleanup symmetry regardless of how the screen was opened.
