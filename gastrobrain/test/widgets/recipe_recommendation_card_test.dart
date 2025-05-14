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
      final difficultyIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((icon) => icon.icon == Icons.battery_full)
          .length;
      final emptyDifficultyIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((icon) => icon.icon == Icons.battery_0_bar)
          .length;

      expect(difficultyIcons, equals(3)); // 3 filled batteries
      expect(emptyDifficultyIcons, equals(2)); // 2 empty batteries
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

      // Assert - look for the expected format of tooltip text
      expect(find.textContaining('Cooking frequency'), findsOneWidget);
      expect(find.textContaining('90.5'), findsOneWidget);
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

    testWidgets('displays strength label below score indicator',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      // Test high score
      var recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 85.0,
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
      expect(find.text('Strong'), findsOneWidget);

      // Test medium score
      recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 65.0,
        factorScores: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.text('Good'), findsOneWidget);

      // Test low score
      recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 35.0,
        factorScores: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeRecommendationCard(recommendation: recommendation),
          ),
        ),
      );

      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('displays factor badges with strength labels',
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
        totalScore: 75.0,
        factorScores: {
          'frequency': 85.0, // Due
          'rating': 65.0, // Good
          'protein_rotation': 45.0, // Recent
          'variety_encouragement': 30.0, // Regular
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

      // Assert
      // Find all instances of strength labels
      expect(find.text('Due'), findsAtLeastNWidgets(1));
      expect(find.text('Good'), findsAtLeastNWidgets(1));
      expect(find.text('Recent'), findsAtLeastNWidgets(1));
      expect(find.text('Regular'), findsAtLeastNWidgets(1));

      // Should find the "Recent" warning for protein rotation
      expect(find.text('Recent'), findsOneWidget);

      // Verify that each factor icon is present
      expect(find.byIcon(Icons.schedule), findsOneWidget); // frequency
      expect(find.byIcon(Icons.star), findsWidgets); // rating
      expect(
          find.byIcon(Icons.rotate_right), findsOneWidget); // protein_rotation
      expect(
          find.byIcon(Icons.shuffle), findsOneWidget); // variety_encouragement
    });

    // Add this test to test/widgets/recipe_recommendation_card_test.dart
    testWidgets('shows appropriate protein warning based on score',
        (WidgetTester tester) async {
      // Arrange
      final recipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: null,
      );

      // Test very low protein score
      final recommendation = RecipeRecommendation(
        recipe: recipe,
        totalScore: 70.0,
        factorScores: {
          'protein_rotation': 20.0, // Very low score
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

      // Assert
      expect(find.text('Recent'), findsOneWidget);

      // Check tooltip with long press
      final tooltipFinder = find.ancestor(
        of: find.byIcon(Icons.warning),
        matching: find.byType(Tooltip),
      );

      await tester.longPress(tooltipFinder);
      await tester.pump();

      expect(find.textContaining('protein type was used recently'),
          findsOneWidget);
    });
  });
}
