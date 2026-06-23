import 'package:equatable/equatable.dart';

/// Enum untuk role pengguna
enum UserRole {
  owner,
  supervisor,
  cashier;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.cashier:
        return 'Kasir';
    }
  }

  /// Check apakah user memiliki akses lebih tinggi atau sama
  bool hasAccessLevel(UserRole required) {
    return index <= required.index;
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.cashier,
    );
  }
}

/// Entity User
class User extends Equatable {
  final int? id;
  final String username;
  final String passwordHash;
  final String name;
  final String? pin;
  final UserRole role;
  final bool isActive;
  final int failedLoginCount;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.name,
    this.pin,
    required this.role,
    this.isActive = true,
    this.failedLoginCount = 0,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if account is currently locked
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  /// Check if user can perform supervisor-level actions
  bool get canSupervise => role == UserRole.owner || role == UserRole.supervisor;

  /// Check if user is owner
  bool get isOwner => role == UserRole.owner;

  /// Check if user can access reports
  bool get canViewReports => canSupervise;

  /// Check if user can manage menu & stock
  bool get canManageMenu => canSupervise;

  /// Check if user can void transactions
  bool get canVoidTransaction => canSupervise;

  /// Check if user can manage settings
  bool get canManageSettings => isOwner;

  /// Check if user can manage users
  bool get canManageUsers => isOwner;

  /// Check if user can backup/restore
  bool get canBackupRestore => isOwner;

  /// Check if user can view activity logs
  bool get canViewLogs => isOwner;

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? name,
    String? pin,
    UserRole? role,
    bool? isActive,
    int? failedLoginCount,
    DateTime? lockedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      failedLoginCount: failedLoginCount ?? this.failedLoginCount,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, username, name, role, isActive];
}
