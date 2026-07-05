import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/cashbook.dart';

class CashbookEntryTile extends StatelessWidget {
  const CashbookEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  final CashbookEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = entry.isIncome;
    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    final amountText = entry.currency.isDefault
        ? CurrencyFormatter.formatXaf(entry.amountXaf)
        : '${CurrencyFormatter.format(entry.amountOriginal, currency: entry.currency)} → ${CurrencyFormatter.formatXaf(entry.amountXaf)}';

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
                radius: 18,
                backgroundColor: amountColor.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: amountColor),
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
                            entry.description,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'} $amountText',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.categoryLabel} · ${DateFormat.yMMMd().format(entry.entryDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.customerName != null ||
                        entry.vehicleLabel != null ||
                        entry.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (entry.customerName != null)
                            'Customer: ${entry.customerName}',
                          if (entry.vehicleLabel != null)
                            'Vehicle: ${entry.vehicleLabel}',
                          if (entry.notes != null) entry.notes,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!entry.currency.isDefault)
                          _ChipLabel(text: entry.currency.code),
                        if (entry.hasAttachment) ...[
                          const SizedBox(width: 6),
                          const _ChipLabel(
                            text: 'Attachment',
                            icon: Icons.attach_file,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          'Balance ${CurrencyFormatter.formatCompact(entry.runningBalanceXaf)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete entry',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12),
            const SizedBox(width: 4),
          ],
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
