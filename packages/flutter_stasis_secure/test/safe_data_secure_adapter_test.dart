import 'package:flutter_stasis_secure/flutter_stasis_secure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeSafeDataSecureAdapter', () {
    test('writes and reads back a secure record', () async {
      final adapter = FakeSafeDataSecureAdapter();

      await adapter.write(
        const SafeDataSecureRecord(
          key: 'refresh_token',
          encodedValue: 'encrypted-token',
        ),
      );

      final record = await adapter.read('refresh_token');

      expect(record, isNotNull);
      expect(record!.key, 'refresh_token');
      expect(record.encodedValue, 'encrypted-token');
    });

    test('returns null for unknown keys', () async {
      final adapter = FakeSafeDataSecureAdapter();

      final record = await adapter.read('missing');

      expect(record, isNull);
    });

    test('overwrites existing entries for the same key', () async {
      final adapter = FakeSafeDataSecureAdapter();

      await adapter.write(
        const SafeDataSecureRecord(key: 'refresh_token', encodedValue: 'first'),
      );
      await adapter.write(
        const SafeDataSecureRecord(
          key: 'refresh_token',
          encodedValue: 'second',
        ),
      );

      final record = await adapter.read('refresh_token');

      expect(record, isNotNull);
      expect(record!.encodedValue, 'second');
    });

    test('delete removes an existing entry', () async {
      final adapter = FakeSafeDataSecureAdapter();

      await adapter.write(
        const SafeDataSecureRecord(
          key: 'refresh_token',
          encodedValue: 'encrypted-token',
        ),
      );

      await adapter.delete('refresh_token');

      expect(await adapter.read('refresh_token'), isNull);
    });

    test('delete is safe for unknown keys', () async {
      final adapter = FakeSafeDataSecureAdapter();

      await adapter.delete('missing');

      expect(await adapter.read('missing'), isNull);
    });
  });
}
