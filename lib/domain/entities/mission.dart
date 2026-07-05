import 'package:equatable/equatable.dart';

enum MissionStatus {
  active('active'),
  inactive('inactive'),
  completed('completed');

  const MissionStatus(this.code);

  final String code;

  static MissionStatus fromCode(String code) {
    return MissionStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => MissionStatus.active,
    );
  }
}

/// A mission-based rental contract category.
class Mission extends Equatable {
  const Mission({
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

  final String id;
  final String name;
  final String code;
  final MissionStatus status;
  final String? description;
  final String? clientName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  @override
  List<Object?> get props => [id, code];
}

enum RentalAgreementStatus {
  pending('pending'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const RentalAgreementStatus(this.code);

  final String code;

  static RentalAgreementStatus fromCode(String code) {
    return RentalAgreementStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => RentalAgreementStatus.pending,
    );
  }
}

/// A vehicle rental agreement, optionally linked to a mission.
class RentalAgreement extends Equatable {
  const RentalAgreement({
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

  final String id;
  final String vehicleId;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final int dailyRateXaf;
  final int totalAmountXaf;
  final RentalAgreementStatus status;
  final String? missionId;
  final String? missionName;
  final String? vehicleLabel;
  final String? customerName;
  final String? rentalPeriodId;
  final int depositXaf;
  final String? notes;

  bool get hasMission => missionId != null;

  int get rentalDays => endDate.difference(startDate).inDays + 1;

  @override
  List<Object?> get props => [id, vehicleId, missionId];
}

class RentalAgreementInput extends Equatable {
  const RentalAgreementInput({
    required this.vehicleId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.dailyRateXaf,
    this.missionId,
    this.rentalPeriodId,
    this.depositXaf = 0,
    this.notes,
  });

  final String vehicleId;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final int dailyRateXaf;
  final String? missionId;
  final String? rentalPeriodId;
  final int depositXaf;
  final String? notes;

  int get totalAmountXaf => dailyRateXaf * (endDate.difference(startDate).inDays + 1);

  @override
  List<Object?> get props => [vehicleId, customerId, startDate, missionId];
}
