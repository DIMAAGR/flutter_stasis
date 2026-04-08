import 'package:equatable/equatable.dart';

import 'auth_grant.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.issuedAt,
  });

  factory AuthSession.fromGrant(AuthGrant grant) {
    return AuthSession(
      userId: grant.userId,
      email: grant.email,
      issuedAt: grant.issuedAt,
    );
  }

  final String userId;
  final String email;
  final DateTime issuedAt;

  @override
  List<Object?> get props => [userId, email, issuedAt];
}
