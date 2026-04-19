import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/core/theme/app_theme.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/widgets/dashboard/quick_actions_panel.dart';

void main() {
  group('BottomNavigationBar - Theme Compliance', () {
    testWidgets('BottomNavigationBar without overrides uses theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      );

      // Get the BottomNavigationBar widget
      final bottomNavBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));

      // Verify it doesn't have inline overrides (relies on theme)
      expect(bottomNavBar.selectedItemColor, isNull);
      expect(bottomNavBar.unselectedItemColor, isNull);
      expect(bottomNavBar.backgroundColor, isNull);
      expect(bottomNavBar.type, isNull); // Should use theme type
    });

    testWidgets('BottomNavigationBar renders with theme colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      );

      // Verify BottomNavigationBar is rendered
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar tab switching works',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(child: Text('Content $selectedIndex')),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initially on index 0
      expect(find.text('Content 0'), findsOneWidget);

      // Tap second item
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Verify tab switched
      expect(find.text('Content 1'), findsOneWidget);
    });
  });

  group('BackButton - Theme Compliance', () {
    testWidgets('BackButton uses theme styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test'),
              leading: BackButton(
                onPressed: () {}, // Custom action
              ),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      // Verify BackButton is rendered
      expect(find.byType(BackButton), findsOneWidget);

      // Verify it doesn't override icon
      final backButton = tester.widget<BackButton>(find.byType(BackButton));
      expect(backButton.color, isNull); // Uses theme
    });

    testWidgets('BackButton with custom onPressed works',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test'),
              leading: BackButton(
                onPressed: () {
                  wasPressed = true;
                },
              ),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      // Tap the back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify custom callback was called
      expect(wasPressed, isTrue);
    });
  });

  group('Plan Today vs View This Week (#295)', () {
    Widget buildPanel({
      required VoidCallback onPlanToday,
      required VoidCallback onViewThisWeek,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Scaffold(
          body: QuickActionsPanel(
            onPlanToday: onPlanToday,
            onViewThisWeek: onViewThisWeek,
            onAddRecipe: () {},
            onBrowseRecipes: () {},
          ),
        ),
      );
    }

    testWidgets('Plan Today and View This Week fire independent callbacks',
        (WidgetTester tester) async {
      bool planTodayCalled = false;
      bool viewThisWeekCalled = false;

      await tester.pumpWidget(buildPanel(
        onPlanToday: () => planTodayCalled = true,
        onViewThisWeek: () => viewThisWeekCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan Today'));
      await tester.pumpAndSettle();
      expect(planTodayCalled, isTrue);
      expect(viewThisWeekCalled, isFalse);
    });

    testWidgets('View This Week does not trigger Plan Today callback',
        (WidgetTester tester) async {
      bool planTodayCalled = false;

      await tester.pumpWidget(buildPanel(
        onPlanToday: () => planTodayCalled = true,
        onViewThisWeek: () {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      expect(planTodayCalled, isFalse);
    });
  });
}
