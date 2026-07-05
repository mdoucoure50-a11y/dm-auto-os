import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';
import '../data/services/supabase_auth_service.dart';
import '../data/services/supabase_client_service.dart';
import '../data/services/supabase_database_service.dart';
import '../data/services/supabase_storage_service.dart';

// ---------------------------------------------------------------------------
// Core client
// ---------------------------------------------------------------------------

final supabaseClientServiceProvider = Provider<SupabaseClientService>(
  (ref) => SupabaseClientService.instance,
);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final clientService = ref.watch(supabaseClientServiceProvider);
  if (!clientService.isConnected) return null;
  try {
    return clientService.client;
  } catch (_) {
    return null;
  }
});

final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(supabaseClientServiceProvider).isConnected;
});

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService(ref.watch(supabaseClientServiceProvider));
});

final supabaseDatabaseServiceProvider = Provider<SupabaseDatabaseService>((ref) {
  return SupabaseDatabaseService(ref.watch(supabaseClientServiceProvider));
});

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(
    clientService: ref.watch(supabaseClientServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Environment metadata (settings UI)
// ---------------------------------------------------------------------------

final supabaseEnvProvider = Provider<SupabaseEnvInfo>((ref) {
  final clientService = ref.watch(supabaseClientServiceProvider);
  return SupabaseEnvInfo(
    isConfigured: EnvConfig.isSupabaseConfigured,
    isConnected: clientService.isConnected,
    url: EnvConfig.supabaseUrlForLogs,
    documentsBucket: EnvConfig.storageDocumentsBucket,
    vehiclePhotosBucket: EnvConfig.storageVehiclePhotosBucket,
  );
});

/// Non-sensitive Supabase connection metadata for settings UI.
class SupabaseEnvInfo {
  const SupabaseEnvInfo({
    required this.isConfigured,
    required this.isConnected,
    this.url,
    required this.documentsBucket,
    required this.vehiclePhotosBucket,
  });

  final bool isConfigured;
  final bool isConnected;
  final String? url;
  final String documentsBucket;
  final String vehiclePhotosBucket;
}
