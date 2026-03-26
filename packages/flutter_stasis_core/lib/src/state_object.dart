import 'package:equatable/equatable.dart';

import 'view_model_state.dart';

/// Immutable state object owned by a single view model/screen.
///
/// [Self] allows preserving concrete type when changing only the internal
/// [ViewModelState].
abstract class StateObject<F, S, Self extends StateObject<F, S, Self>>
    extends Equatable {
  /// Creates a state object with current [state].
  const StateObject({required this.state});

  /// Internal lifecycle state.
  final ViewModelState<F, S> state;

  /// Returns a copy with a new [state] while preserving screen fields.
  Self withState(ViewModelState<F, S> state);

  /// Convenience accessor for success payload.
  S? get dataOrNull => switch (state) {
    SuccessState<F, S>(data: final d) => d,
    _ => null,
  };

  /// Convenience accessor for failure payload.
  F? get failureOrNull => switch (state) {
    ErrorState<F, S>(failure: final f) => f,
    _ => null,
  };

  /// Explicit lifecycle discriminant from [state].
  InternalState get actualState => state.actualState;

  /// Whether current state is loading.
  bool get isLoading => actualState == InternalState.loading;

  /// Whether current state is success.
  bool get isSuccess => actualState == InternalState.success;

  /// Whether current state is error.
  bool get isError => actualState == InternalState.error;
}
