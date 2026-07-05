import 'user_role.dart';

/// Granular permissions for role-based access control.
enum AppPermission {
  // Dashboard
  viewDashboard('view_dashboard'),

  // Vehicles
  viewVehicles('view_vehicles'),
  createVehicle('create_vehicle'),
  editVehicle('edit_vehicle'),
  deleteVehicle('delete_vehicle'),

  // Rentals
  viewRentals('view_rentals'),
  createRental('create_rental'),
  editRental('edit_rental'),
  cancelRental('cancel_rental'),

  // Services
  viewServices('view_services'),
  createService('create_service'),
  editService('edit_service'),
  completeService('complete_service'),

  // Trading
  viewTrading('view_trading'),
  createSale('create_sale'),

  // Customers
  viewCustomers('view_customers'),
  manageCustomers('manage_customers'),

  // Users & settings
  viewUsers('view_users'),
  manageUsers('manage_users'),
  viewSettings('view_settings'),
  manageSettings('manage_settings'),
  viewReports('view_reports'),
  manageReports('manage_reports');

  const AppPermission(this.code);

  final String code;
}

/// Maps roles to their granted permissions.
abstract final class RolePermissions {
  static const Set<AppPermission> _employeePermissions = {
    AppPermission.viewDashboard,
    AppPermission.viewVehicles,
    AppPermission.createVehicle,
    AppPermission.editVehicle,
    AppPermission.viewRentals,
    AppPermission.createRental,
    AppPermission.editRental,
    AppPermission.viewServices,
    AppPermission.createService,
    AppPermission.editService,
    AppPermission.completeService,
    AppPermission.viewTrading,
    AppPermission.createSale,
    AppPermission.viewCustomers,
    AppPermission.manageCustomers,
    AppPermission.viewSettings,
  };

  static const Set<AppPermission> _administratorPermissions = {
    ..._employeePermissions,
    AppPermission.deleteVehicle,
    AppPermission.cancelRental,
    AppPermission.viewUsers,
    AppPermission.manageUsers,
    AppPermission.manageSettings,
    AppPermission.viewReports,
    AppPermission.manageReports,
  };

  static Set<AppPermission> forRole(UserRole role) {
    return switch (role) {
      UserRole.administrator => _administratorPermissions,
      UserRole.employee => _employeePermissions,
    };
  }

  static bool hasPermission(UserRole role, AppPermission permission) {
    return forRole(role).contains(permission);
  }
}
