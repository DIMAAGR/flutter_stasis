import 'package:equatable/equatable.dart';

class AuthChallenge extends Equatable {
  const AuthChallenge({required this.destinationHint, required this.demoCode});

  final String destinationHint;
  final String demoCode;

  @override
  List<Object?> get props => [destinationHint, demoCode];
}
