import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/theme/app_theme.dart';
import 'package:gastrobrain/core/theme/design_tokens.dart';

void main() {
  group('Navigation Theme Configuration', () {
    test('lightTheme has BottomNavigationBar theme configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme.bottomNavigationBarTheme, isNotNull);
      expect(theme.bottomNavigationBarTheme.backgroundColor,
          equals(DesignTokens.surface));
      expect(theme.bottomNavigationBarTheme.selectedItemColor,
          equals(DesignTokens.primary));
      expect(theme.bottomNavigationBarTheme.unselectedItemColor,
          equals(DesignTokens.textSecondary));
      expect(theme.bottomNavigationBarTheme.type,
          equals(BottomNavigationBarType.fixed));
      expect(theme.bottomNavigationBarTheme.elevation,
          equals(DesignTokens.elevation2));
    });

    test('lightTheme has AppBar theme configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme.appBarTheme, isNotNull);
      expect(
          theme.appBarTheme.backgroundColor, equals(DesignTokens.surface));
      expect(theme.appBarTheme.foregroundColor,
          equals(DesignTokens.textPrimary));
      expect(theme.appBarTheme.elevation, equals(0));
      expect(theme.appBarTheme.centerTitle, equals(false));
    });

    test('lightTheme has TabBar theme configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme.tabBarTheme, isNotNull);
      expect(theme.tabBarTheme.indicatorColor, equals(DesignTokens.primary));
      expect(theme.tabBarTheme.labelColor, equals(DesignTokens.primary));
      expect(theme.tabBarTheme.unselectedLabelColor,
          equals(DesignTokens.textSecondary));
      expect(theme.tabBarTheme.indicatorSize, equals(TabBarIndicatorSize.tab));
    });

    test('TabBar theme uses correct typography', () {
      final theme = AppTheme.lightTheme;

      // Verify label style
      expect(theme.tabBarTheme.labelStyle, isNotNull);
      expect(theme.tabBarTheme.labelStyle!.fontSize,
          equals(DesignTokens.bodySmallSize));
      expect(theme.tabBarTheme.labelStyle!.fontWeight,
          equals(DesignTokens.weightMedium));

      // Verify unselected label style
      expect(theme.tabBarTheme.unselectedLabelStyle, isNotNull);
      expect(theme.tabBarTheme.unselectedLabelStyle!.fontSize,
          equals(DesignTokens.bodySmallSize));
      expect(theme.tabBarTheme.unselectedLabelStyle!.fontWeight,
          equals(DesignTokens.weightRegular));
    });

    test('TabBar theme has correct indicator styling', () {
      final theme = AppTheme.lightTheme;

      expect(theme.tabBarTheme.indicator, isNotNull);
      expect(theme.tabBarTheme.indicator, isA<UnderlineTabIndicator>());

      final indicator = theme.tabBarTheme.indicator as UnderlineTabIndicator;
      expect(indicator.borderSide.color, equals(DesignTokens.primary));
      expect(indicator.borderSide.width, equals(DesignTokens.borderWidthThin));
    });

    test('BottomNavigationBar theme uses correct typography', () {
      final theme = AppTheme.lightTheme;

      // Verify selected label style
      expect(theme.bottomNavigationBarTheme.selectedLabelStyle, isNotNull);
      expect(theme.bottomNavigationBarTheme.selectedLabelStyle!.fontSize,
          equals(DesignTokens.captionSize));
      expect(theme.bottomNavigationBarTheme.selectedLabelStyle!.fontWeight,
          equals(DesignTokens.weightMedium));

      // Verify unselected label style
      expect(theme.bottomNavigationBarTheme.unselectedLabelStyle, isNotNull);
      expect(theme.bottomNavigationBarTheme.unselectedLabelStyle!.fontSize,
          equals(DesignTokens.captionSize));
      expect(theme.bottomNavigationBarTheme.unselectedLabelStyle!.fontWeight,
          equals(DesignTokens.weightRegular));
    });

    test('AppBar theme uses correct typography', () {
      final theme = AppTheme.lightTheme;

      expect(theme.appBarTheme.titleTextStyle, isNotNull);
      expect(theme.appBarTheme.titleTextStyle!.fontSize,
          equals(DesignTokens.heading2Size));
      expect(theme.appBarTheme.titleTextStyle!.fontWeight,
          equals(DesignTokens.weightSemibold));
      expect(theme.appBarTheme.titleTextStyle!.height,
          equals(DesignTokens.tightLineHeight));
      expect(theme.appBarTheme.titleTextStyle!.color,
          equals(DesignTokens.textPrimary));
    });

    test('IconButton theme is configured for navigation icons', () {
      final theme = AppTheme.lightTheme;

      expect(theme.iconButtonTheme, isNotNull);
      expect(theme.iconButtonTheme.style, isNotNull);

      // Verify icon button styling
      final foregroundColor =
          theme.iconButtonTheme.style!.foregroundColor?.resolve({});
      expect(foregroundColor, equals(DesignTokens.textSecondary));

      final iconSize = theme.iconButtonTheme.style!.iconSize?.resolve({});
      expect(iconSize, equals(DesignTokens.iconSizeMedium));
    });
  });

  group('Navigation Theme Integration', () {
    testWidgets('TabBar uses theme configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Test'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                    Tab(text: 'Tab 3'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Content 1')),
                  Center(child: Text('Content 2')),
                  Center(child: Text('Content 3')),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify TabBar exists and uses theme
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(find.text('Tab 3'), findsOneWidget);

      // Verify TabBar widget doesn't override theme colors
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, isNull); // Uses theme
      expect(tabBar.unselectedLabelColor, isNull); // Uses theme
      expect(tabBar.indicator, isNull); // Uses theme
    });

    testWidgets('BottomNavigationBar uses theme configuration',
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

      // Verify BottomNavigationBar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify it doesn't override theme properties
      final bottomNavBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNavBar.selectedItemColor, isNull); // Uses theme
      expect(bottomNavBar.unselectedItemColor, isNull); // Uses theme
      expect(bottomNavBar.backgroundColor, isNull); // Uses theme
    });

    testWidgets('AppBar uses theme configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test Title'),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      // Verify AppBar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);

      // Verify AppBar doesn't override theme properties
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNull); // Uses theme
      expect(appBar.foregroundColor, isNull); // Uses theme
    });
  });
}
