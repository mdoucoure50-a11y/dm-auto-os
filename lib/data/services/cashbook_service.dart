import '../../domain/entities/cashbook.dart';
import '../models/cashbook_models.dart';
import 'supabase_client_service.dart';
import 'supabase_database_service.dart';

/// Low-level Supabase operations for the cashbook module.
class CashbookService {
  CashbookService({
    required SupabaseDatabaseService databaseService,
    required SupabaseClientService clientService,
  })  : _databaseService = databaseService,
        _clientService = clientService;

  final SupabaseDatabaseService _databaseService;
  final SupabaseClientService _clientService;

  bool get isAvailable => _databaseService.isAvailable;

  Future<List<CashbookEntryModel>> fetchEntries(CashbookFilter filter) async {
    return _databaseService.execute(() async {
      dynamic query = _databaseService
          .from('cashbook_entries')
          .select()
          .order('entry_date', ascending: false)
          .order('cashbook_sequence', ascending: false);

      if (filter.entryType != null) {
        query = query.eq(
          'transaction_type',
          filter.entryType == CashbookEntryType.income ? 'income' : 'expense',
        );
      }

      if (filter.categoryCode != null) {
        query = query.eq('category', filter.categoryCode!);
      }

      if (filter.customerId != null) {
        query = query.eq('customer_id', filter.customerId!);
      }

      if (filter.vehicleId != null) {
        query = query.eq('vehicle_id', filter.vehicleId!);
      }

      if (filter.currency != null) {
        query = query.eq('currency_code', filter.currency!.code);
      }

      if (filter.startDate != null) {
        query = query.gte(
          'entry_date',
          _formatDate(filter.startDate!),
        );
      }

      if (filter.endDate != null) {
        query = query.lte(
          'entry_date',
          _formatDate(filter.endDate!),
        );
      }

      if (filter.searchQuery.trim().isNotEmpty) {
        final term = filter.searchQuery.trim();
        query = query.or(
          'description.ilike.%$term%,notes.ilike.%$term%,reference_number.ilike.%$term%,customer_name.ilike.%$term%,vehicle_label.ilike.%$term%',
        );
      }

      final rows = await query as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(CashbookEntryModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load cashbook entries');
  }

  Future<CashbookEntryModel?> fetchEntryById(String id) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('cashbook_entries')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return CashbookEntryModel.fromJson(row);
    }, errorMessage: 'Failed to load cashbook entry');
  }

  Future<CashbookDailySummaryModel?> fetchDailySummary(DateTime date) async {
    return _databaseService.execute(() async {
      final row = await _databaseService
          .from('cashbook_daily_summary')
          .select()
          .eq('summary_date', _formatDate(date))
          .maybeSingle();

      if (row == null) return null;
      return CashbookDailySummaryModel.fromJson(row);
    }, errorMessage: 'Failed to load daily summary');
  }

  Future<CashbookPeriodSummaryModel> fetchPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _databaseService.execute(() async {
      final rows = await _clientService.client.rpc(
        'get_cashbook_period_summary',
        params: {
          'p_start_date': _formatDate(startDate),
          'p_end_date': _formatDate(endDate),
        },
      ) as List<dynamic>;

      if (rows.isEmpty) {
        return CashbookPeriodSummaryModel(
          startDate: startDate,
          endDate: endDate,
          entryCount: 0,
          totalIncomeXaf: 0,
          totalExpenseXaf: 0,
          netBalanceXaf: 0,
          incomeCount: 0,
          expenseCount: 0,
        );
      }

      return CashbookPeriodSummaryModel.fromJson(
        rows.first as Map<String, dynamic>,
      );
    }, errorMessage: 'Failed to load period summary');
  }

  Future<List<CustomerOptionModel>> fetchCustomerOptions() async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('customers')
          .select('id, full_name')
          .isFilter('deleted_at', null)
          .order('full_name') as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(CustomerOptionModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load customers');
  }

  Future<List<VehicleOptionModel>> fetchVehicleOptions() async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('vehicles')
          .select('id, make, model, license_plate')
          .isFilter('deleted_at', null)
          .order('license_plate') as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(VehicleOptionModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load vehicles');
  }

  Future<Map<String, dynamic>> insertTransaction({
    required CashbookEntryInput input,
    required String recordedByUserId,
  }) async {
    return _databaseService.execute(() async {
      final payload = _transactionPayload(input, recordedByUserId);
      final row = await _databaseService
          .from('transactions')
          .insert(payload)
          .select()
          .single();
      return row;
    }, errorMessage: 'Failed to create cashbook entry');
  }

  Future<Map<String, dynamic>> updateTransaction({
    required String id,
    required CashbookEntryInput input,
    required String recordedByUserId,
  }) async {
    return _databaseService.execute(() async {
      final payload = _transactionPayload(input, recordedByUserId)
        ..remove('recorded_by')
        ..['updated_by'] = recordedByUserId;

      final row = await _databaseService
          .from('transactions')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return row;
    }, errorMessage: 'Failed to update cashbook entry');
  }

  Future<void> softDeleteTransaction({
    required String id,
    required String deletedByUserId,
  }) async {
    await _databaseService.execute(() async {
      await _databaseService.from('transactions').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'deleted_by': deletedByUserId,
        'updated_by': deletedByUserId,
      }).eq('id', id);
    }, errorMessage: 'Failed to delete cashbook entry');
  }

  Future<void> upsertVehicleExpense({
    required String transactionId,
    required CashbookEntryInput input,
    required String userId,
  }) async {
    if (input.entryType != CashbookEntryType.expense ||
        input.vehicleId == null) {
      return;
    }

    final expenseCategory =
        ExpenseCategory.fromCode(input.categoryCode).vehicleExpenseCode;

    await _databaseService.execute(() async {
      final existing = await _databaseService
          .from('expenses')
          .select('id')
          .eq('transaction_id', transactionId)
          .maybeSingle();

      final payload = {
        'vehicle_id': input.vehicleId,
        'transaction_id': transactionId,
        'category': expenseCategory,
        'description': input.resolvedDescription,
        'amount_xaf': input.amountXaf,
        'expense_date': _formatDate(input.entryDate),
        'notes': input.notes,
        'updated_by': userId,
      };

      if (existing == null) {
        await _databaseService.from('expenses').insert({
          ...payload,
          'created_by': userId,
        });
      } else {
        await _databaseService
            .from('expenses')
            .update(payload)
            .eq('transaction_id', transactionId);
      }
    }, errorMessage: 'Failed to sync vehicle expense');
  }

  Future<void> insertDocument({
    required String transactionId,
    required String title,
    required String filePath,
    required String fileName,
    String? mimeType,
    int? fileSizeBytes,
    required String uploadedByUserId,
  }) async {
    await _databaseService.execute(() async {
      await _databaseService.from('documents').insert({
        'title': title,
        'document_type': 'receipt',
        'file_path': filePath,
        'file_name': fileName,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'transaction_id': transactionId,
        'uploaded_by': uploadedByUserId,
        'created_by': uploadedByUserId,
      });
    }, errorMessage: 'Failed to save attachment metadata');
  }

  Map<String, dynamic> _transactionPayload(
    CashbookEntryInput input,
    String recordedByUserId,
  ) {
    return {
      'transaction_type':
          input.entryType == CashbookEntryType.income ? 'income' : 'expense',
      'category': input.categoryCode,
      'amount_xaf': input.amountXaf,
      'amount_original': input.amountOriginal,
      'currency_code': input.currency.code,
      'exchange_rate': input.exchangeRate,
      'description': input.resolvedDescription,
      'transaction_date': _formatDate(input.entryDate),
      'notes': input.notes,
      'customer_id': input.customerId,
      'vehicle_id': input.vehicleId,
      'recorded_by': recordedByUserId,
      'created_by': recordedByUserId,
      'is_cashbook_posted': true,
    };
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
