import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'supabase_client_service.dart';

/// Supabase PostgreSQL database service (PostgREST).
class SupabaseDatabaseService {
  SupabaseDatabaseService(this._clientService);

  final SupabaseClientService _clientService;

  bool get isAvailable => _clientService.isConnected;

  /// Returns a query builder for [tableName].
  supa.SupabaseQueryBuilder from(String tableName) {
    return _clientService.client.from(tableName);
  }

  /// Fetches a single row by primary key, or null if not found.
  Future<Map<String, dynamic>?> fetchById(
    String tableName,
    String id,
  ) async {
    return execute(
      () => from(tableName).select().eq('id', id).maybeSingle(),
      errorMessage: 'Failed to fetch $tableName record',
    );
  }

  /// Wraps database calls with timeout and error handling.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    if (!_clientService.isConnected) {
      throw const NetworkException(
        'Database requires Supabase connection',
      );
    }

    try {
      return await operation().timeout(AppConstants.networkTimeout);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(
        errorMessage ?? e.message,
        code: e.code,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(errorMessage ?? e.toString());
    }
  }
}
