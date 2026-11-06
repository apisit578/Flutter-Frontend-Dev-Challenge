# Solutions — Rescu Assessment

## RES-102 · Crash after leaving My orders

### 1. Root Cause Analysis
In `_PickupCountdownState` (`lib/feature/order/widget/pickup_countdown.dart`), a periodic timer `Timer.periodic(const Duration(seconds: 1), ...)` is initialized inside `initState()` to update the countdown widget every second.
However, two critical flaws were present:
1. The `Timer` reference was not saved to any instance field.
2. The `dispose()` lifecycle method was not implemented to cancel the timer when the widget is unmounted/disposed.

When the user navigates away from the "My orders" screen, `_PickupCountdownState` is unmounted and disposed (`mounted == false`). However, the un-cancelled `Timer.periodic` continues to fire every 1 second in the background and invokes `setState(() {})` on the disposed State object, leading to the Flutter debug crash:
`Unhandled Exception: setState() called after dispose(): _PickupCountdownState#...`

### 2. Why this fix is the right one
- Stored the periodic timer reference in `Timer? _timer`.
- Implemented `dispose()` to explicitly call `_timer?.cancel()` before `super.dispose()`, cleanly stopping background timer execution when the widget is removed from the widget tree.
- Added a `if (mounted)` check inside the timer callback as a defensive programming best practice.

#### Alternative Considered & Rejected
- **Alternative 1:** Swallowing the error by placing `try { setState(() {}); } catch (_) {}` or checking only `if (mounted) setState(() {});` without cancelling the timer in `dispose()`.
- **Why Rejected:** Leaving the timer running indefinitely in the background leaks memory and CPU resources across the app lifecycle. Cancelling the timer in `dispose()` addresses the root cause directly.
- **Alternative 2:** Moving the countdown state to `OrdersController`.
- **Why Rejected:** The 1-second UI countdown ticker is purely a view-layer concern. Keeping it local to `PickupCountdown` avoids triggering unnecessary rebuilds of the entire `OrdersScreen` list.

### 3. Edge Cases Considered
- **Rapid Navigation:** If a user opens "My orders" and immediately presses back before the first 1-second tick fires, `dispose()` will cancel `_timer` cleanly.
- **Widget re-mounting / rebuilds:** Flutter framework manages `State` lifecycle cleanly; cancelling on `dispose()` guarantees no orphaned background timers remain.
