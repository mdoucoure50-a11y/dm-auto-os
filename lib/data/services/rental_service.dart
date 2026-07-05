import '../../domain/entities/mission.dart';
import '../models/mission_models.dart';
import 'supabase_database_service.dart';

class RentalService {
  RentalService(this._databaseService);

  final SupabaseDatabaseService _databaseService;

  bool get isAvailable => _databaseService.isAvailable;

  static const _select = '''
    *,
    missions(name, code),
    vehicles(make, model, license_plate),
    customers(full_name)
  ''';

  Future<List<RentalAgreementModel>> fetchRentals() async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('rentals')
          .select(_select)
          .isFilter('deleted_at', null)
          .order('start_date', ascending: false) as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(RentalAgreementModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load rentals');
  }

  Future<RentalAgreementModel> createRental(
    RentalAgreementInput input, {
    required String createdByUserId,
  }) async {
    return _databaseService.execute(() async {
      final row = await _databaseService.from('rentals').insert({
        'vehicle_id': input.vehicleId,
        'customer_id': input.customerId,
        'start_date': _formatDate(input.startDate),
        'end_date': _formatDate(input.endDate),
        'daily_rate_xaf': input.dailyRateXaf,
        'total_amount_xaf': input.totalAmountXaf,
        'deposit_xaf': input.depositXaf,
        'mission_id': input.missionId,
        'rental_period_id': input.rentalPeriodId,
        'notes': input.notes,
        'status': 'active',
        'created_by': createdByUserId,
      }).select(_select).single();

      return RentalAgreementModel.fromJson(row);
    }, errorMessage: 'Failed to create rental');
  }

  Future<RentalAgreementModel> updateRentalMission({
    required String rentalId,
    String? missionId,
    required String updatedByUserId,
  }) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('rentals')
          .update({
            'mission_id': missionId,
            'updated_by': updatedByUserId,
          })
          .eq('id', rentalId)
          .select(_select)
          .single();

      return RentalAgreementModel.fromJson(row);
    }, errorMessage: 'Failed to update rental mission');
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
