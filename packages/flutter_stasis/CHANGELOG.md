## 0.3.1

- Updated command docs and examples to include stable `policyKey` usage.
- Clarified that `restartable` suppresses stale callbacks but does not cancel in-flight I/O.
- Updated example ViewModel to use explicit keying for `droppable` command execution.

## 0.3.0

- Pre-1.0 release line.
- Added `StasisNotifier` and integrated it into `StasisViewModel`.
- Added `invalidate()` and `batch()` helpers to `StasisViewModel`.
