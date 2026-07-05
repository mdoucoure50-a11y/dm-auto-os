import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../domain/entities/cashbook.dart';
import '../../../../providers/cashbook_provider.dart';
import '../widgets/cashbook_entry_tile.dart';
import '../widgets/cashbook_filter_sheet.dart';
import '../widgets/cashbook_summary_card.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(cashbookFilterProvider);
    final entriesAsync = ref.watch(cashbookEntriesProvider);
    final dailyAsync = ref.watch(cashbookDailySummaryProvider);
    final periodAsync = ref.watch(cashbookPeriodSummaryProvider);
    final canManage = ref.watch(hasPermissionProvider(AppPermission.manageCashbook));

    final periodLabel = filter.startDate != null && filter.endDate != null
        ? '${DateFormat.yMMMd().format(filter.startDate!)} – ${DateFormat.yMMMd().format(filter.endDate!)}'
        : 'Current month';

    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
                  ],
                ),
              ),
              if (canManage) ...[
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.cashbook}/new?type=expense',
                  ),
                  icon: const Icon(Icons.remove),
                  label: const Text('Expense'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.cashbook}/new?type=income',
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Income'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search description, notes, customer, vehicle...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _updateSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: _updateSearch,
            onChanged: (value) {
              if (value.isEmpty) _updateSearch('');
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Filters'),
                selected: filter.hasActiveFilters,
                onSelected: (_) => _openFilters(context),
                avatar: const Icon(Icons.filter_list, size: 18),
              ),
              if (filter.entryType != null)
                Chip(
                  label: Text(
                    filter.entryType == CashbookEntryType.income
                        ? 'Income'
                        : 'Expense',
                  ),
                  onDeleted: () => _updateFilter(
                    filter.copyWith(clearEntryType: true),
                  ),
                ),
              if (filter.currency != null)
                Chip(
                  label: Text(filter.currency!.code),
                  onDeleted: () => _updateFilter(
                    filter.copyWith(clearCurrency: true),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          periodAsync.when(
            data: (periodSummary) => dailyAsync.when(
              data: (dailySummary) => CashbookSummaryCards(
                dailySummary: dailySummary,
                periodSummary: periodSummary,
                summaryDate: filter.summaryDate ?? DateTime.now(),
                periodLabel: periodLabel,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyState(
                    title: 'No cashbook entries',
                    subtitle: filter.hasActiveFilters ||
                            filter.searchQuery.isNotEmpty
                        ? 'Try adjusting your search or filters.'
                        : 'Record income and expenses to track your daily cash position.',
                    icon: Icons.account_balance_wallet_outlined,
                    action: canManage
                        ? () => context.push(
                              '${AppRoutes.cashbook}/new?type=income',
                            )
                        : null,
                    actionLabel: 'Add Income',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(cashbookEntriesProvider);
                    ref.invalidate(cashbookDailySummaryProvider);
                    ref.invalidate(cashbookPeriodSummaryProvider);
                    await ref.read(cashbookEntriesProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return CashbookEntryTile(
                        entry: entry,
                        onTap: canManage
                            ? () => context.push(
                                  '${AppRoutes.cashbook}/${entry.id}/edit',
                                )
                            : null,
                        onDelete: canManage
                            ? () => _confirmDelete(context, entry.id)
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                title: 'Unable to load cashbook',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateSearch(String query) {
    final current = ref.read(cashbookFilterProvider);
    ref.read(cashbookFilterProvider.notifier).state =
        current.copyWith(searchQuery: query);
  }

  void _updateFilter(CashbookFilter filter) {
    ref.read(cashbookFilterProvider.notifier).state = filter;
  }

  Future<void> _openFilters(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const CashbookFilterSheet(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This will remove the entry from the cashbook ledger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(cashbookControllerProvider.notifier).deleteEntry(entryId);
    }
  }
}
