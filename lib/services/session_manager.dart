import 'dart:async';
import '../domain/entities/user.dart';

/// Mengelola session pengguna yang sedang login
/// Termasuk auto-logout setelah timeout
class SessionManager {
  User? _currentUser;
  Timer? _sessionTimer;
  int _timeoutMinutes = 15;
  VoidCallback? _onSessionExpired;

  /// User yang sedang login
  User? get currentUser => _currentUser;

  /// Apakah ada user yang login
  bool get isLoggedIn => _currentUser != null;

  /// Set callback saat session expired
  set onSessionExpired(VoidCallback? callback) {
    _onSessionExpired = callback;
  }

  /// Set timeout duration
  set timeoutMinutes(int minutes) {
    _timeoutMinutes = minutes;
  }

  /// Login user — start session timer
  void login(User user) {
    _currentUser = user;
    _resetTimer();
  }

  /// Logout user — clear session
  void logout() {
    _currentUser = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Reset timer (dipanggil setiap ada aktivitas user)
  void resetActivity() {
    if (_currentUser != null) {
      _resetTimer();
    }
  }

  /// Reset session timer
  void _resetTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(minutes: _timeoutMinutes), () {
      _currentUser = null;
      _onSessionExpired?.call();
    });
  }

  /// Cek apakah user memiliki role tertentu atau lebih tinggi
  bool hasAccess(UserRole requiredRole) {
    if (_currentUser == null) return false;
    return _currentUser!.role.hasAccessLevel(requiredRole);
  }

  /// Cek apakah user bisa melakukan aksi supervisor
  bool get canSupervise => _currentUser?.canSupervise ?? false;

  /// Cek apakah user adalah owner
  bool get isOwner => _currentUser?.isOwner ?? false;

  /// Dispose timer
  void dispose() {
    _sessionTimer?.cancel();
  }
}

typedef VoidCallback = void Function();
