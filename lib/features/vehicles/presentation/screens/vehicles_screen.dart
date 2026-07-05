import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fleet Management', style: context.textTheme.titleLarge),
              PermissionGuard(
                permission: AppPermission.createVehicle,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: const EmptyState(
              title: 'No vehicles yet',
              subtitle: 'Add your first vehicle to start managing your fleet.',
              icon: Icons.directions_car_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
