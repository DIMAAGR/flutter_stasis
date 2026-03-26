/// Discriminant for [ViewModelState] runtime phase.
enum InternalState { initial, loading, success, error }

/// Canonical state lifecycle used by view models.
sealed class ViewModelState<F, S> {
  const ViewModelState();

  /// Explicit lifecycle discriminant for this state instance.
  InternalState get actualState => switch (this) {
    InitialState<F, S>() => InternalState.initial,
    LoadingState<F, S>() => InternalState.loading,
    SuccessState<F, S>() => InternalState.success,
    ErrorState<F, S>() => InternalState.error,
  };

  /// Exhaustive handling for all state variants.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(S data) success,
    required T Function(F failure) error,
  }) {
    switch (this) {
      case InitialState<F, S>():
        return initial();
      case LoadingState<F, S>():
        return loading();
      case SuccessState<F, S>(:final data):
        return success(data);
      case ErrorState<F, S>(:final failure):
        return error(failure);
    }
  }
}

/// Initial state.
final class InitialState<F, S> extends ViewModelState<F, S> {
  const InitialState();
}

/// Loading state.
final class LoadingState<F, S> extends ViewModelState<F, S> {
  const LoadingState();
}

/// Success state with [data].
final class SuccessState<F, S> extends ViewModelState<F, S> {
  const SuccessState(this.data);

  final S data;
}

/// Error state with [failure].
final class ErrorState<F, S> extends ViewModelState<F, S> {
  const ErrorState(this.failure);

  final F failure;
}
