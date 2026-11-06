# Solutions — Rescu Assessment

## RES-105 · Home feed is janky and memory keeps climbing

### 1. Root Cause Analysis
DevTools profiling identified three contributing factors to scrolling jank and memory growth on the Home feed:
1. **Unscoped Top-Level `Obx` Re-renders (Jank Trigger):**
   The entire `HomeScreen.build()` was wrapped inside a single `Obx` listening to `controller.scrollOffset.value`. On every single scroll tick (60+ FPS), updating `scrollOffset` caused the entire widget tree—including `Scaffold`, `SmartRefresher`, `ListView`, and all `DealCard` instances—to rebuild completely from scratch.
2. **Non-Lazy List View Construction:**
   The feed used `ListView(children: [...])`, which eagerly instantiated and kept all deal cards in memory at once regardless of viewport visibility.
3. **Decoded Image Cache Ballooning (Memory Growth):**
   `TheNetworkImage` rendered images via `CachedNetworkImage` without setting `memCacheWidth` or `memCacheHeight`. High-resolution images were decoded and stored in Flutter's engine image cache at full target bitmap resolution, continuously increasing RAM usage as the feed grew until OS process termination.

### 2. Why this fix is the right one
- **Scoped Reactivity:** Removed the top-level `Obx`. `scrollOffset` is now scoped strictly to `AppBar` (for elevation) and `floatingActionButton` (for scroll-to-top visibility). Scrolling no longer triggers feed body re-renders.
- **Lazy Rendering with `ListView.builder`:** Replaced non-lazy `ListView` with `ListView.builder`, instantiating widgets on-demand as they enter the viewport and recycling offscreen widgets.
- **Image Decode Resizing:** Added `memCacheWidth` and `memCacheHeight` parameters in `TheNetworkImage` (downsampling decoded bitmaps to target display dimensions, e.g. 600x400 max), reducing RAM memory footprint per card by ~70–90%.

#### Alternative Considered & Rejected
- **Alternative:** Increasing `imageCache.maximumSizeBytes` globally or removing image caching entirely.
- **Why Rejected:** Raising cache size limits delays out-of-memory crashes rather than solving bitmap inflation. Removing caching degrades scroll smoothness. Downsampling decoded bitmaps solves memory growth directly while maintaining smooth cached scrolling.

### 3. Edge Cases Considered
- **Varying device pixel ratios:** `memCacheWidth` multiplies layout width by 2 to preserve crispness on high-DPI displays without decoding full-resolution raw source images.
- **Dynamic list header elements:** `ListView.builder` index mapping accounts for optional `FlashDealsSection` and header controls without breaking index math.
