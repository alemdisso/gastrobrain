import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/widgets/dashboard/quick_actions_panel.dart';

Widget _buildPanel({
  VoidCallback? onPlanToday,
  VoidCallback? onViewThisWeek,
  VoidCallback? onAddRecipe,
  VoidCallback? onBrowseRecipes,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(
      body: QuickActionsPanel(
        onViewThisWeek: onViewThisWeek ?? () {},
        onAddRecipe: onAddRecipe ?? () {},
        onBrowseRecipes: onBrowseRecipes ?? () {},
        onPlanToday: onPlanToday,
      ),
    ),
  );
}

void main() {
  group('QuickActionsPanel', () {
    testWidgets('renders Plan Today button', (WidgetTester tester) async {
      await tester.pumpWidget(_buildPanel());
      await tester.pumpAndSettle();

      expect(find.text('Plan Today'), findsOneWidget);
    });

    testWidgets('tapping Plan Today calls onPlanToday callback',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(_buildPanel(onPlanToday: () => called = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan Today'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('null onPlanToday does not throw on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildPanel(onPlanToday: null));
      await tester.pumpAndSettle();

      // Tapping a card with null onTap should be a no-op — no exception thrown
      await tester.tap(find.text('Plan Today'));
      await tester.pumpAndSettle();
      // No expect needed — test passes if no exception is thrown
    });
  });
}
