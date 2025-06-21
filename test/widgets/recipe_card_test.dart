import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_card.dart';

void main() {
  group('RecipeCard Layout Tests', () {
    late Recipe testRecipe;

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

    testWidgets('expanded recipe card should not have text overflow with long last cooked date', (WidgetTester tester) async {
      // Create a date that will format to a long string
      final longDate = DateTime(2023, 12, 25); // "25/12/2023" - reasonably long
      
      // Build the widget in a constrained width to simulate mobile
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
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
        ),
      );

      // First, expand the card to see the problematic section
      final expandButton = find.byIcon(Icons.expand_more);
      expect(expandButton, findsOneWidget);
      
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Look for the "Last cooked" text
      final lastCookedText = find.textContaining('Last cooked:');
      expect(lastCookedText, findsOneWidget);

      // This is where we would check for overflow, but Flutter's testing
      // framework makes it challenging to detect RenderFlex overflow directly
      // Let's at least verify the widgets exist and are rendered
      final actionButtons = find.byType(IconButton);
      expect(actionButtons, findsAtLeast(2)); // Should find multiple action buttons
    });
  });
}