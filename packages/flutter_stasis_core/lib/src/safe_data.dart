import 'safe_data_enums.dart';
import 'safe_data_policy.dart';

/// Clock callback used by [SafeData] to evaluate expiration deterministically.
typedef SafeDataNow = DateTime Function();

/// Runtime-managed field for short-lived or sensitive data.
class SafeData<T> {
  /// Creates a managed field with an optional [initialValue].
  SafeData({T? initialValue, required this.policy, SafeDataNow? now})
    : _now = now ?? DateTime.now {
    _validatePolicy(policy);

    if (initialValue == null) {
      _status = SafeDataStatus.empty;
      return;
    }

    _value = initialValue;
    _status = SafeDataStatus.available;
    _expiresAt = _computeExpiresAt();
  }

  /// Creates a field constrained to runtime memory only.
  SafeData.memoryOnly({
    T? initialValue,
    bool clearOnDispose = true,
    Duration? expiresAfter,
    Set<Object> clearOnCommandSuccess = const <Object>{},
    Set<Object> clearOnCommandError = const <Object>{},
    SafeDataLogStrategy logStrategy = SafeDataLogStrategy.redacted,
    SafeDataNow? now,
  }) : this(
         initialValue: initialValue,
         policy: SafeDataPolicy(
           clearOnDispose: clearOnDispose,
           expiresAfter: expiresAfter,
           clearOnCommandSuccess: clearOnCommandSuccess,
           clearOnCommandError: clearOnCommandError,
           persistence: SafeDataPersistence.memoryOnly,
           logStrategy: logStrategy,
         ),
         now: now,
       );

  final SafeDataPolicy policy;
  final SafeDataNow _now;

  T? _value;
  DateTime? _expiresAt;
  SafeDataStatus _status = SafeDataStatus.empty;
  SafeDataClearReason? _lastClearReason;
  void Function()? _onChanged;

  /// Whether a valid value is available right now.
  bool get hasValue {
    _syncExpiration();
    return _status == SafeDataStatus.available && _value != null;
  }

  /// Whether the field was explicitly cleared.
  bool get isCleared {
    _syncExpiration();
    return _status == SafeDataStatus.cleared;
  }

  /// Whether the field has expired.
  bool get isExpired {
    _syncExpiration();
    return _status == SafeDataStatus.expired;
  }

  /// Absolute expiration deadline for the current value, if any.
  DateTime? get expiresAt {
    _syncExpiration();
    return _expiresAt;
  }

  /// Current externally visible status.
  SafeDataStatus get status {
    _syncExpiration();
    return _status;
  }

  /// Returns the current value when still valid.
  T? readOrNull() {
    _syncExpiration();
    return _status == SafeDataStatus.available ? _value : null;
  }

  /// Returns the current value or throws if unavailable.
  T requireValid() {
    final value = readOrNull();
    if (value == null) {
      throw StateError(
        'SafeData does not contain a valid value. Current status: $status.',
      );
    }
    return value;
  }

  /// Replaces the current value and resets the expiration window.
  ///
  /// Passing `null` to a nullable `SafeData<T?>` returns the field to the
  /// `empty` state. Use [clear] when the distinction between `empty` and
  /// explicitly `cleared` matters.
  void set(T value) {
    if (value == null) {
      final changed =
          _status != SafeDataStatus.empty ||
          _value != null ||
          _expiresAt != null ||
          _lastClearReason != null;
      _value = null;
      _expiresAt = null;
      _status = SafeDataStatus.empty;
      _lastClearReason = null;
      if (changed) _notifyChanged();
      return;
    }

    _value = value;
    _expiresAt = _computeExpiresAt();
    _status = SafeDataStatus.available;
    _lastClearReason = null;
    _notifyChanged();
  }

  /// Clears the current value.
  void clear({SafeDataClearReason reason = SafeDataClearReason.manual}) {
    final changed =
        _status != SafeDataStatus.cleared ||
        _value != null ||
        _expiresAt != null ||
        _lastClearReason != reason;
    _value = null;
    _expiresAt = null;
    _status = SafeDataStatus.cleared;
    _lastClearReason = reason;
    if (changed) _notifyChanged();
  }

  /// Registers a callback for runtime-visible internal changes.
  void attachRuntime({required void Function() onChanged}) {
    if (_onChanged != null) {
      throw StateError(
        'SafeData already has an attached runtime. Detach it before attaching '
        'another runtime callback.',
      );
    }
    _onChanged = onChanged;
  }

  /// Detaches the current runtime callback, if any.
  void detachRuntime() {
    _onChanged = null;
  }

  /// Applies command-linked cleanup rules and reports whether the field changed.
  bool handleCommandCompletion({
    required Object commandKey,
    required bool succeeded,
  }) {
    final matchingKeys = succeeded
        ? policy.clearOnCommandSuccess
        : policy.clearOnCommandError;

    if (!matchingKeys.contains(commandKey)) return false;

    clear(
      reason: succeeded
          ? SafeDataClearReason.commandSuccess
          : SafeDataClearReason.commandError,
    );
    return true;
  }

  static void _validatePolicy(SafeDataPolicy policy) {
    final expiresAfter = policy.expiresAfter;
    if (expiresAfter != null && expiresAfter.isNegative) {
      throw ArgumentError.value(
        expiresAfter,
        'policy.expiresAfter',
        'SafeData expiration must be zero or positive.',
      );
    }
  }

  DateTime? _computeExpiresAt() {
    final expiresAfter = policy.expiresAfter;
    if (expiresAfter == null) return null;
    return _now().add(expiresAfter);
  }

  void _syncExpiration() {
    if (_status != SafeDataStatus.available) return;
    final expiresAt = _expiresAt;
    if (expiresAt == null) return;
    if (_now().isBefore(expiresAt)) return;

    _value = null;
    _status = SafeDataStatus.expired;
    _lastClearReason = SafeDataClearReason.expiration;
    _notifyChanged();
  }

  void _notifyChanged() => _onChanged?.call();

  @override
  String toString() {
    _syncExpiration();

    final visibleValue = switch (policy.logStrategy) {
      SafeDataLogStrategy.plain => '$_value',
      SafeDataLogStrategy.masked => _maskValue(_value),
      SafeDataLogStrategy.redacted => '<redacted>',
    };

    return 'SafeData(status: $_status, value: $visibleValue, '
        'expiresAt: $_expiresAt, lastClearReason: $_lastClearReason)';
  }
}

String _maskValue(Object? value) {
  if (value == null) return '<masked>';

  final raw = '$value';
  if (raw.isEmpty) return '<masked>';
  if (raw.length <= 4) return '*' * raw.length;

  final visibleTail = raw.substring(raw.length - 4);
  return '${'*' * (raw.length - 4)}$visibleTail';
}
