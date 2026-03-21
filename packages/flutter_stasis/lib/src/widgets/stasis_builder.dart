import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builder widget for `ValueListenable`-based state channels.
class StasisBuilder<T> extends StatelessWidget {
  const StasisBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  /// Source state listenable.
  final ValueListenable<T> listenable;

  /// Build callback with current state value.
  final Widget Function(BuildContext context, T state, Widget? child) builder;

  /// Optional static child.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: (context, value, staticChild) =>
          builder(context, value, staticChild),
      child: child,
    );
  }
}
