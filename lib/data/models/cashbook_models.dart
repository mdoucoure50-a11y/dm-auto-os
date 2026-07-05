import '../../core/constants/currency_constants.dart';
import '../../domain/entities/cashbook.dart';

class CashbookEntryModel {
  CashbookEntryModel({
    required this.id,
    required this.cashbookSequence,
    required this.entryDate,
    required this.transactionType,
    required this.category,
    required this.currencyCode,
    required this.amountOriginal,
    required this.exchangeRate,
    required this.amountXaf,
    required this.signedAmountXaf,
    required this.runningBalanceXaf,
    required this.description,
    this.notes,
    this.referenceNumber,
    this.paymentMethod,
    this.vehicleId,
    this.customerId,
    this.customerName,
    this.vehicleLabel,
    this.attachmentCount = 0,
    this.recordedBy,
    this.createdAt,
  });

  factory CashbookEntryModel.fromJson(Map<String, dynamic> json) {
    return CashbookEntryModel(
      id: json['id'] as String,
      cashbookSequence: (json['cashbook_sequence'] as num?)?.toInt() ?? 0,
      entryDate: DateTime.parse(json['entry_date'] as String),
      transactionType: json['transaction_type'] as String,
      category: json['category'] as String,
      currencyCode: json['currency_code'] as String? ?? 'XAF',
      amountOriginal: (json['amount_original'] as num?)?.toInt() ??
          (json['amount_xaf'] as num).toInt(),
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      amountXaf: (json['amount_xaf'] as num).toInt(),
      signedAmountXaf: (json['signed_amount_xaf'] as num).toInt(),
      runningBalanceXaf: (json['running_balance_xaf'] as num).toInt(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      referenceNumber: json['reference_number'] as String?,
      paymentMethod: json['payment_method'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      vehicleLabel: json['vehicle_label'] as String?,
      attachmentCount: (json['attachment_count'] as num?)?.toInt() ?? 0,
      recordedBy: json['recorded_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final int cashbookSequence;
  final DateTime entryDate;
  final String transactionType;
  final String category;
  final String currencyCode;
  final int amountOriginal;
  final double exchangeRate;
  final int amountXaf;
  final int signedAmountXaf;
  final int runningBalanceXaf;
  final String description;
  final String? notes;
  final String? referenceNumber;
  final String? paymentMethod;
  final String? vehicleId;
  final String? customerId;
  final String? customerName;
  final String? vehicleLabel;
  final int attachmentCount;
  final String? recordedBy;
  final DateTime? createdAt;

  CashbookEntry toEntity() {
    return CashbookEntry(
      id: id,
      cashbookSequence: cashbookSequence,
      entryDate: entryDate,
      entryType: transactionType == 'income'
          ? CashbookEntryType.income
          : CashbookEntryType.expense,
      categoryCode: category,
      currency: AppCurrency.fromCode(currencyCode),
      amountOriginal: amountOriginal,
      exchangeRate: exchangeRate,
      amountXaf: amountXaf,
      signedAmountXaf: signedAmountXaf,
      runningBalanceXaf: runningBalanceXaf,
      description: description,
      notes: notes,
      referenceNumber: referenceNumber,
      paymentMethod: paymentMethod,
      vehicleId: vehicleId,
      customerId: customerId,
      customerName: customerName,
      vehicleLabel: vehicleLabel,
      attachmentCount: attachmentCount,
      recordedBy: recordedBy,
      createdAt: createdAt,
    );
  }
}

class CashbookDailySummaryModel {
  CashbookDailySummaryModel({
    required this.summaryDate,
    required this.entryCount,
    required this.totalIncomeXaf,
    required this.totalExpenseXaf,
    required this.netBalanceXaf,
  });

  factory CashbookDailySummaryModel.fromJson(Map<String, dynamic> json) {
    return CashbookDailySummaryModel(
      summaryDate: DateTime.parse(json['summary_date'] as String),
      entryCount: (json['entry_count'] as num).toInt(),
      totalIncomeXaf: (json['total_income_xaf'] as num).toInt(),
      totalExpenseXaf: (json['total_expense_xaf'] as num).toInt(),
      netBalanceXaf: (json['net_balance_xaf'] as num).toInt(),
    );
  }

  final DateTime summaryDate;
  final int entryCount;
  final int totalIncomeXaf;
  final int totalExpenseXaf;
  final int netBalanceXaf;

  CashbookDailySummary toEntity() => CashbookDailySummary(
        summaryDate: summaryDate,
        entryCount: entryCount,
        totalIncomeXaf: totalIncomeXaf,
        totalExpenseXaf: totalExpenseXaf,
        netBalanceXaf: netBalanceXaf,
      );
}

class CashbookPeriodSummaryModel {
  CashbookPeriodSummaryModel({
    required this.startDate,
    required this.endDate,
    required this.entryCount,
    required this.totalIncomeXaf,
    required this.totalExpenseXaf,
    required this.netBalanceXaf,
    required this.incomeCount,
    required this.expenseCount,
  });

  factory CashbookPeriodSummaryModel.fromJson(Map<String, dynamic> json) {
    return CashbookPeriodSummaryModel(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      entryCount: (json['entry_count'] as num).toInt(),
      totalIncomeXaf: (json['total_income_xaf'] as num).toInt(),
      totalExpenseXaf: (json['total_expense_xaf'] as num).toInt(),
      netBalanceXaf: (json['net_balance_xaf'] as num).toInt(),
      incomeCount: (json['income_count'] as num).toInt(),
      expenseCount: (json['expense_count'] as num).toInt(),
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final int entryCount;
  final int totalIncomeXaf;
  final int totalExpenseXaf;
  final int netBalanceXaf;
  final int incomeCount;
  final int expenseCount;

  CashbookPeriodSummary toEntity() => CashbookPeriodSummary(
        startDate: startDate,
        endDate: endDate,
        entryCount: entryCount,
        totalIncomeXaf: totalIncomeXaf,
        totalExpenseXaf: totalExpenseXaf,
        netBalanceXaf: netBalanceXaf,
        incomeCount: incomeCount,
        expenseCount: expenseCount,
      );
}

class CustomerOptionModel {
  CustomerOptionModel({required this.id, required this.fullName});

  factory CustomerOptionModel.fromJson(Map<String, dynamic> json) {
    return CustomerOptionModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
    );
  }

  final String id;
  final String fullName;

  CustomerOption toEntity() => CustomerOption(id: id, fullName: fullName);
}

class VehicleOptionModel {
  VehicleOptionModel({
    required this.id,
    required this.make,
    required this.model,
    required this.licensePlate,
  });

  factory VehicleOptionModel.fromJson(Map<String, dynamic> json) {
    return VehicleOptionModel(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      licensePlate: json['license_plate'] as String,
    );
  }

  final String id;
  final String make;
  final String model;
  final String licensePlate;

  VehicleOption toEntity() => VehicleOption(
        id: id,
        label: '$make $model',
        licensePlate: licensePlate,
      );
}
