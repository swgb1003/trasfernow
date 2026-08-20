import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/favorites_provider.dart';
import '../data/notification_settings_provider.dart';
import '../data/onboarding_preferences.dart';
import 'router.dart';

class TransferNowApp extends ConsumerStatefulWidget {
  const TransferNowApp({super.key});

  @override
  ConsumerState<TransferNowApp> createState() => _TransferNowAppState();
}

class _TransferNowAppState extends ConsumerState<TransferNowApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Start local-first Firestore preference synchronization at app launch,
    // rather than waiting until the user opens MY or notification settings.
    // See SPEC.md §13-§15, §36.
    ref.read(favoritesProvider);
    ref.read(notificationSettingsProvider);

    // See SPEC.md §20: screens 01-03 appear only before initial setup.
    final onboardingComplete =
        ref.read(onboardingPreferencesProvider).isComplete;
    _router = buildAppRouter(
      initialLocation: onboardingComplete ? '/live' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TRANSFER NOW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
