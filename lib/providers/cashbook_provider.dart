import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cashbook_repository_impl.dart';
import '../data/services/cashbook_service.dart';
import '../domain/entities/cashbook.dart';
import '../domain/repositories/cashbook_repository.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final cashbookServiceProvider = Provider<CashbookService>((ref) {
  return CashbookService(
    databaseService: ref.watch(supabaseDatabaseServiceProvider),
    clientService: ref.watch(supabaseClientServiceProvider),
  );
});

final cashbookRepositoryProvider = Provider<CashbookRepository>((ref) {
  return CashbookRepositoryImpl(
    cashbookService: ref.watch(cashbookServiceProvider),
    storageService: ref.watch(supabaseStorageServiceProvider),
  );
});

final cashbookFilterProvider =
    StateProvider<CashbookFilter>((ref) => CashbookFilter(
          summaryDate: DateTime.now(),
          startDate: _startOfMonth(DateTime.now()),
          endDate: _endOfMonth(DateTime.now()),
        ));

final cashbookEntriesProvider =
    FutureProvider.autoDispose<List<CashbookEntry>>((ref) async {
  final repository = ref.watch(cashbookRepositoryProvider);
  final filter = ref.watch(cashbookFilterProvider);
  return repository.fetchEntries(filter);
});

final cashbookDailySummaryProvider =
    FutureProvider.autoDispose<CashbookDailySummary?>((ref) async {
  final repository = ref.watch(cashbookRepositoryProvider);
  final filter = ref.watch(cashbookFilterProvider);
  final date = filter.summaryDate ?? DateTime.now();
  return repository.fetchDailySummary(date);
});

final cashbookPeriodSummaryProvider =
    FutureProvider.autoDispose<CashbookPeriodSummary>((ref) async {
  final repository = ref.watch(cashbookRepositoryProvider);
  final filter = ref.watch(cashbookFilterProvider);
  final start = filter.startDate ?? _startOfMonth(DateTime.now());
  final end = filter.endDate ?? _endOfMonth(DateTime.now());
  return repository.fetchPeriodSummary(startDate: start, endDate: end);
});

final customerOptionsProvider =
    FutureProvider.autoDispose<List<CustomerOption>>((ref) async {
  return ref.watch(cashbookRepositoryProvider).fetchCustomerOptions();
});

final vehicleOptionsProvider =
    FutureProvider.autoDispose<List<VehicleOption>>((ref) async {
  return ref.watch(cashbookRepositoryProvider).fetchVehicleOptions();
});

final cashbookEntryProvider = FutureProvider.autoDispose
    .family<CashbookEntry?, String>((ref, id) async {
  return ref.watch(cashbookRepositoryProvider).fetchEntryById(id);
});

class CashbookController extends StateNotifier<AsyncValue<void>> {
  CashbookController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> saveEntry({
    String? entryId,
    required CashbookEntryInput input,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    String? attachmentMimeType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw StateError('Not authenticated');

      final repository = _ref.read(cashbookRepositoryProvider);
      if (entryId == null) {
        await repository.createEntry(
          input,
          attachmentBytes: attachmentBytes,
          attachmentFileName: attachmentFileName,
          attachmentMimeType: attachmentMimeType,
          recordedByUserId: user.id,
        );
      } else {
        await repository.updateEntry(
          entryId,
          input,
          attachmentBytes: attachmentBytes,
          attachmentFileName: attachmentFileName,
          attachmentMimeType: attachmentMimeType,
          recordedByUserId: user.id,
        );
      }

      _invalidateCashbook();
    });
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw StateError('Not authenticated');

      await _ref
          .read(cashbookRepositoryProvider)
          .deleteEntry(entryId, deletedByUserId: user.id);
      _invalidateCashbook();
    });
  }

  void _invalidateCashbook() {
    _ref.invalidate(cashbookEntriesProvider);
    _ref.invalidate(cashbookDailySummaryProvider);
    _ref.invalidate(cashbookPeriodSummaryProvider);
  }
}

final cashbookControllerProvider =
    StateNotifierProvider<CashbookController, AsyncValue<void>>((ref) {
  return CashbookController(ref);
});

DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month);

DateTime _endOfMonth(DateTime date) =>
    DateTime(date.year, date.month + 1, 0);
