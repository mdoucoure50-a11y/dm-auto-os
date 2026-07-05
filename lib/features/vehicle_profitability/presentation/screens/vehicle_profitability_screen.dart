import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class VehicleProfitabilityScreen extends ConsumerWidget {
  const VehicleProfitabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Profitability', style: context.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Per-vehicle income vs expense analysis (XAF)',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: EmptyState(
              title: 'No profitability data',
              subtitle:
                  'Profitability is calculated from cashbook income and vehicle expenses.',
              icon: Icons.trending_up_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
