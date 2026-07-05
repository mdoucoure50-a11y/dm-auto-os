import 'user_role.dart';

/// Granular permissions for role-based access control.
enum AppPermission {
  // Dashboard
  viewDashboard('view_dashboard'),

  // Phase 1 — Primary modules
  viewRentals('view_rentals'),
  createRental('create_rental'),
  editRental('edit_rental'),
  cancelRental('cancel_rental'),

  viewCashbook('view_cashbook'),
  manageCashbook('manage_cashbook'),

  viewRentalPeriods('view_rental_periods'),
  manageRentalPeriods('manage_rental_periods'),
  closeRentalPeriod('close_rental_period'),

  viewVehicleProfitability('view_vehicle_profitability'),

  viewCustomers('view_customers'),
  manageCustomers('manage_customers'),

  viewDrivers('view_drivers'),
  manageDrivers('manage_drivers'),

  viewDocuments('view_documents'),
  manageDocuments('manage_documents'),

  // Fleet (supports rentals & profitability)
  viewVehicles('view_vehicles'),
  createVehicle('create_vehicle'),
  editVehicle('edit_vehicle'),
  deleteVehicle('delete_vehicle'),

  // Phase 2 — Secondary modules (Workshop)
  viewServices('view_services'),
  createService('create_service'),
  editService('edit_service'),
  completeService('complete_service'),

  viewTrading('view_trading'),
  createSale('create_sale'),

  // Administration
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
    // Phase 1
    AppPermission.viewRentals,
    AppPermission.createRental,
    AppPermission.editRental,
    AppPermission.viewCashbook,
    AppPermission.manageCashbook,
    AppPermission.viewRentalPeriods,
    AppPermission.manageRentalPeriods,
    AppPermission.viewVehicleProfitability,
    AppPermission.viewCustomers,
    AppPermission.manageCustomers,
    AppPermission.viewDrivers,
    AppPermission.manageDrivers,
    AppPermission.viewDocuments,
    AppPermission.manageDocuments,
    // Fleet
    AppPermission.viewVehicles,
    AppPermission.createVehicle,
    AppPermission.editVehicle,
    // Secondary — Workshop (optional)
    AppPermission.viewServices,
    AppPermission.createService,
    AppPermission.editService,
    AppPermission.completeService,
    AppPermission.viewTrading,
    AppPermission.createSale,
    AppPermission.viewSettings,
  };

  static const Set<AppPermission> _administratorPermissions = {
    ..._employeePermissions,
    AppPermission.cancelRental,
    AppPermission.closeRentalPeriod,
    AppPermission.deleteVehicle,
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
