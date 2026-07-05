import 'package:flutter/material.dart';

import '../permissions/app_permission.dart';

/// Application route paths and names.
abstract final class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Main shell
  static const String dashboard = '/';
  static const String vehicles = '/vehicles';
  static const String rentals = '/rentals';
  static const String services = '/services';
  static const String trading = '/trading';
  static const String settings = '/settings';
  static const String users = '/users';
  static const String reports = '/reports';

  static const List<String> publicRoutes = [login, forgotPassword];
}

/// Navigation destination metadata.
class NavDestination {
  const NavDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.permission,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? permission;
}

/// All navigation destinations with required permissions.
abstract final class AppNavigation {
  static const destinations = <NavDestination>[
    NavDestination(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    NavDestination(
      route: AppRoutes.vehicles,
      label: 'Vehicles',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      permission: 'view_vehicles',
    ),
    NavDestination(
      route: AppRoutes.rentals,
      label: 'Rentals',
      icon: Icons.key_outlined,
      selectedIcon: Icons.key,
      permission: 'view_rentals',
    ),
    NavDestination(
      route: AppRoutes.services,
      label: 'Services',
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      permission: 'view_services',
    ),
    NavDestination(
      route: AppRoutes.trading,
      label: 'Trading',
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell,
      permission: 'view_trading',
    ),
    NavDestination(
      route: AppRoutes.reports,
      label: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      permission: 'view_reports',
    ),
    NavDestination(
      route: AppRoutes.users,
      label: 'Users',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      permission: 'view_users',
    ),
    NavDestination(
      route: AppRoutes.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      permission: 'view_settings',
    ),
  ];

  static AppPermission? permissionFromCode(String? code) {
    if (code == null) return AppPermission.viewDashboard;
    for (final permission in AppPermission.values) {
      if (permission.code == code) return permission;
    }
    return null;
  }
}
