import 'dart:async';

import 'command.dart';
import 'command_execution_scope.dart';
import 'command_policy.dart';
import 'command_result.dart';

/// Programming error thrown when a [Command] breaks its contract.
///
/// Commands must always resolve to a [CommandResult]. Throwing from
/// `command()` bypasses failure typing and should be treated as a bug.
final class CommandContractViolationError extends Error {
  /// Creates a contract violation error.
  CommandContractViolationError({
    required this.originalError,
    required this.originalStackTrace,
  });

  /// Original uncaught error thrown by the command.
  final Object originalError;

  /// Stack trace captured at the original throw site.
  final StackTrace originalStackTrace;

  @override
  String toString() {
    return 'CommandContractViolationError: Command.call() must return '
        'CommandSuccess/CommandFailure and must not throw.\n'
        'Original error: $originalError\n'
        'Original stack trace: $originalStackTrace';
  }
}

/// Encapsulates command execution flow for async stasis results.
class CommandAction {
  /// Creates a command action helper.
  CommandAction();

  static final CommandExecutionScope _globalScope = CommandExecutionScope();

  static Object _resolvePolicyKey({
    required Object? policyKey,
    required Object fallbackKey,
    required CommandPolicy policy,
  }) {
    assert(() {
      if (policyKey == null) {
        throw AssertionError(
          'CommandPolicy.${policy.name} requires a stable policyKey in debug '
          'mode. Provide policyKey to group calls reliably.',
        );
      }
      return true;
    }());
    return policyKey ?? fallbackKey;
  }

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

    late final CommandResult<F, R> output;
    try {
      output = await command();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CommandContractViolationError(
          originalError: error,
          originalStackTrace: stackTrace,
        ),
        stackTrace,
      );
    }

    if (!canDispatchCallbacks()) return output;

    await output.fold(onFailure: onError, onSuccess: onSuccess);
    return output;
  }

  /// Runs a command and triggers [onLoading], [onError] and [onSuccess].
  ///
  /// This is intentionally explicit to avoid hidden behavior.
  ///
  /// For `droppable`, `sequential` and `restartable`, pass a stable [policyKey]
  /// to group invocations consistently. In debug mode, missing keys trigger an
  /// assertion to prevent accidental keying by command identity.
  static Future<CommandResult<F, R>> execute<F, R>({
    required Command<F, R> command,
    required FutureOr<void> Function(F failure) onError,
    required FutureOr<void> Function(R result) onSuccess,
    FutureOr<void> Function()? onLoading,
    CommandPolicy policy = CommandPolicy.parallel,
    Object? policyKey,
    CommandExecutionScope? scope,
  }) {
    final executionScope = scope ?? _globalScope;

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
        final key = _resolvePolicyKey(
          policyKey: policyKey,
          fallbackKey: command,
          policy: policy,
        );
        final existing = executionScope.inFlight[key];
        if (existing != null) return existing as Future<CommandResult<F, R>>;

        final future = _run<F, R>(
          command: command,
          onError: onError,
          onSuccess: onSuccess,
          onLoading: onLoading,
          canDispatchCallbacks: () => true,
        );
        executionScope.inFlight[key] =
            future as Future<CommandResult<dynamic, dynamic>>;
        future.whenComplete(() {
          if (identical(executionScope.inFlight[key], future)) {
            executionScope.inFlight.remove(key);
          }
        });
        return future;

      case CommandPolicy.sequential:
        final key = _resolvePolicyKey(
          policyKey: policyKey,
          fallbackKey: command,
          policy: policy,
        );
        final completer = Completer<CommandResult<F, R>>();
        final previous =
            executionScope.sequentialLocks[key] ?? Future<void>.value();

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
        final key = _resolvePolicyKey(
          policyKey: policyKey,
          fallbackKey: command,
          policy: policy,
        );
        final nextEpoch = (executionScope.restartableEpochByKey[key] ?? 0) + 1;
        executionScope.restartableEpochByKey[key] = nextEpoch;

        return _run<F, R>(
          command: command,
          onError: onError,
          onSuccess: onSuccess,
          onLoading: onLoading,
          canDispatchCallbacks: () =>
              executionScope.restartableEpochByKey[key] == nextEpoch,
        );
    }
  }
}
