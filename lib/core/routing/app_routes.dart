import 'package:flutter/material.dart';

import '../constants/app_modules.dart';
import '../permissions/app_permission.dart';

/// Application route paths and names.
abstract final class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Main shell — Phase 1 primary modules
  static const String dashboard = '/';
  static const String rentals = '/rentals';
  static const String cashbook = '/cashbook';
  static const String rentalPeriods = '/rental-periods';
  static const String vehicleProfitability = '/vehicle-profitability';
  static const String customers = '/customers';
  static const String drivers = '/drivers';
  static const String documents = '/documents';

  // Supporting & secondary modules
  static const String vehicles = '/vehicles';
  static const String workshop = '/workshop';
  static const String trading = '/trading';
  static const String reports = '/reports';
  static const String users = '/users';
  static const String settings = '/settings';

  /// Legacy alias — redirects to workshop.
  static const String services = workshop;

  static const List<String> publicRoutes = [login, forgotPassword];
}

/// Navigation destination metadata.
class NavDestination {
  const NavDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.tier,
    required this.moduleId,
    this.permission,
    this.showInCompactNav = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ModuleTier tier;
  final AppModuleId moduleId;
  final String? permission;

  /// Shown in mobile bottom navigation bar (max ~4 items).
  final bool showInCompactNav;

  bool get isPrimary => tier == ModuleTier.primary;
  bool get isSecondary => tier == ModuleTier.secondary;
}

/// All navigation destinations ordered by development priority.
abstract final class AppNavigation {
  static const destinations = <NavDestination>[
    NavDestination(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.dashboard,
      showInCompactNav: true,
    ),
    NavDestination(
      route: AppRoutes.rentals,
      label: 'Rentals',
      icon: Icons.key_outlined,
      selectedIcon: Icons.key,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.rentals,
      permission: 'view_rentals',
      showInCompactNav: true,
    ),
    NavDestination(
      route: AppRoutes.cashbook,
      label: 'Cashbook',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.cashbook,
      permission: 'view_cashbook',
      showInCompactNav: true,
    ),
    NavDestination(
      route: AppRoutes.rentalPeriods,
      label: 'Period Closing',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.rentalPeriods,
      permission: 'view_rental_periods',
    ),
    NavDestination(
      route: AppRoutes.vehicleProfitability,
      label: 'Profitability',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.vehicleProfitability,
      permission: 'view_vehicle_profitability',
    ),
    NavDestination(
      route: AppRoutes.customers,
      label: 'Customers',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.customers,
      permission: 'view_customers',
      showInCompactNav: true,
    ),
    NavDestination(
      route: AppRoutes.drivers,
      label: 'Drivers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.drivers,
      permission: 'view_drivers',
    ),
    NavDestination(
      route: AppRoutes.documents,
      label: 'Documents',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      tier: ModuleTier.primary,
      moduleId: AppModuleId.documents,
      permission: 'view_documents',
    ),
    NavDestination(
      route: AppRoutes.vehicles,
      label: 'Fleet',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      tier: ModuleTier.secondary,
      moduleId: AppModuleId.vehicles,
      permission: 'view_vehicles',
    ),
    NavDestination(
      route: AppRoutes.workshop,
      label: 'Workshop',
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      tier: ModuleTier.secondary,
      moduleId: AppModuleId.workshop,
      permission: 'view_services',
    ),
    NavDestination(
      route: AppRoutes.trading,
      label: 'Trading',
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell,
      tier: ModuleTier.secondary,
      moduleId: AppModuleId.trading,
      permission: 'view_trading',
    ),
    NavDestination(
      route: AppRoutes.reports,
      label: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      tier: ModuleTier.admin,
      moduleId: AppModuleId.reports,
      permission: 'view_reports',
    ),
    NavDestination(
      route: AppRoutes.users,
      label: 'Users',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      tier: ModuleTier.admin,
      moduleId: AppModuleId.users,
      permission: 'view_users',
    ),
    NavDestination(
      route: AppRoutes.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      tier: ModuleTier.admin,
      moduleId: AppModuleId.settings,
      permission: 'view_settings',
    ),
  ];

  static List<NavDestination> get primaryDestinations =>
      destinations.where((d) => d.tier == ModuleTier.primary).toList();

  static List<NavDestination> get secondaryDestinations =>
      destinations.where((d) => d.tier == ModuleTier.secondary).toList();

  static List<NavDestination> get compactNavDestinations =>
      destinations.where((d) => d.showInCompactNav).toList();

  static AppPermission? permissionFromCode(String? code) {
    if (code == null) return AppPermission.viewDashboard;
    for (final permission in AppPermission.values) {
      if (permission.code == code) return permission;
    }
    return null;
  }
}
