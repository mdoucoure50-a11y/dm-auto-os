import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/loading_indicator.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

class DMAutoOSApp extends ConsumerWidget {
  const DMAutoOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: LoadingIndicator(message: 'Loading...'),
        ),
      );
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
