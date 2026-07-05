import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return ContentContainer(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${user?.displayName ?? 'User'}',
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s an overview of your business today',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _StatsGrid(),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _QuickActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveLayout.value(
      context: context,
      mobile: 2,
      tablet: 2,
      desktop: 4,
    );

    final stats = [
      _StatCardData(
        title: 'Available Vehicles',
        value: '24',
        icon: Icons.directions_car,
        color: context.colorScheme.primary,
      ),
      _StatCardData(
        title: 'Active Rentals',
        value: '8',
        icon: Icons.key,
        color: context.colorScheme.secondary,
      ),
      _StatCardData(
        title: 'Service Orders',
        value: '5',
        icon: Icons.build,
        color: context.colorScheme.tertiary,
      ),
      _StatCardData(
        title: 'Revenue (Month)',
        value: CurrencyFormatter.formatCompact(4500000),
        icon: Icons.payments,
        color: context.colorScheme.primary,
        subtitle: CurrencyConstants.code,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveLayout.isMobile(context) ? 1.4 : 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _StatCard(data: stats[index]),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(data.icon, color: data.color),
                if (data.subtitle != null)
                  Text(
                    data.subtitle!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data.title,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        PermissionGuard(
          permission: AppPermission.createRental,
          child: _ActionChip(
            label: 'New Rental',
            icon: Icons.key,
            onTap: () {},
          ),
        ),
        PermissionGuard(
          permission: AppPermission.manageCashbook,
          child: _ActionChip(
            label: 'Cashbook Entry',
            icon: Icons.account_balance_wallet,
            onTap: () {},
          ),
        ),
        PermissionGuard(
          permission: AppPermission.manageRentalPeriods,
          child: _ActionChip(
            label: 'Close Period',
            icon: Icons.event_available,
            onTap: () {},
          ),
        ),
        PermissionGuard(
          permission: AppPermission.manageCustomers,
          child: _ActionChip(
            label: 'Add Customer',
            icon: Icons.person_add,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
