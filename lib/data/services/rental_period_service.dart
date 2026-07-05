import '../../domain/entities/rental_period.dart';
import '../models/rental_period_models.dart';
import 'supabase_client_service.dart';
import 'supabase_database_service.dart';

/// Supabase operations for rental period closing.
class RentalPeriodService {
  RentalPeriodService({
    required SupabaseDatabaseService databaseService,
    required SupabaseClientService clientService,
  })  : _databaseService = databaseService,
        _clientService = clientService;

  final SupabaseDatabaseService _databaseService;
  final SupabaseClientService _clientService;

  bool get isAvailable => _databaseService.isAvailable;

  static const _periodSelect = '''
    *,
    customers(full_name),
    rental_period_reports(id)
  ''';

  Future<List<RentalPeriodModel>> fetchPeriods({bool? openOnly}) async {
    return _databaseService.execute(() async {
      dynamic query = _databaseService
          .from('rental_periods')
          .select(_periodSelect)
          .isFilter('deleted_at', null)
          .order('start_date', ascending: false);

      if (openOnly == true) {
        query = query.eq('status', 'active').eq('is_locked', false);
      } else if (openOnly == false) {
        query = query.eq('status', 'closed');
      }

      final rows = await query as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(_mapPeriodRow)
          .toList();
    }, errorMessage: 'Failed to load rental periods');
  }

  Future<RentalPeriodModel?> fetchPeriodById(String id) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('rental_periods')
          .select(_periodSelect)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return _mapPeriodRow(row);
    }, errorMessage: 'Failed to load rental period');
  }

  Future<RentalPeriodModel> openPeriod(OpenRentalPeriodInput input) async {
    return _databaseService.execute(() async {
      final row = await _clientService.client.rpc(
        'open_rental_period',
        params: {
          'p_name': input.name.trim(),
          'p_start_date': _formatDate(input.startDate),
          'p_end_date': _formatDate(input.endDate),
          'p_customer_id': input.customerId,
          'p_description': input.description,
          'p_notes': input.notes,
        },
      ) as Map<String, dynamic>;

      return RentalPeriodModel.fromJson(row);
    }, errorMessage: 'Failed to open rental period');
  }

  Future<RentalPeriodReportModel> closePeriod(
    String periodId, {
    String? closingNotes,
  }) async {
    return _databaseService.execute(() async {
      final row = await _clientService.client.rpc(
        'close_rental_period',
        params: {
          'p_rental_period_id': periodId,
          'p_closing_notes': closingNotes,
        },
      ) as Map<String, dynamic>;

      final report = RentalPeriodReportModel.fromJson(row);
      final vehicleStats = await fetchVehicleStats(report.id);
      final missionStats = await fetchMissionStats(report.id);
      return RentalPeriodReportModel.fromJson(
        row,
        vehicleStats: vehicleStats,
        missionStats: missionStats,
      );
    }, errorMessage: 'Failed to close rental period');
  }

  Future<RentalPeriodReportModel?> fetchReportByPeriodId(
    String periodId,
  ) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('rental_period_reports')
          .select()
          .eq('rental_period_id', periodId)
          .maybeSingle();

      if (row == null) return null;

      final vehicleStats = await fetchVehicleStats(row['id'] as String);
      final missionStats = await fetchMissionStats(row['id'] as String);
      return RentalPeriodReportModel.fromJson(
        row,
        vehicleStats: vehicleStats,
        missionStats: missionStats,
      );
    }, errorMessage: 'Failed to load period report');
  }

  Future<RentalPeriodReportModel?> fetchReportById(String reportId) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('rental_period_reports')
          .select()
          .eq('id', reportId)
          .maybeSingle();

      if (row == null) return null;

      final vehicleStats = await fetchVehicleStats(reportId);
      final missionStats = await fetchMissionStats(reportId);
      return RentalPeriodReportModel.fromJson(
        row,
        vehicleStats: vehicleStats,
        missionStats: missionStats,
      );
    }, errorMessage: 'Failed to load report');
  }

  Future<List<RentalPeriodReportModel>> fetchAllReports() async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('rental_period_reports')
          .select()
          .order('generated_at', ascending: false) as List<dynamic>;

      final reports = <RentalPeriodReportModel>[];
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final vehicleStats = await fetchVehicleStats(row['id'] as String);
        final missionStats = await fetchMissionStats(row['id'] as String);
        reports.add(RentalPeriodReportModel.fromJson(
          row,
          vehicleStats: vehicleStats,
          missionStats: missionStats,
        ));
      }
      return reports;
    }, errorMessage: 'Failed to load reports');
  }

  Future<List<MissionPeriodStatModel>> fetchMissionStats(String reportId) async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('rental_period_mission_stats')
          .select()
          .eq('report_id', reportId)
          .order('profit_rank', ascending: true) as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(MissionPeriodStatModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load mission stats');
  }

  Future<List<VehiclePeriodStatModel>> fetchVehicleStats(String reportId) async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('rental_period_vehicle_stats')
          .select()
          .eq('report_id', reportId)
          .order('profit_rank', ascending: true) as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(VehiclePeriodStatModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load vehicle stats');
  }

  RentalPeriodModel _mapPeriodRow(Map<String, dynamic> json) {
    final reports = json['rental_period_reports'];
    String? reportId;

    if (reports is List && reports.isNotEmpty) {
      reportId = (reports.first as Map<String, dynamic>)['id'] as String?;
    } else if (reports is Map<String, dynamic>) {
      reportId = reports['id'] as String?;
    }

    final customer = json['customers'];
    final customerName = customer is Map<String, dynamic>
        ? customer['full_name'] as String?
        : null;

    return RentalPeriodModel.fromJson({
      ...json,
      'customer_name': customerName,
      'report_id': reportId,
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
