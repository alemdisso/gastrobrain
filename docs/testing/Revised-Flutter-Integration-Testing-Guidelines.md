# Revised Flutter Integration Testing Guidelines for Gastrobrain

## Core Principles

1. **Test focused functionality, not complete user journeys**
   - Focus on specific, isolated functionality instead of end-to-end workflows
   - Break complex flows into smaller, manageable test units
   - Prefer multiple focused tests over a single comprehensive test

2. **Prefer database operations over UI interactions for setup**
   - Set up test data directly through database calls when possible
   - Use UI interactions only for the specific functionality being tested
   - This approach is more reliable and less brittle than UI-driven setup

3. **Gradually add complexity**
   - Start with simple database-only tests to verify core functionality
   - Add minimal UI testing only after data operations are confirmed working
   - Build tests incrementally, verifying each step before adding more

4. **Test like a user, but set up like a developer**
   - Use direct database access and APIs for test setup and verification
   - Use UI interactions only for the specific user behavior being tested
   - Focus on user-visible elements and flows for assertions

5. **Write resilient tests that can recover**
   - Handle potential failures gracefully
   - Add cleanup code that works even when tests fail
   - Design tests to be independent and not affected by previous test runs

## Element Selection Strategy

### Preferred Selector Priority (Most to Least Reliable)

1. **Test keys (when intentionally added for testing)**
   ```dart
   find.byKey(const Key('meal-plan-tab'))
   ```

2. **Text content visible to users**
   ```dart
   find.text('Weekly Meal Plan')
   find.textContaining('Week of')
   ```

3. **Semantic labels and tooltips**
   ```dart
   find.byTooltip('Next Week')
   find.bySemanticsLabel('Add new recipe')
   ```

4. **Widget types with context**
   ```dart
   find.descendant(
     of: find.byType(ListTile),
     matching: find.text('Test Recipe 1')
   )
   ```

5. **Icon widgets**
   ```dart
   find.byIcon(Icons.add)
   ```

### Avoid When Possible

- Complex nested widget finders without context
- Implementation-specific widget types
- Index-based selection that might change
- Deeply nested widget structures
- Absolute positioning or layout-dependent selectors

## Data Management and Test Isolation

1. **Clean up existing data before creating test data**
   ```dart
   // Check for and remove existing data to prevent conflicts
   final existingPlan = await dbHelper.getMealPlanForWeek(weekStart);
   if (existingPlan != null) {
     await dbHelper.deleteMealPlan(existingPlan.id);
   }
   ```

2. **Use database operations for setup and verification**
   ```dart
   // Create test data directly in the database
   final recipe = Recipe(
     id: testRecipeId,
     name: 'Test Recipe',
     desiredFrequency: FrequencyType.weekly,
     createdAt: DateTime.now(),
   );
   await dbHelper.insertRecipe(recipe);
   
   // Verify database state
   final savedRecipe = await dbHelper.getRecipe(testRecipeId);
   expect(savedRecipe, isNotNull);
   ```

3. **Add intermediate verification steps**
   ```dart
   // Verify each step succeeded before continuing
   await dbHelper.insertMealPlanItem(lunchItem);
   
   // Verify item was added
   final planWithItem = await dbHelper.getMealPlan(mealPlanId);
   expect(planWithItem!.items.length, 1, reason: "Item wasn't added to meal plan");
   ```

4. **Include clear error messages and reasons**
   ```dart
   // Add detailed reasons for assertions
   expect(savedPlan!.items.length, 2, 
     reason: "Expected 2 items but found ${savedPlan.items.length}");
   ```

## Async Handling

1. **Use appropriate waiting with custom timeouts**
   ```dart
   // Allow more time for app initialization
   await tester.pumpAndSettle(const Duration(seconds: 3));
   ```

2. **Handle potentially missing elements gracefully**
   ```dart
   // Use warnIfMissed to prevent test failure when tapping
   await tester.tap(finder, warnIfMissed: false);
   ```

3. **Verify state before proceeding**
   ```dart
   // Check if we're on expected screen before proceeding
   expect(find.text('Select Recipe'), findsOneWidget);
   ```

4. **Add explicit delays at critical integration points**
   ```dart
   // Sometimes needed for database operations to complete
   await Future.delayed(const Duration(milliseconds: 500));
   ```

## Test Structure

1. **Organize by feature functionality**
   ```dart
   group('Meal Planning - Core Functionality', () {
     testWidgets('Database operations for meal plans', (...) {...});
     testWidgets('UI rendering of meal plans', (...) {...});
   });
   ```

2. **Break complex flows into steps with clear comments**
   ```dart
   // 1. Create meal plan in database
   await dbHelper.insertMealPlan(mealPlan);
   
   // 2. Add items to the plan
   await dbHelper.insertMealPlanItem(lunchItem);
   
   // 3. Verify the data was saved correctly
   final savedPlan = await dbHelper.getMealPlanForWeek(weekStart);
   ```

3. **Verify both UI and database state when appropriate**
   ```dart
   // Verify UI updated correctly
   expect(find.text('Test Recipe'), findsOneWidget);
   
   // Verify database state matches
   final mealPlan = await dbHelper.getMealPlanForWeek(weekStart);
   expect(mealPlan!.items.length, greaterThan(0));
   ```

## Recommended Test Types

1. **Database operation tests**
   - Verify CRUD operations work correctly
   - Test relationships and queries
   - Focus on data integrity

2. **Minimal UI render tests**
   - Verify key UI elements appear correctly
   - Test basic interactions only
   - Avoid complex navigation chains

3. **Critical path tests**
   - Test the most important user workflows
   - Keep as simple as possible
   - Focus on one specific interaction pattern

4. **Error handling tests**
   - Verify the app handles errors gracefully
   - Test edge cases and boundary conditions
   - Ensure proper user feedback

## Example: Balanced Integration Test

```dart
testWidgets('Can add a meal to weekly plan', (WidgetTester tester) async {
  // Set up test data directly in database
  final recipe = await setupTestRecipe(dbHelper);
  
  // Launch app and navigate to meal plan screen
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Navigate to meal plan tab
  await navigateToMealPlanTab(tester);
  
  // Verify we're on the meal plan screen
  expect(find.text('Weekly Meal Plan'), findsOneWidget);
  
  // Tap on an empty meal slot
  await tester.tap(find.text('Add meal').first);
  await tester.pumpAndSettle();
  
  // Select our test recipe
  await tester.tap(find.text(recipe.name));
  await tester.pumpAndSettle();
  
  // Verify recipe was added to UI
  expect(find.text(recipe.name), findsOneWidget);
  
  // Verify database was updated correctly
  final weekStart = getWeekStart(DateTime.now());
  final mealPlan = await dbHelper.getMealPlanForWeek(weekStart);
  expect(mealPlan, isNotNull);
  expect(mealPlan!.items.isNotEmpty, isTrue);
  
  // Clean up - remove test data
  await cleanupTestData(dbHelper, recipe.id);
});
```

This balanced approach tests the most critical functionality while minimizing dependencies and maintaining reliability.