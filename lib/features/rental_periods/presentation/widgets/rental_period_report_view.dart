import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/rental_period.dart';

class RentalPeriodReportView extends StatelessWidget {
  const RentalPeriodReportView({super.key, required this.report});

  final RentalPeriodReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          report.periodName,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${DateFormat.yMMMd().format(report.periodStart)} – ${DateFormat.yMMMd().format(report.periodEnd)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (report.generatedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Generated ${DateFormat.yMMMd().add_jm().format(report.generatedAt!)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        _TotalsCard(report: report),
        const SizedBox(height: 16),
        _RankingCard(
          title: 'Most Profitable Vehicle',
          icon: Icons.trending_up,
          vehicleLabel: report.mostProfitableVehicleLabel,
          metricLabel: 'Profit',
          metricValue: report.mostProfitableVehicleProfitXaf != null
              ? CurrencyFormatter.formatXaf(report.mostProfitableVehicleProfitXaf!)
              : '—',
        ),
        const SizedBox(height: 12),
        _RankingCard(
          title: 'Most Utilized Vehicle',
          icon: Icons.speed,
          vehicleLabel: report.mostUtilizedVehicleLabel,
          metricLabel: 'Rental days',
          metricValue: report.mostUtilizedRentalDays?.toString() ?? '—',
        ),
        const SizedBox(height: 20),
        Text('Profitability by Mission', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (report.missionStats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No mission-assigned rentals in this period.'),
            ),
          )
        else ...[
          if (report.mostProfitableMission != null)
            _RankingCard(
              title: 'Most Profitable Mission',
              icon: Icons.flag_outlined,
              vehicleLabel: report.mostProfitableMission!.missionName,
              metricLabel: 'Profit',
              metricValue: CurrencyFormatter.formatXaf(
                report.mostProfitableMission!.profitXaf,
              ),
            ),
          const SizedBox(height: 8),
          ...report.missionStats.map(
            (stat) => _MissionStatCard(stat: stat),
          ),
        ],
        const SizedBox(height: 20),
        Text('Per Vehicle', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (report.vehicleStats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No vehicle activity recorded for this period.'),
            ),
          )
        else
          ...report.vehicleStats.map(
            (stat) => _VehicleStatCard(stat: stat),
          ),
        if (report.closingNotes != null && report.closingNotes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Closing Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(report.closingNotes!),
            ),
          ),
        ],
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.report});

  final RentalPeriodReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TotalRow(
              label: 'Total Rental Revenue',
              value: CurrencyFormatter.formatXaf(report.totalRentalRevenueXaf),
              color: Colors.green.shade700,
            ),
            const Divider(height: 20),
            _TotalRow(
              label: 'Total Rental Expenses',
              value: CurrencyFormatter.formatXaf(report.totalRentalExpensesXaf),
              color: Colors.red.shade700,
            ),
            const Divider(height: 20),
            _TotalRow(
              label: 'Net Profit',
              value: CurrencyFormatter.formatXaf(report.netProfitXaf),
              color: report.netProfitXaf >= 0
                  ? Colors.green.shade800
                  : Colors.red.shade800,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
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

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.icon,
    required this.vehicleLabel,
    required this.metricLabel,
    required this.metricValue,
  });

  final String title;
  final IconData icon;
  final String? vehicleLabel;
  final String metricLabel;
  final String metricValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(vehicleLabel ?? 'No data'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(metricLabel, style: Theme.of(context).textTheme.labelSmall),
            Text(
              metricValue,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionStatCard extends StatelessWidget {
  const _MissionStatCard({required this.stat});

  final MissionPeriodStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.missionName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (stat.profitRank == 1)
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
              ],
            ),
            if (stat.missionCode != null) ...[
              const SizedBox(height: 2),
              Text(
                stat.missionCode!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Revenue',
                    value: CurrencyFormatter.formatXaf(stat.revenueXaf),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Expenses',
                    value: CurrencyFormatter.formatXaf(stat.expensesXaf),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Profit',
                    value: CurrencyFormatter.formatXaf(stat.profitXaf),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stat.rentalCount} rentals · ${stat.rentalDays} days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatCard extends StatelessWidget {
  const _VehicleStatCard({required this.stat});

  final VehiclePeriodStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${stat.vehicleLabel} (${stat.licensePlate})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (stat.profitRank == 1)
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Revenue',
                    value: CurrencyFormatter.formatXaf(stat.revenueXaf),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Expenses',
                    value: CurrencyFormatter.formatXaf(stat.expensesXaf),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Profit',
                    value: CurrencyFormatter.formatXaf(stat.profitXaf),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stat.rentalCount} rentals · ${stat.rentalDays} days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
