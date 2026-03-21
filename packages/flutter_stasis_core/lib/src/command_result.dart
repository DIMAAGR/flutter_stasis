/// Result contract for command execution independent from external FP libs.
sealed class CommandResult<F, R> {
  const CommandResult();

  /// Exhaustive handling for success and failure.
  T fold<T>({
    required T Function(F failure) onFailure,
    required T Function(R result) onSuccess,
  }) {
    switch (this) {
      case CommandFailure<F, R>(:final failure):
        return onFailure(failure);
      case CommandSuccess<F, R>(:final result):
        return onSuccess(result);
    }
  }

  /// Maps only successful value preserving failure type.
  CommandResult<F, S> map<S>(S Function(R value) mapper) {
    return switch (this) {
      CommandFailure<F, R>(:final failure) => CommandFailure<F, S>(failure),
      CommandSuccess<F, R>(:final result) => CommandSuccess<F, S>(
        mapper(result),
      ),
    };
  }

  /// Returns success payload or `null`.
  R? get resultOrNull => switch (this) {
    CommandSuccess<F, R>(:final result) => result,
    _ => null,
  };

  /// Returns failure payload or `null`.
  F? get failureOrNull => switch (this) {
    CommandFailure<F, R>(:final failure) => failure,
    _ => null,
  };
}

/// Successful command output.
final class CommandSuccess<F, R> extends CommandResult<F, R> {
  const CommandSuccess(this.result);

  final R result;
}

/// Failed command output.
final class CommandFailure<F, R> extends CommandResult<F, R> {
  const CommandFailure(this.failure);

  final F failure;
}
