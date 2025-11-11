// test/core/services/recommendation_factors/protein_rotation_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/core/services/recommendation_factors/protein_rotation_factor.dart';
import 'package:gastrobrain/core/services/meal_plan_analysis_service.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('ProteinRotationFactor', () {
    late ProteinRotationFactor factor;

    setUp(() {
      factor = ProteinRotationFactor();
    });

    test('should have id "protein_rotation"', () {
      expect(factor.id, equals('protein_rotation'));
    });

    test('should have weight 30', () {
      expect(factor.defaultWeight, equals(30));
    });

    test('should require proteinTypes and recentMeals data', () {
      expect(factor.requiredData, contains('proteinTypes'));
      expect(factor.requiredData, contains('recentMeals'));
    });

    test('should give high score to recipes with no proteins', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Vegetable Stir Fry',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipe.id: {}, // No proteins
        },
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - should get a neutral-to-good score for recipes with no proteins
      expect(score, equals(70.0));
    });

    test('should give high score to recipes with only non-main proteins',
        () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Tofu Stir Fry',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipe.id: {ProteinType.plantBased}, // Non-main protein
        },
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - should get a good score for recipes with only non-main proteins
      expect(score, equals(90.0));
    });

    test('should give perfect score when no recent meals', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Curry',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipe.id: {ProteinType.chicken}, // Main protein
        },
        'recentMeals': <Map<String, dynamic>>[], // No recent meals
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - should get perfect score with no recent meals
      expect(score, equals(100.0));
    });

    test('should apply full penalty for same protein used yesterday', () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Beef Stew',
        createdAt: DateTime.now(),
      );

      final yesterdayRecipeId = IdGenerator.generateId();
      final yesterdayRecipe = Recipe(
        id: yesterdayRecipeId,
        name: 'Beef Tacos',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {ProteinType.beef}, // Today's recipe has beef
          yesterdayRecipeId: {
            ProteinType.beef
          }, // Yesterday's recipe also had beef
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [yesterdayRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - should get a 0 score due to 100% penalty
      expect(score, equals(0.0));
    });

    test('should apply partial penalty for same protein used 3 days ago',
        () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Grilled Chicken',
        createdAt: DateTime.now(),
      );

      final oldRecipeId = IdGenerator.generateId();
      final oldRecipe = Recipe(
        id: oldRecipeId,
        name: 'Chicken Soup',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {ProteinType.chicken}, // Today's recipe has chicken
          oldRecipeId: {ProteinType.chicken}, // 3 days ago also had chicken
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [oldRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 3)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - 50% penalty for 3 days ago = score of 50
      expect(score, equals(50.0));
    });

    test('should handle multiple proteins in a recipe', () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Surf and Turf',
        createdAt: DateTime.now(),
      );

      final beefRecipeId = IdGenerator.generateId();
      final beefRecipe = Recipe(
        id: beefRecipeId,
        name: 'Beef Stir Fry',
        createdAt: DateTime.now(),
      );

      final seafoodRecipeId = IdGenerator.generateId();
      final seafoodRecipe = Recipe(
        id: seafoodRecipeId,
        name: 'Shrimp Pasta',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {
            ProteinType.beef,
            ProteinType.seafood
          }, // Today's recipe has both beef and seafood
          beefRecipeId: {ProteinType.beef}, // 1 day ago had beef
          seafoodRecipeId: {ProteinType.seafood}, // 2 days ago had seafood
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [beefRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
          {
            'recipes': [seafoodRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 2)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Average of 100% penalty for beef and 75% penalty for seafood = 87.5% penalty = 12.5 score
      expect(score, closeTo(12.5, 0.1));
    });

    test('should ignore proteins used more than 4 days ago', () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Pork Chops',
        createdAt: DateTime.now(),
      );

      final oldRecipeId = IdGenerator.generateId();
      final oldRecipe = Recipe(
        id: oldRecipeId,
        name: 'Pork Roast',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {ProteinType.pork}, // Today's recipe has pork
          oldRecipeId: {ProteinType.pork}, // 5 days ago also had pork
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [oldRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 5)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - No penalty for proteins used 5+ days ago
      expect(score, equals(100.0));
    });

    test('should prioritize the most recent occurrence of a protein', () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Fish Tacos',
        createdAt: DateTime.now(),
      );

      final recentFishId = IdGenerator.generateId();
      final recentFish = Recipe(
        id: recentFishId,
        name: 'Grilled Fish',
        createdAt: DateTime.now(),
      );

      final olderFishId = IdGenerator.generateId();
      final olderFish = Recipe(
        id: olderFishId,
        name: 'Fish Curry',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {ProteinType.fish}, // Today's recipe has fish
          recentFishId: {ProteinType.fish}, // 1 day ago was fish
          olderFishId: {ProteinType.fish}, // 3 days ago was also fish
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [recentFish],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
          {
            'recipes': [olderFish],
            'cookedAt': DateTime.now().subtract(const Duration(days: 3)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Should use the 1-day penalty (100%) not the 3-day penalty
      expect(score, equals(0.0));
    });

    test('should count duplicate proteins only once in the same recipe',
        () async {
      // Arrange - Recipe with multiple ingredients containing the same protein
      // (e.g., "Beef" and "Beef Stock" both contain beef)
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Beef Ragù',
        createdAt: DateTime.now(),
      );

      final yesterdayRecipeId = IdGenerator.generateId();
      final yesterdayRecipe = Recipe(
        id: yesterdayRecipeId,
        name: 'Grilled Chicken',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          // The Set automatically deduplicates if beef appears multiple times
          recipeId: {ProteinType.beef}, // Contains beef (from both "Beef" and "Beef Stock")
          yesterdayRecipeId: {ProteinType.chicken}, // Had chicken yesterday
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [yesterdayRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Should get perfect score since beef wasn't used recently
      // If duplicates were counted separately, the score calculation would be wrong
      expect(score, equals(100.0));
    });

    test('should handle beef ragù with beef used yesterday (duplicate protein edge case)',
        () async {
      // Arrange - This tests the exact scenario from the issue
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Beef Ragù',
        createdAt: DateTime.now(),
      );

      final yesterdayRecipeId = IdGenerator.generateId();
      final yesterdayRecipe = Recipe(
        id: yesterdayRecipeId,
        name: 'Beef Tacos',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          // Even if ingredients list has [beef, beef] from "Beef + Beef Stock",
          // the Set ensures we only have one beef entry
          recipeId: {ProteinType.beef},
          yesterdayRecipeId: {ProteinType.beef},
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [yesterdayRecipe],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Should apply 100% penalty once (not twice)
      // Score = 100 - (100% penalty) = 0.0
      expect(score, equals(0.0));
    });

    test('should track proteins from secondary recipes in multi-recipe meals',
        () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Beef Tacos',
        createdAt: DateTime.now(),
      );

      // Yesterday's meal had chicken curry (primary) + beef empanadas (side)
      final chickenCurryId = IdGenerator.generateId();
      final chickenCurry = Recipe(
        id: chickenCurryId,
        name: 'Chicken Curry',
        createdAt: DateTime.now(),
      );

      final beefEmpanadasId = IdGenerator.generateId();
      final beefEmpanadas = Recipe(
        id: beefEmpanadasId,
        name: 'Beef Empanadas',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {ProteinType.beef}, // Today's recipe has beef
          chickenCurryId: {ProteinType.chicken}, // Yesterday's primary dish
          beefEmpanadasId: {ProteinType.beef}, // Yesterday's side dish
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            // Multi-recipe meal with both chicken (primary) and beef (secondary)
            'recipes': [chickenCurry, beefEmpanadas],
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Should apply 100% penalty for beef from the side dish
      // This proves that secondary recipe proteins are tracked
      expect(score, equals(0.0));
    });

    test(
        'should track multiple proteins from multi-recipe meals with different penalties',
        () async {
      // Arrange
      final recipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: recipeId,
        name: 'Surf and Turf', // Has both beef and seafood
        createdAt: DateTime.now(),
      );

      // Two days ago: Chicken (primary) + Beef side
      final chickenId = IdGenerator.generateId();
      final chicken = Recipe(
        id: chickenId,
        name: 'Grilled Chicken',
        createdAt: DateTime.now(),
      );

      final beefSideId = IdGenerator.generateId();
      final beefSide = Recipe(
        id: beefSideId,
        name: 'Beef Skewers',
        createdAt: DateTime.now(),
      );

      // Three days ago: Seafood Paella (single recipe)
      final paellaId = IdGenerator.generateId();
      final paella = Recipe(
        id: paellaId,
        name: 'Seafood Paella',
        createdAt: DateTime.now(),
      );

      final context = {
        'proteinTypes': <String, Set<ProteinType>>{
          recipeId: {
            ProteinType.beef,
            ProteinType.seafood
          }, // Today has both
          chickenId: {ProteinType.chicken},
          beefSideId: {ProteinType.beef}, // Beef from side dish 2 days ago
          paellaId: {ProteinType.seafood}, // Seafood 3 days ago
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipes': [chicken, beefSide], // Multi-recipe meal 2 days ago
            'cookedAt': DateTime.now().subtract(const Duration(days: 2)),
          },
          {
            'recipes': [paella], // Single recipe 3 days ago
            'cookedAt': DateTime.now().subtract(const Duration(days: 3)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      // Beef: 2 days ago = 75% penalty
      // Seafood: 3 days ago = 50% penalty
      // Average: (75% + 50%) / 2 = 62.5% penalty
      // Score: 100 - 62.5 = 37.5
      expect(score, equals(37.5));
    });

    group('With Meal Plan (Penalty Strategy)', () {
      test('should use penalty strategy when provided in context', () async {
        // Arrange
        final recipeId = IdGenerator.generateId();
        final recipe = Recipe(
          id: recipeId,
          name: 'Chicken Curry',
          createdAt: DateTime.now(),
        );

        // Create penalty strategy with chicken heavily penalized
        final penaltyStrategy = ProteinPenaltyStrategy(
          penalties: {
            ProteinType.chicken: 0.8, // 80% penalty (planned + recently cooked)
            ProteinType.beef: 0.3, // 30% penalty
          },
        );

        final context = {
          'proteinTypes': <String, Set<ProteinType>>{
            recipeId: {ProteinType.chicken},
          },
          'penaltyStrategy': penaltyStrategy,
          'recentMeals': <Map<String, dynamic>>[], // Should be ignored
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should apply 80% penalty from strategy
        // Score = 100 - 80 = 20.0
        expect(score, equals(20.0));
      });

      test('should give perfect score when protein has no penalty in strategy',
          () async {
        // Arrange
        final recipeId = IdGenerator.generateId();
        final recipe = Recipe(
          id: recipeId,
          name: 'Beef Tacos',
          createdAt: DateTime.now(),
        );

        // Create penalty strategy with only chicken penalized
        final penaltyStrategy = ProteinPenaltyStrategy(
          penalties: {
            ProteinType.chicken: 0.6, // 60% penalty
          },
        );

        final context = {
          'proteinTypes': <String, Set<ProteinType>>{
            recipeId: {ProteinType.beef}, // Beef not in penalty map
          },
          'penaltyStrategy': penaltyStrategy,
          'recentMeals': <Map<String, dynamic>>[],
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - No penalty for beef
        expect(score, equals(100.0));
      });

      test('should average penalties when recipe has multiple proteins',
          () async {
        // Arrange
        final recipeId = IdGenerator.generateId();
        final recipe = Recipe(
          id: recipeId,
          name: 'Surf and Turf',
          createdAt: DateTime.now(),
        );

        // Create penalty strategy with different penalties
        final penaltyStrategy = ProteinPenaltyStrategy(
          penalties: {
            ProteinType.beef: 0.6, // 60% penalty
            ProteinType.seafood: 0.4, // 40% penalty
          },
        );

        final context = {
          'proteinTypes': <String, Set<ProteinType>>{
            recipeId: {ProteinType.beef, ProteinType.seafood},
          },
          'penaltyStrategy': penaltyStrategy,
          'recentMeals': <Map<String, dynamic>>[],
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Average penalty: (60 + 40) / 2 = 50
        // Score = 100 - 50 = 50.0
        expect(score, equals(50.0));
      });

      test('should fallback to recentMeals when no penalty strategy provided',
          () async {
        // Arrange
        final recipeId = IdGenerator.generateId();
        final recipe = Recipe(
          id: recipeId,
          name: 'Chicken Curry',
          createdAt: DateTime.now(),
        );

        final yesterdayRecipeId = IdGenerator.generateId();
        final yesterdayRecipe = Recipe(
          id: yesterdayRecipeId,
          name: 'Chicken Stir Fry',
          createdAt: DateTime.now(),
        );

        final context = {
          'proteinTypes': <String, Set<ProteinType>>{
            recipeId: {ProteinType.chicken},
            yesterdayRecipeId: {ProteinType.chicken},
          },
          // No penaltyStrategy - should use recentMeals
          'recentMeals': <Map<String, dynamic>>[
            {
              'recipes': [yesterdayRecipe],
              'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
            },
          ],
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should use fallback behavior (100% penalty)
        expect(score, equals(0.0));
      });

      test('should clamp score to valid range when penalty exceeds 100%',
          () async {
        // Arrange
        final recipeId = IdGenerator.generateId();
        final recipe = Recipe(
          id: recipeId,
          name: 'Chicken Curry',
          createdAt: DateTime.now(),
        );

        // Create penalty strategy with extreme penalty (clamped to 1.0 max)
        final penaltyStrategy = ProteinPenaltyStrategy(
          penalties: {
            ProteinType.chicken: 1.0, // 100% penalty (maximum)
          },
        );

        final context = {
          'proteinTypes': <String, Set<ProteinType>>{
            recipeId: {ProteinType.chicken},
          },
          'penaltyStrategy': penaltyStrategy,
          'recentMeals': <Map<String, dynamic>>[],
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Score should be clamped to 0.0
        expect(score, equals(0.0));
      });
    });
  });
}
