# Solutions — Rescu Assessment

## F-3 · Stock reservations with optimistic UI

### 1. Implementation & Architecture
- **Optimistic Cart UI & Background Reservation:**
  When a user adds an item or increases quantity, `CartService.add()` updates the local cart state immediately (instant UI feedback). In the background, `_reserveOptimistically()` issues a POST `/reservations` request to reserve stock for 5 minutes.
- **Rollback on Conflict (409):**
  If the reservation request fails with a 409 error (stock contention or insufficient quantity), `CartService` rolls back the item/quantity from the bag and displays a friendly notice (`Get.snackbar('Could not reserve stock', ...)`).
- **Hold Countdown Timer per Line Item:**
  Added `ReservationCountdown` widget on each cart line item displaying remaining hold duration (e.g. `Held for 04:32`).
- **Releasing Holds on Quantity Change / Removal:**
  When reducing quantity or removing a cart line, any active reservation ID is released via `OrderRepo.releaseReservation()`.
- **Checkout & 410 Handling:**
  Checkout passes active reservation IDs. If checkout returns a `410 Reservation Expired` status code, `CartController` catches it, purges expired line items, and notifies the user to review their updated cart.

### 2. Product Decision on In-App Expiration (Underspecified Requirement)
- **Decision:**
  When a reservation expires while the user is actively using the app (or mid-checkout):
  1. The item is automatically removed from the bag when the countdown reaches zero.
  2. A clear, non-technical notification is displayed (`Get.snackbar('Hold Expired', '...')`).
  3. If a 410 error occurs during checkout, the expired item is purged and checkout is aborted so the user can review their updated cart.
- **Justification:**
  Allowing checkout to proceed with expired holds causes payment gateway failures or stock conflicts. Automatically purging expired holds with explicit user notices guarantees cart data is always synchronized with backend availability while maintaining a transparent user experience.

### 3. Edge Cases Considered
- **Rapid quantity changes:** Old reservation IDs are released asynchronously when replaced by new reservation holds for updated quantities.
- **Network timeouts during reservation:** Caught safely with user-facing rollback and notification.
