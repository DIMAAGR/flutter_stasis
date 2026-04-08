import 'package:flutter_stasis/flutter_stasis.dart';
import 'package:flutter_stasis_secure/flutter_stasis_secure.dart';

import '../../domain/entities/auth_challenge.dart';
import '../../domain/entities/auth_grant.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/use_cases/auth_use_cases.dart';
import 'auth_runtime_state.dart';

class AuthRuntimeViewModel
    extends StasisViewModel<AuthFailure, AuthSession, AuthRuntimeState> {
  AuthRuntimeViewModel(
    this._requestOtp,
    this._verifyOtp,
    SafeDataSecureAdapter secureAdapter,
  ) : super(AuthRuntimeState.initial()) {
    manageSafeData(state.password);
    manageSafeData(state.otpCode);
    manageSafeData(state.accessToken);
    manageSafeData(state.refreshToken);

    _refreshTokenBinding = SafeDataSecureBinding<String>(
      field: state.refreshToken,
      adapter: secureAdapter,
      key: 'example_refresh_token',
      encode: (value) => 'enc:$value',
      decode: (value) => value.replaceFirst('enc:', ''),
    );
  }

  final RequestOtpUseCase _requestOtp;
  final VerifyOtpUseCase _verifyOtp;
  late final SafeDataSecureBinding<String> _refreshTokenBinding;

  void updatePassword(String value) => _setFieldValue(state.password, value);

  void updateOtpCode(String value) => _setFieldValue(state.otpCode, value);

  Future<void> requestOtp() => execute<AuthChallenge>(
    command: TaskCommand(() async {
      final password = state.password.readOrNull();
      if (password == null) {
        return const CommandFailure(AuthFailure.missingPassword());
      }
      return _requestOtp(password);
    }),
    onLoading: () {
      update(
        (s) => s.copyWith(
          isRequestingOtp: true,
          statusMessage: 'Requesting OTP...',
        ),
      );
    },
    onSuccess: (challenge) {
      setInitialState(
        withUpdate: (s) => s.copyWith(
          step: AuthStep.awaitingOtp,
          isRequestingOtp: false,
          statusMessage:
              'OTP sent to ${challenge.destinationHint}. Demo code: '
              '${challenge.demoCode}',
        ),
      );
    },
    onError: (failure) {
      setError(
        failure,
        withUpdate: (s) =>
            s.copyWith(isRequestingOtp: false, statusMessage: failure.message),
      );
    },
    commandKey: 'request-otp',
  );

  Future<void> verifyOtp() => execute<AuthGrant>(
    command: TaskCommand(() async {
      final otp = state.otpCode.readOrNull();
      if (otp == null) {
        return const CommandFailure(AuthFailure.missingOtp());
      }
      return _verifyOtp(otp);
    }),
    onLoading: () {
      update(
        (s) =>
            s.copyWith(isVerifyingOtp: true, statusMessage: 'Verifying OTP...'),
      );
    },
    onSuccess: (grant) {
      _applyGrant(grant);
      setSuccess(
        AuthSession.fromGrant(grant),
        withUpdate: (s) => s.copyWith(
          step: AuthStep.authenticated,
          isVerifyingOtp: false,
          statusMessage: 'Authenticated as ${grant.email}.',
        ),
      );
    },
    onError: (failure) {
      setError(
        failure,
        withUpdate: (s) =>
            s.copyWith(isVerifyingOtp: false, statusMessage: failure.message),
      );
    },
    commandKey: 'verify-otp',
  );

  Future<bool> persistRefreshToken() async {
    final persisted = await _refreshTokenBinding.persist();
    update(
      (s) => s.copyWith(
        statusMessage: persisted
            ? 'Refresh token persisted explicitly.'
            : 'Nothing to persist or secure persistence is not allowed.',
      ),
    );
    return persisted;
  }

  Future<bool> restoreRefreshToken() async {
    final restored = await _refreshTokenBinding.restore();
    update(
      (s) => s.copyWith(
        statusMessage: restored
            ? 'Refresh token restored into memory.'
            : 'No persisted refresh token found.',
      ),
    );
    return restored;
  }

  Future<void> deletePersistedRefreshToken() async {
    await _refreshTokenBinding.deletePersisted();
    update(
      (s) => s.copyWith(statusMessage: 'Persisted refresh token deleted.'),
    );
  }

  void clearInMemorySecrets() {
    batch(() {
      state.accessToken.clear();
      state.refreshToken.clear();
    });
    update(
      (s) => s.copyWith(
        statusMessage: 'In-memory access and refresh tokens cleared.',
      ),
    );
  }

  void _setFieldValue(SafeData<String> field, String rawValue) {
    final next = rawValue.trim();
    if (next.isEmpty) {
      field.clear();
      return;
    }
    field.set(next);
  }

  void _applyGrant(AuthGrant grant) {
    batch(() {
      state.accessToken.set(grant.accessToken);
      state.refreshToken.set(grant.refreshToken);
    });
  }
}
