import 'dart:async';

import 'package:flutter/widgets.dart';

import '../events/ui_event.dart';

/// Listens to one-shot UI events and forwards them to [onEvent].
class StasisEventListener extends StatefulWidget {
  const StasisEventListener({
    super.key,
    required this.stream,
    required this.onEvent,
    required this.child,
  });

  /// Event stream emitted by a stasis view model.
  final Stream<UiEvent> stream;

  /// Side-effect handler executed for each event.
  final FutureOr<void> Function(BuildContext context, UiEvent event) onEvent;

  /// Child subtree.
  final Widget child;

  @override
  State<StasisEventListener> createState() => _StasisEventListenerState();
}

class _StasisEventListenerState extends State<StasisEventListener> {
  StreamSubscription<UiEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant StasisEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _unbind();
      _bind();
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _bind() {
    _subscription = widget.stream.listen((event) async {
      if (!mounted) return;
      await widget.onEvent(context, event);
    });
  }

  void _unbind() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
