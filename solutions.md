# Solutions — Rescu Assessment

## RES-107 · Deep link opens to a crash

### 1. Root Cause Analysis
When navigating to a deal from the Home feed, the app passed a fully populated `DealModel` instance in `Get.arguments`. `DealDetailsController.onInit()` expected `deal = Get.arguments as DealModel`.
However, when opening the screen via a deep link (e.g. `rescu://open/deal?id=42&source=push`), `Get.arguments` is `null`. Attempting to cast `null as DealModel` threw an unhandled `TypeError`:
`type 'Null' is not a subtype of type 'DealModel'`

### 2. Why this fix is the right one
- Modified `DealDetailsController` to handle both navigation origins:
  1. **In-app navigation:** If `Get.arguments` is a `DealModel`, use it immediately for zero-latency rendering.
  2. **Deep link navigation:** If `Get.arguments` is null, extract `id` from query parameters (`Get.parameters['id']`) and fetch the deal asynchronously using `dealRepo.fetchById(id)`.
- Added reactive `_deal = Rxn<DealModel>()` and `isLoading` flags to present a clean loading UI while the deep-linked deal is being retrieved.
- Disposed `_cartWorker` in `onClose()` to maintain clean worker lifecycle management.

#### Alternative Considered & Rejected
- **Alternative:** Mandatory fallback redirect back to Home screen whenever `Get.arguments` is missing.
- **Why Rejected:** Explicit requirement states deep links must land the user directly on a fully functional deal page. Fetching the deal by ID satisfies deep link functionality natively.

### 3. Edge Cases Considered
- **Invalid or missing deal ID parameter:** Handled by validating `int.tryParse(idParam)` and presenting an explicit "Deal not found" UI state.
- **Network errors during deep link fetch:** Caught in `catch` block with logging and safe `isLoading` reset.
