# Solutions — Rescu Assessment

## RES-101 · Search shows results for the wrong query

### 1. Root Cause Analysis
There were two primary issues in `SearchDealsController`:
1. **Async Race Condition (Stale Overwrite / Out-of-Order Execution):**
   In `FakeApiService.searchDeals`, broader queries take longer to respond than specific ones (e.g. `s` takes ~1200ms delay while `sushi` takes ~180ms delay). When a user types quickly letter-by-letter ("s" -> "su" -> "sus" -> "sush" -> "sushi"), multiple async `_search(query)` requests execute concurrently. The request for `sushi` completes first and updates the UI. However, the earlier request for `s` finishes later and overwrites `results` with stale results for `s`.
2. **Missing Keystroke Debounce:**
   `onQueryChanged` triggered an API call immediately on every single keystroke, causing unnecessary request flooding and compounding the race condition.

### 2. Why this fix is the right one
- Added a **300ms Debounce Timer** (`_debounceTimer`) so that rapid typing triggers only one request after the user pauses.
- Added a **Latest Query Validation** (`if (query == _currentQuery)`): Even if an in-flight async request completes out-of-order, its result is discarded unless it matches the currently active text box query.
- Cancelled the timer in `onClose()` to prevent memory leaks.

#### Alternative Considered & Rejected
- **Alternative:** Using `CancelableOperation` (from `async` package) or HTTP cancellation token to cancel pending network futures.
- **Why Rejected:** `FakeApiService.searchDeals` doesn't natively expose an HTTP `Cancellable` instance. Checking `query == _currentQuery` provides a clean, zero-dependency, safe guard against race conditions, while the 300ms debounce prevents request flooding in the first place.

### 3. Edge Cases Considered
- **User clears search input (empty string):** `onQueryChanged('')` immediately cancels the debounce timer, resets `_currentQuery = ''`, clears `results`, and resets `isLoading` and `hasSearched` without waiting for the timer.
- **Out-of-order response completion:** Handled by validating `query == _currentQuery` before updating `results` and before hiding the loading indicator.
- **Controller disposal:** `_debounceTimer` is cancelled inside `onClose()`.
