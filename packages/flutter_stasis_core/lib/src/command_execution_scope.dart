import 'dart:async';

import 'command_result.dart';

/// Mutable execution context used by command policies.
///
/// Keep one scope per owner (for example one ViewModel instance) to prevent
/// policy state from leaking across unrelated flows.
class CommandExecutionScope {
  /// Creates an isolated execution scope for command policies.
  CommandExecutionScope();

  /// In-flight futures keyed by command identity (used by `droppable` policy).
  final Map<Object, Future<CommandResult<dynamic, dynamic>>> inFlight =
      <Object, Future<CommandResult<dynamic, dynamic>>>{};

  /// Sequential lock chain keyed by policy key.
  final Map<Object, Future<void>> sequentialLocks = <Object, Future<void>>{};

  /// Restartable epoch counters keyed by policy key.
  final Map<Object, int> restartableEpochByKey = <Object, int>{};

  /// Clears all tracked policy state.
  void clear() {
    inFlight.clear();
    sequentialLocks.clear();
    restartableEpochByKey.clear();
  }
}
