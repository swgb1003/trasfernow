import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transfer_now/app/app.dart';
import 'package:transfer_now/widgets/official_reveal_overlay.dart';

void main() {
  testWidgets('LIVE screen shows the top breaking transfer case', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: TransferNowApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('LIVE'), findsWidgets);
    expect(find.text('🔥 BREAKING'), findsOneWidget);

    await tester.tap(find.text('SEARCH'));
    await tester.pumpAndSettle();
    expect(find.text('SEARCH'), findsWidgets);
  });

  testWidgets('MARKET screen renders overview stats and trending list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MARKET'));
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S MARKET"), findsOneWidget);
    expect(find.text('TRENDING NOW'), findsOneWidget);

    await tester.tap(find.text('RANKINGS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('€'), findsWidgets);
  });

  testWidgets('AI screen answers a suggested question about a club', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();

    expect(find.text('今日Chelseaで何か動いた?'), findsOneWidget);

    await tester.tap(find.text('今日Chelseaで何か動いた?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chelseaに関係する移籍案件'), findsOneWidget);
  });

  testWidgets('detail screen timeline animates in without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
    await tester.pumpAndSettle();

    // Top BREAKING card (finalStage, not OFFICIAL) opens the detail screen.
    await tester.tap(find.text('🔥 BREAKING'));
    // The timeline reveal + pulse animation never settle on their own
    // (pulse loops forever), so step the clock manually instead of
    // pumpAndSettle.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('移籍タイムライン'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OFFICIAL case shows the reveal overlay and it dismisses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SEARCH'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Isak');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alexander Isak'));
    // One frame to let the push transition start, then let it finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "OFFICIAL" alone is ambiguous (the underlying detail screen's own
    // 成立可能性 label also reads "OFFICIAL" at 100%), so key off text
    // that's unique to the celebration overlay.
    expect(find.byType(OfficialRevealOverlay), findsOneWidget);
    expect(find.textContaining('WELCOME TO'), findsOneWidget);

    // Skip the celebration by tapping it, then let the exit fade finish.
    await tester.tap(find.byType(OfficialRevealOverlay));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(OfficialRevealOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
