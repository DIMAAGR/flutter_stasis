import 'package:flutter_stasis_core/flutter_stasis_core.dart';

import 'safe_data_secure_adapter.dart';
import 'safe_data_secure_record.dart';

/// Encodes a field value before secure persistence.
typedef SafeDataSecureEncoder<T> = String Function(T value);

/// Decodes a persisted value back into the field type.
typedef SafeDataSecureDecoder<T> = T Function(String value);

/// Explicit secure persistence binding for a [SafeData] field.
///
/// This binding is intentionally imperative. Values are only persisted or
/// restored when the caller explicitly invokes those actions.
final class SafeDataSecureBinding<T> {
  /// Creates a secure binding for [field].
  const SafeDataSecureBinding({
    required this.field,
    required this.adapter,
    required this.key,
    required this.encode,
    required this.decode,
  });

  /// Field managed by this binding.
  final SafeData<T> field;

  /// Secure adapter used for persistence.
  final SafeDataSecureAdapter adapter;

  /// Logical key used by the adapter.
  final String key;

  /// Encoder used before writing to secure storage.
  final SafeDataSecureEncoder<T> encode;

  /// Decoder used after reading from secure storage.
  final SafeDataSecureDecoder<T> decode;

  /// Persists the current field value when policy allows secure storage.
  Future<bool> persist() async {
    if (!_allowsSecurePersistence) return false;

    final value = field.readOrNull();
    if (value == null) return false;

    await adapter.write(
      SafeDataSecureRecord(key: key, encodedValue: encode(value)),
    );
    return true;
  }

  /// Restores the field explicitly from the secure backend.
  Future<bool> restore() async {
    if (!_allowsSecurePersistence) return false;

    final record = await adapter.read(key);
    if (record == null) return false;

    field.set(decode(record.encodedValue));
    return true;
  }

  /// Deletes the persisted value for this binding key.
  Future<void> deletePersisted() => adapter.delete(key);

  bool get _allowsSecurePersistence =>
      field.policy.persistence == SafeDataPersistence.secureStorage;
}
