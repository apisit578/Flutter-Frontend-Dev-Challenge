# Solutions — Rescu Assessment

## F-1 · Live flash-sale countdowns

### 1. Implementation & Architecture
- **Dedicated Ticker Widget (`FlashSaleCountdown`):**
  Created a lightweight, self-contained `FlashSaleCountdown` widget in `lib/feature/shared_widget/flash_sale_countdown.dart` that manages a 1-second `Timer.periodic`. Rebuilds are strictly isolated to its own `Text` widget, preventing parent cards or list views from rebuilding every second.
- **Formatting:**
  Formated remaining durations cleanly as `mm:ss` (or `hh:mm:ss` if remaining time exceeds 1 hour).
- **Expiration & Cart Removal:**
  - Added `isFlashExpired` property to `DealModel`.
  - When countdown reaches zero (`remaining <= Duration.zero`), the widget updates to an "Expired" state and fires `onExpired` callback.
  - In `CartService`: `add()` rejects expired flash deals with a snackbar notice. `removeExpiredFlashItems()` automatically purges expired items from the bag and displays an in-app notice (`Get.snackbar`).
  - Cards on the home feed (`DealCard`), flash rail (`FlashDealsSection`), and details screen (`DealDetailsScreen`) update to disabled states when expired.

### 2. Performance & DevTools Evidence
- **Per-Second Scoped Rebuilds:** By containing the `Timer.periodic` inside `_FlashSaleCountdownState`, scrolling through 100+ visible items triggers zero rebuilds on `ListView`, `DealCard`, or `HomeScreen`. DevTools Widget Inspector shows only individual `FlashSaleCountdown` text containers updating each second.

### 3. Edge Cases Considered
- **Timer Disposal:** `_timer?.cancel()` is called in `dispose()` to eliminate background timers when cards scroll off-screen or routes are popped.
- **Cart Consistency:** Periodic checks and expiration callbacks guarantee users cannot purchase deals after flash sales end.
