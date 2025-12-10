# RecipeProvider Test Setup Documentation

## Overview

`RecipeProvider` is a state management provider used in `MealHistoryScreen._handleEditMeal()` to refresh recipe statistics after editing a meal. Tests that exercise this functionality must properly mock the provider to avoid database calls during testing.

## How RecipeProvider is Used in `_handleEditMeal`

**Location**: `lib/screens/meal_history_screen.dart:186-187`

```dart
// Refresh recipe statistics to reflect any changes in meal data
final recipeProvider = context.read<RecipeProvider>();
await recipeProvider.refreshMealStats();
```

### Call Flow

1. **User saves edited meal** → Dialog returns updated data
2. **Meal is updated in database** → `updateMeal()` called
3. **Recipe associations updated** → Side dishes added/removed
4. **Meal list refreshed** → `_loadMeals()` called
5. **RecipeProvider.refreshMealStats() called** → Updates recipe statistics
6. **Success snackbar shown** → User feedback

### What `refreshMealStats()` Does

**Location**: `lib/core/providers/recipe_provider.dart:191-193`

```dart
/// Refreshes meal statistics for all recipes from database
Future<void> refreshMealStats() async {
  await loadRecipes(forceRefresh: true);
}
```

This method:
- Reloads all recipes from the database with `forceRefresh: true`
- Updates meal counts (how many times each recipe was cooked)
- Updates last cooked dates for each recipe
- Notifies listeners so UI updates across the app

**Why it's needed**: When a meal is edited (e.g., servings changed, date modified), the recipe's statistics may change. The provider ensures the UI reflects these changes everywhere.

## Test Setup Requirements

### 1. Mock RecipeProvider Class

Create a mock that overrides `refreshMealStats()` to prevent actual database operations:

**Location**: `test/screens/meal_history_edit_test.dart:16-22`

```dart
// Simple mock RecipeProvider for testing
class MockRecipeProvider extends RecipeProvider {
  @override
  Future<void> refreshMealStats() async {
    // No-op for testing
    return Future.value();
  }
}
```

**Important Notes**:
- Must extend `RecipeProvider` (not implement)
- Override only `refreshMealStats()` - other methods are not used in this context
- Return `Future.value()` to complete the async operation without side effects
- No database calls or state changes occur in tests

### 2. Provider Setup in createTestableWidget()

Wrap the MaterialApp in a `ChangeNotifierProvider` to inject the mock:

**Location**: `test/screens/meal_history_edit_test.dart:30-47`

```dart
Widget createTestableWidget(Widget child) {
  return ChangeNotifierProvider<RecipeProvider>(
    create: (_) => MockRecipeProvider(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', ''),
      ],
      home: child,
    ),
  );
}
```

**Key Points**:
- `ChangeNotifierProvider<RecipeProvider>` wraps the entire MaterialApp
- `create: (_) => MockRecipeProvider()` creates a fresh mock for each test
- This makes `context.read<RecipeProvider>()` work in the widget under test
- The mock is automatically disposed when the test completes

## Why This Setup is Required

### Without Provider Setup ❌

```dart
Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child); // Missing provider!
}
```

**Result**:
- Test will crash with `ProviderNotFoundException`
- Error message: "Error: Could not find the correct Provider<RecipeProvider>"
- `context.read<RecipeProvider>()` call fails

### With Provider Setup ✅

```dart
Widget createTestableWidget(Widget child) {
  return ChangeNotifierProvider<RecipeProvider>(
    create: (_) => MockRecipeProvider(),
    child: MaterialApp(home: child),
  );
}
```

**Result**:
- `context.read<RecipeProvider>()` returns the mock
- `refreshMealStats()` is called but does nothing (no-op)
- Test continues without database side effects
- No state changes that could affect other tests

## Complete Test Setup Example

Here's a complete example for testing meal edit functionality with snackbar verification:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import '../mocks/mock_database_helper.dart';
import '../helpers/snackbar_test_helpers.dart';

// Mock RecipeProvider for testing
class MockRecipeProvider extends RecipeProvider {
  @override
  Future<void> refreshMealStats() async {
    // No-op for testing
    return Future.value();
  }
}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe testRecipe;
  late Meal testMeal;

  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider<RecipeProvider>(
      create: (_) => MockRecipeProvider(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('pt', ''),
        ],
        home: child,
      ),
    );
  }

  setUp(() async {
    mockDbHelper = MockDatabaseHelper();

    testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    testMeal = Meal(
      id: 'test-meal-1',
      recipeId: null,
      cookedAt: DateTime.now().subtract(const Duration(days: 1)),
      servings: 3,
      notes: 'Test meal',
      wasSuccessful: true,
    );

    await mockDbHelper.insertRecipe(testRecipe);
    await mockDbHelper.insertMeal(testMeal);
  });

  tearDown(() {
    mockDbHelper.resetAllData();
  });

  group('Meal Edit Feedback Tests', () {
    testWidgets('shows success snackbar after successful edit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Change servings
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify success snackbar appears
      await SnackbarTestHelpers.waitForSnackBar(tester);
      SnackbarTestHelpers.expectSuccessSnackBar('Meal updated successfully');
    });
  });
}
```

## Advanced: Verifying Provider Calls

If you need to verify that `refreshMealStats()` was actually called:

```dart
class MockRecipeProvider extends RecipeProvider {
  int refreshCallCount = 0;

  @override
  Future<void> refreshMealStats() async {
    refreshCallCount++;
    return Future.value();
  }
}

// In test:
testWidgets('calls refreshMealStats after edit', (tester) async {
  final mockProvider = MockRecipeProvider();

  await tester.pumpWidget(
    ChangeNotifierProvider<RecipeProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: MealHistoryScreen(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      ),
    ),
  );

  // ... perform edit ...

  expect(mockProvider.refreshCallCount, 1);
});
```

## Common Issues and Solutions

### Issue 1: ProviderNotFoundException

**Error**: `Error: Could not find the correct Provider<RecipeProvider>`

**Solution**: Ensure `ChangeNotifierProvider<RecipeProvider>` wraps the MaterialApp in `createTestableWidget()`

### Issue 2: Test Hangs or Times Out

**Error**: Test never completes, hangs at `await recipeProvider.refreshMealStats()`

**Solution**: Verify `MockRecipeProvider.refreshMealStats()` returns `Future.value()`, not a database call

### Issue 3: Provider Not Accessible in Dialog

**Error**: Provider works in screen but fails when dialog is shown

**Solution**: The provider must wrap the MaterialApp (not just the screen), so dialogs inherit the provider context

### Issue 4: Multiple Provider Types Needed

**Error**: Need both RecipeProvider and other providers

**Solution**: Use `MultiProvider`:
```dart
Widget createTestableWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RecipeProvider>(
        create: (_) => MockRecipeProvider(),
      ),
      ChangeNotifierProvider<MealProvider>(
        create: (_) => MockMealProvider(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}
```

## Dependencies Required

Add these to your test file imports:

```dart
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
```

## Testing Checklist

When creating tests that use `_handleEditMeal`:

- [ ] Create `MockRecipeProvider` class that extends `RecipeProvider`
- [ ] Override `refreshMealStats()` to return `Future.value()`
- [ ] Wrap MaterialApp in `ChangeNotifierProvider<RecipeProvider>`
- [ ] Use `create: (_) => MockRecipeProvider()` in the provider
- [ ] Verify snackbar appears after successful edit
- [ ] Verify error snackbar appears on failure
- [ ] Test passes without actual database calls
- [ ] No `ProviderNotFoundException` errors

## References

- RecipeProvider source: `lib/core/providers/recipe_provider.dart`
- MealHistoryScreen usage: `lib/screens/meal_history_screen.dart:186-187`
- Existing test example: `test/screens/meal_history_edit_test.dart`
- Provider package docs: https://pub.dev/packages/provider
- Testing with Provider: https://pub.dev/packages/provider#testing