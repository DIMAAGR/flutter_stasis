import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ui_event.dart';

/// Delivery mode used by [UiEventChannel].
enum UiEventMode {
  /// Safer default for one-shot UI events:
  /// keeps architecture closer to one consumer per view model scope.
  singleConsumer,

  /// Advanced mode that allows multiple concurrent listeners.
  broadcast,
}

/// Channel for one-shot [UiEvent]s with optional owner-based listener binding.
class UiEventChannel {
  UiEventChannel({this.mode = UiEventMode.singleConsumer});

  /// Listener delivery mode.
  final UiEventMode mode;

  final StreamController<UiEvent> _controller =
      StreamController<UiEvent>.broadcast();
  final Map<Object, StreamSubscription<UiEvent>> _ownerBindings =
      <Object, StreamSubscription<UiEvent>>{};
  int _anonymousListenerCount = 0;
  bool _disposed = false;

  /// Stream listened by views/widgets.
  Stream<UiEvent> get stream => _controller.stream;

  /// Number of active listeners known by this channel.
  ///
  /// Includes owner-bound listeners and listeners created through [listen].
  int get listenerCount => _ownerBindings.length + _anonymousListenerCount;

  /// Whether at least one listener is currently active.
  bool get hasListeners => listenerCount > 0;

  /// Emits a new [event] if channel is still open.
  void emit(UiEvent event) {
    if (_disposed || _controller.isClosed) return;
    _controller.add(event);
  }

  /// Subscribes a listener with optional lifecycle tracking.
  ///
  /// Prefer [bind]/[unbind] with owner ids for UI listeners to avoid accidental
  /// duplicates caused by widget recreation.
  StreamSubscription<UiEvent> listen(
    FutureOr<void> Function(UiEvent event) onEvent,
  ) {
    if (_disposed) return _NoopUiEventSubscription();

    _anonymousListenerCount++;
    _debugWarnIfMultipleListeners();

    final subscription = _controller.stream.listen((event) async {
      await onEvent(event);
    });

    return _TrackedUiEventSubscription(
      subscription,
      onCancel: () {
        if (_anonymousListenerCount > 0) _anonymousListenerCount--;
      },
    );
  }

  /// Binds (or replaces) a listener for [ownerId].
  ///
  /// If the same owner binds multiple times, the previous subscription is
  /// canceled and replaced.
  void bind({
    required Object ownerId,
    required FutureOr<void> Function(UiEvent event) onEvent,
  }) {
    if (_disposed) return;

    _ownerBindings.remove(ownerId)?.cancel();
    _ownerBindings[ownerId] = _controller.stream.listen((event) async {
      await onEvent(event);
    });
    _debugWarnIfMultipleListeners();
  }

  /// Unbinds a previously bound [ownerId].
  Future<void> unbind(Object ownerId) async {
    final existing = _ownerBindings.remove(ownerId);
    await existing?.cancel();
  }

  void _debugWarnIfMultipleListeners() {
    assert(() {
      if (mode == UiEventMode.singleConsumer && listenerCount > 1) {
        debugPrint(
          '[flutter_stasis] UiEventChannel(singleConsumer) has '
          '$listenerCount active listeners. '
          'Prefer one listener per view model scope. '
          'Use bind/unbind with ownerId to dedupe.',
        );
      }
      return true;
    }());
  }

  /// Closes the event stream.
  Future<void> dispose() async {
    _disposed = true;
    _anonymousListenerCount = 0;

    final subscriptions = _ownerBindings.values.toList();
    _ownerBindings.clear();
    for (final sub in subscriptions) {
      await sub.cancel();
    }

    await _controller.close();
  }
}

class _NoopUiEventSubscription implements StreamSubscription<UiEvent> {
  @override
  Future<E> asFuture<E>([E? futureValue]) {
    if (futureValue != null) return Future<E>.value(futureValue);
    if (null is E) return Future<E>.value(null as E);
    return Completer<E>().future;
  }

  @override
  Future<void> cancel() async {}

  @override
  bool get isPaused => false;

  @override
  void onData(void Function(UiEvent data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}
}

class _TrackedUiEventSubscription implements StreamSubscription<UiEvent> {
  _TrackedUiEventSubscription(this._delegate, {required this.onCancel});

  final StreamSubscription<UiEvent> _delegate;
  final VoidCallback onCancel;
  bool _isCanceled = false;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture<E>(futureValue);

  @override
  Future<void> cancel() {
    if (!_isCanceled) {
      _isCanceled = true;
      onCancel();
    }
    return _delegate.cancel();
  }

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  void onData(void Function(UiEvent data)? handleData) {
    _delegate.onData(handleData);
  }

  @override
  void onDone(void Function()? handleDone) {
    _delegate.onDone(handleDone);
  }

  @override
  void onError(Function? handleError) {
    _delegate.onError(handleError);
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _delegate.pause(resumeSignal);
  }

  @override
  void resume() {
    _delegate.resume();
  }
}
