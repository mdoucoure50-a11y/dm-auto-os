import 'package:dm_auto_os/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig', () {
    test('isSupabaseConfigured is false without credentials', () {
      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('isSupabaseConfigured is false for placeholder values', () async {
      await EnvConfig.load();
      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('storage bucket defaults are non-empty', () {
      expect(EnvConfig.storageDocumentsBucket, 'documents');
      expect(EnvConfig.storageVehiclePhotosBucket, 'vehicle-photos');
    });

    test('supabaseUrlForLogs does not throw when url is null', () {
      expect(EnvConfig.supabaseUrlForLogs, isNull);
    });
  });
}
