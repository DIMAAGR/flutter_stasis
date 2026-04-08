/// Declares whether a safe field may be persisted.
enum SafeDataPersistence {
  /// The value must never be persisted or restored.
  never,

  /// The value may live only in runtime memory.
  memoryOnly,

  /// The value may be delegated to a secure persistence backend.
  secureStorage,
}

/// Controls how a safe field should appear in logs and diagnostics.
enum SafeDataLogStrategy {
  /// Writes the raw value.
  plain,

  /// Writes a masked representation.
  masked,

  /// Never writes the raw value.
  redacted,
}

/// Describes the externally visible lifecycle of a safe field.
enum SafeDataStatus {
  /// No value was ever set or the field was initialized empty.
  empty,

  /// A valid value is currently available.
  available,

  /// The value existed but is no longer valid because it expired.
  expired,

  /// The value was explicitly cleared.
  cleared,
}

/// Records why the value was cleared.
enum SafeDataClearReason {
  manual,
  dispose,
  expiration,
  commandSuccess,
  commandError,
  runtimeReset,
}
