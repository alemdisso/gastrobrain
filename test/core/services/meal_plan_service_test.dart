// test/core/services/meal_plan_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/meal_plan_service.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MealPlanService service;
  late MealPlan testMealPlan;
  late Recipe testRecipe;

  setUp(() async {
    mockDbHelper = MockDatabaseHelper();
    service = MealPlanService(mockDbHelper);

    testMealPlan = MealPlan(
      id: IdGenerator.generateId(),
      weekStartDate: DateTime(2026, 2, 27),
      notes: '',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
    await mockDbHelper.insertMealPlan(testMealPlan);

    testRecipe = Recipe(
      id: IdGenerator.generateId(),
      name: 'Test Recipe',
      desiredFrequency: FrequencyType.weekly,
      servings: 4,
      createdAt: DateTime.now(),
    );
    await mockDbHelper.insertRecipe(testRecipe);
  });

  tearDown(() {
    mockDbHelper.resetAllData();
  });

  group('addOrUpdateMealToSlot — plannedServings', () {
    test('defaults to 4 when no plannedServings provided', () async {
      final updatedPlan = await service.addOrUpdateMealToSlot(
        mealPlan: testMealPlan,
        date: DateTime(2026, 2, 28),
        mealType: 'lunch',
        primaryRecipe: testRecipe,
      );

      final items = updatedPlan.getItemsForDateAndMealType(
          DateTime(2026, 2, 28), 'lunch');
      expect(items, isNotEmpty);
      expect(items.first.plannedServings, 4);
    });

    test('persists custom plannedServings value', () async {
      final updatedPlan = await service.addOrUpdateMealToSlot(
        mealPlan: testMealPlan,
        date: DateTime(2026, 2, 28),
        mealType: 'dinner',
        primaryRecipe: testRecipe,
        plannedServings: 6,
      );

      final items = updatedPlan.getItemsForDateAndMealType(
          DateTime(2026, 2, 28), 'dinner');
      expect(items, isNotEmpty);
      expect(items.first.plannedServings, 6);
    });

    test('uses recipe servings as default when caller passes it', () async {
      final smallRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Small Recipe',
        desiredFrequency: FrequencyType.weekly,
        servings: 2,
        createdAt: DateTime.now(),
      );
      await mockDbHelper.insertRecipe(smallRecipe);

      final updatedPlan = await service.addOrUpdateMealToSlot(
        mealPlan: testMealPlan,
        date: DateTime(2026, 3, 1),
        mealType: 'lunch',
        primaryRecipe: smallRecipe,
        plannedServings: smallRecipe.servings,
      );

      final items = updatedPlan.getItemsForDateAndMealType(
          DateTime(2026, 3, 1), 'lunch');
      expect(items, isNotEmpty);
      expect(items.first.plannedServings, 2);
    });

    test('replacing existing slot preserves new plannedServings', () async {
      // First call: add slot with 4 servings
      await service.addOrUpdateMealToSlot(
        mealPlan: testMealPlan,
        date: DateTime(2026, 2, 28),
        mealType: 'lunch',
        primaryRecipe: testRecipe,
        plannedServings: 4,
      );

      // Second call: replace same slot with 8 servings
      final updatedPlan = await service.addOrUpdateMealToSlot(
        mealPlan: testMealPlan,
        date: DateTime(2026, 2, 28),
        mealType: 'lunch',
        primaryRecipe: testRecipe,
        plannedServings: 8,
      );

      final items = updatedPlan.getItemsForDateAndMealType(
          DateTime(2026, 2, 28), 'lunch');
      expect(items.length, 1);
      expect(items.first.plannedServings, 8);
    });
  });
}
