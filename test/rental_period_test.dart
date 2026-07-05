import 'package:dm_auto_os/data/models/rental_period_models.dart';
import 'package:dm_auto_os/domain/entities/rental_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RentalPeriodStatus', () {
    test('active period can be closed when not locked', () {
      final period = RentalPeriod(
        id: 'p1',
        name: 'Test',
        startDate: _start,
        endDate: _end,
        status: RentalPeriodStatus.active,
        isLocked: false,
      );

      expect(period.canClose, isTrue);
      expect(period.hasReport, isFalse);
    });

    test('closed locked period cannot be closed again', () {
      final period = RentalPeriod(
        id: 'p1',
        name: 'Test',
        startDate: _start,
        endDate: _end,
        status: RentalPeriodStatus.closed,
        isLocked: true,
        reportId: 'r1',
      );

      expect(period.canClose, isFalse);
      expect(period.hasReport, isTrue);
    });
  });

  group('RentalPeriodReport', () {
    test('identifies most profitable and utilized vehicles', () {
      final report = RentalPeriodReport(
        id: 'r1',
        rentalPeriodId: 'p1',
        periodName: 'June 2026',
        periodStart: _start,
        periodEnd: _end,
        totalRentalRevenueXaf: 270000,
        totalRentalExpensesXaf: 85000,
        netProfitXaf: 185000,
        rentalCount: 3,
        vehicleStats: [
          VehiclePeriodStat(
            id: 's1',
            vehicleId: 'v1',
            vehicleLabel: 'Hilux',
            licensePlate: 'CE-1234-A',
            revenueXaf: 180000,
            expensesXaf: 50000,
            profitXaf: 130000,
            rentalCount: 2,
            rentalDays: 14,
          ),
          VehiclePeriodStat(
            id: 's2',
            vehicleId: 'v2',
            vehicleLabel: 'Patrol',
            licensePlate: 'LT-5678-B',
            revenueXaf: 90000,
            expensesXaf: 35000,
            profitXaf: 55000,
            rentalCount: 1,
            rentalDays: 7,
          ),
        ],
        missionStats: const [],
      );

      expect(report.mostProfitableVehicle?.vehicleId, 'v1');
      expect(report.mostUtilizedVehicle?.rentalDays, 14);
      expect(report.netProfitXaf, 185000);
    });

    test('identifies most profitable mission', () {
      final report = RentalPeriodReport(
        id: 'r1',
        rentalPeriodId: 'p1',
        periodName: 'June 2026',
        periodStart: _start,
        periodEnd: _end,
        totalRentalRevenueXaf: 270000,
        totalRentalExpensesXaf: 85000,
        netProfitXaf: 185000,
        rentalCount: 3,
        vehicleStats: const [],
        missionStats: const [
          MissionPeriodStat(
            id: 'ms1',
            missionId: 'm1',
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
            id: 'ms2',
            missionId: 'm2',
            missionName: 'COMILOG Contract',
            missionCode: 'comilog',
            revenueXaf: 90000,
            expensesXaf: 30000,
            profitXaf: 60000,
            rentalCount: 1,
            rentalDays: 4,
            profitRank: 2,
          ),
        ],
      );

      expect(report.mostProfitableMission?.missionName, 'African Union Summit');
      expect(report.mostProfitableMission?.profitXaf, 95000);
    });
  });

  group('RentalPeriodReportModel', () {
    test('maps JSON with vehicle stats to entity', () {
      final model = RentalPeriodReportModel.fromJson(
        {
          'id': 'r1',
          'rental_period_id': 'p1',
          'period_name': 'June 2026',
          'period_start': '2026-06-01',
          'period_end': '2026-06-30',
          'total_rental_revenue_xaf': 270000,
          'total_rental_expenses_xaf': 85000,
          'net_profit_xaf': 185000,
          'rental_count': 3,
          'most_profitable_vehicle_label': 'Hilux (CE-1234-A)',
          'most_utilized_vehicle_label': 'Hilux (CE-1234-A)',
          'most_utilized_rental_days': 14,
        },
        vehicleStats: [
          VehiclePeriodStatModel(
            id: 's1',
            vehicleId: 'v1',
            vehicleLabel: 'Hilux',
            licensePlate: 'CE-1234-A',
            revenueXaf: 180000,
            expensesXaf: 50000,
            profitXaf: 130000,
            rentalCount: 2,
            rentalDays: 14,
            profitRank: 1,
            utilizationRank: 1,
          ),
        ],
      );

      final entity = model.toEntity();
      expect(entity.periodName, 'June 2026');
      expect(entity.vehicleStats.length, 1);
      expect(entity.totalRentalRevenueXaf, 270000);
    });
  });

  group('OpenRentalPeriodInput', () {
    test('requires name and date range', () {
      final input = OpenRentalPeriodInput(
        name: 'July Week 1',
        startDate: _start,
        endDate: _end,
      );

      expect(input.name, 'July Week 1');
      expect(input.customerId, isNull);
    });
  });
}

final _start = DateTime(2026, 6, 1);
final _end = DateTime(2026, 6, 30);