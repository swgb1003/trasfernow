import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class TransferNowApp extends StatelessWidget {
  const TransferNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TRANSFER NOW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
