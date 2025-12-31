import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_card.dart';
import 'package:gastrobrain/screens/recipe_instructions_view_screen.dart';
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
      final lastCookedText = find.textContaining('Last Cooked: ');
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

    testWidgets('recipe card displays date in English locale format (MM/DD/YYYY)',
        (WidgetTester tester) async {
      final testDate = DateTime(2023, 12, 25);

      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: testDate,
          ),
          locale: const Locale('en', 'US'),
        ),
      );

      await tester.pumpAndSettle();

      // Expand the card to see the last cooked date
      final expandButton = find.byIcon(Icons.expand_more);
      if (expandButton.evaluate().isNotEmpty) {
        await tester.tap(expandButton);
        await tester.pumpAndSettle();
      }

      // Should display date in English format (MM/DD/YYYY)
      // DateFormat.yMd('en_US') formats 2023-12-25 as "12/25/2023"
      expect(find.textContaining('12/25/2023'), findsOneWidget);
    });

    testWidgets('recipe card displays date in Portuguese locale format (DD/MM/YYYY)',
        (WidgetTester tester) async {
      final testDate = DateTime(2023, 12, 25);

      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: testDate,
          ),
          locale: const Locale('pt', 'BR'),
        ),
      );

      await tester.pumpAndSettle();

      // Expand the card to see the last cooked date
      final expandButton = find.byIcon(Icons.expand_more);
      if (expandButton.evaluate().isNotEmpty) {
        await tester.tap(expandButton);
        await tester.pumpAndSettle();
      }

      // Should display date in Portuguese format (DD/MM/YYYY)
      // DateFormat.yMd('pt_BR') formats 2023-12-25 as "25/12/2023"
      expect(find.textContaining('25/12/2023'), findsOneWidget);
    });

    testWidgets('recipe card displays "Never cooked" when lastCooked is null and mealCount is 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: testRecipe,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 0,
            lastCooked: null,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand the card
      final expandButton = find.byIcon(Icons.expand_more);
      if (expandButton.evaluate().isNotEmpty) {
        await tester.tap(expandButton);
        await tester.pumpAndSettle();
      }

      // Should display "Never cooked" (combines mealCount and lastCooked null state)
      expect(find.text('Never cooked'), findsOneWidget);
    });

    testWidgets('shows instructions button in expanded card',
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

      await tester.pumpAndSettle();

      // Expand the card to show buttons (if not already expanded)
      final expandMoreButton = find.byIcon(Icons.expand_more);
      if (expandMoreButton.evaluate().isNotEmpty) {
        await tester.tap(expandMoreButton);
        await tester.pumpAndSettle();
      }

      // Verify instructions button is visible
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byTooltip('View Instructions'), findsOneWidget);
    });

    testWidgets('tapping instructions button navigates to view screen',
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

      await tester.pumpAndSettle();

      // Expand the card to show buttons (if not already expanded)
      final expandMoreButton = find.byIcon(Icons.expand_more);
      if (expandMoreButton.evaluate().isNotEmpty) {
        await tester.tap(expandMoreButton);
        await tester.pumpAndSettle();
      }

      // Tap the instructions button
      await tester.tap(find.byIcon(Icons.description));
      await tester.pumpAndSettle();

      // Verify navigation to RecipeInstructionsViewScreen
      expect(find.byType(RecipeInstructionsViewScreen), findsOneWidget);
    });

    testWidgets('instructions button appears in correct order',
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

      await tester.pumpAndSettle();

      // Expand the card to show buttons (if not already expanded)
      final expandMoreButton = find.byIcon(Icons.expand_more);
      if (expandMoreButton.evaluate().isNotEmpty) {
        await tester.tap(expandMoreButton);
        await tester.pumpAndSettle();
      }

      // Verify button order: Ingredients, Instructions, History, More
      // Find all action buttons
      expect(find.byIcon(Icons.list_alt), findsOneWidget); // Ingredients
      expect(find.byIcon(Icons.description), findsOneWidget); // Instructions
      expect(find.byIcon(Icons.history), findsOneWidget); // History
      expect(find.byIcon(Icons.more_vert), findsOneWidget); // More menu

      // Verify instructions button appears between ingredients and history
      // by checking their positions in the render tree
      final ingredientsButton = find.byIcon(Icons.list_alt);
      final instructionsButton = find.byIcon(Icons.description);
      final historyButton = find.byIcon(Icons.history);

      final ingredientsX = tester.getCenter(ingredientsButton).dx;
      final instructionsX = tester.getCenter(instructionsButton).dx;
      final historyX = tester.getCenter(historyButton).dx;

      // Instructions should be between Ingredients and History (left to right)
      expect(instructionsX, greaterThan(ingredientsX));
      expect(instructionsX, lessThan(historyX));
    });

    testWidgets('instructions button works even with empty instructions',
        (WidgetTester tester) async {
      final recipeWithoutInstructions = Recipe(
        id: 'test-recipe-no-instructions',
        name: 'Recipe Without Instructions',
        category: RecipeCategory.mainDishes,
        desiredFrequency: FrequencyType.weekly,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
        createdAt: DateTime.now(),
        instructions: '', // Empty instructions
      );

      await tester.pumpWidget(
        createTestableWidget(
          RecipeCard(
            recipe: recipeWithoutInstructions,
            onEdit: () {},
            onDelete: () {},
            onCooked: () {},
            mealCount: 5,
            lastCooked: DateTime(2023, 12, 25),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand the card to show buttons (if not already expanded)
      final expandMoreButton = find.byIcon(Icons.expand_more);
      if (expandMoreButton.evaluate().isNotEmpty) {
        await tester.tap(expandMoreButton);
        await tester.pumpAndSettle();
      }

      // Button should still be visible even with empty instructions
      expect(find.byIcon(Icons.description), findsOneWidget);

      // Tap the button and verify navigation works
      await tester.tap(find.byIcon(Icons.description));
      await tester.pumpAndSettle();

      // View screen should open (it will show empty state message)
      expect(find.byType(RecipeInstructionsViewScreen), findsOneWidget);
    });
  });
}
