import 'package:dm_auto_os/data/services/supabase_health_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseHealthCheck', () {
    test('verify returns unhealthy when credentials are not configured', () async {
      final result = await SupabaseHealthCheck.verify();

      expect(result.isHealthy, isFalse);
      expect(result.authReachable, isFalse);
      expect(result.databaseReachable, isFalse);
      expect(result.message, contains('not configured'));
    });
  });
}
