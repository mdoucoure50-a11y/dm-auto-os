import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('User Management', style: context.textTheme.titleLarge),
              PermissionGuard(
                permission: AppPermission.manageUsers,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add User'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: const EmptyState(
              title: 'No users to display',
              subtitle: 'Manage employee accounts and roles here.',
              icon: Icons.people_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
