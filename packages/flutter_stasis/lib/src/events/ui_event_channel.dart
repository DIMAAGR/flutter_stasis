import 'dart:async';

import 'ui_event.dart';

/// Broadcast channel for one-shot [UiEvent]s.
class UiEventChannel {
  final StreamController<UiEvent> _controller =
      StreamController<UiEvent>.broadcast();

  /// Stream listened by views/widgets.
  Stream<UiEvent> get stream => _controller.stream;

  /// Emits a new [event] if channel is still open.
  void emit(UiEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  /// Closes the event stream.
  Future<void> dispose() => _controller.close();
}
