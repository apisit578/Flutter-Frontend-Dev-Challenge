# Solutions — Rescu Assessment

## F-2 · Impression tracking

### 1. Implementation & Architecture
- **Impression Triggering:**
  Created `DealImpressionTracker` wrapping deal widgets with `VisibilityDetector`. When a card is `≥50%` visible for at least 1 continuous second (`Timer` threshold), it calls `analytics.trackDealImpression(...)`.
- **Properties & Deduplication:**
  - Logged properties: `deal_id`, `source` (`home_feed`, `flash_rail`, or `search`), and `position` (list index).
  - Deduplicated per app session using `_impressedDealIds` set in `AnalyticsService`. Each deal ID is tracked at most once per session across all screens.
- **Batching & Flushing:**
  - In `AnalyticsService`, logged events are queued into `_pendingBatch`.
  - Flushed to `FakeApiService.sendAnalyticsBatch()` when:
    1. **10 events** accumulate in the batch, OR
    2. **15 seconds** elapse after the first event enters a new batch.
  - Events are also logged to `AnalyticsService.events` so they appear immediately on the **Analytics debug** screen.

### 2. Performance Impact
- `VisibilityDetector` keys are uniquely identified per position and source (`key: Key('deal-impression-$source-$position-$dealId')`).
- Timers are cancelled on disposal (`dispose()`) or when visibility drops below 50% before the 1-second threshold, preventing unneeded background operations during fast scrolling.

### 3. Edge Cases Considered
- **Fast Scrolling:** If a card scrolls past in under 1 second or with <50% visibility, its timer cancels and no event is logged.
- **App Termination / Teardown:** Unsent pending batch items are flushed in `AnalyticsService.onClose()`.
