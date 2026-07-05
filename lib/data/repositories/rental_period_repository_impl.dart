import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/rental_period.dart';
import '../../domain/repositories/rental_period_repository.dart';
import '../services/rental_period_service.dart';

class RentalPeriodRepositoryImpl implements RentalPeriodRepository {
  RentalPeriodRepositoryImpl({required RentalPeriodService service})
      : _service = service;

  final RentalPeriodService _service;
  final _uuid = const Uuid();

  final List<RentalPeriod> _demoPeriods = _seedDemoPeriods();
  final Map<String, RentalPeriodReport> _demoReports = _seedDemoReports();

  @override
  Future<List<RentalPeriod>> fetchPeriods({bool? openOnly}) async {
    if (!_service.isAvailable) {
      return _filterDemoPeriods(openOnly);
    }

    final models = await _service.fetchPeriods(openOnly: openOnly);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RentalPeriod?> fetchPeriodById(String id) async {
    if (!_service.isAvailable) {
      return _demoPeriods.where((period) => period.id == id).firstOrNull;
    }

    final model = await _service.fetchPeriodById(id);
    return model?.toEntity();
  }

  @override
  Future<RentalPeriod> openPeriod(
    OpenRentalPeriodInput input, {
    required String openedByUserId,
  }) async {
    if (!_service.isAvailable) {
      return _openDemoPeriod(input, openedByUserId);
    }

    final model = await _service.openPeriod(input);
    return model.toEntity();
  }

  @override
  Future<RentalPeriodReport> closePeriod(
    String periodId, {
    String? closingNotes,
    required String closedByUserId,
  }) async {
    if (!_service.isAvailable) {
      return _closeDemoPeriod(periodId, closingNotes, closedByUserId);
    }

    final model = await _service.closePeriod(periodId, closingNotes: closingNotes);
    return model.toEntity();
  }

  @override
  Future<RentalPeriodReport?> fetchReportByPeriodId(String periodId) async {
    if (!_service.isAvailable) {
      return _demoReports[periodId];
    }

    final model = await _service.fetchReportByPeriodId(periodId);
    return model?.toEntity();
  }

  @override
  Future<RentalPeriodReport?> fetchReportById(String reportId) async {
    if (!_service.isAvailable) {
      return _demoReports.values
          .where((report) => report.id == reportId)
          .firstOrNull;
    }

    final model = await _service.fetchReportById(reportId);
    return model?.toEntity();
  }

  @override
  Future<List<RentalPeriodReport>> fetchAllReports() async {
    if (!_service.isAvailable) {
      return _demoReports.values.toList()
        ..sort((a, b) => b.generatedAt!.compareTo(a.generatedAt!));
    }

    final models = await _service.fetchAllReports();
    return models.map((model) => model.toEntity()).toList();
  }

  List<RentalPeriod> _filterDemoPeriods(bool? openOnly) {
    if (openOnly == true) {
      return _demoPeriods.where((period) => period.canClose).toList();
    }
    if (openOnly == false) {
      return _demoPeriods
          .where((period) => period.status.isClosed)
          .toList();
    }
    return List.unmodifiable(_demoPeriods);
  }

  RentalPeriod _openDemoPeriod(
    OpenRentalPeriodInput input,
    String openedByUserId,
  ) {
    final period = RentalPeriod(
      id: _uuid.v4(),
      name: input.name.trim(),
      startDate: _dateOnly(input.startDate),
      endDate: _dateOnly(input.endDate),
      status: RentalPeriodStatus.active,
      isLocked: false,
      description: input.description,
      customerId: input.customerId,
      customerName: input.customerId == 'demo-customer-1'
          ? 'Jean Mbarga'
          : null,
      notes: input.notes,
      openedAt: DateTime.now(),
      openedBy: openedByUserId,
    );

    _demoPeriods.insert(0, period);
    return period;
  }

  RentalPeriodReport _closeDemoPeriod(
    String periodId,
    String? closingNotes,
    String closedByUserId,
  ) {
    final index = _demoPeriods.indexWhere((period) => period.id == periodId);
    if (index == -1) throw const NotFoundException('Rental period not found');

    final period = _demoPeriods[index];
    if (!period.canClose) {
      throw const ValidationException('Period is already closed and locked');
    }

    const revenue = 270000;
    const expenses = 85000;
    final reportId = _uuid.v4();

    final vehicleStats = [
      const VehiclePeriodStat(
        id: 'demo-stat-1',
        vehicleId: 'demo-vehicle-1',
        vehicleLabel: 'Toyota Hilux',
        licensePlate: 'CE-1234-A',
        revenueXaf: 180000,
        expensesXaf: 50000,
        profitXaf: 130000,
        rentalCount: 2,
        rentalDays: 14,
        profitRank: 1,
        utilizationRank: 1,
      ),
      const VehiclePeriodStat(
        id: 'demo-stat-2',
        vehicleId: 'demo-vehicle-2',
        vehicleLabel: 'Nissan Patrol',
        licensePlate: 'LT-5678-B',
        revenueXaf: 90000,
        expensesXaf: 35000,
        profitXaf: 55000,
        rentalCount: 1,
        rentalDays: 7,
        profitRank: 2,
        utilizationRank: 2,
      ),
    ];

    final missionStats = _demoMissionStats();

    final report = RentalPeriodReport(
      id: reportId,
      rentalPeriodId: periodId,
      periodName: period.name,
      periodStart: period.startDate,
      periodEnd: period.endDate,
      totalRentalRevenueXaf: revenue,
      totalRentalExpensesXaf: expenses,
      netProfitXaf: revenue - expenses,
      rentalCount: 3,
      vehicleStats: vehicleStats,
      missionStats: missionStats,
      closingNotes: closingNotes,
      mostProfitableVehicleId: 'demo-vehicle-1',
      mostProfitableVehicleLabel: 'Toyota Hilux (CE-1234-A)',
      mostProfitableVehicleProfitXaf: 130000,
      mostUtilizedVehicleId: 'demo-vehicle-1',
      mostUtilizedVehicleLabel: 'Toyota Hilux (CE-1234-A)',
      mostUtilizedRentalDays: 14,
      generatedAt: DateTime.now(),
      generatedBy: closedByUserId,
    );

    _demoReports[periodId] = report;
    _demoPeriods[index] = RentalPeriod(
      id: period.id,
      name: period.name,
      startDate: period.startDate,
      endDate: period.endDate,
      status: RentalPeriodStatus.closed,
      isLocked: true,
      description: period.description,
      customerId: period.customerId,
      customerName: period.customerName,
      notes: period.notes,
      totalIncomeXaf: revenue,
      totalExpenseXaf: expenses,
      netBalanceXaf: revenue - expenses,
      rentalCount: 3,
      openedAt: period.openedAt,
      openedBy: period.openedBy,
      closedAt: DateTime.now(),
      closedBy: closedByUserId,
      closingNotes: closingNotes,
      reportId: reportId,
    );

    return report;
  }

  static List<RentalPeriod> _seedDemoPeriods() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return [
      RentalPeriod(
        id: 'demo-period-open',
        name: 'July 2026 — Week 1',
        startDate: monthStart,
        endDate: monthStart.add(const Duration(days: 6)),
        status: RentalPeriodStatus.active,
        isLocked: false,
        customerName: 'Jean Mbarga',
        customerId: 'demo-customer-1',
        totalIncomeXaf: 150000,
        totalExpenseXaf: 35000,
        netBalanceXaf: 115000,
        rentalCount: 2,
        openedAt: monthStart,
        openedBy: 'demo-user-id',
      ),
      RentalPeriod(
        id: 'demo-period-closed',
        name: 'June 2026 Closing',
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month, 0),
        status: RentalPeriodStatus.closed,
        isLocked: true,
        totalIncomeXaf: 270000,
        totalExpenseXaf: 85000,
        netBalanceXaf: 185000,
        rentalCount: 3,
        openedAt: DateTime(now.year, now.month - 1, 1),
        closedAt: monthStart,
        closedBy: 'demo-admin-id',
        reportId: 'demo-report-june',
      ),
    ];
  }

  static List<MissionPeriodStat> _demoMissionStats() => const [
        MissionPeriodStat(
          id: 'demo-mission-stat-1',
          missionId: 'demo-mission-au',
          missionName: 'African Union Summit',
          missionCode: 'au-summit',
          revenueXaf: 120000,
          expensesXaf: 25000,
          profitXaf: 95000,
          rentalCount: 1,
          rentalDays: 7,
          profitRank: 1,
        ),
        MissionPeriodStat(
          id: 'demo-mission-stat-2',
          missionId: 'demo-mission-comilog',
          missionName: 'COMILOG Contract',
          missionCode: 'comilog',
          revenueXaf: 90000,
          expensesXaf: 30000,
          profitXaf: 60000,
          rentalCount: 1,
          rentalDays: 4,
          profitRank: 2,
        ),
        MissionPeriodStat(
          id: 'demo-mission-stat-3',
          missionId: 'demo-mission-airport',
          missionName: 'Airport Transfer',
          missionCode: 'airport-transfer',
          revenueXaf: 60000,
          expensesXaf: 30000,
          profitXaf: 30000,
          rentalCount: 1,
          rentalDays: 3,
          profitRank: 3,
        ),
      ];

  static Map<String, RentalPeriodReport> _seedDemoReports() {
    final now = DateTime.now();
    final vehicleStats = [
      const VehiclePeriodStat(
        id: 'demo-stat-june-1',
        vehicleId: 'demo-vehicle-1',
        vehicleLabel: 'Toyota Hilux',
        licensePlate: 'CE-1234-A',
        revenueXaf: 180000,
        expensesXaf: 50000,
        profitXaf: 130000,
        rentalCount: 2,
        rentalDays: 14,
        profitRank: 1,
        utilizationRank: 1,
      ),
      const VehiclePeriodStat(
        id: 'demo-stat-june-2',
        vehicleId: 'demo-vehicle-2',
        vehicleLabel: 'Nissan Patrol',
        licensePlate: 'LT-5678-B',
        revenueXaf: 90000,
        expensesXaf: 35000,
        profitXaf: 55000,
        rentalCount: 1,
        rentalDays: 7,
        profitRank: 2,
        utilizationRank: 2,
      ),
    ];

    return {
      'demo-period-closed': RentalPeriodReport(
        id: 'demo-report-june',
        rentalPeriodId: 'demo-period-closed',
        periodName: 'June 2026 Closing',
        periodStart: DateTime(now.year, now.month - 1, 1),
        periodEnd: DateTime(now.year, now.month, 0),
        totalRentalRevenueXaf: 270000,
        totalRentalExpensesXaf: 85000,
        netProfitXaf: 185000,
        rentalCount: 3,
        vehicleStats: vehicleStats,
        missionStats: _demoMissionStats(),
        mostProfitableVehicleId: 'demo-vehicle-1',
        mostProfitableVehicleLabel: 'Toyota Hilux (CE-1234-A)',
        mostProfitableVehicleProfitXaf: 130000,
        mostUtilizedVehicleId: 'demo-vehicle-1',
        mostUtilizedVehicleLabel: 'Toyota Hilux (CE-1234-A)',
        mostUtilizedRentalDays: 14,
        generatedAt: DateTime(now.year, now.month, 1),
        generatedBy: 'demo-admin-id',
      ),
    };
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
