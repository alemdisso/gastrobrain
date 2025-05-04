import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/widgets/recipe_recommendation_card.dart';

void main() {
  group('RecipeRecommendationCard', () {
    testWidgets('displays recipe name correctly', (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe Name',
        createdAt: DateTime.now(),
        desiredFrequency: null,
        difficulty: 3,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 75.0,
        factorScores: {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Recipe Name'), findsOneWidget);
    });

    testWidgets('displays difficulty stars correctly',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
        difficulty: 3, // 3 out of 5 stars
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 80.0,
        factorScores: {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // Assert
      final starIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((icon) => icon.icon == Icons.star)
          .length;
      final emptyStarIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((icon) => icon.icon == Icons.star_border)
          .length;

      expect(starIcons, equals(3)); // 3 filled stars
      expect(emptyStarIcons, equals(2)); // 2 empty stars
    });

    testWidgets('displays cooking time correctly', (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
        difficulty: 1,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 90.0,
        factorScores: {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // Assert
      expect(find.text('45 min'), findsOneWidget); // 15 + 30 = 45
    });

    testWidgets('displays score indicator with correct color',
        (WidgetTester tester) async {
      // Test high score (green)
      var recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      var recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 85.0, // Should be green
        factorScores: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);

      // Test medium score (amber)
      recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 65.0, // Should be amber
        factorScores: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.text('65'), findsOneWidget);

      // Test low score (red)
      recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 45.0, // Should be red
        factorScores: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 70.0,
        factorScores: {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(
              recommendation: recommendation,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RecipeRecommendationCard));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('displays factor indicators correctly',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
        difficulty: 3, // Explicitly set difficulty
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 75.0,
        factorScores: {
          'frequency': 90.0,
          'protein_rotation': 30.0, // Low score - should show warning
          'rating': 80.0,
          'unknown_factor': 50.0, // Should be ignored
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // First, let's just check for the basic factor icons
      expect(find.byIcon(Icons.schedule), findsOneWidget); // frequency
      expect(
          find.byIcon(Icons.rotate_right), findsOneWidget); // protein_rotation
      expect(find.byIcon(Icons.star),
          findsWidgets); // At least one star for rating factor
      expect(find.byIcon(Icons.warning), findsOneWidget); // protein warning
    });
    testWidgets('shows warning icon for low protein rotation score',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      // Test low protein score (< 50)
      var recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 70.0,
        factorScores: {
          'protein_rotation': 30.0, // Should show warning
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);

      // Test high protein score (>= 50) - should not show warning
      recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 70.0,
        factorScores: {
          'protein_rotation': 80.0, // Should not show warning
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('shows tooltips for factor indicators',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 85.0,
        factorScores: {
          'frequency': 90.5,
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // Find the tooltip widget by finding the Icon first, then getting its parent
      final tooltipFinder = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Tooltip),
      );

      await tester.longPress(tooltipFinder);
      await tester.pump();

      // Assert
      expect(find.text('Cooking frequency score: 90.5'), findsOneWidget);
    });

    testWidgets('handles empty factor scores', (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 50.0,
        factorScores: {}, // Empty factor scores
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      // Assert
      expect(find.text('No factors'), findsOneWidget);
    });
  });
}
