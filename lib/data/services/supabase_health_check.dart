import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';

/// Result of a Supabase connectivity health check.
class SupabaseHealthResult {
  const SupabaseHealthResult({
    required this.isHealthy,
    this.authReachable = false,
    this.databaseReachable = false,
    this.message,
  });

  final bool isHealthy;
  final bool authReachable;
  final bool databaseReachable;
  final String? message;
}

/// Verifies Supabase Auth and PostgREST are reachable with the publishable key.
abstract final class SupabaseHealthCheck {
  static Future<SupabaseHealthResult> verify() async {
    final url = EnvConfig.supabaseUrl;
    final key = EnvConfig.supabasePublishableKey;

    if (url == null || key == null || !EnvConfig.isSupabaseConfigured) {
      return const SupabaseHealthResult(
        isHealthy: false,
        message: 'Supabase credentials not configured',
      );
    }

    final headers = {
      'apikey': key,
      'Authorization': 'Bearer $key',
    };

    try {
      final authResponse = await http
          .get(Uri.parse('$url/auth/v1/health'), headers: headers)
          .timeout(AppConstants.networkTimeout);

      final restResponse = await http
          .get(Uri.parse('$url/rest/v1/'), headers: headers)
          .timeout(AppConstants.networkTimeout);

      final authOk = authResponse.statusCode == 200;
      final restOk = restResponse.statusCode == 200;

      if (authOk && restOk) {
        return const SupabaseHealthResult(
          isHealthy: true,
          authReachable: true,
          databaseReachable: true,
          message: 'Auth and database reachable',
        );
      }

      return SupabaseHealthResult(
        isHealthy: false,
        authReachable: authOk,
        databaseReachable: restOk,
        message: _failureMessage(authOk, restOk),
      );
    } catch (e) {
      return SupabaseHealthResult(
        isHealthy: false,
        message: 'Health check failed: $e',
      );
    }
  }

  static String _failureMessage(bool authOk, bool restOk) {
    if (!authOk && !restOk) {
      return 'Auth and database unreachable — check URL and publishable key';
    }
    if (!authOk) return 'Authentication service unreachable';
    return 'Database API unreachable';
  }
}
