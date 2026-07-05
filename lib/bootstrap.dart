import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/services/supabase_client_service.dart';
import 'providers/theme_provider.dart';

/// Application bootstrap — initializes services before runApp.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseClientService.instance.initialize();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const DMAutoOSApp(),
    ),
  );
}
