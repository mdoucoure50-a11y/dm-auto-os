import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Orders', style: context.textTheme.titleLarge),
              PermissionGuard(
                permission: AppPermission.createService,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Service'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: const EmptyState(
              title: 'No service orders',
              subtitle: 'Schedule vehicle maintenance and repairs here.',
              icon: Icons.build_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
