import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../domain/entities/mission.dart';
import '../../../../providers/cashbook_provider.dart';
import '../../../../providers/rental_provider.dart';

class RentalsScreen extends ConsumerWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(rentalsProvider);
    final canCreate = ref.watch(hasPermissionProvider(AppPermission.createRental));

    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vehicle Rentals',
                  style: context.textTheme.titleLarge,
                ),
              ),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => context.push('${AppRoutes.rentals}/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Rental'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each rental can optionally belong to a mission',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: rentalsAsync.when(
              data: (rentals) {
                if (rentals.isEmpty) {
                  return EmptyState(
                    title: 'No rentals yet',
                    subtitle:
                        'Create a rental agreement and assign it to a mission.',
                    icon: Icons.key_outlined,
                    action: canCreate
                        ? () => context.push('${AppRoutes.rentals}/new')
                        : null,
                    actionLabel: 'New Rental',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(rentalsProvider);
                    await ref.read(rentalsProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: rentals.length,
                    itemBuilder: (context, index) {
                      final rental = rentals[index];
                      return _RentalTile(rental: rental);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                title: 'Unable to load rentals',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalTile extends StatelessWidget {
  const _RentalTile({required this.rental});

  final RentalAgreement rental;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rental.vehicleLabel ?? 'Vehicle',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatXaf(rental.totalAmountXaf),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${rental.customerName ?? 'Customer'} · ${DateFormat.yMMMd().format(rental.startDate)} – ${DateFormat.yMMMd().format(rental.endDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (rental.hasMission) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.flag_outlined, size: 16),
                label: Text(rental.missionName ?? 'Mission'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
