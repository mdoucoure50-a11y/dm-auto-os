import 'package:equatable/equatable.dart';

import '../../core/permissions/user_role.dart';

/// User profile data from the database.
class UserProfileModel extends Equatable {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'employee'),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role.value,
    'phone': phone,
    'avatar_url': avatarUrl,
    'is_active': isActive,
  };

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
