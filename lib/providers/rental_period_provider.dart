import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/rental_period_repository_impl.dart';
import '../data/services/rental_period_service.dart';
import '../domain/entities/rental_period.dart';
import '../domain/repositories/rental_period_repository.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final rentalPeriodServiceProvider = Provider<RentalPeriodService>((ref) {
  return RentalPeriodService(
    databaseService: ref.watch(supabaseDatabaseServiceProvider),
    clientService: ref.watch(supabaseClientServiceProvider),
  );
});

final rentalPeriodRepositoryProvider = Provider<RentalPeriodRepository>((ref) {
  return RentalPeriodRepositoryImpl(
    service: ref.watch(rentalPeriodServiceProvider),
  );
});

final rentalPeriodFilterProvider =
    StateProvider<RentalPeriodListFilter>((ref) => const RentalPeriodListFilter());

final rentalPeriodsProvider =
    FutureProvider.autoDispose<List<RentalPeriod>>((ref) async {
  final repository = ref.watch(rentalPeriodRepositoryProvider);
  final filter = ref.watch(rentalPeriodFilterProvider);
  return repository.fetchPeriods(openOnly: filter.openOnly);
});

final rentalPeriodProvider = FutureProvider.autoDispose
    .family<RentalPeriod?, String>((ref, id) async {
  return ref.watch(rentalPeriodRepositoryProvider).fetchPeriodById(id);
});

final rentalPeriodReportProvider = FutureProvider.autoDispose
    .family<RentalPeriodReport?, String>((ref, periodId) async {
  return ref
      .watch(rentalPeriodRepositoryProvider)
      .fetchReportByPeriodId(periodId);
});

final rentalPeriodReportsProvider =
    FutureProvider.autoDispose<List<RentalPeriodReport>>((ref) async {
  return ref.watch(rentalPeriodRepositoryProvider).fetchAllReports();
});

class RentalPeriodListFilter {
  const RentalPeriodListFilter({this.openOnly});

  final bool? openOnly;

  RentalPeriodListFilter copyWith({bool? openOnly, bool clearOpenOnly = false}) {
    return RentalPeriodListFilter(
      openOnly: clearOpenOnly ? null : (openOnly ?? this.openOnly),
    );
  }
}

class RentalPeriodController extends StateNotifier<AsyncValue<void>> {
  RentalPeriodController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<RentalPeriod> openPeriod(OpenRentalPeriodInput input) async {
    state = const AsyncLoading();
    late RentalPeriod period;

    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw StateError('Not authenticated');

      period = await _ref.read(rentalPeriodRepositoryProvider).openPeriod(
            input,
            openedByUserId: user.id,
          );
      _invalidate();
    });

    if (state.hasError) throw state.error!;
    return period;
  }

  Future<RentalPeriodReport> closePeriod(
    String periodId, {
    String? closingNotes,
  }) async {
    state = const AsyncLoading();
    late RentalPeriodReport report;

    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw StateError('Not authenticated');

      report = await _ref.read(rentalPeriodRepositoryProvider).closePeriod(
            periodId,
            closingNotes: closingNotes,
            closedByUserId: user.id,
          );
      _invalidate();
    });

    if (state.hasError) throw state.error!;
    return report;
  }

  void _invalidate() {
    _ref.invalidate(rentalPeriodsProvider);
    _ref.invalidate(rentalPeriodReportsProvider);
  }
}

final rentalPeriodControllerProvider =
    StateNotifierProvider<RentalPeriodController, AsyncValue<void>>((ref) {
  return RentalPeriodController(ref);
});
