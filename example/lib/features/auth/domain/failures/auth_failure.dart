import 'package:flutter_stasis/flutter_stasis.dart';

class AuthFailure extends StateFailure {
  const AuthFailure(super.message);

  const AuthFailure.missingPassword() : super('Enter the demo password first.');
  const AuthFailure.invalidPassword()
    : super('Use the demo password "stasis123".');
  const AuthFailure.missingOtp() : super('Enter the demo OTP code first.');
  const AuthFailure.invalidOtp() : super('Use the demo OTP "654321".');
}
