import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/rental_period.dart';
import '../../../../providers/rental_period_provider.dart';
import '../widgets/rental_period_report_view.dart';

class RentalPeriodDetailScreen extends ConsumerWidget {
  const RentalPeriodDetailScreen({super.key, required this.periodId});

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodAsync = ref.watch(rentalPeriodProvider(periodId));
    final canClose =
        ref.watch(hasPermissionProvider(AppPermission.closeRentalPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Period'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: periodAsync.when(
        data: (period) {
          if (period == null) {
            return const Center(child: Text('Period not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(period.name, style: context.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${DateFormat.yMMMd().format(period.startDate)} – ${DateFormat.yMMMd().format(period.endDate)}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      period.isLocked ? Icons.lock : Icons.lock_open,
                      size: 16,
                    ),
                    label: Text(
                      period.isLocked ? 'Closed & Locked' : period.status.code,
                    ),
                  ),
                  if (period.rentalCount > 0)
                    Chip(label: Text('${period.rentalCount} rentals')),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        'Revenue',
                        CurrencyFormatter.formatXaf(period.totalIncomeXaf),
                      ),
                      _Row(
                        'Expenses',
                        CurrencyFormatter.formatXaf(period.totalExpenseXaf),
                      ),
                      const Divider(),
                      _Row(
                        'Net',
                        CurrencyFormatter.formatXaf(period.netBalanceXaf),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (period.canClose && canClose)
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/rental-periods/$periodId/close'),
                  icon: const Icon(Icons.lock),
                  label: const Text('Close & Lock Period'),
                ),
              if (period.hasReport)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/rental-periods/$periodId/report'),
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('View Closing Report'),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class RentalPeriodCloseScreen extends ConsumerStatefulWidget {
  const RentalPeriodCloseScreen({super.key, required this.periodId});

  final String periodId;

  @override
  ConsumerState<RentalPeriodCloseScreen> createState() =>
      _RentalPeriodCloseScreenState();
}

class _RentalPeriodCloseScreenState
    extends ConsumerState<RentalPeriodCloseScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(rentalPeriodProvider(widget.periodId));
    final saveState = ref.watch(rentalPeriodControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Close Rental Period'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: periodAsync.when(
        data: (period) {
          if (period == null) {
            return const Center(child: Text('Period not found'));
          }

          if (!period.canClose) {
            return const Center(
              child: Text('This period is already closed and locked.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Closing will lock this period permanently and generate a '
                  'report with revenue, expenses, profit, and vehicle rankings.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Closing notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: saveState.isLoading ? null : () => _close(period),
                  icon: const Icon(Icons.lock),
                  label: saveState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Close Period & Generate Report'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _close(RentalPeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm period closing'),
        content: Text(
          'Close and lock "${period.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Period'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final report = await ref
          .read(rentalPeriodControllerProvider.notifier)
          .closePeriod(
            widget.periodId,
            closingNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (!mounted) return;
      context.go('/rental-periods/${widget.periodId}/report');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Period closed. Net profit: ${CurrencyFormatter.formatXaf(report.netProfitXaf)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class RentalPeriodReportScreen extends ConsumerWidget {
  const RentalPeriodReportScreen({super.key, required this.periodId});

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rentalPeriodReportProvider(periodId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Closing Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }
          return RentalPeriodReportView(report: report);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: bold
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
