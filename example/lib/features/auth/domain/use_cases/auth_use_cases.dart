import 'dart:async';

import 'package:flutter_stasis/flutter_stasis.dart';

import '../entities/auth_challenge.dart';
import '../entities/auth_grant.dart';
import '../failures/auth_failure.dart';

class DemoAuthRepository {
  int _tokenVersion = 0;

  Future<AuthChallenge> requestOtp(String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (password != 'stasis123') {
      throw const AuthFailure.invalidPassword();
    }

    return const AuthChallenge(
      destinationHint: 'demo@stasis.dev',
      demoCode: '654321',
    );
  }

  Future<AuthGrant> verifyOtp(String otp) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (otp != '654321') {
      throw const AuthFailure.invalidOtp();
    }

    _tokenVersion++;
    final issuedAt = DateTime.now();
    return AuthGrant(
      userId: 'demo-user',
      email: 'demo@stasis.dev',
      accessToken: 'access-token-$_tokenVersion',
      refreshToken: 'refresh-token-$_tokenVersion',
      issuedAt: issuedAt,
    );
  }
}

class RequestOtpUseCase {
  RequestOtpUseCase(this._repository);

  final DemoAuthRepository _repository;

  Future<CommandResult<AuthFailure, AuthChallenge>> call(
    String password,
  ) async {
    if (password.trim().isEmpty) {
      return const CommandFailure(AuthFailure.missingPassword());
    }

    try {
      final challenge = await _repository.requestOtp(password.trim());
      return CommandSuccess(challenge);
    } on AuthFailure catch (failure) {
      return CommandFailure(failure);
    }
  }
}

class VerifyOtpUseCase {
  VerifyOtpUseCase(this._repository);

  final DemoAuthRepository _repository;

  Future<CommandResult<AuthFailure, AuthGrant>> call(String otp) async {
    if (otp.trim().isEmpty) {
      return const CommandFailure(AuthFailure.missingOtp());
    }

    try {
      final grant = await _repository.verifyOtp(otp.trim());
      return CommandSuccess(grant);
    } on AuthFailure catch (failure) {
      return CommandFailure(failure);
    }
  }
}
