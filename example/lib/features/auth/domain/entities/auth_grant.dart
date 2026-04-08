import 'package:equatable/equatable.dart';

class AuthGrant extends Equatable {
  const AuthGrant({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.issuedAt,
  });

  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime issuedAt;

  @override
  List<Object?> get props => [
    userId,
    email,
    accessToken,
    refreshToken,
    issuedAt,
  ];
}
