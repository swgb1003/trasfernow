import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/ai_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/live/live_screen.dart';
import '../features/market/market_screen.dart';
import '../features/my/my_screen.dart';
import '../features/search/search_screen.dart';
import 'root_shell.dart';

/// Builds a fresh [GoRouter]. This must NOT be a top-level singleton:
/// [GoRouter] keeps mutable navigation state (current location, history)
/// on the instance itself, so a shared singleton would leak the previous
/// screen's location across independent [TransferNowApp] instances (e.g.
/// between widget tests, each of which mounts its own app).
GoRouter buildAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/live',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/live', builder: (_, __) => const LiveScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/market', builder: (_, __) => const MarketScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/ai', builder: (_, __) => const AiScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/my', builder: (_, __) => const MyScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/case/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DetailScreen(caseId: state.pathParameters['id']!),
      ),
    ],
  );
}
