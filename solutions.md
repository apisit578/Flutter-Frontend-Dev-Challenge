# Solutions — Rescu Assessment

## RES-104 · Duplicate deals in the home feed

### 1. Root Cause Analysis
In `HomeController`, there was a concurrency race condition between `refreshDeals()` and `loadMore()`:
1. When scrolling near the bottom, `loadMore()` begins fetching page 2 (`_page` is incremented to 2, `_isFetchingMore = true`).
2. If the user quickly pulls down to refresh while `loadMore()` is still in flight, `refreshDeals()` executes `_page = 1` and fetches page 1.
3. `refreshDeals()` finishes first and replaces `deals` with page 1 items.
4. Shortly after, the earlier `loadMore()` call finishes and appends page 2 items (`deals.addAll(...)`), even though `_page` had been reset to 1 by `refreshDeals()`.
5. On the next scroll, `loadMore()` increments `_page` from 1 to 2 again and fetches page 2 a second time, appending it again and resulting in duplicate cards.

### 2. Why this fix is the right one
- Added a `_refreshRequestId` counter and an `_isRefreshing` flag.
- When `refreshDeals()` is called, it increments `_refreshRequestId` and sets `_isRefreshing = true`.
- `loadMore()` checks `if (_isFetchingMore || _isRefreshing) return;` to prevent triggering new load requests while refreshing.
- If a `loadMore()` was already in flight before a refresh began, its completion callback checks `if (currentRequestId == _refreshRequestId && !_isRefreshing)`. Stale pagination results from pre-refresh requests are silently discarded.
- Added deduplication by ID (`existingIds.contains(d.id)`) before adding new items to `deals`.

#### Alternative Considered & Rejected
- **Alternative:** Relying only on deduplication (`Set<int>` / `existingIds.contains`) without request ID tracking.
- **Why Rejected:** Deduplication prevents identical items, but does not fix stale page counters (`_page`). Tracking request IDs guarantees state machine consistency between pagination and refreshing.

### 3. Edge Cases Considered
- **Rapid pull-to-refresh:** `if (_isRefreshing) return;` prevents concurrent pull-to-refresh calls.
- **Network failure during loadMore or refresh:** Handled in `catch` blocks with `refreshController.refreshFailed()` / `refreshController.loadFailed()`.
