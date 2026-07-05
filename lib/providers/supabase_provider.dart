import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/supabase_service.dart';

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
