import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/cashbook/presentation/screens/cashbook_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/drivers/presentation/screens/drivers_screen.dart';
import '../../features/rental_periods/presentation/screens/rental_periods_screen.dart';
import '../../features/rentals/presentation/screens/rentals_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/app_shell.dart';
import '../../features/trading/presentation/screens/trading_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/vehicle_profitability/presentation/screens/vehicle_profitability_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../../providers/auth_provider.dart';
import '../permissions/permission_guard.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final permissionService = ref.watch(permissionServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final isPublicRoute = AppRoutes.publicRoutes.contains(state.matchedLocation);

      if (isLoading) return null;

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.dashboard;
      }

      if (isAuthenticated && !isPublicRoute) {
        final destination = AppNavigation.destinations
            .where((d) => d.route == state.matchedLocation)
            .firstOrNull;

        if (destination?.permission != null) {
          final permission = AppNavigation.permissionFromCode(
            destination!.permission,
          );
          if (permission != null &&
              !permissionService.can(user.role, permission)) {
            return AppRoutes.dashboard;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.rentals,
            name: 'rentals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RentalsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cashbook,
            name: 'cashbook',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CashbookScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.rentalPeriods,
            name: 'rentalPeriods',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RentalPeriodsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.vehicleProfitability,
            name: 'vehicleProfitability',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehicleProfitabilityScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.customers,
            name: 'customers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.drivers,
            name: 'drivers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DriversScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.documents,
            name: 'documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.vehicles,
            name: 'vehicles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehiclesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.workshop,
            name: 'workshop',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ServicesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.trading,
            name: 'trading',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TradingScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
