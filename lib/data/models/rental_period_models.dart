import '../../domain/entities/rental_period.dart';

class RentalPeriodModel {
  RentalPeriodModel({
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

  factory RentalPeriodModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'];
    return RentalPeriodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
      isLocked: json['is_locked'] as bool? ?? false,
      description: json['description'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: customer is Map<String, dynamic>
          ? customer['full_name'] as String?
          : json['customer_name'] as String?,
      notes: json['notes'] as String?,
      totalIncomeXaf: (json['total_income_xaf'] as num?)?.toInt() ?? 0,
      totalExpenseXaf: (json['total_expense_xaf'] as num?)?.toInt() ?? 0,
      netBalanceXaf: (json['net_balance_xaf'] as num?)?.toInt() ?? 0,
      rentalCount: (json['rental_count'] as num?)?.toInt() ?? 0,
      openedAt: json['opened_at'] != null
          ? DateTime.parse(json['opened_at'] as String)
          : null,
      openedBy: json['opened_by'] as String?,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      closedBy: json['closed_by'] as String?,
      closingNotes: json['closing_notes'] as String?,
      reportId: json['report_id'] as String?,
    );
  }

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
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

  RentalPeriod toEntity() => RentalPeriod(
        id: id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        status: RentalPeriodStatus.fromCode(status),
        isLocked: isLocked,
        description: description,
        customerId: customerId,
        customerName: customerName,
        notes: notes,
        totalIncomeXaf: totalIncomeXaf,
        totalExpenseXaf: totalExpenseXaf,
        netBalanceXaf: netBalanceXaf,
        rentalCount: rentalCount,
        openedAt: openedAt,
        openedBy: openedBy,
        closedAt: closedAt,
        closedBy: closedBy,
        closingNotes: closingNotes,
        reportId: reportId,
      );
}

class VehiclePeriodStatModel {
  VehiclePeriodStatModel({
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

  factory VehiclePeriodStatModel.fromJson(Map<String, dynamic> json) {
    return VehiclePeriodStatModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      vehicleLabel: json['vehicle_label'] as String,
      licensePlate: json['license_plate'] as String,
      revenueXaf: (json['revenue_xaf'] as num).toInt(),
      expensesXaf: (json['expenses_xaf'] as num).toInt(),
      profitXaf: (json['profit_xaf'] as num).toInt(),
      rentalCount: (json['rental_count'] as num).toInt(),
      rentalDays: (json['rental_days'] as num).toInt(),
      profitRank: (json['profit_rank'] as num?)?.toInt(),
      utilizationRank: (json['utilization_rank'] as num?)?.toInt(),
    );
  }

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

  VehiclePeriodStat toEntity() => VehiclePeriodStat(
        id: id,
        vehicleId: vehicleId,
        vehicleLabel: vehicleLabel,
        licensePlate: licensePlate,
        revenueXaf: revenueXaf,
        expensesXaf: expensesXaf,
        profitXaf: profitXaf,
        rentalCount: rentalCount,
        rentalDays: rentalDays,
        profitRank: profitRank,
        utilizationRank: utilizationRank,
      );
}

class MissionPeriodStatModel {
  MissionPeriodStatModel({
    required this.id,
    this.missionId,
    required this.missionName,
    this.missionCode,
    required this.revenueXaf,
    required this.expensesXaf,
    required this.profitXaf,
    required this.rentalCount,
    required this.rentalDays,
    this.profitRank,
  });

  factory MissionPeriodStatModel.fromJson(Map<String, dynamic> json) {
    return MissionPeriodStatModel(
      id: json['id'] as String,
      missionId: json['mission_id'] as String?,
      missionName: json['mission_name'] as String,
      missionCode: json['mission_code'] as String?,
      revenueXaf: (json['revenue_xaf'] as num).toInt(),
      expensesXaf: (json['expenses_xaf'] as num).toInt(),
      profitXaf: (json['profit_xaf'] as num).toInt(),
      rentalCount: (json['rental_count'] as num).toInt(),
      rentalDays: (json['rental_days'] as num).toInt(),
      profitRank: (json['profit_rank'] as num?)?.toInt(),
    );
  }

  final String id;
  final String? missionId;
  final String missionName;
  final String? missionCode;
  final int revenueXaf;
  final int expensesXaf;
  final int profitXaf;
  final int rentalCount;
  final int rentalDays;
  final int? profitRank;

  MissionPeriodStat toEntity() => MissionPeriodStat(
        id: id,
        missionId: missionId,
        missionName: missionName,
        missionCode: missionCode,
        revenueXaf: revenueXaf,
        expensesXaf: expensesXaf,
        profitXaf: profitXaf,
        rentalCount: rentalCount,
        rentalDays: rentalDays,
        profitRank: profitRank,
      );
}

class RentalPeriodReportModel {
  RentalPeriodReportModel({
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
    required this.missionStats,
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

  factory RentalPeriodReportModel.fromJson(
    Map<String, dynamic> json, {
    List<VehiclePeriodStatModel> vehicleStats = const [],
    List<MissionPeriodStatModel> missionStats = const [],
  }) {
    return RentalPeriodReportModel(
      id: json['id'] as String,
      rentalPeriodId: json['rental_period_id'] as String,
      periodName: json['period_name'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalRentalRevenueXaf: (json['total_rental_revenue_xaf'] as num).toInt(),
      totalRentalExpensesXaf:
          (json['total_rental_expenses_xaf'] as num).toInt(),
      netProfitXaf: (json['net_profit_xaf'] as num).toInt(),
      rentalCount: (json['rental_count'] as num).toInt(),
      vehicleStats: vehicleStats,
      missionStats: missionStats,
      closingNotes: json['closing_notes'] as String?,
      mostProfitableVehicleId: json['most_profitable_vehicle_id'] as String?,
      mostProfitableVehicleLabel:
          json['most_profitable_vehicle_label'] as String?,
      mostProfitableVehicleProfitXaf:
          (json['most_profitable_vehicle_profit_xaf'] as num?)?.toInt(),
      mostUtilizedVehicleId: json['most_utilized_vehicle_id'] as String?,
      mostUtilizedVehicleLabel: json['most_utilized_vehicle_label'] as String?,
      mostUtilizedRentalDays:
          (json['most_utilized_rental_days'] as num?)?.toInt(),
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : null,
      generatedBy: json['generated_by'] as String?,
    );
  }

  final String id;
  final String rentalPeriodId;
  final String periodName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalRentalRevenueXaf;
  final int totalRentalExpensesXaf;
  final int netProfitXaf;
  final int rentalCount;
  final List<VehiclePeriodStatModel> vehicleStats;
  final List<MissionPeriodStatModel> missionStats;
  final String? closingNotes;
  final String? mostProfitableVehicleId;
  final String? mostProfitableVehicleLabel;
  final int? mostProfitableVehicleProfitXaf;
  final String? mostUtilizedVehicleId;
  final String? mostUtilizedVehicleLabel;
  final int? mostUtilizedRentalDays;
  final DateTime? generatedAt;
  final String? generatedBy;

  RentalPeriodReport toEntity() => RentalPeriodReport(
        id: id,
        rentalPeriodId: rentalPeriodId,
        periodName: periodName,
        periodStart: periodStart,
        periodEnd: periodEnd,
        totalRentalRevenueXaf: totalRentalRevenueXaf,
        totalRentalExpensesXaf: totalRentalExpensesXaf,
        netProfitXaf: netProfitXaf,
        rentalCount: rentalCount,
        vehicleStats: vehicleStats.map((stat) => stat.toEntity()).toList(),
        missionStats: missionStats.map((stat) => stat.toEntity()).toList(),
        closingNotes: closingNotes,
        mostProfitableVehicleId: mostProfitableVehicleId,
        mostProfitableVehicleLabel: mostProfitableVehicleLabel,
        mostProfitableVehicleProfitXaf: mostProfitableVehicleProfitXaf,
        mostUtilizedVehicleId: mostUtilizedVehicleId,
        mostUtilizedVehicleLabel: mostUtilizedVehicleLabel,
        mostUtilizedRentalDays: mostUtilizedRentalDays,
        generatedAt: generatedAt,
        generatedBy: generatedBy,
      );
}
