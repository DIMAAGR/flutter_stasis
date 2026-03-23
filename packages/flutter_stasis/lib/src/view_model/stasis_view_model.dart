import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_stasis_core/flutter_stasis_core.dart';

import '../events/ui_event.dart';
import '../events/ui_event_channel.dart';
import 'stasis_notifier.dart';

/// Base view model used by `flutter_stasis`.
///
/// It forces an initial [StateObject] at construction time and offers helpers
/// for:
/// - immutable state updates
/// - loading/success/error transitions
/// - command execution
/// - one-shot UI events
abstract class StasisViewModel<F, S, T extends StateObject<F, S, T>> {
  StasisViewModel(T initialState)
    : _stateNotifier = StasisNotifier<T>(initialState);

  final StasisNotifier<T> _stateNotifier;
  final UiEventChannel _events = UiEventChannel();
  final CommandExecutionScope _commandExecutionScope = CommandExecutionScope();

  bool _disposed = false;

  /// Current immutable state snapshot.
  T get state => _stateNotifier.value;

  /// Listenable state channel.
  ValueListenable<T> get stateListenable => _stateNotifier;

  /// One-shot UI event stream.
  Stream<UiEvent> get events => _events.stream;

  /// Whether this view model was disposed.
  bool get isDisposed => _disposed;

  /// Replaces the whole state.
  @protected
  void setState(T next) {
    if (_disposed) return;
    _stateNotifier.setValue(next);
  }

  /// Updates state using an immutable updater callback.
  @protected
  void update(T Function(T current) updater) {
    if (_disposed) return;
    _stateNotifier.update(updater);
  }

  /// Notifies listeners without replacing current state instance.
  ///
  /// Useful for advanced scenarios with controlled internal mutable resources.
  @protected
  void invalidate() {
    if (_disposed) return;
    _stateNotifier.invalidate();
  }

  /// Coalesces multiple updates into a single notification.
  @protected
  void batch(VoidCallback action) {
    if (_disposed) return;
    _stateNotifier.batch(action);
  }

  /// Emits loading lifecycle state.
  @protected
  void setLoading() {
    update((current) => current.withState(LoadingState<F, S>()));
  }

  /// Emits success lifecycle state with [data].
  @protected
  void setSuccess(S data, {T Function(T current)? withUpdate}) {
    update((current) {
      final next = withUpdate?.call(current) ?? current;
      return next.withState(SuccessState<F, S>(data));
    });
  }

  /// Emits error lifecycle state with [failure].
  @protected
  void setError(F failure, {T Function(T current)? withUpdate}) {
    update((current) {
      final next = withUpdate?.call(current) ?? current;
      return next.withState(ErrorState<F, S>(failure));
    });
  }

  /// Resets lifecycle state to initial.
  @protected
  void setInitialState({T Function(T current)? withUpdate}) {
    update((current) {
      final next = withUpdate?.call(current) ?? current;
      return next.withState(InitialState<F, S>());
    });
  }

  /// Emits a one-shot [UiEvent].
  @protected
  void emit(UiEvent event) {
    if (_disposed) return;
    _events.emit(event);
  }

  /// Executes a command and delegates side effects through callbacks.
  ///
  /// Public by design to allow adapter packages (for example dartz/fpdart)
  /// to compose ergonomics on top of this API.
  Future<CommandResult<F, R>> execute<R>({
    required Command<F, R> command,
    FutureOr<void> Function(F failure)? onError,
    required FutureOr<void> Function(R result) onSuccess,
    FutureOr<void> Function()? onLoading,
    CommandPolicy policy = CommandPolicy.parallel,
    Object? policyKey,
  }) {
    return CommandAction.execute<F, R>(
      command: command,
      onError: (failure) async {
        setError(failure);
        if (onError != null) await onError(failure);
      },
      onSuccess: onSuccess,
      onLoading: onLoading,
      policy: policy,
      policyKey: policyKey,
      scope: _commandExecutionScope,
    );
  }

  /// Releases state and event resources.
  @mustCallSuper
  Future<void> dispose() async {
    _disposed = true;
    _commandExecutionScope.clear();
    _stateNotifier.dispose();
    await _events.dispose();
  }
}
