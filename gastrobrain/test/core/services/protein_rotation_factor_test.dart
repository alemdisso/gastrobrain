// test/core/services/recommendation_factors/protein_rotation_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/core/services/recommendation_factors/protein_rotation_factor.dart';
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
      expect(factor.weight, equals(30));
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
        'proteinTypes': <String, List<ProteinType>>{
          recipe.id: [], // No proteins
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
        'proteinTypes': <String, List<ProteinType>>{
          recipe.id: [ProteinType.plantBased], // Non-main protein
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
        'proteinTypes': <String, List<ProteinType>>{
          recipe.id: [ProteinType.chicken], // Main protein
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
        'proteinTypes': <String, List<ProteinType>>{
          recipeId: [ProteinType.beef], // Today's recipe has beef
          yesterdayRecipeId: [
            ProteinType.beef
          ], // Yesterday's recipe also had beef
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipe': yesterdayRecipe,
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
        'proteinTypes': <String, List<ProteinType>>{
          recipeId: [ProteinType.chicken], // Today's recipe has chicken
          oldRecipeId: [ProteinType.chicken], // 3 days ago also had chicken
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipe': oldRecipe,
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
        'proteinTypes': <String, List<ProteinType>>{
          recipeId: [
            ProteinType.beef,
            ProteinType.seafood
          ], // Today's recipe has both beef and seafood
          beefRecipeId: [ProteinType.beef], // 1 day ago had beef
          seafoodRecipeId: [ProteinType.seafood], // 2 days ago had seafood
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipe': beefRecipe,
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
          {
            'recipe': seafoodRecipe,
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
        'proteinTypes': <String, List<ProteinType>>{
          recipeId: [ProteinType.pork], // Today's recipe has pork
          oldRecipeId: [ProteinType.pork], // 5 days ago also had pork
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipe': oldRecipe,
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
        'proteinTypes': <String, List<ProteinType>>{
          recipeId: [ProteinType.fish], // Today's recipe has fish
          recentFishId: [ProteinType.fish], // 1 day ago was fish
          olderFishId: [ProteinType.fish], // 3 days ago was also fish
        },
        'recentMeals': <Map<String, dynamic>>[
          {
            'recipe': recentFish,
            'cookedAt': DateTime.now().subtract(const Duration(days: 1)),
          },
          {
            'recipe': olderFish,
            'cookedAt': DateTime.now().subtract(const Duration(days: 3)),
          },
        ],
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - Should use the 1-day penalty (100%) not the 3-day penalty
      expect(score, equals(0.0));
    });
  });
}
