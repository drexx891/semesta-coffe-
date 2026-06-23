import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event login
class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

/// Event logout
class LogoutRequested extends AuthEvent {}

/// Event cek session saat app start
class CheckSessionRequested extends AuthEvent {}

/// Event session expired
class SessionExpired extends AuthEvent {}

/// Event validasi PIN supervisor
class ValidatePinRequested extends AuthEvent {
  final String pin;

  const ValidatePinRequested({required this.pin});

  @override
  List<Object?> get props => [pin];
}
