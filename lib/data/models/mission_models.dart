import '../../domain/entities/mission.dart';

class MissionModel {
  MissionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.description,
    this.clientName,
    this.startDate,
    this.endDate,
    this.notes,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      clientName: json['client_name'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String name;
  final String code;
  final String status;
  final String? description;
  final String? clientName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  Mission toEntity() => Mission(
        id: id,
        name: name,
        code: code,
        status: MissionStatus.fromCode(status),
        description: description,
        clientName: clientName,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
      );
}

class RentalAgreementModel {
  RentalAgreementModel({
    required this.id,
    required this.vehicleId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.dailyRateXaf,
    required this.totalAmountXaf,
    required this.status,
    this.missionId,
    this.missionName,
    this.vehicleLabel,
    this.customerName,
    this.rentalPeriodId,
    this.depositXaf = 0,
    this.notes,
  });

  factory RentalAgreementModel.fromJson(Map<String, dynamic> json) {
    final mission = json['missions'];
    final vehicle = json['vehicles'];
    final customer = json['customers'];

    return RentalAgreementModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      customerId: json['customer_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      dailyRateXaf: (json['daily_rate_xaf'] as num).toInt(),
      totalAmountXaf: (json['total_amount_xaf'] as num).toInt(),
      status: json['status'] as String,
      missionId: json['mission_id'] as String?,
      missionName: mission is Map<String, dynamic>
          ? mission['name'] as String?
          : json['mission_name'] as String?,
      vehicleLabel: vehicle is Map<String, dynamic>
          ? '${vehicle['make']} ${vehicle['model']}'
          : json['vehicle_label'] as String?,
      customerName: customer is Map<String, dynamic>
          ? customer['full_name'] as String?
          : json['customer_name'] as String?,
      rentalPeriodId: json['rental_period_id'] as String?,
      depositXaf: (json['deposit_xaf'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String vehicleId;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final int dailyRateXaf;
  final int totalAmountXaf;
  final String status;
  final String? missionId;
  final String? missionName;
  final String? vehicleLabel;
  final String? customerName;
  final String? rentalPeriodId;
  final int depositXaf;
  final String? notes;

  RentalAgreement toEntity() => RentalAgreement(
        id: id,
        vehicleId: vehicleId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        dailyRateXaf: dailyRateXaf,
        totalAmountXaf: totalAmountXaf,
        status: RentalAgreementStatus.fromCode(status),
        missionId: missionId,
        missionName: missionName,
        vehicleLabel: vehicleLabel,
        customerName: customerName,
        rentalPeriodId: rentalPeriodId,
        depositXaf: depositXaf,
        notes: notes,
      );
}
