// test/edge_cases/error_scenarios/validation_failures_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

/// Tests for entity validation failures using EntityValidator.
///
/// Verifies that the EntityValidator properly rejects invalid data:
/// - Recipe validation with invalid data
/// - Meal validation with invalid data
/// - Ingredient validation with invalid data
/// - Servings validation with boundary values
/// - Time validation with negative values
/// - MealPlan validation with invalid dates
/// - MealPlanItem validation with invalid data
/// - Helpful and descriptive error messages
/// - Field-level validation specificity
///
/// Note: These are unit tests for the validator layer, complementing
/// widget-level validation tests in the test pyramid approach.
void main() {
  group('Entity Validation Failures', () {
    group('Recipe Validation', () {
      test('validateRecipe throws when ID is empty', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: '',
            name: 'Test Recipe',
            ingredients: [],
            instructions: [],
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Recipe ID cannot be empty',
            ),
          ),
        );
      });

      test('validateRecipe throws when name is empty', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: IdGenerator.generateId(),
            name: '',
            ingredients: [],
            instructions: [],
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Recipe name cannot be empty',
            ),
          ),
        );
      });

      test('validateRecipe accepts valid recipe with all fields', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: IdGenerator.generateId(),
            name: 'Valid Recipe',
            ingredients: [
              {'id': '1', 'name': 'Ingredient 1'}
            ],
            instructions: ['Step 1', 'Step 2'],
          ),
          returnsNormally,
        );
      });

      test('validateRecipe accepts recipe with empty ingredients (temporarily)', () {
        // Note: Currently ingredients validation is disabled
        expect(
          () => EntityValidator.validateRecipe(
            id: IdGenerator.generateId(),
            name: 'Valid Recipe',
            ingredients: [],
            instructions: ['Step 1'],
          ),
          returnsNormally,
        );
      });

      test('validateRecipe accepts recipe with empty instructions (temporarily)', () {
        // Note: Currently instructions validation is disabled
        expect(
          () => EntityValidator.validateRecipe(
            id: IdGenerator.generateId(),
            name: 'Valid Recipe',
            ingredients: [
              {'id': '1', 'name': 'Ingredient'}
            ],
            instructions: [],
          ),
          returnsNormally,
        );
      });

      test('validation error message is helpful and specific', () {
        try {
          EntityValidator.validateRecipe(
            id: '',
            name: 'Test',
            ingredients: [],
            instructions: [],
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, isNotEmpty);
          expect(e.message.toLowerCase(), contains('id'));
          expect(e.message.toLowerCase(), contains('empty'));
        }
      });
    });

    group('Meal Validation', () {
      test('validateMeal throws when name is empty', () {
        expect(
          () => EntityValidator.validateMeal(
            name: '',
            date: DateTime.now(),
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal name cannot be empty',
            ),
          ),
        );
      });

      test('validateMeal throws when date is in the future', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: futureDate,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal date cannot be in the future',
            ),
          ),
        );
      });

      test('validateMeal throws when recipeIds is empty list', () {
        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: DateTime.now(),
            recipeIds: [],
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal must include at least one recipe',
            ),
          ),
        );
      });

      test('validateMeal accepts valid meal with null recipeIds', () {
        expect(
          () => EntityValidator.validateMeal(
            name: 'Valid Meal',
            date: DateTime.now(),
            recipeIds: null,
          ),
          returnsNormally,
        );
      });

      test('validateMeal accepts valid meal with recipe IDs', () {
        expect(
          () => EntityValidator.validateMeal(
            name: 'Valid Meal',
            date: DateTime.now(),
            recipeIds: ['recipe1', 'recipe2'],
          ),
          returnsNormally,
        );
      });

      test('validateMeal accepts meal with date in the past', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Past Meal',
            date: pastDate,
          ),
          returnsNormally,
        );
      });

      test('validateMeal rejects date exactly 1 second in future', () {
        final futureDate = DateTime.now().add(const Duration(seconds: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: futureDate,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validation error messages are specific to field', () {
        try {
          EntityValidator.validateMeal(
            name: '',
            date: DateTime.now(),
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message.toLowerCase(), contains('name'));
        }

        try {
          EntityValidator.validateMeal(
            name: 'Test',
            date: DateTime.now().add(const Duration(days: 1)),
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message.toLowerCase(), contains('date'));
          expect(e.message.toLowerCase(), contains('future'));
        }
      });
    });

    group('Servings Validation', () {
      test('validateServings throws when servings is zero', () {
        expect(
          () => EntityValidator.validateServings(0),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Number of servings must be positive',
            ),
          ),
        );
      });

      test('validateServings throws when servings is negative', () {
        expect(
          () => EntityValidator.validateServings(-1),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => EntityValidator.validateServings(-999),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateServings accepts positive servings', () {
        expect(() => EntityValidator.validateServings(1), returnsNormally);
        expect(() => EntityValidator.validateServings(2), returnsNormally);
        expect(() => EntityValidator.validateServings(999), returnsNormally);
      });

      test('validation error message is helpful', () {
        try {
          EntityValidator.validateServings(0);
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message.toLowerCase(), contains('servings'));
          expect(e.message.toLowerCase(), contains('positive'));
        }
      });
    });

    group('Time Validation', () {
      test('validateTime throws when time is negative', () {
        expect(
          () => EntityValidator.validateTime(-1.0, 'Prep'),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Prep time cannot be negative',
            ),
          ),
        );

        expect(
          () => EntityValidator.validateTime(-999.5, 'Cook'),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Cook time cannot be negative',
            ),
          ),
        );
      });

      test('validateTime accepts zero time', () {
        expect(() => EntityValidator.validateTime(0.0, 'Prep'), returnsNormally);
        expect(() => EntityValidator.validateTime(0.0, 'Cook'), returnsNormally);
      });

      test('validateTime accepts null time', () {
        expect(() => EntityValidator.validateTime(null, 'Prep'), returnsNormally);
      });

      test('validateTime accepts positive time values', () {
        expect(() => EntityValidator.validateTime(1.0, 'Prep'), returnsNormally);
        expect(() => EntityValidator.validateTime(15.5, 'Cook'), returnsNormally);
        expect(() => EntityValidator.validateTime(999.9, 'Total'), returnsNormally);
      });

      test('validation error message includes field name', () {
        try {
          EntityValidator.validateTime(-5.0, 'Prep');
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, contains('Prep'));
          expect(e.message.toLowerCase(), contains('negative'));
        }

        try {
          EntityValidator.validateTime(-10.0, 'Cook');
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, contains('Cook'));
        }
      });
    });

    group('Ingredient Validation', () {
      test('validateIngredient throws when ID is empty', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: '',
            name: 'Test Ingredient',
            category: IngredientCategory.vegetable,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Ingredient ID cannot be empty',
            ),
          ),
        );
      });

      test('validateIngredient throws when name is empty', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: '',
            category: IngredientCategory.vegetable,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Ingredient name cannot be empty',
            ),
          ),
        );
      });

      test('validateIngredient throws when protein category missing proteinType', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: 'Chicken',
            category: IngredientCategory.protein,
            proteinType: null,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Protein type must be selected for protein ingredients',
            ),
          ),
        );
      });

      test('validateIngredient accepts valid non-protein ingredient', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: 'Carrot',
            category: IngredientCategory.vegetable,
            unit: MeasurementUnit.gram,
          ),
          returnsNormally,
        );
      });

      test('validateIngredient accepts valid protein ingredient with proteinType', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: 'Chicken',
            category: IngredientCategory.protein,
            unit: MeasurementUnit.gram,
            proteinType: ProteinType.chicken,
          ),
          returnsNormally,
        );
      });

      test('validateIngredient accepts ingredient without unit', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: 'Salt',
            category: IngredientCategory.seasoning,
            unit: null,
          ),
          returnsNormally,
        );
      });

      test('validation error messages are specific', () {
        try {
          EntityValidator.validateIngredient(
            id: '',
            name: 'Test',
            category: IngredientCategory.vegetable,
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message.toLowerCase(), contains('id'));
        }

        try {
          EntityValidator.validateIngredient(
            id: IdGenerator.generateId(),
            name: 'Chicken',
            category: IngredientCategory.protein,
            proteinType: null,
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message.toLowerCase(), contains('protein type'));
        }
      });
    });

    group('Recipe Ingredient Validation', () {
      test('validateRecipeIngredient throws when ingredientId is empty', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: '',
            recipeId: IdGenerator.generateId(),
            quantity: 1.0,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Ingredient must be selected',
            ),
          ),
        );
      });

      test('validateRecipeIngredient throws when recipeId is empty', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: IdGenerator.generateId(),
            recipeId: '',
            quantity: 1.0,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Recipe ID cannot be empty',
            ),
          ),
        );
      });

      test('validateRecipeIngredient throws when quantity is zero', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: IdGenerator.generateId(),
            recipeId: IdGenerator.generateId(),
            quantity: 0.0,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Quantity must be greater than zero',
            ),
          ),
        );
      });

      test('validateRecipeIngredient throws when quantity is negative', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: IdGenerator.generateId(),
            recipeId: IdGenerator.generateId(),
            quantity: -1.0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateRecipeIngredient accepts valid data', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: IdGenerator.generateId(),
            recipeId: IdGenerator.generateId(),
            quantity: 1.0,
          ),
          returnsNormally,
        );
      });

      test('validateRecipeIngredient accepts decimal quantity', () {
        expect(
          () => EntityValidator.validateRecipeIngredient(
            ingredientId: IdGenerator.generateId(),
            recipeId: IdGenerator.generateId(),
            quantity: 0.5,
          ),
          returnsNormally,
        );
      });
    });

    group('Meal Plan Validation', () {
      test('validateMealPlan throws when ID is empty', () {
        expect(
          () => EntityValidator.validateMealPlan(
            id: '',
            weekStartDate: DateTime(2024, 1, 5), // Friday
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal plan ID cannot be empty',
            ),
          ),
        );
      });

      test('validateMealPlan throws when week start is not Friday', () {
        expect(
          () => EntityValidator.validateMealPlan(
            id: IdGenerator.generateId(),
            weekStartDate: DateTime(2024, 1, 1), // Monday
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Week start date must be a Friday',
            ),
          ),
        );

        expect(
          () => EntityValidator.validateMealPlan(
            id: IdGenerator.generateId(),
            weekStartDate: DateTime(2024, 1, 6), // Saturday
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateMealPlan accepts valid Friday week start', () {
        expect(
          () => EntityValidator.validateMealPlan(
            id: IdGenerator.generateId(),
            weekStartDate: DateTime(2024, 1, 5), // Friday
          ),
          returnsNormally,
        );
      });
    });

    group('Meal Plan Item Validation', () {
      test('validateMealPlanItem throws when ID is empty', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: '',
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-01-01',
            mealType: 'lunch',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal Plan Item ID cannot be empty',
            ),
          ),
        );
      });

      test('validateMealPlanItem throws when mealPlanId is empty', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: '',
            plannedDate: '2024-01-01',
            mealType: 'lunch',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal plan ID cannot be empty',
            ),
          ),
        );
      });

      test('validateMealPlanItem throws when plannedDate format is invalid', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '01/01/2024',
            mealType: 'lunch',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Planned date must be in YYYY-MM-DD format',
            ),
          ),
        );

        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-1-1',
            mealType: 'lunch',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateMealPlanItem throws when mealType is invalid', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-01-01',
            mealType: 'breakfast',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'Meal type must be either "lunch" or "dinner"',
            ),
          ),
        );

        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-01-01',
            mealType: 'snack',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateMealPlanItem accepts valid lunch item', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-01-01',
            mealType: 'lunch',
          ),
          returnsNormally,
        );
      });

      test('validateMealPlanItem accepts valid dinner item', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: IdGenerator.generateId(),
            plannedDate: '2024-01-01',
            mealType: 'dinner',
          ),
          returnsNormally,
        );
      });
    });

    group('Multiple Validation Errors', () {
      test('recipe validation fails on first error encountered', () {
        // When multiple fields are invalid, first error is thrown
        expect(
          () => EntityValidator.validateRecipe(
            id: '', // Invalid
            name: '', // Also invalid
            ingredients: [],
            instructions: [],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('meal validation fails on first error encountered', () {
        expect(
          () => EntityValidator.validateMeal(
            name: '', // Invalid
            date: DateTime.now().add(const Duration(days: 1)), // Also invalid
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validation exceptions contain helpful error messages', () {
        final testCases = [
          () => EntityValidator.validateRecipe(
                id: '',
                name: 'Test',
                ingredients: [],
                instructions: [],
              ),
          () => EntityValidator.validateMeal(
                name: '',
                date: DateTime.now(),
              ),
          () => EntityValidator.validateServings(0),
          () => EntityValidator.validateTime(-1.0, 'Prep'),
          () => EntityValidator.validateIngredient(
                id: '',
                name: 'Test',
                category: IngredientCategory.vegetable,
              ),
        ];

        for (final testCase in testCases) {
          try {
            testCase();
            fail('Should have thrown ValidationException');
          } on ValidationException catch (e) {
            expect(e.message, isNotEmpty,
                reason: 'Error message should not be empty');
            expect(e.message.length, greaterThan(10),
                reason: 'Error message should be descriptive');
          }
        }
      });
    });
  });
}
