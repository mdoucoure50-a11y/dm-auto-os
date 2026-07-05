import 'package:equatable/equatable.dart';

import '../../core/constants/currency_constants.dart';

enum CashbookEntryType { income, expense }

enum IncomeCategory {
  rentalPayment('rental_payment', 'Rental Payment'),
  vehicleSale('vehicle_sale', 'Vehicle Sale'),
  servicePayment('service_payment', 'Service Payment'),
  deposit('deposit', 'Deposit'),
  refund('refund', 'Refund'),
  otherIncome('other_income', 'Other Income');

  const IncomeCategory(this.code, this.label);

  final String code;
  final String label;

  static IncomeCategory fromCode(String code) {
    return IncomeCategory.values.firstWhere(
      (category) => category.code == code,
      orElse: () => IncomeCategory.otherIncome,
    );
  }
}

enum ExpenseCategory {
  fuel('fuel', 'Fuel'),
  maintenance('maintenance', 'Maintenance'),
  insurance('insurance', 'Insurance'),
  registration('registration', 'Registration'),
  tax('tax', 'Tax'),
  salary('salary', 'Salary'),
  otherExpense('other_expense', 'Other Expense');

  const ExpenseCategory(this.code, this.label);

  final String code;
  final String label;

  static ExpenseCategory fromCode(String code) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.code == code,
      orElse: () => ExpenseCategory.otherExpense,
    );
  }

  /// Maps to vehicle expense table category when applicable.
  String get vehicleExpenseCode => switch (this) {
        ExpenseCategory.fuel => 'fuel',
        ExpenseCategory.maintenance => 'maintenance',
        ExpenseCategory.insurance => 'insurance',
        ExpenseCategory.registration => 'registration',
        _ => 'other',
      };
}

/// A single cashbook ledger entry.
class CashbookEntry extends Equatable {
  const CashbookEntry({
    required this.id,
    required this.cashbookSequence,
    required this.entryDate,
    required this.entryType,
    required this.categoryCode,
    required this.currency,
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

  final String id;
  final int cashbookSequence;
  final DateTime entryDate;
  final CashbookEntryType entryType;
  final String categoryCode;
  final AppCurrency currency;
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

  bool get isIncome => entryType == CashbookEntryType.income;
  bool get hasAttachment => attachmentCount > 0;

  String get categoryLabel => isIncome
      ? IncomeCategory.fromCode(categoryCode).label
      : ExpenseCategory.fromCode(categoryCode).label;

  @override
  List<Object?> get props => [id, entryDate, entryType, amountXaf];
}

/// Input for creating or updating a cashbook entry.
class CashbookEntryInput extends Equatable {
  const CashbookEntryInput({
    required this.entryType,
    required this.categoryCode,
    required this.amountOriginal,
    required this.currency,
    required this.exchangeRate,
    required this.entryDate,
    this.customerId,
    this.vehicleId,
    this.notes,
    this.description,
  });

  final CashbookEntryType entryType;
  final String categoryCode;
  final int amountOriginal;
  final AppCurrency currency;
  final double exchangeRate;
  final DateTime entryDate;
  final String? customerId;
  final String? vehicleId;
  final String? notes;
  final String? description;

  int get amountXaf => CurrencyConstants.toXaf(
        amountOriginal: amountOriginal,
        currency: currency,
        exchangeRate: exchangeRate,
      );

  String get resolvedDescription =>
      description?.trim().isNotEmpty == true
          ? description!.trim()
          : _defaultDescription();

  String _defaultDescription() {
    if (entryType == CashbookEntryType.income) {
      return IncomeCategory.fromCode(categoryCode).label;
    }
    return ExpenseCategory.fromCode(categoryCode).label;
  }

  @override
  List<Object?> get props => [
        entryType,
        categoryCode,
        amountOriginal,
        currency,
        entryDate,
      ];
}

/// Filter options for cashbook list queries.
class CashbookFilter extends Equatable {
  const CashbookFilter({
    this.searchQuery = '',
    this.entryType,
    this.categoryCode,
    this.customerId,
    this.vehicleId,
    this.currency,
    this.startDate,
    this.endDate,
    this.summaryDate,
  });

  final String searchQuery;
  final CashbookEntryType? entryType;
  final String? categoryCode;
  final String? customerId;
  final String? vehicleId;
  final AppCurrency? currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? summaryDate;

  CashbookFilter copyWith({
    String? searchQuery,
    CashbookEntryType? entryType,
    String? categoryCode,
    String? customerId,
    String? vehicleId,
    AppCurrency? currency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? summaryDate,
    bool clearEntryType = false,
    bool clearCategory = false,
    bool clearCustomer = false,
    bool clearVehicle = false,
    bool clearCurrency = false,
    bool clearDateRange = false,
  }) {
    return CashbookFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      entryType: clearEntryType ? null : (entryType ?? this.entryType),
      categoryCode: clearCategory ? null : (categoryCode ?? this.categoryCode),
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      currency: clearCurrency ? null : (currency ?? this.currency),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      summaryDate: summaryDate ?? this.summaryDate,
    );
  }

  bool get hasActiveFilters =>
      entryType != null ||
      categoryCode != null ||
      customerId != null ||
      vehicleId != null ||
      currency != null ||
      startDate != null ||
      endDate != null;

  @override
  List<Object?> get props => [
        searchQuery,
        entryType,
        categoryCode,
        customerId,
        vehicleId,
        currency,
        startDate,
        endDate,
        summaryDate,
      ];
}

/// Daily cashbook totals.
class CashbookDailySummary extends Equatable {
  const CashbookDailySummary({
    required this.summaryDate,
    required this.entryCount,
    required this.totalIncomeXaf,
    required this.totalExpenseXaf,
    required this.netBalanceXaf,
  });

  final DateTime summaryDate;
  final int entryCount;
  final int totalIncomeXaf;
  final int totalExpenseXaf;
  final int netBalanceXaf;

  @override
  List<Object?> get props => [summaryDate, netBalanceXaf];
}

/// Period cashbook totals.
class CashbookPeriodSummary extends Equatable {
  const CashbookPeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.entryCount,
    required this.totalIncomeXaf,
    required this.totalExpenseXaf,
    required this.netBalanceXaf,
    required this.incomeCount,
    required this.expenseCount,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int entryCount;
  final int totalIncomeXaf;
  final int totalExpenseXaf;
  final int netBalanceXaf;
  final int incomeCount;
  final int expenseCount;

  @override
  List<Object?> get props => [startDate, endDate, netBalanceXaf];
}

/// Minimal customer option for dropdowns.
class CustomerOption extends Equatable {
  const CustomerOption({required this.id, required this.fullName});

  final String id;
  final String fullName;

  @override
  List<Object?> get props => [id];
}

/// Minimal vehicle option for dropdowns.
class VehicleOption extends Equatable {
  const VehicleOption({
    required this.id,
    required this.label,
    required this.licensePlate,
  });

  final String id;
  final String label;
  final String licensePlate;

  @override
  List<Object?> get props => [id];
}
