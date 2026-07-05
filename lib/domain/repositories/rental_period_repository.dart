import '../entities/rental_period.dart';

/// Rental period closing data access contract.
abstract interface class RentalPeriodRepository {
  Future<List<RentalPeriod>> fetchPeriods({bool? openOnly});

  Future<RentalPeriod?> fetchPeriodById(String id);

  Future<RentalPeriod> openPeriod(
    OpenRentalPeriodInput input, {
    required String openedByUserId,
  });

  Future<RentalPeriodReport> closePeriod(
    String periodId, {
    String? closingNotes,
    required String closedByUserId,
  });

  Future<RentalPeriodReport?> fetchReportByPeriodId(String periodId);

  Future<RentalPeriodReport?> fetchReportById(String reportId);

  Future<List<RentalPeriodReport>> fetchAllReports();
}
