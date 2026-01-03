// test/mocks/mock_database_error_simulation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/ingredient.dart';
import '../mocks/mock_database_helper.dart';

/// Verification tests for Issue #244 - Error Simulation Support
///
/// These tests verify that error simulation works correctly for all
/// methods added/refactored in Phase 1 and Phase 2.
void main() {
  late MockDatabaseHelper mockDb;

  setUp(() {
    mockDb = MockDatabaseHelper();
  });

  tearDown(() {
    mockDb.resetAllData();
    mockDb.resetErrorSimulation();
  });

  group('Phase 1 - High Priority Methods', () {
    group('getAllIngredients() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        // Configure mock to fail
        mockDb.failOnOperation('getAllIngredients');

        // Verify it throws
        expect(
          () async => await mockDb.getAllIngredients(),
          throwsA(isA<Exception>()),
        );
      });

      test('auto-resets after throwing', () async {
        // Configure mock to fail
        mockDb.failOnOperation('getAllIngredients');

        // First call throws
        expect(
          () async => await mockDb.getAllIngredients(),
          throwsA(isA<Exception>()),
        );

        // Second call succeeds (auto-reset)
        final ingredients = await mockDb.getAllIngredients();
        expect(ingredients, isA<List<Ingredient>>());
      });

      test('supports custom exception', () async {
        final customException = Exception('Custom error message');
        mockDb.failOnOperation('getAllIngredients', exception: customException);

        try {
          await mockDb.getAllIngredients();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, equals(customException));
        }
      });
    });

    group('getRecipe() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getRecipe');

        expect(
          () async => await mockDb.getRecipe('test-id'),
          throwsA(isA<Exception>()),
        );
      });

      test('works normally without error simulation', () async {
        final recipe = await mockDb.getRecipe('test-id');
        expect(recipe, isNull); // No recipe with this ID
      });
    });

    group('getRecentMeals() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getRecentMeals');

        expect(
          () async => await mockDb.getRecentMeals(limit: 10),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAllMeals() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getAllMeals');

        expect(
          () async => await mockDb.getAllMeals(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getMealRecipesForMeal() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getMealRecipesForMeal');

        expect(
          () async => await mockDb.getMealRecipesForMeal('meal-id'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteMeal() refactored error simulation', () {
      test('throws exception with new standard pattern', () async {
        mockDb.failOnOperation('deleteMeal');

        expect(
          () async => await mockDb.deleteMeal('meal-id'),
          throwsA(isA<Exception>()),
        );
      });

      test('legacy shouldThrowOnDelete still works', () async {
        mockDb.shouldThrowOnDelete = true;

        expect(
          () async => await mockDb.deleteMeal('meal-id'),
          throwsA(isA<Exception>()),
        );
      });

      test('standard pattern takes precedence over legacy', () async {
        final customException = Exception('Standard pattern error');
        mockDb.failOnOperation('deleteMeal', exception: customException);
        mockDb.shouldThrowOnDelete = true;

        try {
          await mockDb.deleteMeal('meal-id');
          fail('Should have thrown exception');
        } catch (e) {
          // Should throw the standard pattern exception, not legacy
          expect(e, equals(customException));
        }
      });
    });
  });

  group('Phase 2 - Medium Priority Methods', () {
    group('getRecipesWithSortAndFilter() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getRecipesWithSortAndFilter');

        expect(
          () async => await mockDb.getRecipesWithSortAndFilter(),
          throwsA(isA<Exception>()),
        );
      });

      test('works with parameters when no error simulation', () async {
        final recipes = await mockDb.getRecipesWithSortAndFilter(
          sortBy: 'name',
          sortOrder: 'asc',
          filters: {'difficulty': 'easy'},
        );
        expect(recipes, isA<List>());
      });
    });

    group('getMealPlan() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getMealPlan');

        expect(
          () async => await mockDb.getMealPlan('plan-id'),
          throwsA(isA<Exception>()),
        );
      });

      test('returns null for non-existent plan without error simulation',
          () async {
        final plan = await mockDb.getMealPlan('non-existent-id');
        expect(plan, isNull);
      });
    });

    group('getMealPlanForWeek() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getMealPlanForWeek');

        expect(
          () async => await mockDb.getMealPlanForWeek(DateTime.now()),
          throwsA(isA<Exception>()),
        );
      });

      test('returns null when no plan exists without error simulation',
          () async {
        final plan = await mockDb.getMealPlanForWeek(DateTime.now());
        expect(plan, isNull);
      });
    });

    group('getMealPlanItemsForDate() error simulation', () {
      test('throws exception when error simulation is enabled', () async {
        mockDb.failOnOperation('getMealPlanItemsForDate');

        expect(
          () async => await mockDb.getMealPlanItemsForDate(DateTime.now()),
          throwsA(isA<Exception>()),
        );
      });

      test('returns empty list when no items exist without error simulation',
          () async {
        final items = await mockDb.getMealPlanItemsForDate(DateTime.now());
        expect(items, isEmpty);
      });
    });
  });

  group('Error Simulation Infrastructure', () {
    test('resetErrorSimulation() clears error state', () async {
      mockDb.failOnOperation('getAllIngredients');
      mockDb.resetErrorSimulation();

      // Should not throw after reset
      final ingredients = await mockDb.getAllIngredients();
      expect(ingredients, isA<List<Ingredient>>());
    });

    test('operation-specific targeting works', () async {
      // Configure to fail only on getAllIngredients
      mockDb.failOnOperation('getAllIngredients');

      // getAllIngredients should throw
      expect(
        () async => await mockDb.getAllIngredients(),
        throwsA(isA<Exception>()),
      );

      // Other operations should work fine
      final recipes = await mockDb.getAllRecipes();
      expect(recipes, isA<List>());
    });

    test('multiple operations can be configured sequentially', () async {
      // First operation fails
      mockDb.failOnOperation('getAllIngredients');
      expect(
        () async => await mockDb.getAllIngredients(),
        throwsA(isA<Exception>()),
      );

      // Configure second operation to fail
      mockDb.failOnOperation('getMealPlan');
      expect(
        () async => await mockDb.getMealPlan('id'),
        throwsA(isA<Exception>()),
      );

      // First operation now works (auto-reset after first throw)
      final ingredients = await mockDb.getAllIngredients();
      expect(ingredients, isA<List>());
    });
  });

  group('Backward Compatibility', () {
    test('existing error simulation for getAllRecipes still works', () async {
      // This method already had error simulation before #244
      mockDb.failOnOperation('getAllRecipes');

      expect(
          () async => await mockDb.getAllRecipes(), throwsA(isA<Exception>()));
    });

    test('existing error simulation for deleteRecipe still works', () async {
      // This method already had error simulation before #244
      mockDb.failOnOperation('deleteRecipe');

      expect(
          () async => await mockDb.deleteRecipe('id'), throwsA(isA<Exception>()));
    });
  });
}