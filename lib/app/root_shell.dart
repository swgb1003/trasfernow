import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell for the 5 tabs: LIVE | SEARCH | MARKET | AI | MY.
/// See SPEC.md §20 画面構成.
class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.bolt, label: 'LIVE'),
    (icon: Icons.search, label: 'SEARCH'),
    (icon: Icons.show_chart, label: 'MARKET'),
    (icon: Icons.auto_awesome, label: 'AI'),
    (icon: Icons.person_outline, label: 'MY'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
