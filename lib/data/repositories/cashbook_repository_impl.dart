import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/constants/currency_constants.dart';
import '../../domain/entities/cashbook.dart';
import '../../domain/repositories/cashbook_repository.dart';
import '../services/cashbook_service.dart';
import '../services/supabase_storage_service.dart';

class CashbookRepositoryImpl implements CashbookRepository {
  CashbookRepositoryImpl({
    required CashbookService cashbookService,
    required SupabaseStorageService storageService,
  })  : _cashbookService = cashbookService,
        _storageService = storageService;

  final CashbookService _cashbookService;
  final SupabaseStorageService _storageService;
  final _uuid = const Uuid();

  final List<CashbookEntry> _demoEntries = _seedDemoEntries();
  final List<CustomerOption> _demoCustomers = const [
    CustomerOption(id: 'demo-customer-1', fullName: 'Jean Mbarga'),
    CustomerOption(id: 'demo-customer-2', fullName: 'Marie Nguema'),
  ];
  final List<VehicleOption> _demoVehicles = const [
    VehicleOption(
      id: 'demo-vehicle-1',
      label: 'Toyota Hilux',
      licensePlate: 'CE-1234-A',
    ),
    VehicleOption(
      id: 'demo-vehicle-2',
      label: 'Nissan Patrol',
      licensePlate: 'LT-5678-B',
    ),
  ];

  @override
  Future<List<CashbookEntry>> fetchEntries(CashbookFilter filter) async {
    if (!_cashbookService.isAvailable) {
      return _filterDemoEntries(filter);
    }

    final models = await _cashbookService.fetchEntries(filter);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<CashbookEntry?> fetchEntryById(String id) async {
    if (!_cashbookService.isAvailable) {
      return _demoEntries.where((entry) => entry.id == id).firstOrNull;
    }

    final model = await _cashbookService.fetchEntryById(id);
    return model?.toEntity();
  }

  @override
  Future<CashbookDailySummary?> fetchDailySummary(DateTime date) async {
    if (!_cashbookService.isAvailable) {
      return _computeDemoDailySummary(date);
    }

    final model = await _cashbookService.fetchDailySummary(date);
    return model?.toEntity();
  }

  @override
  Future<CashbookPeriodSummary> fetchPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_cashbookService.isAvailable) {
      return _computeDemoPeriodSummary(startDate, endDate);
    }

    final model = await _cashbookService.fetchPeriodSummary(
      startDate: startDate,
      endDate: endDate,
    );
    return model.toEntity();
  }

  @override
  Future<List<CustomerOption>> fetchCustomerOptions() async {
    if (!_cashbookService.isAvailable) return _demoCustomers;

    final models = await _cashbookService.fetchCustomerOptions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<VehicleOption>> fetchVehicleOptions() async {
    if (!_cashbookService.isAvailable) return _demoVehicles;

    final models = await _cashbookService.fetchVehicleOptions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<CashbookEntry> createEntry(
    CashbookEntryInput input, {
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    String? attachmentMimeType,
    required String recordedByUserId,
  }) async {
    if (!_cashbookService.isAvailable) {
      return _createDemoEntry(input, hasAttachment: attachmentBytes != null);
    }

    final transaction = await _cashbookService.insertTransaction(
      input: input,
      recordedByUserId: recordedByUserId,
    );

    final transactionId = transaction['id'] as String;

    await _cashbookService.upsertVehicleExpense(
      transactionId: transactionId,
      input: input,
      userId: recordedByUserId,
    );

    if (attachmentBytes != null && attachmentFileName != null) {
      await _uploadAttachment(
        transactionId: transactionId,
        bytes: attachmentBytes,
        fileName: attachmentFileName,
        mimeType: attachmentMimeType,
        userId: recordedByUserId,
      );
    }

    final entry = await _cashbookService.fetchEntryById(transactionId);
    if (entry == null) {
      throw StateError('Created cashbook entry could not be loaded');
    }
    return entry.toEntity();
  }

  @override
  Future<CashbookEntry> updateEntry(
    String id,
    CashbookEntryInput input, {
    Uint8List? attachmentBytes,
    String? attachmentFileName,
    String? attachmentMimeType,
    required String recordedByUserId,
  }) async {
    if (!_cashbookService.isAvailable) {
      return _updateDemoEntry(id, input, hasAttachment: attachmentBytes != null);
    }

    await _cashbookService.updateTransaction(
      id: id,
      input: input,
      recordedByUserId: recordedByUserId,
    );

    await _cashbookService.upsertVehicleExpense(
      transactionId: id,
      input: input,
      userId: recordedByUserId,
    );

    if (attachmentBytes != null && attachmentFileName != null) {
      await _uploadAttachment(
        transactionId: id,
        bytes: attachmentBytes,
        fileName: attachmentFileName,
        mimeType: attachmentMimeType,
        userId: recordedByUserId,
      );
    }

    final entry = await _cashbookService.fetchEntryById(id);
    if (entry == null) {
      throw StateError('Updated cashbook entry could not be loaded');
    }
    return entry.toEntity();
  }

  @override
  Future<void> deleteEntry(
    String id, {
    required String deletedByUserId,
  }) async {
    if (!_cashbookService.isAvailable) {
      _demoEntries.removeWhere((entry) => entry.id == id);
      _recomputeDemoBalances();
      return;
    }

    await _cashbookService.softDeleteTransaction(
      id: id,
      deletedByUserId: deletedByUserId,
    );
  }

  Future<void> _uploadAttachment({
    required String transactionId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    required String userId,
  }) async {
    final path = await _storageService.uploadDocument(
      entityType: 'transactions',
      entityId: transactionId,
      fileName: fileName,
      bytes: bytes,
      contentType: mimeType,
    );

    await _cashbookService.insertDocument(
      transactionId: transactionId,
      title: fileName,
      filePath: path,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
      uploadedByUserId: userId,
    );
  }

  List<CashbookEntry> _filterDemoEntries(CashbookFilter filter) {
    Iterable<CashbookEntry> entries = _demoEntries;

    if (filter.entryType != null) {
      entries = entries.where((entry) => entry.entryType == filter.entryType);
    }

    if (filter.categoryCode != null) {
      entries =
          entries.where((entry) => entry.categoryCode == filter.categoryCode);
    }

    if (filter.customerId != null) {
      entries = entries.where((entry) => entry.customerId == filter.customerId);
    }

    if (filter.vehicleId != null) {
      entries = entries.where((entry) => entry.vehicleId == filter.vehicleId);
    }

    if (filter.currency != null) {
      entries = entries.where((entry) => entry.currency == filter.currency);
    }

    if (filter.startDate != null) {
      entries = entries.where(
        (entry) => !entry.entryDate.isBefore(_dateOnly(filter.startDate!)),
      );
    }

    if (filter.endDate != null) {
      entries = entries.where(
        (entry) => !entry.entryDate.isAfter(_dateOnly(filter.endDate!)),
      );
    }

    if (filter.searchQuery.trim().isNotEmpty) {
      final query = filter.searchQuery.trim().toLowerCase();
      entries = entries.where((entry) {
        return entry.description.toLowerCase().contains(query) ||
            (entry.notes?.toLowerCase().contains(query) ?? false) ||
            (entry.customerName?.toLowerCase().contains(query) ?? false) ||
            (entry.vehicleLabel?.toLowerCase().contains(query) ?? false);
      });
    }

    return entries.toList()
      ..sort((a, b) {
        final dateCompare = b.entryDate.compareTo(a.entryDate);
        if (dateCompare != 0) return dateCompare;
        return b.cashbookSequence.compareTo(a.cashbookSequence);
      });
  }

  CashbookDailySummary? _computeDemoDailySummary(DateTime date) {
    final day = _dateOnly(date);
    final entries = _demoEntries.where((entry) => _dateOnly(entry.entryDate) == day);
    if (entries.isEmpty) return null;

    final income = entries
        .where((entry) => entry.isIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amountXaf);
    final expense = entries
        .where((entry) => !entry.isIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amountXaf);

    return CashbookDailySummary(
      summaryDate: day,
      entryCount: entries.length,
      totalIncomeXaf: income,
      totalExpenseXaf: expense,
      netBalanceXaf: income - expense,
    );
  }

  CashbookPeriodSummary _computeDemoPeriodSummary(
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final entries = _demoEntries.where((entry) {
      final date = _dateOnly(entry.entryDate);
      return !date.isBefore(start) && !date.isAfter(end);
    });

    final incomeEntries = entries.where((entry) => entry.isIncome);
    final expenseEntries = entries.where((entry) => !entry.isIncome);

    final income =
        incomeEntries.fold<int>(0, (sum, entry) => sum + entry.amountXaf);
    final expense =
        expenseEntries.fold<int>(0, (sum, entry) => sum + entry.amountXaf);

    return CashbookPeriodSummary(
      startDate: start,
      endDate: end,
      entryCount: entries.length,
      totalIncomeXaf: income,
      totalExpenseXaf: expense,
      netBalanceXaf: income - expense,
      incomeCount: incomeEntries.length,
      expenseCount: expenseEntries.length,
    );
  }

  CashbookEntry _createDemoEntry(
    CashbookEntryInput input, {
    required bool hasAttachment,
  }) {
    final entry = CashbookEntry(
      id: _uuid.v4(),
      cashbookSequence: _demoEntries.length + 1,
      entryDate: _dateOnly(input.entryDate),
      entryType: input.entryType,
      categoryCode: input.categoryCode,
      currency: input.currency,
      amountOriginal: input.amountOriginal,
      exchangeRate: input.exchangeRate,
      amountXaf: input.amountXaf,
      signedAmountXaf:
          input.entryType == CashbookEntryType.income ? input.amountXaf : -input.amountXaf,
      runningBalanceXaf: 0,
      description: input.resolvedDescription,
      notes: input.notes,
      customerId: input.customerId,
      vehicleId: input.vehicleId,
      customerName: _demoCustomers
          .where((customer) => customer.id == input.customerId)
          .map((customer) => customer.fullName)
          .firstOrNull,
      vehicleLabel: _demoVehicles
          .where((vehicle) => vehicle.id == input.vehicleId)
          .map((vehicle) => '${vehicle.label} (${vehicle.licensePlate})')
          .firstOrNull,
      attachmentCount: hasAttachment ? 1 : 0,
      recordedBy: 'demo-user-id',
      createdAt: DateTime.now(),
    );

    _demoEntries.add(entry);
    _recomputeDemoBalances();
    return _demoEntries.firstWhere((item) => item.id == entry.id);
  }

  CashbookEntry _updateDemoEntry(
    String id,
    CashbookEntryInput input, {
    required bool hasAttachment,
  }) {
    final index = _demoEntries.indexWhere((entry) => entry.id == id);
    if (index == -1) throw StateError('Demo entry not found');

    final existing = _demoEntries[index];
    final updated = CashbookEntry(
      id: existing.id,
      cashbookSequence: existing.cashbookSequence,
      entryDate: _dateOnly(input.entryDate),
      entryType: input.entryType,
      categoryCode: input.categoryCode,
      currency: input.currency,
      amountOriginal: input.amountOriginal,
      exchangeRate: input.exchangeRate,
      amountXaf: input.amountXaf,
      signedAmountXaf:
          input.entryType == CashbookEntryType.income ? input.amountXaf : -input.amountXaf,
      runningBalanceXaf: existing.runningBalanceXaf,
      description: input.resolvedDescription,
      notes: input.notes,
      customerId: input.customerId,
      vehicleId: input.vehicleId,
      customerName: _demoCustomers
          .where((customer) => customer.id == input.customerId)
          .map((customer) => customer.fullName)
          .firstOrNull,
      vehicleLabel: _demoVehicles
          .where((vehicle) => vehicle.id == input.vehicleId)
          .map((vehicle) => '${vehicle.label} (${vehicle.licensePlate})')
          .firstOrNull,
      attachmentCount: hasAttachment ? 1 : existing.attachmentCount,
      recordedBy: existing.recordedBy,
      createdAt: existing.createdAt,
    );

    _demoEntries[index] = updated;
    _recomputeDemoBalances();
    return _demoEntries[index];
  }

  void _recomputeDemoBalances() {
    final sorted = [..._demoEntries]
      ..sort((a, b) {
        final dateCompare = a.entryDate.compareTo(b.entryDate);
        if (dateCompare != 0) return dateCompare;
        return a.cashbookSequence.compareTo(b.cashbookSequence);
      });

    var balance = 0;
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      balance += entry.signedAmountXaf;
      final index = _demoEntries.indexWhere((item) => item.id == entry.id);
      if (index == -1) continue;
      _demoEntries[index] = CashbookEntry(
        id: entry.id,
        cashbookSequence: entry.cashbookSequence,
        entryDate: entry.entryDate,
        entryType: entry.entryType,
        categoryCode: entry.categoryCode,
        currency: entry.currency,
        amountOriginal: entry.amountOriginal,
        exchangeRate: entry.exchangeRate,
        amountXaf: entry.amountXaf,
        signedAmountXaf: entry.signedAmountXaf,
        runningBalanceXaf: balance,
        description: entry.description,
        notes: entry.notes,
        customerId: entry.customerId,
        vehicleId: entry.vehicleId,
        customerName: entry.customerName,
        vehicleLabel: entry.vehicleLabel,
        attachmentCount: entry.attachmentCount,
        recordedBy: entry.recordedBy,
        createdAt: entry.createdAt,
      );
    }
  }

  static List<CashbookEntry> _seedDemoEntries() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return [
      CashbookEntry(
        id: 'demo-entry-1',
        cashbookSequence: 1,
        entryDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        entryType: CashbookEntryType.income,
        categoryCode: IncomeCategory.rentalPayment.code,
        currency: AppCurrency.xaf,
        amountOriginal: 150000,
        exchangeRate: 1,
        amountXaf: 150000,
        signedAmountXaf: 150000,
        runningBalanceXaf: 150000,
        description: 'Weekly rental — Hilux',
        notes: 'Paid in cash',
        customerId: 'demo-customer-1',
        customerName: 'Jean Mbarga',
        vehicleId: 'demo-vehicle-1',
        vehicleLabel: 'Toyota Hilux (CE-1234-A)',
        attachmentCount: 0,
        recordedBy: 'demo-user-id',
        createdAt: yesterday,
      ),
      CashbookEntry(
        id: 'demo-entry-2',
        cashbookSequence: 2,
        entryDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        entryType: CashbookEntryType.expense,
        categoryCode: ExpenseCategory.fuel.code,
        currency: AppCurrency.xaf,
        amountOriginal: 35000,
        exchangeRate: 1,
        amountXaf: 35000,
        signedAmountXaf: -35000,
        runningBalanceXaf: 115000,
        description: 'Fuel refill',
        vehicleId: 'demo-vehicle-1',
        vehicleLabel: 'Toyota Hilux (CE-1234-A)',
        attachmentCount: 1,
        recordedBy: 'demo-user-id',
        createdAt: yesterday,
      ),
      CashbookEntry(
        id: 'demo-entry-3',
        cashbookSequence: 3,
        entryDate: DateTime(today.year, today.month, today.day),
        entryType: CashbookEntryType.income,
        categoryCode: IncomeCategory.deposit.code,
        currency: AppCurrency.usd,
        amountOriginal: 200,
        exchangeRate: 600,
        amountXaf: 120000,
        signedAmountXaf: 120000,
        runningBalanceXaf: 235000,
        description: 'Security deposit (USD)',
        notes: 'Converted at 600 XAF/USD',
        customerId: 'demo-customer-2',
        customerName: 'Marie Nguema',
        attachmentCount: 0,
        recordedBy: 'demo-user-id',
        createdAt: today,
      ),
    ];
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

