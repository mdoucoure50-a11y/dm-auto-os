import 'package:uuid/uuid.dart';

import '../../domain/entities/mission.dart';
import '../../domain/repositories/rental_repository.dart';
import '../repositories/mission_repository_impl.dart';
import '../services/rental_service.dart';

class RentalRepositoryImpl implements RentalRepository {
  RentalRepositoryImpl({required RentalService service}) : _service = service;

  final RentalService _service;
  final _uuid = const Uuid();

  final List<RentalAgreement> _demoRentals = _seedDemoRentals();

  @override
  Future<List<RentalAgreement>> fetchRentals() async {
    if (!_service.isAvailable) return List.unmodifiable(_demoRentals);

    final models = await _service.fetchRentals();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RentalAgreement> createRental(
    RentalAgreementInput input, {
    required String createdByUserId,
  }) async {
    if (!_service.isAvailable) {
      return _createDemoRental(input);
    }

    final model = await _service.createRental(
      input,
      createdByUserId: createdByUserId,
    );
    return model.toEntity();
  }

  RentalAgreement _createDemoRental(RentalAgreementInput input) {
    final mission = MissionRepositoryImpl.demoMissions
        .where((mission) => mission.id == input.missionId)
        .firstOrNull;

    final rental = RentalAgreement(
      id: _uuid.v4(),
      vehicleId: input.vehicleId,
      customerId: input.customerId,
      startDate: input.startDate,
      endDate: input.endDate,
      dailyRateXaf: input.dailyRateXaf,
      totalAmountXaf: input.totalAmountXaf,
      status: RentalAgreementStatus.active,
      missionId: input.missionId,
      missionName: mission?.name,
      vehicleLabel: 'Toyota Hilux',
      customerName: 'Jean Mbarga',
      rentalPeriodId: input.rentalPeriodId,
      depositXaf: input.depositXaf,
      notes: input.notes,
    );

    _demoRentals.insert(0, rental);
    return rental;
  }

  static List<RentalAgreement> _seedDemoRentals() {
    final now = DateTime.now();
    return [
      RentalAgreement(
        id: 'demo-rental-1',
        vehicleId: 'demo-vehicle-1',
        customerId: 'demo-customer-1',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        dailyRateXaf: 25000,
        totalAmountXaf: 175000,
        status: RentalAgreementStatus.active,
        missionId: 'demo-mission-au',
        missionName: 'African Union Summit',
        vehicleLabel: 'Toyota Hilux',
        customerName: 'Jean Mbarga',
        rentalPeriodId: 'demo-period-open',
      ),
      RentalAgreement(
        id: 'demo-rental-2',
        vehicleId: 'demo-vehicle-2',
        customerId: 'demo-customer-2',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        dailyRateXaf: 30000,
        totalAmountXaf: 90000,
        status: RentalAgreementStatus.active,
        missionId: 'demo-mission-airport',
        missionName: 'Airport Transfer',
        vehicleLabel: 'Nissan Patrol',
        customerName: 'Marie Nguema',
        rentalPeriodId: 'demo-period-open',
      ),
      RentalAgreement(
        id: 'demo-rental-3',
        vehicleId: 'demo-vehicle-1',
        customerId: 'demo-customer-1',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 7)),
        dailyRateXaf: 20000,
        totalAmountXaf: 80000,
        status: RentalAgreementStatus.completed,
        missionId: 'demo-mission-comilog',
        missionName: 'COMILOG Contract',
        vehicleLabel: 'Toyota Hilux',
        customerName: 'Jean Mbarga',
        rentalPeriodId: 'demo-period-closed',
      ),
    ];
  }
}
