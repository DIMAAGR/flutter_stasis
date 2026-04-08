import 'safe_data_enums.dart';

/// Retention and logging rules for [SafeData].
final class SafeDataPolicy {
  /// Creates a policy for a managed safe field.
  const SafeDataPolicy({
    this.clearOnDispose = true,
    this.expiresAfter,
    this.clearOnCommandSuccess = const <Object>{},
    this.clearOnCommandError = const <Object>{},
    this.persistence = SafeDataPersistence.never,
    this.logStrategy = SafeDataLogStrategy.redacted,
  });

  /// Whether the value should be cleared when its owner is disposed.
  final bool clearOnDispose;

  /// Time after which the value becomes invalid.
  final Duration? expiresAfter;

  /// Command keys that clear the value after a successful execution.
  final Set<Object> clearOnCommandSuccess;

  /// Command keys that clear the value after a failed execution.
  final Set<Object> clearOnCommandError;

  /// Persistence strategy requested by the field.
  final SafeDataPersistence persistence;

  /// Strategy used when this field is stringified.
  final SafeDataLogStrategy logStrategy;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SafeDataPolicy &&
            other.clearOnDispose == clearOnDispose &&
            other.expiresAfter == expiresAfter &&
            _setEquals(other.clearOnCommandSuccess, clearOnCommandSuccess) &&
            _setEquals(other.clearOnCommandError, clearOnCommandError) &&
            other.persistence == persistence &&
            other.logStrategy == logStrategy;
  }

  @override
  int get hashCode => Object.hash(
    clearOnDispose,
    expiresAfter,
    _unorderedHash(clearOnCommandSuccess),
    _unorderedHash(clearOnCommandError),
    persistence,
    logStrategy,
  );
}

bool _setEquals(Set<Object> left, Set<Object> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;

  for (final value in left) {
    if (!right.contains(value)) return false;
  }

  return true;
}

int _unorderedHash(Set<Object> values) => Object.hashAll(
  values.toList()..sort((left, right) => '$left'.compareTo('$right')),
);
