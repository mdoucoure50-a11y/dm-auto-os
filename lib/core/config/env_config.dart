import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads Supabase and app secrets from environment variables.
///
/// Priority (highest first):
/// 1. `--dart-define` / `--dart-define-from-file` (production builds)
/// 2. `flutter_dotenv` from bundled `assets/.env.example` (local fallback)
abstract final class EnvConfig {
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const String storageDocumentsBucketKey = 'SUPABASE_STORAGE_DOCUMENTS_BUCKET';
  static const String storageVehiclePhotosBucketKey =
      'SUPABASE_STORAGE_VEHICLE_PHOTOS_BUCKET';

  static const String _placeholderHost = 'your-project';
  static const String _placeholderKey = 'your-anon-key';

  static bool _dotenvLoaded = false;

  /// Loads dotenv assets. Safe to call multiple times.
  static Future<void> load() async {
    if (_dotenvLoaded) return;
    try {
      await dotenv.load(fileName: 'assets/.env.example');
      _dotenvLoaded = true;
    } catch (_) {
      // Dotenv is optional when using --dart-define-from-file.
    }
  }

  /// Supabase project URL (never hardcoded).
  static String? get supabaseUrl {
    const fromDefine = String.fromEnvironment(supabaseUrlKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvGet(supabaseUrlKey);
  }

  /// Supabase anonymous/publishable key (never hardcoded).
  static String? get supabaseAnonKey {
    const fromDefine = String.fromEnvironment(supabaseAnonKeyKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvGet(supabaseAnonKeyKey);
  }

  /// Storage bucket for document uploads.
  static String get storageDocumentsBucket {
    const fromDefine = String.fromEnvironment(storageDocumentsBucketKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvGet(storageDocumentsBucketKey) ?? 'documents';
  }

  /// Storage bucket for vehicle photos.
  static String get storageVehiclePhotosBucket {
    const fromDefine = String.fromEnvironment(storageVehiclePhotosBucketKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvGet(storageVehiclePhotosBucketKey) ?? 'vehicle-photos';
  }

  static String? _dotenvGet(String key) {
    if (!_dotenvLoaded) return null;
    return dotenv.maybeGet(key);
  }

  /// Whether real Supabase credentials are available.
  static bool get isSupabaseConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    if (url == null || key == null) return false;
    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains(_placeholderHost)) return false;
    if (key == _placeholderKey) return false;
    if (!url.startsWith('https://')) return false;

    return true;
  }

  /// Redacted URL for logging (no secrets).
  static String? get supabaseUrlForLogs {
    final url = supabaseUrl;
    if (url == null) return null;
    return url.replaceAll(RegExp(r'//.*@'), '//***@');
  }
}
