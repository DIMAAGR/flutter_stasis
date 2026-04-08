import 'package:flutter_stasis/flutter_stasis.dart';
import 'package:flutter_stasis_secure/flutter_stasis_secure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stasis_example/features/auth/domain/use_cases/auth_use_cases.dart';
import 'package:flutter_stasis_example/features/auth/presentation/view_model/auth_runtime_state.dart';
import 'package:flutter_stasis_example/features/auth/presentation/view_model/auth_runtime_view_model.dart';

AuthRuntimeViewModel _makeVm({FakeSafeDataSecureAdapter? adapter}) {
  final repository = DemoAuthRepository();
  return AuthRuntimeViewModel(
    RequestOtpUseCase(repository),
    VerifyOtpUseCase(repository),
    adapter ?? FakeSafeDataSecureAdapter(),
  );
}

void main() {
  group('AuthRuntimeViewModel', () {
    test(
      'requestOtp success clears password and moves to awaitingOtp',
      () async {
        final vm = _makeVm();

        vm.updatePassword('stasis123');
        await vm.requestOtp();

        expect(vm.state.step, AuthStep.awaitingOtp);
        expect(vm.state.password.readOrNull(), isNull);
        expect(vm.state.password.status, SafeDataStatus.cleared);
        expect(vm.state.statusMessage, contains('654321'));

        await vm.dispose();
      },
    );

    test('requestOtp failure keeps password and exposes error state', () async {
      final vm = _makeVm();

      vm.updatePassword('wrong-password');
      await vm.requestOtp();

      expect(vm.state.isError, isTrue);
      expect(vm.state.password.requireValid(), 'wrong-password');
      expect(vm.state.errorMessage, contains('stasis123'));

      await vm.dispose();
    });

    test(
      'verifyOtp success clears otp and stores tokens only in managed fields',
      () async {
        final vm = _makeVm();

        vm.updatePassword('stasis123');
        await vm.requestOtp();
        vm.updateOtpCode('654321');
        await vm.verifyOtp();

        expect(vm.state.isSuccess, isTrue);
        expect(vm.state.step, AuthStep.authenticated);
        expect(vm.state.otpCode.readOrNull(), isNull);
        expect(vm.state.otpCode.status, SafeDataStatus.cleared);
        expect(vm.state.hasAccessTokenInMemory, isTrue);
        expect(vm.state.hasRefreshTokenInMemory, isTrue);
        expect(vm.state.session, isNotNull);
        expect(vm.state.session!.email, 'demo@stasis.dev');

        await vm.dispose();
      },
    );

    test('persist and restore refresh token are explicit', () async {
      final adapter = FakeSafeDataSecureAdapter();
      final vm = _makeVm(adapter: adapter);

      vm.updatePassword('stasis123');
      await vm.requestOtp();
      vm.updateOtpCode('654321');
      await vm.verifyOtp();

      final persisted = await vm.persistRefreshToken();
      expect(persisted, isTrue);

      vm.clearInMemorySecrets();
      expect(vm.state.hasRefreshTokenInMemory, isFalse);

      final restored = await vm.restoreRefreshToken();
      expect(restored, isTrue);
      expect(vm.state.hasRefreshTokenInMemory, isTrue);
      expect(vm.state.statusMessage, contains('restored'));

      await vm.dispose();
    });

    test('deletePersistedRefreshToken removes stored refresh token', () async {
      final adapter = FakeSafeDataSecureAdapter();
      final vm = _makeVm(adapter: adapter);

      vm.updatePassword('stasis123');
      await vm.requestOtp();
      vm.updateOtpCode('654321');
      await vm.verifyOtp();
      await vm.persistRefreshToken();

      await vm.deletePersistedRefreshToken();

      final restored = await vm.restoreRefreshToken();
      expect(restored, isFalse);

      await vm.dispose();
    });
  });
}
