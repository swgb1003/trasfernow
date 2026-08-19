import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transfer_now/app/app.dart';

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
}
