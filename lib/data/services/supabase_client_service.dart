import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../core/config/env_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

/// Initializes and exposes the Supabase client singleton.
class SupabaseClientService {
  SupabaseClientService._();

  static final SupabaseClientService instance = SupabaseClientService._();

  bool _initialized = false;
  bool _connected = false;

  bool get isInitialized => _initialized;
  bool get isConnected => _connected;

  /// Active Supabase client. Throws if not connected.
  supa.SupabaseClient get client {
    if (!_connected) {
      throw const NetworkException(
        'Supabase is not connected. Configure SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    return supa.Supabase.instance.client;
  }

  /// Initializes the Supabase client from environment variables.
  Future<void> initialize() async {
    if (_initialized) return;

    await EnvConfig.load();

    if (!EnvConfig.isSupabaseConfigured) {
      AppLogger.info(
        'Supabase not configured — demo mode. '
        'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY via '
        '--dart-define-from-file.',
      );
      _initialized = true;
      _connected = false;
      return;
    }

    await supa.Supabase.initialize(
      url: EnvConfig.supabaseUrl!,
      publishableKey: EnvConfig.supabasePublishableKey!,
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
}
