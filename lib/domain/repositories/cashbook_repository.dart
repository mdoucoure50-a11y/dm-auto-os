import 'dart:typed_data';

import '../entities/cashbook.dart';

/// Cashbook data access contract.
abstract interface class CashbookRepository {
  Future<List<CashbookEntry>> fetchEntries(CashbookFilter filter);

  Future<CashbookEntry?> fetchEntryById(String id);

  Future<CashbookDailySummary?> fetchDailySummary(DateTime date);

  Future<CashbookPeriodSummary> fetchPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<CustomerOption>> fetchCustomerOptions();

  Future<List<VehicleOption>> fetchVehicleOptions();

  Future<CashbookEntry> createEntry(
    CashbookEntryInput input, {
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    String? attachmentMimeType,
    required String recordedByUserId,
  });

  Future<CashbookEntry> updateEntry(
    String id,
    CashbookEntryInput input, {
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    String? attachmentMimeType,
    required String recordedByUserId,
  });

  Future<void> deleteEntry(String id, {required String deletedByUserId});
}
