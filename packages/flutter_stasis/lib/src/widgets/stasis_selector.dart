import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Selects a slice of a [ValueListenable] state and rebuilds only when
/// selected value changes.
class StasisSelector<TState, TSelected> extends StatefulWidget {
  const StasisSelector({
    super.key,
    required this.listenable,
    required this.selector,
    required this.builder,
    this.equals,
    this.child,
  });

  /// Source state listenable.
  final ValueListenable<TState> listenable;

  /// Function that extracts the selected value from source state.
  final TSelected Function(TState state) selector;

  /// Optional custom equality used to detect selection changes.
  ///
  /// By default, `==` is used.
  final bool Function(TSelected previous, TSelected next)? equals;

  /// Build callback with selected value.
  final Widget Function(BuildContext context, TSelected selected, Widget? child)
  builder;

  /// Optional static child.
  final Widget? child;

  @override
  State<StasisSelector<TState, TSelected>> createState() =>
      _StasisSelectorState<TState, TSelected>();
}

class _StasisSelectorState<TState, TSelected>
    extends State<StasisSelector<TState, TSelected>> {
  late TSelected _selected;

  bool _didSelectionChange(TSelected previous, TSelected next) {
    final equals = widget.equals;
    if (equals != null) return !equals(previous, next);
    return previous != next;
  }

  void _listener() {
    final next = widget.selector(widget.listenable.value);
    if (!_didSelectionChange(_selected, next)) return;
    setState(() => _selected = next);
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.selector(widget.listenable.value);
    widget.listenable.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant StasisSelector<TState, TSelected> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_listener);
      _selected = widget.selector(widget.listenable.value);
      widget.listenable.addListener(_listener);
      return;
    }

    if (oldWidget.selector != widget.selector ||
        oldWidget.equals != widget.equals) {
      final next = widget.selector(widget.listenable.value);
      if (_didSelectionChange(_selected, next)) {
        _selected = next;
      }
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selected, widget.child);
  }
}
