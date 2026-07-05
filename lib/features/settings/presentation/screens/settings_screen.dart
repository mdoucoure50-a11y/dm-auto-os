import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isSupabaseConfigured = ref.watch(isSupabaseConfiguredProvider);

    return ContentContainer(
      child: ListView(
        children: [
          Text('Settings', style: context.textTheme.titleLarge),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text(user?.initials ?? '?')),
                  title: Text(user?.displayName ?? ''),
                  subtitle: Text('${user?.email ?? ''} · ${user?.role.label ?? ''}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggleDarkMode(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Business'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(
                    '${CurrencyConstants.name} (${CurrencyConstants.code})',
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Locale'),
                  subtitle: Text(AppConstants.defaultLocale),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'System'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isSupabaseConfigured
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: isSupabaseConfigured ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Database Connection'),
                  subtitle: Text(
                    isSupabaseConfigured
                        ? 'Connected to Supabase'
                        : 'Demo mode (Supabase not configured)',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: Text('${AppConstants.appName} v1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
