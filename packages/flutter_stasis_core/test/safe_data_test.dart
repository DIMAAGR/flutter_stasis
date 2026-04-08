import 'package:flutter_stasis_core/flutter_stasis_core.dart';
import 'package:test/test.dart';

void main() {
  group('SafeData', () {
    test(
      'memoryOnly constructor applies the memory-only persistence preset',
      () {
        final data = SafeData<String>.memoryOnly(
          initialValue: 'password',
          expiresAfter: const Duration(seconds: 30),
          clearOnCommandSuccess: const {'login'},
          logStrategy: SafeDataLogStrategy.masked,
        );

        expect(data.readOrNull(), 'password');
        expect(data.policy.persistence, SafeDataPersistence.memoryOnly);
        expect(data.policy.clearOnDispose, isTrue);
        expect(data.policy.expiresAfter, const Duration(seconds: 30));
        expect(data.policy.clearOnCommandSuccess, equals({'login'}));
        expect(data.policy.logStrategy, SafeDataLogStrategy.masked);
      },
    );

    test('starts available when initialized with a value', () {
      final data = SafeData<String>(
        initialValue: '123456',
        policy: const SafeDataPolicy(),
      );

      expect(data.hasValue, isTrue);
      expect(data.isExpired, isFalse);
      expect(data.isCleared, isFalse);
      expect(data.status, SafeDataStatus.available);
      expect(data.readOrNull(), '123456');
      expect(data.requireValid(), '123456');
      expect(data.expiresAt, isNull);
    });

    test('starts empty when initialized without a value', () {
      final data = SafeData<String>(policy: const SafeDataPolicy());

      expect(data.hasValue, isFalse);
      expect(data.isExpired, isFalse);
      expect(data.isCleared, isFalse);
      expect(data.status, SafeDataStatus.empty);
      expect(data.readOrNull(), isNull);
      expect(() => data.requireValid(), throwsA(isA<StateError>()));
    });

    test('clear removes the current value and marks the field as cleared', () {
      final data = SafeData<String>(
        initialValue: 'refresh-token',
        policy: const SafeDataPolicy(),
      );

      data.clear();

      expect(data.hasValue, isFalse);
      expect(data.isCleared, isTrue);
      expect(data.isExpired, isFalse);
      expect(data.status, SafeDataStatus.cleared);
      expect(data.readOrNull(), isNull);
      expect(() => data.requireValid(), throwsA(isA<StateError>()));
    });

    test('clear is idempotent', () {
      final data = SafeData<String>(
        initialValue: 'access-token',
        policy: const SafeDataPolicy(),
      );

      data.clear();
      data.clear();

      expect(data.hasValue, isFalse);
      expect(data.status, SafeDataStatus.cleared);
      expect(data.readOrNull(), isNull);
    });

    test('set replaces the previous value and makes it available again', () {
      final data = SafeData<String>(
        initialValue: 'old-token',
        policy: const SafeDataPolicy(),
      );

      data.clear();
      data.set('new-token');

      expect(data.hasValue, isTrue);
      expect(data.isCleared, isFalse);
      expect(data.isExpired, isFalse);
      expect(data.status, SafeDataStatus.available);
      expect(data.readOrNull(), 'new-token');
      expect(data.requireValid(), 'new-token');
    });

    test('set(null) on a nullable field resets the field back to empty', () {
      final data = SafeData<String?>(
        initialValue: 'temporary-secret',
        policy: const SafeDataPolicy(),
      );

      data.set(null);

      expect(data.hasValue, isFalse);
      expect(data.isCleared, isFalse);
      expect(data.isExpired, isFalse);
      expect(data.status, SafeDataStatus.empty);
      expect(data.readOrNull(), isNull);
      expect(() => data.requireValid(), throwsA(isA<StateError>()));
    });

    test('redacts the raw value in string output by default', () {
      final data = SafeData<String>(
        initialValue: 'super-secret-password',
        policy: const SafeDataPolicy(),
      );

      final description = data.toString();

      expect(description, contains('redacted'));
      expect(description, isNot(contains('super-secret-password')));
    });

    test('tracks expiration and hides expired values', () {
      var currentTime = DateTime.utc(2026, 4, 8, 12, 0, 0);

      final data = SafeData<String>(
        initialValue: 'otp-code',
        policy: const SafeDataPolicy(expiresAfter: Duration(seconds: 30)),
        now: () => currentTime,
      );

      expect(data.status, SafeDataStatus.available);
      expect(data.expiresAt, DateTime.utc(2026, 4, 8, 12, 0, 30));
      expect(data.readOrNull(), 'otp-code');

      currentTime = DateTime.utc(2026, 4, 8, 12, 0, 29);
      expect(data.isExpired, isFalse);
      expect(data.readOrNull(), 'otp-code');

      currentTime = DateTime.utc(2026, 4, 8, 12, 0, 30);
      expect(data.isExpired, isTrue);
      expect(data.hasValue, isFalse);
      expect(data.status, SafeDataStatus.expired);
      expect(data.readOrNull(), isNull);
      expect(() => data.requireValid(), throwsA(isA<StateError>()));
    });

    test('expires immediately when configured with Duration.zero', () {
      final currentTime = DateTime.utc(2026, 4, 8, 12, 0, 0);

      final data = SafeData<String>(
        initialValue: 'otp-code',
        policy: const SafeDataPolicy(expiresAfter: Duration.zero),
        now: () => currentTime,
      );

      expect(data.expiresAt, currentTime);
      expect(data.status, SafeDataStatus.expired);
      expect(data.hasValue, isFalse);
      expect(data.readOrNull(), isNull);
      expect(() => data.requireValid(), throwsA(isA<StateError>()));
    });

    test('rejects negative expiration durations', () {
      expect(
        () => SafeData<String>(
          initialValue: 'otp-code',
          policy: const SafeDataPolicy(
            expiresAfter: Duration(microseconds: -1),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('set resets the expiration window from the new write time', () {
      var currentTime = DateTime.utc(2026, 4, 8, 12, 0, 0);

      final data = SafeData<String>(
        initialValue: 'first-otp',
        policy: const SafeDataPolicy(expiresAfter: Duration(seconds: 30)),
        now: () => currentTime,
      );

      currentTime = DateTime.utc(2026, 4, 8, 12, 0, 10);
      data.set('second-otp');

      expect(data.status, SafeDataStatus.available);
      expect(data.readOrNull(), 'second-otp');
      expect(data.expiresAt, DateTime.utc(2026, 4, 8, 12, 0, 40));

      currentTime = DateTime.utc(2026, 4, 8, 12, 0, 39);
      expect(data.isExpired, isFalse);
      expect(data.requireValid(), 'second-otp');

      currentTime = DateTime.utc(2026, 4, 8, 12, 0, 40);
      expect(data.isExpired, isTrue);
      expect(data.readOrNull(), isNull);
    });

    test('does not expire when no expiration policy is configured', () {
      var currentTime = DateTime.utc(2026, 4, 8, 12, 0, 0);

      final data = SafeData<String>(
        initialValue: 'session-id',
        policy: const SafeDataPolicy(),
        now: () => currentTime,
      );

      currentTime = DateTime.utc(2030, 1, 1);

      expect(data.isExpired, isFalse);
      expect(data.hasValue, isTrue);
      expect(data.expiresAt, isNull);
      expect(data.requireValid(), 'session-id');
    });

    test('matching success command key clears the field', () {
      final data = SafeData<String>(
        initialValue: 'password',
        policy: const SafeDataPolicy(clearOnCommandSuccess: {'login'}),
      );

      final cleared = data.handleCommandCompletion(
        commandKey: 'login',
        succeeded: true,
      );

      expect(cleared, isTrue);
      expect(data.readOrNull(), isNull);
      expect(data.status, SafeDataStatus.cleared);
    });

    test('matching error command key clears the field', () {
      final data = SafeData<String>(
        initialValue: '123456',
        policy: const SafeDataPolicy(clearOnCommandError: {'verify-otp'}),
      );

      final cleared = data.handleCommandCompletion(
        commandKey: 'verify-otp',
        succeeded: false,
      );

      expect(cleared, isTrue);
      expect(data.readOrNull(), isNull);
      expect(data.status, SafeDataStatus.cleared);
    });

    test('unrelated command key does not clear the field', () {
      final data = SafeData<String>(
        initialValue: 'password',
        policy: const SafeDataPolicy(clearOnCommandSuccess: {'login'}),
      );

      final cleared = data.handleCommandCompletion(
        commandKey: 'submit-profile',
        succeeded: true,
      );

      expect(cleared, isFalse);
      expect(data.readOrNull(), 'password');
      expect(data.status, SafeDataStatus.available);
    });

    test(
      'attached runtime callback fires on visible changes and stops after detach',
      () {
        final notifications = <String>[];
        final data = SafeData<String>(
          initialValue: 'first',
          policy: const SafeDataPolicy(),
        );

        data.attachRuntime(onChanged: () => notifications.add('changed'));

        data.set('second');
        data.clear();
        data.detachRuntime();
        data.set('third');

        expect(notifications, ['changed', 'changed']);
        expect(data.readOrNull(), 'third');
      },
    );

    test('rejects attaching a second runtime without detaching first', () {
      final data = SafeData<String>(
        initialValue: 'first',
        policy: const SafeDataPolicy(),
      );

      data.attachRuntime(onChanged: () {});

      expect(
        () => data.attachRuntime(onChanged: () {}),
        throwsA(isA<StateError>()),
      );
    });

    test('supports attach-detach-attach cycles', () {
      final notifications = <String>[];
      final data = SafeData<String>(
        initialValue: 'first',
        policy: const SafeDataPolicy(),
      );

      data.attachRuntime(onChanged: () => notifications.add('first-runtime'));
      data.set('second');

      data.detachRuntime();
      data.attachRuntime(onChanged: () => notifications.add('second-runtime'));
      data.clear();

      expect(notifications, ['first-runtime', 'second-runtime']);
      expect(data.status, SafeDataStatus.cleared);
    });
  });
}
