/// Encoded value stored by a secure adapter.
final class SafeDataSecureRecord {
  /// Creates a secure record payload.
  const SafeDataSecureRecord({required this.key, required this.encodedValue});

  /// Logical storage key.
  final String key;

  /// Encoded or encrypted representation of the value.
  final String encodedValue;
}
