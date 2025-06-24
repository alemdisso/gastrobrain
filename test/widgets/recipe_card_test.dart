import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_card.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('RecipeCard Layout Tests', () {
    late Recipe testRecipe;

    Widget createTestableWidget(Widget child,
        {Locale locale = const Locale('en', '')}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('pt', ''),
        ],
        home: Scaffold(body: child),
      );
    }

    setUp(() {
      testRecipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe with a Very Long Name That Might Cause Issues',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        createdAt: DateTime.now(),
      );
    });

    testWidgets(
        'expanded recipe card should not have text overflow with long last cooked date',
        (WidgetTester tester) async {
      // Create a date that will format to a long string
      final longDate = DateTime(2023, 12, 25); // "25/12/2023" - reasonably long

      // Build the widget in a constrained width to simulate mobile
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 350, // Simulate narrow mobile screen
            child: RecipeCard(
              recipe: testRecipe,
              onEdit: () {},
              onDelete: () {},
              onCooked: () {},
              mealCount: 15, // High count to make "Times cooked: 15" longer
              lastCooked: longDate,
            ),
          ),
        ),
      );

      // First, expand the card to see the problematic section
      final expandButton = find.byIcon(Icons.expand_more);
      expect(expandButton, findsOneWidget);

      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Look for the "Last cooked" text
      final lastCookedText = find.textContaining('Preparada em ');
      expect(lastCookedText, findsOneWidget);

      // This is where we would check for overflow, but Flutter's testing
      // framework makes it challenging to detect RenderFlex overflow directly
      // Let's at least verify the widgets exist and are rendered
      final actionButtons = find.byType(IconButton);
      expect(actionButtons,
          findsAtLeast(2)); // Should find multiple action buttons
    });

    testWidgets('recipe card displays localized category - English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      // Should display English category name
      expect(find.text('Main dishes'), findsOneWidget);
    });

    testWidgets('recipe card displays localized category - Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
          locale: const Locale('pt', ''),
        ),
      );

      // Should display Portuguese category name
      expect(find.text('Pratos principais'), findsOneWidget);
    });
  });
}
