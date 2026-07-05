import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return ResponsiveBuilder(
      mobile: (context) => _MobileShell(
        currentRoute: currentRoute,
        user: user,
        child: child,
      ),
      tablet: (context) => _TabletShell(
        currentRoute: currentRoute,
        user: user,
        child: child,
      ),
      desktop: (context) => _DesktopShell(
        currentRoute: currentRoute,
        user: user,
        child: child,
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({
    required this.currentRoute,
    required this.user,
    required this.child,
  });

  final String currentRoute;
  final dynamic user;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _visibleDestinations(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRoute(currentRoute)),
        actions: [
          if (user != null) _UserAvatarMenu(user: user),
        ],
      ),
      drawer: _AppDrawer(
        currentRoute: currentRoute,
        destinations: destinations,
        user: user,
      ),
      body: child,
      bottomNavigationBar: destinations.length <= 5
          ? NavigationBar(
              selectedIndex: _selectedIndex(destinations, currentRoute),
              onDestinationSelected: (index) =>
                  context.go(destinations[index].route),
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

class _TabletShell extends ConsumerWidget {
  const _TabletShell({
    required this.currentRoute,
    required this.user,
    required this.child,
  });

  final String currentRoute;
  final dynamic user;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _visibleDestinations(ref);
    final selectedIndex = _selectedIndex(destinations, currentRoute);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                context.go(destinations[index].route),
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.directions_car_filled,
                color: context.colorScheme.primary,
                size: 32,
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: user != null ? _UserAvatarMenu(user: user) : null,
                ),
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _ShellHeader(title: _titleForRoute(currentRoute)),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({
    required this.currentRoute,
    required this.user,
    required this.child,
  });

  final String currentRoute;
  final dynamic user;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _visibleDestinations(ref);
    final selectedIndex = _selectedIndex(destinations, currentRoute);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: context.screenWidth >= Breakpoints.desktop,
            minExtendedWidth: Breakpoints.extendedNavigationRailWidth,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                context.go(destinations[index].route),
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_filled,
                    color: context.colorScheme.primary,
                    size: 36,
                  ),
                  if (context.screenWidth >= Breakpoints.desktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appName,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: user != null
                      ? _UserAvatarMenu(user: user, showName: true)
                      : null,
                ),
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _ShellHeader(title: _titleForRoute(currentRoute)),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        title,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.currentRoute,
    required this.destinations,
    required this.user,
  });

  final String currentRoute;
  final List<NavItem> destinations;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(user?.initials ?? '?'),
            ),
            decoration: BoxDecoration(color: context.colorScheme.primary),
          ),
          Expanded(
            child: ListView(
              children: destinations
                  .map(
                    (d) => ListTile(
                      leading: Icon(
                        currentRoute == d.route ? d.selectedIcon : d.icon,
                      ),
                      title: Text(d.label),
                      selected: currentRoute == d.route,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(d.route);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatarMenu extends ConsumerWidget {
  const _UserAvatarMenu({required this.user, this.showName = false});

  final dynamic user;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(user.initials, style: const TextStyle(fontSize: 12)),
            ),
            if (showName) ...[
              const SizedBox(width: 8),
              Text(user.displayName, style: context.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            title: Text(user.displayName),
            subtitle: Text(user.role.label),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => context.go(AppRoutes.settings),
        ),
        PopupMenuItem(
          value: 'logout',
          child: const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

class NavItem {
  const NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

List<NavItem> _visibleDestinations(WidgetRef ref) {
  final all = AppNavigation.destinations;
  return all
      .where((dest) {
        if (dest.permission == null) return true;
        final permission = AppNavigation.permissionFromCode(dest.permission);
        if (permission == null) return true;
        return ref.watch(hasPermissionProvider(permission));
      })
      .map(
        (d) => NavItem(
          route: d.route,
          label: d.label,
          icon: d.icon,
          selectedIcon: d.selectedIcon,
        ),
      )
      .toList();
}

int _selectedIndex(List<NavItem> destinations, String currentRoute) {
  final index = destinations.indexWhere((d) => d.route == currentRoute);
  return index >= 0 ? index : 0;
}

String _titleForRoute(String route) {
  final dest = AppNavigation.destinations
      .where((d) => d.route == route)
      .firstOrNull;
  return dest?.label ?? 'DM Auto OS';
}
