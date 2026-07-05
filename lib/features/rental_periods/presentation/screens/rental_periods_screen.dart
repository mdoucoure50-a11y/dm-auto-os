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
import '../../../../providers/rental_period_provider.dart';
import '../widgets/rental_period_tile.dart';

enum _PeriodFilter { all, open, closed }

class RentalPeriodsScreen extends ConsumerStatefulWidget {
  const RentalPeriodsScreen({super.key});

  @override
  ConsumerState<RentalPeriodsScreen> createState() =>
      _RentalPeriodsScreenState();
}

class _RentalPeriodsScreenState extends ConsumerState<RentalPeriodsScreen> {
  _PeriodFilter _filter = _PeriodFilter.all;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(rentalPeriodsProvider);
    final canManage =
        ref.watch(hasPermissionProvider(AppPermission.manageRentalPeriods));
    final canClose =
        ref.watch(hasPermissionProvider(AppPermission.closeRentalPeriod));

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
                    Text(
                      'Rental Period Closing',
                      style: context.textTheme.titleLarge,
                    ),
                    Text(
                      'Open periods, close and lock as administrator, view reports',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () =>
                      context.push('${AppRoutes.rentalPeriods}/open'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Open Period'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<_PeriodFilter>(
            segments: const [
              ButtonSegment(value: _PeriodFilter.all, label: Text('All')),
              ButtonSegment(value: _PeriodFilter.open, label: Text('Open')),
              ButtonSegment(value: _PeriodFilter.closed, label: Text('Closed')),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) {
              setState(() => _filter = selection.first);
              ref.read(rentalPeriodFilterProvider.notifier).state =
                  RentalPeriodListFilter(
                openOnly: switch (selection.first) {
                  _PeriodFilter.open => true,
                  _PeriodFilter.closed => false,
                  _PeriodFilter.all => null,
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: periodsAsync.when(
              data: (periods) {
                if (periods.isEmpty) {
                  return EmptyState(
                    title: 'No rental periods',
                    subtitle: canManage
                        ? 'Open a period to group rentals and track closing totals.'
                        : 'No periods match the current filter.',
                    icon: Icons.event_available_outlined,
                    action: canManage
                        ? () =>
                            context.push('${AppRoutes.rentalPeriods}/open')
                        : null,
                    actionLabel: 'Open Period',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(rentalPeriodsProvider);
                    await ref.read(rentalPeriodsProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: periods.length,
                    itemBuilder: (context, index) {
                      final period = periods[index];
                      return RentalPeriodTile(
                        period: period,
                        onTap: () => context.push(
                          '${AppRoutes.rentalPeriods}/${period.id}',
                        ),
                        trailing: period.canClose && canClose
                            ? IconButton(
                                tooltip: 'Close period',
                                icon: const Icon(Icons.lock),
                                onPressed: () => context.push(
                                  '${AppRoutes.rentalPeriods}/${period.id}/close',
                                ),
                              )
                            : period.hasReport
                                ? IconButton(
                                    tooltip: 'View report',
                                    icon:
                                        const Icon(Icons.summarize_outlined),
                                    onPressed: () => context.push(
                                      '${AppRoutes.rentalPeriods}/${period.id}/report',
                                    ),
                                  )
                                : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                title: 'Unable to load periods',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
