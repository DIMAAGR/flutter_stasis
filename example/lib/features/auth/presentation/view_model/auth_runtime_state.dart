import 'package:flutter_stasis/flutter_stasis.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';

enum AuthStep { idle, awaitingOtp, authenticated }

class AuthRuntimeState
    extends StateObject<AuthFailure, AuthSession, AuthRuntimeState> {
  AuthRuntimeState({
    required super.state,
    required this.password,
    required this.otpCode,
    required this.accessToken,
    required this.refreshToken,
    this.step = AuthStep.idle,
    this.statusMessage = 'Use password stasis123 and OTP 654321.',
    this.isRequestingOtp = false,
    this.isVerifyingOtp = false,
  });

  factory AuthRuntimeState.initial() => AuthRuntimeState(
    state: const InitialState<AuthFailure, AuthSession>(),
    password: SafeData<String>.memoryOnly(
      logStrategy: SafeDataLogStrategy.redacted,
      clearOnCommandSuccess: const {'request-otp'},
    ),
    otpCode: SafeData<String>.memoryOnly(
      expiresAfter: const Duration(seconds: 30),
      clearOnCommandSuccess: const {'verify-otp'},
      logStrategy: SafeDataLogStrategy.masked,
    ),
    accessToken: SafeData<String>.memoryOnly(
      clearOnDispose: true,
      logStrategy: SafeDataLogStrategy.masked,
    ),
    refreshToken: SafeData<String>(
      policy: const SafeDataPolicy(
        clearOnDispose: false,
        persistence: SafeDataPersistence.secureStorage,
        logStrategy: SafeDataLogStrategy.masked,
      ),
    ),
  );

  final SafeData<String> password;
  final SafeData<String> otpCode;
  final SafeData<String> accessToken;
  final SafeData<String> refreshToken;
  final AuthStep step;
  final String statusMessage;
  final bool isRequestingOtp;
  final bool isVerifyingOtp;

  AuthSession? get session => dataOrNull;
  String? get errorMessage => failureOrNull?.message;
  bool get hasAccessTokenInMemory => accessToken.hasValue;
  bool get hasRefreshTokenInMemory => refreshToken.hasValue;

  @override
  AuthRuntimeState withState(ViewModelState<AuthFailure, AuthSession> state) =>
      copyWith(state: state);

  AuthRuntimeState copyWith({
    ViewModelState<AuthFailure, AuthSession>? state,
    AuthStep? step,
    String? statusMessage,
    bool? isRequestingOtp,
    bool? isVerifyingOtp,
  }) {
    return AuthRuntimeState(
      state: state ?? this.state,
      password: password,
      otpCode: otpCode,
      accessToken: accessToken,
      refreshToken: refreshToken,
      step: step ?? this.step,
      statusMessage: statusMessage ?? this.statusMessage,
      isRequestingOtp: isRequestingOtp ?? this.isRequestingOtp,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
    );
  }

  @override
  List<Object?> get props => [
    state,
    step,
    statusMessage,
    isRequestingOtp,
    isVerifyingOtp,
  ];
}
