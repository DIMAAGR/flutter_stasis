import 'package:flutter_stasis_core/flutter_stasis_core.dart';
import 'package:flutter_stasis_secure/flutter_stasis_secure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeDataSecureBinding', () {
    test(
      'persists the current field value when secure storage is allowed',
      () async {
        final field = SafeData<String>(
          initialValue: 'refresh-token',
          policy: const SafeDataPolicy(
            persistence: SafeDataPersistence.secureStorage,
          ),
        );
        final adapter = FakeSafeDataSecureAdapter();
        final binding = SafeDataSecureBinding<String>(
          field: field,
          adapter: adapter,
          key: 'refresh_token',
          encode: (value) => 'enc:$value',
          decode: (value) => value.replaceFirst('enc:', ''),
        );

        final persisted = await binding.persist();

        expect(persisted, isTrue);
        final record = await adapter.read('refresh_token');
        expect(record, isNotNull);
        expect(record!.encodedValue, 'enc:refresh-token');
      },
    );

    test(
      'does not persist when the field policy forbids secure storage',
      () async {
        final field = SafeData<String>(
          initialValue: 'refresh-token',
          policy: const SafeDataPolicy(persistence: SafeDataPersistence.never),
        );
        final adapter = _RecordingSecureAdapter();
        final binding = SafeDataSecureBinding<String>(
          field: field,
          adapter: adapter,
          key: 'refresh_token',
          encode: (value) => value,
          decode: (value) => value,
        );

        final persisted = await binding.persist();

        expect(persisted, isFalse);
        expect(adapter.writeCalls, 0);
      },
    );

    test('does not persist when the field has no valid value', () async {
      final field = SafeData<String>(
        policy: const SafeDataPolicy(
          persistence: SafeDataPersistence.secureStorage,
        ),
      );
      final adapter = _RecordingSecureAdapter();
      final binding = SafeDataSecureBinding<String>(
        field: field,
        adapter: adapter,
        key: 'refresh_token',
        encode: (value) => value,
        decode: (value) => value,
      );

      final persisted = await binding.persist();

      expect(persisted, isFalse);
      expect(adapter.writeCalls, 0);
    });

    test('restores explicitly from the adapter into the field', () async {
      final field = SafeData<String>(
        policy: const SafeDataPolicy(
          persistence: SafeDataPersistence.secureStorage,
        ),
      );
      final adapter = FakeSafeDataSecureAdapter();
      await adapter.write(
        const SafeDataSecureRecord(
          key: 'refresh_token',
          encodedValue: 'enc:restored-token',
        ),
      );
      final binding = SafeDataSecureBinding<String>(
        field: field,
        adapter: adapter,
        key: 'refresh_token',
        encode: (value) => 'enc:$value',
        decode: (value) => value.replaceFirst('enc:', ''),
      );

      final restored = await binding.restore();

      expect(restored, isTrue);
      expect(field.requireValid(), 'restored-token');
      expect(field.status, SafeDataStatus.available);
    });

    test(
      'restore recomputes expiration from the current restore time',
      () async {
        var currentTime = DateTime.utc(2026, 4, 8, 12, 0, 0);
        final field = SafeData<String>(
          policy: const SafeDataPolicy(
            persistence: SafeDataPersistence.secureStorage,
            expiresAfter: Duration(seconds: 30),
          ),
          now: () => currentTime,
        );
        final adapter = FakeSafeDataSecureAdapter();
        await adapter.write(
          const SafeDataSecureRecord(
            key: 'otp_code',
            encodedValue: 'enc:654321',
          ),
        );
        final binding = SafeDataSecureBinding<String>(
          field: field,
          adapter: adapter,
          key: 'otp_code',
          encode: (value) => 'enc:$value',
          decode: (value) => value.replaceFirst('enc:', ''),
        );

        currentTime = DateTime.utc(2026, 4, 8, 12, 1, 0);
        final restored = await binding.restore();

        expect(restored, isTrue);
        expect(field.requireValid(), '654321');
        expect(field.expiresAt, DateTime.utc(2026, 4, 8, 12, 1, 30));
      },
    );

    test('restore returns false when no persisted value exists', () async {
      final field = SafeData<String>(
        policy: const SafeDataPolicy(
          persistence: SafeDataPersistence.secureStorage,
        ),
      );
      final adapter = _RecordingSecureAdapter();
      final binding = SafeDataSecureBinding<String>(
        field: field,
        adapter: adapter,
        key: 'missing',
        encode: (value) => value,
        decode: (value) => value,
      );

      final restored = await binding.restore();

      expect(restored, isFalse);
      expect(field.readOrNull(), isNull);
      expect(adapter.readCalls, 1);
    });

    test(
      'restore does not run when secure storage is not allowed by policy',
      () async {
        final field = SafeData<String>(
          policy: const SafeDataPolicy(
            persistence: SafeDataPersistence.memoryOnly,
          ),
        );
        final adapter = _RecordingSecureAdapter();
        final binding = SafeDataSecureBinding<String>(
          field: field,
          adapter: adapter,
          key: 'refresh_token',
          encode: (value) => value,
          decode: (value) => value,
        );

        final restored = await binding.restore();

        expect(restored, isFalse);
        expect(adapter.readCalls, 0);
      },
    );

    test('deletePersisted removes the stored value', () async {
      final field = SafeData<String>(
        initialValue: 'refresh-token',
        policy: const SafeDataPolicy(
          persistence: SafeDataPersistence.secureStorage,
        ),
      );
      final adapter = FakeSafeDataSecureAdapter();
      final binding = SafeDataSecureBinding<String>(
        field: field,
        adapter: adapter,
        key: 'refresh_token',
        encode: (value) => value,
        decode: (value) => value,
      );

      await binding.persist();
      await binding.deletePersisted();

      expect(await adapter.read('refresh_token'), isNull);
    });
  });
}

final class _RecordingSecureAdapter implements SafeDataSecureAdapter {
  int writeCalls = 0;
  int readCalls = 0;
  int deleteCalls = 0;
  final Map<String, SafeDataSecureRecord> _storage =
      <String, SafeDataSecureRecord>{};

  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    _storage.remove(key);
  }

  @override
  Future<SafeDataSecureRecord?> read(String key) async {
    readCalls++;
    return _storage[key];
  }

  @override
  Future<void> write(SafeDataSecureRecord record) async {
    writeCalls++;
    _storage[record.key] = record;
  }
}
