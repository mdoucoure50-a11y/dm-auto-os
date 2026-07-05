import 'package:equatable/equatable.dart';

enum RentalPeriodStatus {
  planned('planned'),
  active('active'),
  completed('completed'),
  cancelled('cancelled'),
  closed('closed');

  const RentalPeriodStatus(this.code);

  final String code;

  static RentalPeriodStatus fromCode(String code) {
    return RentalPeriodStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => RentalPeriodStatus.planned,
    );
  }

  bool get isOpen => this == RentalPeriodStatus.active;
  bool get isClosed => this == RentalPeriodStatus.closed;
}

/// A rental billing/contract period.
class RentalPeriod extends Equatable {
  const RentalPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isLocked,
    this.description,
    this.customerId,
    this.customerName,
    this.notes,
    this.totalIncomeXaf = 0,
    this.totalExpenseXaf = 0,
    this.netBalanceXaf = 0,
    this.rentalCount = 0,
    this.openedAt,
    this.openedBy,
    this.closedAt,
    this.closedBy,
    this.closingNotes,
    this.reportId,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final RentalPeriodStatus status;
  final bool isLocked;
  final String? description;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final int totalIncomeXaf;
  final int totalExpenseXaf;
  final int netBalanceXaf;
  final int rentalCount;
  final DateTime? openedAt;
  final String? openedBy;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closingNotes;
  final String? reportId;

  bool get canClose => status.isOpen && !isLocked;
  bool get hasReport => reportId != null;

  @override
  List<Object?> get props => [id, status, isLocked];
}

/// Input for opening a new rental period.
class OpenRentalPeriodInput extends Equatable {
  const OpenRentalPeriodInput({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.customerId,
    this.description,
    this.notes,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? customerId;
  final String? description;
  final String? notes;

  @override
  List<Object?> get props => [name, startDate, endDate];
}

/// Per-vehicle performance within a closed rental period.
class VehiclePeriodStat extends Equatable {
  const VehiclePeriodStat({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.licensePlate,
    required this.revenueXaf,
    required this.expensesXaf,
    required this.profitXaf,
    required this.rentalCount,
    required this.rentalDays,
    this.profitRank,
    this.utilizationRank,
  });

  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String licensePlate;
  final int revenueXaf;
  final int expensesXaf;
  final int profitXaf;
  final int rentalCount;
  final int rentalDays;
  final int? profitRank;
  final int? utilizationRank;

  @override
  List<Object?> get props => [vehicleId, profitXaf, rentalDays];
}

/// Permanent closing report for a rental period.
class RentalPeriodReport extends Equatable {
  const RentalPeriodReport({
    required this.id,
    required this.rentalPeriodId,
    required this.periodName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRentalRevenueXaf,
    required this.totalRentalExpensesXaf,
    required this.netProfitXaf,
    required this.rentalCount,
    required this.vehicleStats,
    this.closingNotes,
    this.mostProfitableVehicleId,
    this.mostProfitableVehicleLabel,
    this.mostProfitableVehicleProfitXaf,
    this.mostUtilizedVehicleId,
    this.mostUtilizedVehicleLabel,
    this.mostUtilizedRentalDays,
    this.generatedAt,
    this.generatedBy,
  });

  final String id;
  final String rentalPeriodId;
  final String periodName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalRentalRevenueXaf;
  final int totalRentalExpensesXaf;
  final int netProfitXaf;
  final int rentalCount;
  final List<VehiclePeriodStat> vehicleStats;
  final String? closingNotes;
  final String? mostProfitableVehicleId;
  final String? mostProfitableVehicleLabel;
  final int? mostProfitableVehicleProfitXaf;
  final String? mostUtilizedVehicleId;
  final String? mostUtilizedVehicleLabel;
  final int? mostUtilizedRentalDays;
  final DateTime? generatedAt;
  final String? generatedBy;

  VehiclePeriodStat? get mostProfitableVehicle {
    if (vehicleStats.isEmpty) return null;
    return vehicleStats.reduce(
      (best, stat) => stat.profitXaf > best.profitXaf ? stat : best,
    );
  }

  VehiclePeriodStat? get mostUtilizedVehicle {
    if (vehicleStats.isEmpty) return null;
    return vehicleStats.reduce(
      (best, stat) => stat.rentalDays > best.rentalDays ? stat : best,
    );
  }

  @override
  List<Object?> get props => [id, rentalPeriodId, netProfitXaf];
}
