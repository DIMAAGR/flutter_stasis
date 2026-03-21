import 'package:flutter/foundation.dart';
import 'package:flutter_stasis_core/flutter_stasis_core.dart';

/// Helper extension for immutable updates on `ValueNotifier<StateObject>`.
extension StateObjectNotifierX<F, S, T extends StateObject<F, S, T>>
    on ValueNotifier<T> {
  /// Applies immutable updater and publishes a new state instance.
  void update(T Function(T current) updater) {
    value = updater(value);
  }
}
