import 'package:flutter/foundation.dart';

/// State notifier used by `flutter_stasis` view models.
///
/// It supports two update paths:
/// - [setValue]/[update] for immutable state replacement
/// - [invalidate] to notify listeners without replacing [value]
///
/// The [batch] API coalesces multiple updates into a single notification.
class StasisNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a notifier with [initialValue].
  StasisNotifier(T initialValue) : _value = initialValue;

  T _value;
  int _version = 0;
  int _batchDepth = 0;
  bool _pendingNotification = false;
  bool _disposed = false;

  /// Current value snapshot.
  @override
  T get value => _value;

  /// Monotonic counter incremented on each visible change.
  int get version => _version;

  /// Whether updates are currently being batched.
  bool get isBatching => _batchDepth > 0;

  /// Replaces [value] and notifies listeners when changed.
  void setValue(T next) {
    if (_disposed) return;
    if (_value == next) return;

    _value = next;
    _version++;
    _notifyOrQueue();
  }

  /// Computes and applies a new value from current state.
  void update(T Function(T current) updater) {
    if (_disposed) return;
    setValue(updater(_value));
  }

  /// Notifies listeners without replacing [value].
  ///
  /// Useful for controlled internal mutations that should trigger selectors.
  void invalidate() {
    if (_disposed) return;
    _version++;
    _notifyOrQueue();
  }

  /// Runs [action] and emits at most one notification at the end.
  void batch(VoidCallback action) {
    if (_disposed) return;

    _batchDepth++;
    try {
      action();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 && _pendingNotification) {
        _pendingNotification = false;
        notifyListeners();
      }
    }
  }

  void _notifyOrQueue() {
    if (isBatching) {
      _pendingNotification = true;
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingNotification = false;
    super.dispose();
  }
}
