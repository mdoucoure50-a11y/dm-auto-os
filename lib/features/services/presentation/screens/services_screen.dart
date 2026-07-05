import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_modules.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

/// Workshop / service orders — optional secondary module (Phase 2).
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workshop = AppModule.workshopModule;

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
                    Text('Workshop', style: context.textTheme.titleLarge),
                    Text(
                      workshop.description ?? 'Optional service orders',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PermissionGuard(
                permission: AppPermission.createService,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Order'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.info_outline, size: 16),
            label: const Text('Secondary module — Phase 2 development'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: EmptyState(
              title: 'No service orders',
              subtitle:
                  'Workshop jobs are optional. Vehicle assignment is not required.',
              icon: Icons.build_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
