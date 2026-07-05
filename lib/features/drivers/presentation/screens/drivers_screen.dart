import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Drivers', style: context.textTheme.titleLarge),
              PermissionGuard(
                permission: AppPermission.manageDrivers,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Driver'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: EmptyState(
              title: 'No drivers yet',
              subtitle: 'Register drivers and assign them to rentals.',
              icon: Icons.badge_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
