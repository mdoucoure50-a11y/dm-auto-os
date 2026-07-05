import 'package:dm_auto_os/data/models/mission_models.dart';
import 'package:dm_auto_os/domain/entities/mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionModel', () {
    test('maps JSON to entity', () {
      final model = MissionModel.fromJson({
        'id': 'm1',
        'name': 'African Union Summit',
        'code': 'au-summit',
        'status': 'active',
        'description': 'VIP transport',
      });

      final entity = model.toEntity();
      expect(entity.name, 'African Union Summit');
      expect(entity.code, 'au-summit');
      expect(entity.status, MissionStatus.active);
    });
  });

  group('RentalAgreement', () {
    test('hasMission is true when missionId is set', () {
      final rental = RentalAgreement(
        id: 'r1',
        vehicleId: 'v1',
        customerId: 'c1',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 7),
        dailyRateXaf: 25000,
        totalAmountXaf: 175000,
        status: RentalAgreementStatus.active,
        missionId: 'm1',
        missionName: 'Airport Transfer',
      );

      expect(rental.hasMission, isTrue);
      expect(rental.rentalDays, 7);
    });

    test('totalAmountXaf is computed from daily rate and days', () {
      final input = RentalAgreementInput(
        vehicleId: 'v1',
        customerId: 'c1',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 3),
        dailyRateXaf: 20000,
        missionId: 'm1',
      );

      expect(input.totalAmountXaf, 60000);
    });
  });

  group('RentalAgreementModel', () {
    test('maps rental with mission join', () {
      final model = RentalAgreementModel.fromJson({
        'id': 'r1',
        'vehicle_id': 'v1',
        'customer_id': 'c1',
        'start_date': '2026-07-01',
        'end_date': '2026-07-07',
        'daily_rate_xaf': 25000,
        'total_amount_xaf': 175000,
        'status': 'active',
        'mission_id': 'm1',
        'missions': {'name': 'COMILOG Contract', 'code': 'comilog'},
        'vehicles': {'make': 'Toyota', 'model': 'Hilux', 'license_plate': 'CE-1'},
        'customers': {'full_name': 'Jean Mbarga'},
      });

      final entity = model.toEntity();
      expect(entity.missionName, 'COMILOG Contract');
      expect(entity.vehicleLabel, 'Toyota Hilux');
      expect(entity.customerName, 'Jean Mbarga');
    });
  });
}
