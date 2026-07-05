import '../entities/mission.dart';

abstract interface class RentalRepository {
  Future<List<RentalAgreement>> fetchRentals();

  Future<RentalAgreement> createRental(
    RentalAgreementInput input, {
    required String createdByUserId,
  });
}
