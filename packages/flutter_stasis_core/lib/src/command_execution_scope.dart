import 'dart:async';

import 'command_result.dart';

/// Mutable execution context used by command policies.
///
/// Keep one scope per owner (for example one ViewModel instance) to prevent
/// policy state from leaking across unrelated flows.
class CommandExecutionScope {
  final Map<Object, Future<CommandResult<dynamic, dynamic>>> inFlight =
      <Object, Future<CommandResult<dynamic, dynamic>>>{};
  final Map<Object, Future<void>> sequentialLocks = <Object, Future<void>>{};
  final Map<Object, int> restartableEpochByKey = <Object, int>{};

  /// Clears all tracked policy state.
  void clear() {
    inFlight.clear();
    sequentialLocks.clear();
    restartableEpochByKey.clear();
  }
}

