import 'safe_data_secure_adapter.dart';
import 'safe_data_secure_record.dart';

/// In-memory adapter used by tests and local development.
final class FakeSafeDataSecureAdapter implements SafeDataSecureAdapter {
  final Map<String, SafeDataSecureRecord> _storage =
      <String, SafeDataSecureRecord>{};

  @override
  Future<void> write(SafeDataSecureRecord record) async {
    _storage[record.key] = record;
  }

  @override
  Future<SafeDataSecureRecord?> read(String key) async => _storage[key];

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }
}
