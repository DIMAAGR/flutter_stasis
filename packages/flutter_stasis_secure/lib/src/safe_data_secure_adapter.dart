import 'safe_data_secure_record.dart';

/// Contract for secure persistence backends used by Stasis safe data.
abstract interface class SafeDataSecureAdapter {
  /// Persists a record under its logical key.
  Future<void> write(SafeDataSecureRecord record);

  /// Reads the record stored under [key], if any.
  Future<SafeDataSecureRecord?> read(String key);

  /// Deletes the record stored under [key], if any.
  Future<void> delete(String key);
}
