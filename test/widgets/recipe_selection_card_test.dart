import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/recipe_selection_card.dart';

void main() {
  late Recipe testRecipe;
  late RecipeRecommendation testRecommendation;

  setUp(() {
    testRecipe = Recipe(
      id: 'test-recipe',
      name: 'Test Recipe',
      category: RecipeCategory.mainDishes,
      desiredFrequency: FrequencyType.weekly,
      difficulty: 3,
      prepTimeMinutes: 30,
      cookTimeMinutes: 45,
      rating: 4,
      createdAt: DateTime.now(),
    );

    testRecommendation = RecipeRecommendation(
      recipe: testRecipe,
      totalScore: 75.0,
      factorScores: {
        'frequency': 80.0,
        'protein_rotation': 70.0,
        'variety_encouragement': 75.0,
        'rating': 85.0,
      },
    );
  });

  group('RecipeSelectionCard - Basic Rendering', () {
    testWidgets('displays recipe name and category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Verify recipe name is displayed
      expect(find.text('Test Recipe'), findsOneWidget);

      // Verify category is displayed
      expect(find.text(RecipeCategory.mainDishes.displayName), findsOneWidget);
    });
    testWidgets('displays all three badge types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Should show all three badges
      expect(
          find.text('Explore'), findsOneWidget); // Timing badge (75% average)
      expect(find.text('Loved'), findsOneWidget); // Quality badge (85%)
      expect(find.text('Moderate'),
          findsOneWidget); // Effort badge (difficulty 3, total time 75min)
    });
  });

  group('RecipeSelectionCard - Interactions', () {
    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('displays tooltips on badge long press',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Find and verify quality badge tooltip
      final qualityBadge = find.text('Loved');
      await tester.longPress(qualityBadge);
      await tester.pump();

      expect(
        find.textContaining('Recipe Quality: 85/100'),
        findsOneWidget,
      );
      expect(
        find.textContaining('one of your favorites'),
        findsOneWidget,
      );
    });
  });

  group('RecipeSelectionCard - Badge Colors', () {
    testWidgets('quality badge shows correct colors based on score',
        (WidgetTester tester) async {
      final scores = [
        (
          score: 90.0,
          bg: Colors.green.withValues(alpha: 0.26),
          border: Colors.green,
          text: Colors.green.shade800
        ),
        (
          score: 72.0,
          bg: Colors.amber.withValues(alpha: 0.26),
          border: Colors.amber,
          text: Colors.amber.shade800
        ),
        (
          score: 30.0,
          bg: Colors.blueGrey.withValues(alpha: 0.26),
          border: Colors.blueGrey.shade700,
          text: Colors.blueGrey.shade700
        ),
        (
          score: 0.0,
          bg: Colors.grey.withValues(alpha: 0.26),
          border: Colors.grey.shade600,
          text: Colors.grey.shade700
        ),
      ];

      for (final scoreInfo in scores) {
        testRecommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {'rating': scoreInfo.score},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecipeSelectionCard(
                recommendation: testRecommendation,
              ),
            ),
          ),
        );

        // Find the badge container by its label text
        final badge = find.ancestor(
          of: find.text(_getQualityLabel(scoreInfo.score)),
          matching: find.byType(Container),
        );

        final container = tester.widget<Container>(badge);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, scoreInfo.bg,
            reason: 'Background color mismatch for score ${scoreInfo.score}');
        expect(decoration.border?.top.color, scoreInfo.border,
            reason: 'Border color mismatch for score ${scoreInfo.score}');

        final text = tester.widget<Text>(find.descendant(
          of: badge,
          matching: find.byType(Text),
        ));

        expect(text.style?.color, scoreInfo.text,
            reason: 'Text color mismatch for score ${scoreInfo.score}');
      }
    });

    testWidgets('timing badge shows correct colors based on score',
        (WidgetTester tester) async {
      final scores = [
        (
          score: 80.0,
          bg: Colors.green.withValues(alpha: 0.26),
          border: Colors.green,
          text: Colors.green.shade800
        ),
        (
          score: 60.0,
          bg: Colors.amber.withValues(alpha: 0.26),
          border: Colors.amber,
          text: Colors.amber.shade800
        ),
        (
          score: 30.0,
          bg: Colors.red.withValues(alpha: 0.26),
          border: Colors.red,
          text: Colors.red.shade800
        ),
      ];

      for (final scoreInfo in scores) {
        testRecommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {
            'frequency': scoreInfo.score,
            'protein_rotation': scoreInfo.score,
            'variety_encouragement': scoreInfo.score,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecipeSelectionCard(
                recommendation: testRecommendation,
              ),
            ),
          ),
        );

        // Find the badge container by its label text
        final badge = find.ancestor(
          of: find.text(_getTimingVarietyLabel(scoreInfo.score)),
          matching: find.byType(Container),
        );

        final container = tester.widget<Container>(badge);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, scoreInfo.bg,
            reason: 'Background color mismatch for score ${scoreInfo.score}');
        expect(decoration.border?.top.color, scoreInfo.border,
            reason: 'Border color mismatch for score ${scoreInfo.score}');

        final text = tester.widget<Text>(
            find.descendant(of: badge, matching: find.byType(Text)));

        expect(text.style?.color, scoreInfo.text,
            reason: 'Text color mismatch for score ${scoreInfo.score}');
      }
    });

    testWidgets('effort badge shows correct colors and labels',
        (WidgetTester tester) async {
      final testCases = [
        (
          difficulty: 2,
          time: 25,
          expectedLabel: 'Quick',
          bg: Colors.green.withValues(alpha: 0.26),
          border: Colors.green,
          text: Colors.green.shade800
        ),
        (
          difficulty: 3,
          time: 45,
          expectedLabel: 'Moderate',
          bg: Colors.amber.withValues(alpha: 0.26),
          border: Colors.amber,
          text: Colors.amber.shade800
        ),
        (
          difficulty: 4,
          time: 90,
          expectedLabel: 'Project',
          bg: Colors.red.withValues(alpha: 0.26),
          border: Colors.red,
          text: Colors.red.shade800
        ),
      ];

      for (final testCase in testCases) {
        testRecipe = Recipe(
          id: 'test-recipe',
          name: 'Test Recipe',
          category: RecipeCategory.mainDishes,
          prepTimeMinutes: testCase.time ~/ 2,
          cookTimeMinutes: testCase.time ~/ 2,
          difficulty: testCase.difficulty,
          createdAt: DateTime.now(), // Adding required createdAt field
        );

        testRecommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {'rating': 75.0},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecipeSelectionCard(
                recommendation: testRecommendation,
              ),
            ),
          ),
        );

        // Find the badge container by its label text
        final badge = find.ancestor(
          of: find.text(testCase.expectedLabel),
          matching: find.byType(Container),
        );

        final container = tester.widget<Container>(badge);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, testCase.bg,
            reason: 'Background color mismatch for ${testCase.expectedLabel}');
        expect(decoration.border?.top.color, testCase.border,
            reason: 'Border color mismatch for ${testCase.expectedLabel}');

        final text = tester.widget<Text>(
            find.descendant(of: badge, matching: find.byType(Text)));

        expect(text.style?.color, testCase.text,
            reason: 'Text color mismatch for ${testCase.expectedLabel}');
      }
    });

    testWidgets('handles missing recommendation data gracefully',
        (WidgetTester tester) async {
      testRecipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        createdAt: DateTime.now(),
      );

      // Test with empty factor scores
      testRecommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 75.0,
        factorScores: {}, // Empty factor scores
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Should show default values for badges
      expect(find.text('Repeat'), findsOneWidget); // Default timing badge
      expect(find.text('New'), findsOneWidget); // Default quality badge
      expect(find.text('Moderate'), findsOneWidget); // Default effort badge

      // Test with missing specific factors
      testRecommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 75.0,
        factorScores: {
          'other_factor': 50.0, // Some unrelated factor
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Should handle missing factors same as empty scores
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);

      // Test with 0.0 scores
      testRecommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 75.0,
        factorScores: {
          'frequency': 0.0,
          'protein_rotation': 0.0,
          'rating': 0.0,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Should show minimum value badges
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('New'),
          findsOneWidget); // Even with 0 rating, shows New for never cooked
      expect(find.text('Moderate'), findsOneWidget);

      // Test recipe with missing time/difficulty but has scores
      testRecipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        category: RecipeCategory.mainDishes,
        createdAt: DateTime.now(),
        // No prepTimeMinutes or difficulty
      );

      testRecommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 75.0,
        factorScores: {
          'frequency': 75.0,
          'protein_rotation': 75.0,
          'rating': 75.0,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeSelectionCard(
              recommendation: testRecommendation,
            ),
          ),
        ),
      );

      // Should still show correct timing/quality badges, but default effort
      expect(find.text('Explore'), findsOneWidget); // Based on 75.0 score
      expect(find.text('High'), findsOneWidget); // Based on 75.0 score
      expect(find.text('Moderate'),
          findsOneWidget); // Default effort without time/difficulty
    });
  });

  group('RecipeSelectionCard - Edge Cases', () {
    testWidgets('timing badge shows correct labels at boundaries',
        (WidgetTester tester) async {
      final scoreLabels = [
        (score: 75.0, expected: 'Explore'), // Exactly at first boundary
        (score: 74.9, expected: 'Varied'), // Just below first boundary
        (score: 60.0, expected: 'Varied'), // Exactly at second boundary
        (score: 59.9, expected: 'Recent'), // Just below second boundary
        (score: 40.0, expected: 'Recent'), // Exactly at third boundary
        (score: 39.9, expected: 'Repeat'), // Just below third boundary
        (score: 0.0, expected: 'Repeat'), // Minimum score
      ];

      for (final test in scoreLabels) {
        testRecommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {
            'frequency': test.score,
            'protein_rotation': test.score,
            'variety_encouragement': test.score,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecipeSelectionCard(
                recommendation: testRecommendation,
              ),
            ),
          ),
        );

        expect(find.text(test.expected), findsOneWidget,
            reason: 'Score ${test.score} should show label ${test.expected}');
      }
    });

    testWidgets('effort badge shows correct labels for different combinations',
        (WidgetTester tester) async {
      final tests = [
        (
          difficulty: 2,
          time: 30,
          expectedLabel: 'Quick'
        ), // Easy and fast (≤30 min)
        (
          difficulty: 2,
          time: 45,
          expectedLabel: 'Easy'
        ), // Easy but longer time
        (
          difficulty: 4,
          time: 90,
          expectedLabel: 'Project'
        ), // Hard and very long (>60 min)
        (
          difficulty: 4,
          time: 45,
          expectedLabel: 'Complex'
        ), // Hard but shorter time
        (difficulty: 3, time: 45, expectedLabel: 'Moderate'), // Everything else
      ];

      for (final test in tests) {
        testRecipe = Recipe(
          id: 'test-recipe',
          name: 'Test Recipe',
          category: RecipeCategory.mainDishes,
          createdAt: DateTime.now(),
          difficulty: test.difficulty,
          prepTimeMinutes: test.time ~/ 2,
          cookTimeMinutes: test.time ~/ 2,
        );

        testRecommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {'rating': 75.0},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecipeSelectionCard(
                recommendation: testRecommendation,
              ),
            ),
          ),
        );

        expect(find.text(test.expectedLabel), findsOneWidget,
            reason:
                'Difficulty ${test.difficulty} and time ${test.time} should show ${test.expectedLabel}');
      }
    });
  });
}

// Helper function to match the widget's logic
String _getQualityLabel(double score) {
  if (score >= 85) return 'Loved';
  if (score >= 70) return 'Great';
  if (score >= 50) return 'Good';
  if (score > 0) return 'Fair';
  return 'New';
}

String _getTimingVarietyLabel(double score) {
  if (score >= 75) return 'Explore'; // High variety, good timing
  if (score >= 60) return 'Varied'; // Good variety, decent timing
  if (score >= 40) return 'Recent'; // Recently used proteins/recipes
  return 'Repeat'; // Very recently used
}
