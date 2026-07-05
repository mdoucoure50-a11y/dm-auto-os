import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports & Analytics', style: context.textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: const EmptyState(
              title: 'Reports coming soon',
              subtitle:
                  'View revenue, rental performance, and fleet analytics.',
              icon: Icons.analytics_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
