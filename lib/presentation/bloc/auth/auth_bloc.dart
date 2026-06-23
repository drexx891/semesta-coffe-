// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/dao/user_dao.dart';
import '../../../data/database/dao/settings_dao.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/activity_log.dart';
import '../../../services/session_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC untuk autentikasi dan manajemen session
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserDao _userDao;
  final SettingsDao _settingsDao;
  final SessionManager _sessionManager;

  static const int _maxLoginAttempts = 5;
  static const int _lockDurationMinutes = 10;

  AuthBloc({
    required UserDao userDao,
    required SettingsDao settingsDao,
    required SessionManager sessionManager,
  })  : _userDao = userDao,
        _settingsDao = settingsDao,
        _sessionManager = sessionManager,
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckSessionRequested>(_onCheckSession);
    on<SessionExpired>(_onSessionExpired);
    on<ValidatePinRequested>(_onValidatePin);

    // Set session expired callback
    _sessionManager.onSessionExpired = () {
      add(SessionExpired());
    };
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Cari user by username dulu untuk cek status lock
      final userMap = await _userDao.getByUsername(event.username);

      if (userMap == null) {
        emit(const AuthError(message: 'Username atau password salah'));
        return;
      }

      // Cek apakah akun aktif
      if (userMap['is_active'] != 1) {
        emit(const AuthError(message: 'Akun tidak aktif. Hubungi Owner.'));
        return;
      }

      // Cek apakah akun terkunci
      final lockedUntil = userMap['locked_until'] as String?;
      if (lockedUntil != null) {
        final lockTime = DateTime.parse(lockedUntil);
        if (DateTime.now().isBefore(lockTime)) {
          emit(AuthLocked(lockedUntil: lockTime));
          return;
        }
      }

      // Autentikasi
      final authenticated = await _userDao.authenticate(event.username, event.password);

      if (authenticated == null) {
        // Login gagal — increment counter
        final failedCount = (userMap['failed_login_count'] as int) + 1;
        await _userDao.incrementFailedLogin(userMap['id'] as int);

        if (failedCount >= _maxLoginAttempts) {
          // Lock account
          final lockUntil = DateTime.now().add(const Duration(minutes: _lockDurationMinutes));
          await _userDao.lockAccount(userMap['id'] as int, lockUntil);
          emit(AuthLocked(lockedUntil: lockUntil));
        } else {
          emit(AuthError(
            message: 'Username atau password salah',
            remainingAttempts: _maxLoginAttempts - failedCount,
          ));
        }
        return;
      }

      // Login berhasil — reset failed count
      await _userDao.resetFailedLogin(authenticated['id'] as int);

      // Buat User entity
      final user = _mapToUser(authenticated);

      // Load timeout setting
      final settings = await _settingsDao.getSettings();
      if (settings != null) {
        _sessionManager.timeoutMinutes = settings['session_timeout_minutes'] as int? ?? 15;
      }

      // Start session
      _sessionManager.login(user);

      // Log aktivitas
      await _settingsDao.insertLog({
        'user_id': user.id,
        'action_type': LogActionType.login,
        'description': 'Login berhasil: ${user.name} (${user.role.displayName})',
        'created_at': DateTime.now().toIso8601String(),
      });

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  /// Handle logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _sessionManager.currentUser;
    if (user != null) {
      await _settingsDao.insertLog({
        'user_id': user.id,
        'action_type': LogActionType.logout,
        'description': 'Logout: ${user.name}',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    _sessionManager.logout();
    emit(const AuthUnauthenticated());
  }

  /// Handle session check saat app start
  Future<void> _onCheckSession(
    CheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Untuk saat ini, selalu mulai dari login
    // Di masa depan bisa implementasi persistent session
    emit(const AuthUnauthenticated());
  }

  /// Handle session expired
  void _onSessionExpired(
    SessionExpired event,
    Emitter<AuthState> emit,
  ) {
    _sessionManager.logout();
    emit(const AuthUnauthenticated(message: 'Sesi telah berakhir. Silakan masuk kembali.'));
  }

  /// Handle PIN validation untuk aksi supervisor
  Future<void> _onValidatePin(
    ValidatePinRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final validatorMap = await _userDao.validatePin(event.pin);

      if (validatorMap != null) {
        final validator = _mapToUser(validatorMap);
        emit(PinValidated(validator: validator));
      } else {
        emit(const PinValidationFailed());
      }

      // Kembalikan ke state authenticated
      if (_sessionManager.currentUser != null) {
        emit(AuthAuthenticated(user: _sessionManager.currentUser!));
      }
    } catch (e) {
      emit(const PinValidationFailed());
    }
  }

  /// Map database row ke User entity
  User _mapToUser(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      name: map['name'] as String,
      pin: map['pin'] as String?,
      role: UserRole.fromString(map['role'] as String),
      isActive: map['is_active'] == 1,
      failedLoginCount: map['failed_login_count'] as int? ?? 0,
      lockedUntil: map['locked_until'] != null ? DateTime.parse(map['locked_until'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  Future<void> close() {
    _sessionManager.dispose();
    return super.close();
  }
}
