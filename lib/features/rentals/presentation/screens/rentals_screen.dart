import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class RentalsScreen extends ConsumerWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vehicle Rentals', style: context.textTheme.titleLarge),
              PermissionGuard(
                permission: AppPermission.createRental,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Rental'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: const EmptyState(
              title: 'No rentals yet',
              subtitle: 'Create a rental agreement to get started.',
              icon: Icons.key_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
