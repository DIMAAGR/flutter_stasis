## 0.4.0

- Added `SafeData<T>` runtime integration to `StasisViewModel`.
- Added `manageSafeData(...)` to bridge managed field updates through `invalidate()`.
- Added explicit `commandKey` support in `execute(...)` for keyed cleanup after success or error.
- Added runtime cleanup of managed safe fields during `dispose()`.

## 0.3.1

- Updated command docs and examples to include stable `policyKey` usage.
- Clarified that `restartable` suppresses stale callbacks but does not cancel in-flight I/O.
- Updated example ViewModel to use explicit keying for `droppable` command execution.

## 0.3.0

- Pre-1.0 release line.
- Added `StasisNotifier` and integrated it into `StasisViewModel`.
- Added `invalidate()` and `batch()` helpers to `StasisViewModel`.
