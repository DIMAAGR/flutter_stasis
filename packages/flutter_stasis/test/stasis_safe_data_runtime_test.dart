import 'package:flutter_stasis/flutter_stasis.dart';
import 'package:flutter_stasis_test/flutter_stasis_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stasis SafeData runtime', () {
    test(
      'managed field changes invalidate listeners without replacing state',
      () async {
        final vm = _TestViewModel();

        final states = await captureStates<_TestState>(
          listenable: vm.stateListenable,
          act: () async {
            vm.setPassword('updated-password');
          },
        );

        expect(states, hasLength(2));
        expect(identical(states.first, states.last), isTrue);
        expect(vm.state.password.requireValid(), 'updated-password');

        await vm.dispose();
      },
    );

    test(
      'dispose clears managed fields configured with clearOnDispose',
      () async {
        final vm = _TestViewModel(
          password: SafeData<String>(
            initialValue: 'super-secret',
            policy: const SafeDataPolicy(clearOnDispose: true),
          ),
        );

        await vm.dispose();

        expect(vm.state.password.readOrNull(), isNull);
        expect(vm.state.password.status, SafeDataStatus.cleared);
      },
    );

    test(
      'dispose preserves managed fields when clearOnDispose is false',
      () async {
        final vm = _TestViewModel(
          password: SafeData<String>(
            initialValue: 'super-secret',
            policy: const SafeDataPolicy(clearOnDispose: false),
          ),
        );

        await vm.dispose();

        expect(vm.state.password.readOrNull(), 'super-secret');
        expect(vm.state.password.status, SafeDataStatus.available);
      },
    );

    test('execute clears matching fields after command success', () async {
      final vm = _TestViewModel(
        password: SafeData<String>(
          initialValue: 'pwd',
          policy: const SafeDataPolicy(clearOnCommandSuccess: {'login'}),
        ),
      );

      await vm.loginSuccess();

      expect(vm.state.password.readOrNull(), isNull);
      expect(vm.state.password.status, SafeDataStatus.cleared);
      expect(vm.state.isSuccess, isTrue);

      await vm.dispose();
    });

    test('execute clears matching fields after command error', () async {
      final vm = _TestViewModel(
        otpCode: SafeData<String>(
          initialValue: '123456',
          policy: const SafeDataPolicy(clearOnCommandError: {'verify-otp'}),
        ),
      );

      await vm.verifyOtpFailure();

      expect(vm.state.otpCode.readOrNull(), isNull);
      expect(vm.state.otpCode.status, SafeDataStatus.cleared);
      expect(vm.state.isError, isTrue);

      await vm.dispose();
    });

    test('execute does not clear fields when commandKey is omitted', () async {
      final vm = _TestViewModel(
        password: SafeData<String>(
          initialValue: 'pwd',
          policy: const SafeDataPolicy(clearOnCommandSuccess: {'login'}),
        ),
      );

      await vm.loginSuccessWithoutKey();

      expect(vm.state.password.readOrNull(), 'pwd');
      expect(vm.state.password.status, SafeDataStatus.available);

      await vm.dispose();
    });

    test('execute does not clear fields for unrelated command keys', () async {
      final vm = _TestViewModel(
        password: SafeData<String>(
          initialValue: 'pwd',
          policy: const SafeDataPolicy(clearOnCommandSuccess: {'login'}),
        ),
      );

      await vm.submitProfileSuccess();

      expect(vm.state.password.readOrNull(), 'pwd');
      expect(vm.state.password.status, SafeDataStatus.available);

      await vm.dispose();
    });
  });
}

final class _TestViewModel extends StasisViewModel<String, String, _TestState> {
  _TestViewModel({SafeData<String>? password, SafeData<String>? otpCode})
    : super(
        _TestState(
          state: const InitialState<String, String>(),
          password:
              password ??
              SafeData<String>(
                initialValue: 'initial-password',
                policy: const SafeDataPolicy(clearOnDispose: true),
              ),
          otpCode:
              otpCode ??
              SafeData<String>(
                initialValue: '111111',
                policy: const SafeDataPolicy(
                  expiresAfter: Duration(minutes: 5),
                ),
              ),
        ),
      ) {
    manageSafeData(state.password);
    manageSafeData(state.otpCode);
  }

  void setPassword(String value) => state.password.set(value);

  Future<void> loginSuccess() => execute<String>(
    command: TaskCommand(() async => const CommandSuccess('ok')),
    onSuccess: setSuccess,
    commandKey: 'login',
  );

  Future<void> loginSuccessWithoutKey() => execute<String>(
    command: TaskCommand(() async => const CommandSuccess('ok')),
    onSuccess: setSuccess,
  );

  Future<void> submitProfileSuccess() => execute<String>(
    command: TaskCommand(() async => const CommandSuccess('ok')),
    onSuccess: setSuccess,
    commandKey: 'submit-profile',
  );

  Future<void> verifyOtpFailure() => execute<String>(
    command: TaskCommand(() async => const CommandFailure('invalid-otp')),
    onSuccess: setSuccess,
    commandKey: 'verify-otp',
  );
}

final class _TestState extends StateObject<String, String, _TestState> {
  const _TestState({
    required super.state,
    required this.password,
    required this.otpCode,
  });

  final SafeData<String> password;
  final SafeData<String> otpCode;

  @override
  _TestState withState(ViewModelState<String, String> state) {
    return _TestState(state: state, password: password, otpCode: otpCode);
  }

  @override
  List<Object?> get props => [state];
}
