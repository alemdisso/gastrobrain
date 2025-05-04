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
  });
}
