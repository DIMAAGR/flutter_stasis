## 0.4.0

- Added `SafeData<T>` for runtime-managed sensitive and short-lived values.
- Added `SafeDataPolicy` and related enums for expiration, cleanup, persistence, and logging strategies.
- Added `SafeData.memoryOnly(...)` convenience constructor.
- Added keyed command cleanup handling and runtime change callbacks for `SafeData`.

## 0.3.1

- Added debug assertions requiring `policyKey` for `droppable`, `sequential`, and `restartable`.
- Added fail-fast `CommandContractViolationError` when `Command.call()` throws instead of returning `CommandResult`.
- Expanded command policy docs with explicit `restartable` and `droppable` semantics.

## 0.3.0

- Pre-1.0 release line.
