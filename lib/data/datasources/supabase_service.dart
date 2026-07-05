import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

/// Initializes and provides access to the Supabase client.
abstract final class SupabaseService {
  static bool _initialized = false;
  static bool _connected = false;

  static bool get isInitialized => _initialized;
  static bool get isConnected => _connected;

  static supa.SupabaseClient get client {
    _ensureConnected();
    return supa.Supabase.instance.client;
  }

  static supa.GoTrueClient get auth {
    _ensureConnected();
    return client.auth;
  }

  static supa.SupabaseStorageClient get storage {
    _ensureConnected();
    return client.storage;
  }

  static supa.SupabaseQueryBuilder table(String name) => client.from(name);

  static void _ensureConnected() {
    if (!_connected) {
      throw const NetworkException(
        'Supabase is not connected. Configure SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  /// Initializes Supabase Auth, PostgreSQL client, and Storage from env vars.
  static Future<void> initialize() async {
    if (_initialized) return;

    await EnvConfig.load();

    if (!EnvConfig.isSupabaseConfigured) {
      AppLogger.info(
        'Supabase not configured — running in demo mode. '
        'Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define-from-file.',
      );
      _initialized = true;
      _connected = false;
      return;
    }

    final url = EnvConfig.supabaseUrl!;
    final anonKey = EnvConfig.supabaseAnonKey!;

    await supa.Supabase.initialize(
      url: url,
      anonKey: anonKey, // ignore: deprecated_member_use
      authOptions: const supa.FlutterAuthClientOptions(
        authFlowType: supa.AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const supa.RealtimeClientOptions(
        logLevel: supa.RealtimeLogLevel.info,
      ),
    );

    _initialized = true;
    _connected = true;
    AppLogger.info('Supabase connected: ${EnvConfig.supabaseUrlForLogs}');
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
    } on supa.StorageException catch (e) {
      throw NetworkException(
        errorMessage ?? e.message,
        code: e.statusCode,
      );
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
