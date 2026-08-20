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

    // The AI要約 card sits further down the page than the initial viewport.
    final detailScrollable = find.descendant(
      of: find.byKey(const ValueKey('detail-content-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('AI SUMMARY'),
      200,
      scrollable: detailScrollable,
    );
    expect(find.text('現在の状況'), findsOneWidget);

    // The summary card's button hands off to the AI REPORTER tab.
    await tester.ensureVisible(find.text('もっと詳しくAIに質問する'));
    await tester.pump();
    await tester.tap(find.text('もっと詳しくAIに質問する'));
    await tester.pumpAndSettle();
    expect(find.text('AI REPORTER'), findsOneWidget);
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

  testWidgets('MY screen manages favorite clubs and players', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();

    // Seeded favorites (FavoritesNotifier's initial state).
    expect(find.text('Chelsea'), findsOneWidget);
    expect(find.text('Alejandro Garnacho'), findsOneWidget);

    // Remove a favorite club via its "x" badge.
    await tester.tap(find.byKey(const ValueKey('remove-club-Chelsea')));
    await tester.pumpAndSettle();
    expect(find.text('Chelsea'), findsNothing);

    // Add it back via the "追加" picker sheet (club section is first).
    await tester.tap(find.text('追加').first);
    await tester.pumpAndSettle();
    expect(find.text('クラブを追加'), findsOneWidget);
    final pickerScrollable = find.descendant(
      of: find.byKey(const ValueKey('add-picker-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text('Liverpool'), 50,
        scrollable: pickerScrollable);
    // scrollUntilVisible stops as soon as any part is visible, which can
    // leave it only partially in view (and its computed center outside the
    // sheet's clip bounds); nudge it fully into view before tapping.
    await tester.ensureVisible(find.text('Liverpool'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liverpool'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 60)); // dismiss the sheet
    await tester.pumpAndSettle();

    expect(find.text('Liverpool'), findsOneWidget);

    // The star toggle on the detail screen shares state with this screen.
    await tester.tap(find.text('SEARCH'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Osimhen');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Victor Osimhen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.star), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();

    expect(find.text('Victor Osimhen'), findsNothing);
  });

  testWidgets(
    'club page lists IN/OUT candidates and is reachable from favorites and detail screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
      await tester.pumpAndSettle();

      // From MY page: tap the seeded "Man Utd" favorite club chip.
      await tester.tap(find.text('MY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Man Utd'));
      await tester.pumpAndSettle();

      expect(find.textContaining('IN ('), findsOneWidget);
      expect(find.textContaining('OUT ('), findsOneWidget);
      // IN tab is selected by default: Everton → Man Utd is a rumour.
      expect(find.text('Jarrad Branthwaite'), findsOneWidget);

      await tester.tap(find.textContaining('OUT ('));
      await tester.pumpAndSettle();
      // Man Utd → Chelsea (Garnacho) shows up as an OUT candidate.
      expect(find.text('Alejandro Garnacho'), findsOneWidget);

      // The star icon here toggles the same favorites state as MY page.
      expect(find.byIcon(Icons.star), findsOneWidget);
      await tester.tap(find.byIcon(Icons.star));
      await tester.pump();
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      // Tapping the OUT row opens that case's detail screen.
      await tester.tap(find.text('Alejandro Garnacho'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Alejandro Garnacho'), findsWidgets);

      // From there, tapping the destination club badge opens Chelsea's
      // club page, which should list Garnacho among its IN candidates.
      await tester.tap(find.text('Chelsea'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('IN (2)'), findsOneWidget);
    },
  );

  testWidgets(
    'notification settings toggle categories and the test buttons fail gracefully without a device',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: TransferNowApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('通知設定'));
      await tester.pumpAndSettle();

      expect(find.text('🔥 BREAKING'), findsOneWidget);
      expect(find.text('🔥 BREAKINGを送る'), findsOneWidget);

      // Turning a category off disables its test button.
      await tester.tap(find.widgetWithText(SwitchListTile, '🔥 BREAKING'));
      await tester.pump();
      final breakingButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('🔥 BREAKINGを送る'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(breakingButton.onPressed, isNull);

      // The plugin has no platform implementation in the test harness, so
      // this must fail gracefully (no crash) rather than throw.
      await tester.ensureVisible(find.text('🤝 AGREEMENTを送る'));
      await tester.pump();
      await tester.tap(find.text('🤝 AGREEMENTを送る'));
      await tester.pump();
      expect(find.textContaining('通知の送信に失敗しました'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
