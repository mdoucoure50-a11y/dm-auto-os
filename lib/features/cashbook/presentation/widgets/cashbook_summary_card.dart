import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/cashbook.dart';

class CashbookSummaryCards extends StatelessWidget {
  const CashbookSummaryCards({
    super.key,
    required this.dailySummary,
    required this.periodSummary,
    required this.summaryDate,
    required this.periodLabel,
  });

  final CashbookDailySummary? dailySummary;
  final CashbookPeriodSummary periodSummary;
  final DateTime summaryDate;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMd().format(summaryDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final dailyCard = _SummaryCard(
          title: 'Daily Summary',
          subtitle: dateLabel,
          income: dailySummary?.totalIncomeXaf ?? 0,
          expense: dailySummary?.totalExpenseXaf ?? 0,
          net: dailySummary?.netBalanceXaf ?? 0,
          entryCount: dailySummary?.entryCount ?? 0,
          accentColor: theme.colorScheme.primary,
        );

        final periodCard = _SummaryCard(
          title: 'Period Summary',
          subtitle: periodLabel,
          income: periodSummary.totalIncomeXaf,
          expense: periodSummary.totalExpenseXaf,
          net: periodSummary.netBalanceXaf,
          entryCount: periodSummary.entryCount,
          accentColor: theme.colorScheme.tertiary,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: dailyCard),
              const SizedBox(width: 12),
              Expanded(child: periodCard),
            ],
          );
        }

        return Column(
          children: [
            dailyCard,
            const SizedBox(height: 12),
            periodCard,
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.income,
    required this.expense,
    required this.net,
    required this.entryCount,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final int income;
  final int expense;
  final int net;
  final int entryCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_outlined, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '$entryCount entries',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Income',
              value: CurrencyFormatter.formatXaf(income),
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            _MetricRow(
              label: 'Expense',
              value: CurrencyFormatter.formatXaf(expense),
              color: Colors.red.shade700,
            ),
            const Divider(height: 20),
            _MetricRow(
              label: 'Net',
              value: CurrencyFormatter.formatXaf(net),
              color: net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: style),
      ],
    );
  }
}
