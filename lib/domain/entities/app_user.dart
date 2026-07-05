import 'package:equatable/equatable.dart';

import '../../core/permissions/user_role.dart';

/// Authenticated user with profile data.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;

  bool get isAdministrator => role.isAdministrator;

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    phone,
    avatarUrl,
    isActive,
  ];
}
