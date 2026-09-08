import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStartedEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmittedEvent({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class QuickDemoLoginEvent extends AuthEvent {
  final String role;

  const QuickDemoLoginEvent(this.role);

  @override
  List<Object?> get props => [role];
}

class LogoutSubmittedEvent extends AuthEvent {}
