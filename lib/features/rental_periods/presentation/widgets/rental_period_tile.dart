import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/rental_period.dart';

class RentalPeriodTile extends StatelessWidget {
  const RentalPeriodTile({
    super.key,
    required this.period,
    this.onTap,
    this.trailing,
  });

  final RentalPeriod period;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(period.status, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(_statusIcon(period.status), color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            period.name,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        _StatusChip(status: period.status, isLocked: period.isLocked),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat.yMMMd().format(period.startDate)} – ${DateFormat.yMMMd().format(period.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (period.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text('Customer: ${period.customerName}'),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Metric(
                          label: 'Revenue',
                          value: CurrencyFormatter.formatXaf(period.totalIncomeXaf),
                          color: Colors.green.shade700,
                        ),
                        _Metric(
                          label: 'Expenses',
                          value: CurrencyFormatter.formatXaf(period.totalExpenseXaf),
                          color: Colors.red.shade700,
                        ),
                        _Metric(
                          label: 'Net',
                          value: CurrencyFormatter.formatXaf(period.netBalanceXaf),
                          color: period.netBalanceXaf >= 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(RentalPeriodStatus status, ThemeData theme) {
    return switch (status) {
      RentalPeriodStatus.active => theme.colorScheme.primary,
      RentalPeriodStatus.closed => theme.colorScheme.tertiary,
      RentalPeriodStatus.cancelled => theme.colorScheme.error,
      _ => theme.colorScheme.outline,
    };
  }

  IconData _statusIcon(RentalPeriodStatus status) {
    return switch (status) {
      RentalPeriodStatus.active => Icons.lock_open,
      RentalPeriodStatus.closed => Icons.lock,
      _ => Icons.event,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isLocked});

  final RentalPeriodStatus status;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final label = status.isClosed && isLocked ? 'Closed & Locked' : status.code;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelMedium,
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
