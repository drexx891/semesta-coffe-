import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State awal
class AuthInitial extends AuthState {}

/// Sedang memproses login
class AuthLoading extends AuthState {}

/// Login berhasil
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Belum login / sudah logout
class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// Login gagal
class AuthError extends AuthState {
  final String message;
  final int? remainingAttempts;

  const AuthError({required this.message, this.remainingAttempts});

  @override
  List<Object?> get props => [message, remainingAttempts];
}

/// Akun terkunci
class AuthLocked extends AuthState {
  final DateTime lockedUntil;

  const AuthLocked({required this.lockedUntil});

  @override
  List<Object?> get props => [lockedUntil];
}

/// PIN validasi berhasil
class PinValidated extends AuthState {
  final User validator;

  const PinValidated({required this.validator});

  @override
  List<Object?> get props => [validator];
}

/// PIN validasi gagal
class PinValidationFailed extends AuthState {
  const PinValidationFailed();
}
