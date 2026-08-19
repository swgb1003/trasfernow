import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class TransferNowApp extends StatefulWidget {
  const TransferNowApp({super.key});

  @override
  State<TransferNowApp> createState() => _TransferNowAppState();
}

class _TransferNowAppState extends State<TransferNowApp> {
  late final GoRouter _router = buildAppRouter();

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
