import 'app_permission.dart';
import 'user_role.dart';

/// Service for evaluating role-based permissions.
class PermissionService {
  const PermissionService();

  bool can(UserRole role, AppPermission permission) {
    return RolePermissions.hasPermission(role, permission);
  }

  bool canAny(UserRole role, List<AppPermission> permissions) {
    return permissions.any((p) => can(role, p));
  }

  bool canAll(UserRole role, List<AppPermission> permissions) {
    return permissions.every((p) => can(role, p));
  }

  List<AppPermission> permissionsFor(UserRole role) {
    return RolePermissions.forRole(role).toList();
  }
}
