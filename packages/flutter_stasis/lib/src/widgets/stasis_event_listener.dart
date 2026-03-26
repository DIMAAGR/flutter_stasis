import 'dart:async';

import 'package:flutter/widgets.dart';

import '../events/ui_event.dart';
import '../events/ui_event_channel.dart';

/// Listens to one-shot UI events and forwards them to [onEvent].
class StasisEventListener extends StatefulWidget {
  const StasisEventListener({
    super.key,
    this.stream,
    this.channel,
    this.ownerKey,
    required this.onEvent,
    required this.child,
  }) : assert(
         (stream != null) != (channel != null),
         'Provide either stream or channel.',
       );

  /// Event stream emitted by a stasis view model (legacy mode).
  final Stream<UiEvent>? stream;

  /// Event channel emitted by a stasis view model.
  ///
  /// Prefer this mode when you want owner-based dedupe.
  final UiEventChannel? channel;

  /// Optional owner identifier used with [channel] mode.
  ///
  /// If provided, this listener binds through `channel.bind(ownerId: ...)`
  /// and automatically replaces previous binding for the same owner.
  final Object? ownerKey;

  /// Side-effect handler executed for each event.
  final FutureOr<void> Function(BuildContext context, UiEvent event) onEvent;

  /// Child subtree.
  final Widget child;

  @override
  State<StasisEventListener> createState() => _StasisEventListenerState();
}

class _StasisEventListenerState extends State<StasisEventListener> {
  StreamSubscription<UiEvent>? _subscription;
  UiEventChannel? _boundChannel;
  Object? _boundOwnerId;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant StasisEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream ||
        oldWidget.channel != widget.channel ||
        oldWidget.ownerKey != widget.ownerKey) {
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
    final channel = widget.channel;
    if (channel != null) {
      final ownerId = widget.ownerKey;
      if (ownerId != null) {
        _boundChannel = channel;
        _boundOwnerId = ownerId;
        channel.bind(ownerId: ownerId, onEvent: _handleEvent);
        return;
      }
      _subscription = channel.listen(_handleEvent);
      return;
    }

    _subscription = widget.stream!.listen(_handleEvent);
  }

  void _unbind() {
    _subscription?.cancel();
    _subscription = null;

    final ownerId = _boundOwnerId;
    final channel = _boundChannel;
    if (ownerId != null && channel != null) {
      unawaited(channel.unbind(ownerId));
    }
    _boundOwnerId = null;
    _boundChannel = null;
  }

  Future<void> _handleEvent(UiEvent event) async {
    if (!mounted) return;
    await widget.onEvent(context, event);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
