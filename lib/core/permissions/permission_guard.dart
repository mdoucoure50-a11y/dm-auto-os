import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import 'app_permission.dart';
import 'permission_service.dart';
import 'user_role.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);

/// Checks if the current user has the required permission.
final hasPermissionProvider = Provider.family<bool, AppPermission>(
  (ref, permission) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;
    return ref.read(permissionServiceProvider).can(user.role, permission);
  },
);

/// Widget that conditionally renders based on user permissions.
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final AppPermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));
    if (hasPermission) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Route-level permission check that redirects unauthorized users.
class PermissionChecker {
  const PermissionChecker(this._service);

  final PermissionService _service;

  bool canAccess({
    required UserRole? role,
    required AppPermission permission,
  }) {
    if (role == null) return false;
    return _service.can(role, permission);
  }
}
