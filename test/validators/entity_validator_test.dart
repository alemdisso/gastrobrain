// test/validators/entity_validator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';

void main() {
  group('EntityValidator - ID validation', () {
    group('validateIngredient', () {
      test('throws ValidationException when ID is empty', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: '',
            name: 'Carrot',
            category: IngredientCategory.vegetable,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Ingredient ID cannot be empty',
          )),
        );
      });

      test('passes validation with valid ID', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: 'valid-id-123',
            name: 'Carrot',
            category: IngredientCategory.vegetable,
          ),
          returnsNormally,
        );
      });

      test('throws ValidationException when name is empty even with valid ID', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: 'valid-id-123',
            name: '',
            category: IngredientCategory.vegetable,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Ingredient name cannot be empty',
          )),
        );
      });

      test('validates with all fields including protein type', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: 'protein-id',
            name: 'Chicken Breast',
            category: IngredientCategory.protein,
            unit: MeasurementUnit.gram,
            proteinType: ProteinType.chicken,
          ),
          returnsNormally,
        );
      });
    });

    group('validateRecipe', () {
      test('throws ValidationException when ID is empty', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: '',
            name: 'Pasta Carbonara',
            ingredients: [],
            instructions: [],
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Recipe ID cannot be empty',
          )),
        );
      });

      test('passes validation with valid ID', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: 'recipe-id-456',
            name: 'Pasta Carbonara',
            ingredients: [],
            instructions: [],
          ),
          returnsNormally,
        );
      });

      test('throws ValidationException when name is empty even with valid ID', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: 'recipe-id-456',
            name: '',
            ingredients: [],
            instructions: [],
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Recipe name cannot be empty',
          )),
        );
      });
    });

    group('validateMealPlanItem', () {
      test('throws ValidationException when ID is empty', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: '',
            mealPlanId: 'meal-plan-id',
            plannedDate: '2024-11-03',
            mealType: 'lunch',
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Meal Plan Item ID cannot be empty',
          )),
        );
      });

      test('passes validation with valid ID', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: 'meal-plan-item-id',
            mealPlanId: 'meal-plan-id',
            plannedDate: '2024-11-03',
            mealType: 'lunch',
          ),
          returnsNormally,
        );
      });

      test('throws ValidationException when mealPlanId is empty even with valid ID', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: 'meal-plan-item-id',
            mealPlanId: '',
            plannedDate: '2024-11-03',
            mealType: 'lunch',
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Meal plan ID cannot be empty',
          )),
        );
      });

      test('validates dinner meal type', () {
        expect(
          () => EntityValidator.validateMealPlanItem(
            id: 'meal-plan-item-id',
            mealPlanId: 'meal-plan-id',
            plannedDate: '2024-11-03',
            mealType: 'dinner',
          ),
          returnsNormally,
        );
      });
    });

    group('validateMealPlan', () {
      test('validates meal plan with ID (already has ID validation)', () {
        // validateMealPlan already has ID validation, so we just verify it works
        final fridayDate = DateTime(2024, 11, 1); // A Friday
        expect(
          () => EntityValidator.validateMealPlan(
            id: 'meal-plan-id',
            weekStartDate: fridayDate,
          ),
          returnsNormally,
        );
      });

      test('throws ValidationException when meal plan ID is empty', () {
        final fridayDate = DateTime(2024, 11, 1); // A Friday
        expect(
          () => EntityValidator.validateMealPlan(
            id: '',
            weekStartDate: fridayDate,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Meal plan ID cannot be empty',
          )),
        );
      });
    });
  });
}
