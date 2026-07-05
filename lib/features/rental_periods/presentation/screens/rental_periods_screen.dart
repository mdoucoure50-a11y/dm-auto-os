import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class RentalPeriodsScreen extends ConsumerWidget {
  const RentalPeriodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rental Period Closing',
                      style: context.textTheme.titleLarge,
                    ),
                    Text(
                      'Group rentals and close billing periods',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PermissionGuard(
                permission: AppPermission.manageRentalPeriods,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Period'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: EmptyState(
              title: 'No rental periods',
              subtitle:
                  'Create a period to group rentals and close with income/expense totals.',
              icon: Icons.event_available_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
