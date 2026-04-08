import 'package:flutter_stasis_core/flutter_stasis_core.dart';
import 'package:test/test.dart';

void main() {
  group('SafeDataPolicy', () {
    test('uses the documented defaults', () {
      const policy = SafeDataPolicy();

      expect(policy.clearOnDispose, isTrue);
      expect(policy.expiresAfter, isNull);
      expect(policy.clearOnCommandSuccess, isEmpty);
      expect(policy.clearOnCommandError, isEmpty);
      expect(policy.persistence, SafeDataPersistence.never);
      expect(policy.logStrategy, SafeDataLogStrategy.redacted);
    });

    test('preserves custom values', () {
      final policy = SafeDataPolicy(
        clearOnDispose: false,
        expiresAfter: const Duration(seconds: 30),
        clearOnCommandSuccess: const {'login', 'reset-password'},
        clearOnCommandError: const {'verify-otp'},
        persistence: SafeDataPersistence.memoryOnly,
        logStrategy: SafeDataLogStrategy.masked,
      );

      expect(policy.clearOnDispose, isFalse);
      expect(policy.expiresAfter, const Duration(seconds: 30));
      expect(policy.clearOnCommandSuccess, equals({'login', 'reset-password'}));
      expect(policy.clearOnCommandError, equals({'verify-otp'}));
      expect(policy.persistence, SafeDataPersistence.memoryOnly);
      expect(policy.logStrategy, SafeDataLogStrategy.masked);
    });

    test('supports value equality', () {
      final first = SafeDataPolicy(
        clearOnDispose: false,
        expiresAfter: const Duration(minutes: 1),
        clearOnCommandSuccess: const {'login'},
        clearOnCommandError: const {'verify-otp'},
        persistence: SafeDataPersistence.secureStorage,
        logStrategy: SafeDataLogStrategy.masked,
      );

      final second = SafeDataPolicy(
        clearOnDispose: false,
        expiresAfter: const Duration(minutes: 1),
        clearOnCommandSuccess: const {'login'},
        clearOnCommandError: const {'verify-otp'},
        persistence: SafeDataPersistence.secureStorage,
        logStrategy: SafeDataLogStrategy.masked,
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('changes equality when one field changes', () {
      const base = SafeDataPolicy();
      final changed = SafeDataPolicy(clearOnCommandSuccess: const {'login'});

      expect(changed, isNot(equals(base)));
    });
  });
}
