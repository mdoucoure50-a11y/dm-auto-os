import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';
import '../data/datasources/supabase_service.dart';
import '../data/datasources/supabase_storage_service.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseService.isConnected) return null;
  try {
    return SupabaseService.client;
  } catch (_) {
    return null;
  }
});

final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  return SupabaseService.isConnected;
});

final supabaseEnvProvider = Provider<SupabaseEnvInfo>((ref) {
  return SupabaseEnvInfo(
    isConfigured: EnvConfig.isSupabaseConfigured,
    isConnected: SupabaseService.isConnected,
    url: EnvConfig.supabaseUrlForLogs,
    documentsBucket: EnvConfig.storageDocumentsBucket,
    vehiclePhotosBucket: EnvConfig.storageVehiclePhotosBucket,
  );
});

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return const SupabaseStorageService();
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
