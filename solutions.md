# Solutions — Rescu Assessment

## RES-106 · Wrong pickup times; "Pickup today" filter misses deals

### 1. Root Cause Analysis
In `PickupWindowModel` (`lib/model/pickup_window_model.dart`), two bugs were identified in time formatting and date calculations:
1. **Raw UTC Formatting in UI Label (`label` getter):**
   The backend API returns ISO-8601 UTC timestamps (e.g. `23:00:00.000Z`). `PickupWindowModel.label` formatted the `start` and `end` `DateTime` instances directly with `DateFormat('HH:mm')` without converting to local time (`.toLocal()`). On a device in UTC+7 (Bangkok), a bakery window of 06:00–09:30 local time is sent as 23:00–02:30 UTC, causing the UI to incorrectly display "Pick up 23:00 – 02:30".
2. **Flawed `isToday` Date Comparison:**
   `isToday` previously performed `start.day == DateTime.now().day`.
   - It compared UTC `start.day` against local `DateTime.now().day`, ignoring timezone offsets (causing windows shifted across midnight UTC to fail the filter).
   - It only checked day-of-month (`.day`) while ignoring `year` and `month`, falsely matching any deal on the same day number in a different month or year.

### 2. Why this fix is the right one
- In `label`: Converted `start` and `end` to local time via `.toLocal()` before formatting with `DateFormat('HH:mm')`.
- In `isToday`: Converted `start` to local time (`localStart = start.toLocal()`) and compared `year`, `month`, and `day` against `DateTime.now()`.
- Added unit tests in `test/model_test.dart` verifying local label formatting and `isToday` accuracy.

#### Alternative Considered & Rejected
- **Alternative:** Converting `start` and `end` directly to local time inside `PickupWindowModel.fromJson`.
- **Why Rejected:** Existing model expectations and API contracts expect `start.isUtc` to be `true` on the parsed model. Converting to local time inside the getters (`label`, `isToday`) preserves model integrity while ensuring view representation is correct.

### 3. Edge Cases Considered
- **Overnight pickup windows (e.g. 23:00 to 02:30 local):** Handled cleanly by `isToday` matching local `start` date.
- **Leap years & month transitions:** Comparing `year`, `month`, and `day` together prevents false positives across different months/years.
