import 'dart:async';

import 'command.dart';
import 'command_execution_scope.dart';
import 'command_policy.dart';
import 'command_result.dart';

/// Encapsulates command execution flow for async stasis results.
class CommandAction {
  /// Creates a command action helper.
  CommandAction();

  static final CommandExecutionScope _globalScope = CommandExecutionScope();

  static Future<CommandResult<F, R>> _run<F, R>({
    required Command<F, R> command,
    required FutureOr<void> Function(F failure) onError,
    required FutureOr<void> Function(R result) onSuccess,
    required FutureOr<void> Function()? onLoading,
    required bool Function() canDispatchCallbacks,
  }) async {
    if (onLoading != null) {
      await onLoading();
    }

    final output = await command();
    if (!canDispatchCallbacks()) return output;

    await output.fold(onFailure: onError, onSuccess: onSuccess);
    return output;
  }

  /// Runs a command and triggers [onLoading], [onError] and [onSuccess].
  ///
  /// This is intentionally explicit to avoid hidden behavior.
  static Future<CommandResult<F, R>> execute<F, R>({
    required Command<F, R> command,
    required FutureOr<void> Function(F failure) onError,
    required FutureOr<void> Function(R result) onSuccess,
    FutureOr<void> Function()? onLoading,
    CommandPolicy policy = CommandPolicy.parallel,
    Object? policyKey,
    CommandExecutionScope? scope,
  }) async {
    final executionScope = scope ?? _globalScope;
    final key = policyKey ?? command;

    switch (policy) {
      case CommandPolicy.parallel:
        return _run<F, R>(
          command: command,
          onError: onError,
          onSuccess: onSuccess,
          onLoading: onLoading,
          canDispatchCallbacks: () => true,
        );

      case CommandPolicy.droppable:
        final existing = executionScope.inFlight[key];
        if (existing != null) return existing as Future<CommandResult<F, R>>;

        final future = _run<F, R>(
          command: command,
          onError: onError,
          onSuccess: onSuccess,
          onLoading: onLoading,
          canDispatchCallbacks: () => true,
        );
        executionScope.inFlight[key] = future as Future<CommandResult<dynamic, dynamic>>;
        future.whenComplete(() {
          if (identical(executionScope.inFlight[key], future)) {
            executionScope.inFlight.remove(key);
          }
        });
        return future;

      case CommandPolicy.sequential:
        final completer = Completer<CommandResult<F, R>>();
        final previous = executionScope.sequentialLocks[key] ?? Future<void>.value();

        late final Future<void> nextLock;
        nextLock = previous
            .catchError((_) {})
            .then((_) async {
              try {
                final result = await _run<F, R>(
                  command: command,
                  onError: onError,
                  onSuccess: onSuccess,
                  onLoading: onLoading,
                  canDispatchCallbacks: () => true,
                );
                completer.complete(result);
              } catch (error, stackTrace) {
                completer.completeError(error, stackTrace);
              }
            })
            .whenComplete(() {
              if (identical(executionScope.sequentialLocks[key], nextLock)) {
                executionScope.sequentialLocks.remove(key);
              }
            });

        executionScope.sequentialLocks[key] = nextLock;
        return completer.future;

      case CommandPolicy.restartable:
        final nextEpoch = (executionScope.restartableEpochByKey[key] ?? 0) + 1;
        executionScope.restartableEpochByKey[key] = nextEpoch;

        return _run<F, R>(
          command: command,
          onError: onError,
          onSuccess: onSuccess,
          onLoading: onLoading,
          canDispatchCallbacks: () => executionScope.restartableEpochByKey[key] == nextEpoch,
        );
    }
  }
}
