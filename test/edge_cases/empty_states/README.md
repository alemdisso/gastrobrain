# Empty States Tests

This directory contains tests for empty state handling across the application.

## What are Empty States?

Empty states occur when a feature or screen has no data to display, such as:
- No recipes in the database
- No ingredients available
- No planned meals in calendar
- No meal history
- Search/filter returns no results

## Why Test Empty States?

Empty states are critical because:
- They're the first experience for new users
- Poor empty states confuse users about what to do next
- Empty data can cause null pointer exceptions if not handled
- UI should provide helpful guidance, not just blank screens

## Test Categories

- `recipes_empty_state_test.dart` - Recipe management with no recipes
- `ingredients_empty_state_test.dart` - Ingredient system with no ingredients
- `meal_planning_empty_state_test.dart` - Meal planning with no planned meals
- `meal_history_empty_state_test.dart` - Meal history with no cooked meals
- `search_empty_state_test.dart` - Search and filter returning no results

## Testing Pattern

```dart
testWidgets('shows empty state when no recipes exist', (tester) async {
  // Setup: Empty database
  final mockDb = TestSetup.setupMockDatabase();
  // mockDb has no recipes by default

  // Build widget
  await tester.pumpWidget(/*...*/);

  // Verify empty state
  EdgeCaseTestHelpers.verifyEmptyState(
    tester,
    expectedMessage: 'No recipes found',
  );

  // Verify helpful action is available
  expect(find.text('Add Recipe'), findsOneWidget);
});
```

## Key Assertions

- ✅ Empty state message is displayed
- ✅ Message is helpful and actionable
- ✅ Primary action button is available (e.g., "Add Recipe")
- ✅ No null pointer exceptions
- ✅ UI renders correctly with empty data

## Related Documentation

- [Edge Case Catalog](../../../docs/EDGE_CASE_CATALOG.md#empty-states)
- [EdgeCaseTestHelpers](../../helpers/edge_case_test_helpers.dart)
