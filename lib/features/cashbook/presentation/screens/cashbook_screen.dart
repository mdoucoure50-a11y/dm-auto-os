import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/empty_state.dart';

class CashbookScreen extends ConsumerWidget {
  const CashbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cashbook', style: context.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Income & expense ledger with running XAF balance',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: EmptyState(
              title: 'No cashbook entries',
              subtitle:
                  'Record income and expenses to track your daily cash position.',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
