import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

/// Initializes and provides access to the Supabase client.
abstract final class SupabaseService {
  static bool _initialized = false;
  static bool _connected = false;

  static bool get isInitialized => _initialized;
  static bool get isConnected => _connected;

  static supa.SupabaseClient get client => supa.Supabase.instance.client;

  static supa.GoTrueClient get auth => client.auth;

  static supa.SupabaseQueryBuilder table(String name) => client.from(name);

  /// Initializes Supabase with environment configuration.
  static Future<void> initialize() async {
    if (_initialized) return;

    await dotenv.load(fileName: 'assets/.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null ||
        anonKey == null ||
        url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project')) {
      AppLogger.info(
        'Supabase not configured — running in offline/demo mode',
      );
      _initialized = true;
      _connected = false;
      return;
    }

    await supa.Supabase.initialize(
      url: url,
      anonKey: anonKey, // ignore: deprecated_member_use
      authOptions: const supa.FlutterAuthClientOptions(
        authFlowType: supa.AuthFlowType.pkce,
      ),
      realtimeClientOptions: const supa.RealtimeClientOptions(
        logLevel: supa.RealtimeLogLevel.info,
      ),
    );

    _initialized = true;
    _connected = true;
    AppLogger.info('Supabase initialized: $url');
  }

  /// Wraps Supabase calls with consistent error handling.
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      return await operation().timeout(AppConstants.networkTimeout);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.code);
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
