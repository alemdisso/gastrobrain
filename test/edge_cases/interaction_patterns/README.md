# Interaction Patterns Tests

This directory contains tests for unusual user interaction patterns and device conditions.

## What are Interaction Patterns?

Interaction patterns test how the app handles:
- Rapid user interactions (button mashing)
- Concurrent actions (multiple dialogs, navigation during async)
- Cancellation mid-operation
- Navigation edge cases (deep stacks, invalid routes)
- State preservation (orientation changes, app backgrounding)
- Device-specific conditions (low memory, screen sizes)

## Why Test Interaction Patterns?

Real users don't always follow the happy path:
- Impatient users tap buttons multiple times
- Users navigate away during loading
- Users rotate device mid-form fill
- App is backgrounded during operations
- Network issues cause timeouts
- Different devices have different constraints

## Test Categories

### Rapid Interactions
- `rapid_tap_test.dart` - Save button rapid taps, duplicate actions
- `concurrent_actions_test.dart` - Multiple dialogs, navigation during async
- `cancellation_test.dart` - Cancel during save, import, export

### Navigation Patterns
- `navigation_test.dart` - Deep stacks, deleted items, invalid routes
- `state_preservation_test.dart` - Form data on orientation change, backgrounding

### Device Conditions
- `memory_performance_test.dart` - Low memory, large datasets
- `screen_orientation_test.dart` - Orientation changes, layout adaptation
- `accessibility_test.dart` - Screen reader, large text, keyboard navigation

### Timing & Async
- `timeout_test.dart` - Query timeout, long operations
- `race_conditions_test.dart` - Concurrent data access

## Testing Pattern

### Rapid Tap Prevention

```dart
testWidgets('prevents duplicate saves from rapid taps', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();
  int saveCount = 0;

  // Track how many times save is called
  mockDb.onInsertRecipe = () => saveCount++;

  await tester.pumpWidget(/*...*/);

  // Simulate rapid taps
  await EdgeCaseTestHelpers.simulateRapidTaps(
    tester,
    target: find.text('Save'),
    tapCount: 10,
  );

  // Should only save once (debouncing)
  expect(saveCount, equals(1),
      reason: 'Save should be debounced to prevent duplicates');
});
```

### Concurrent Operations

```dart
testWidgets('handles concurrent async operations', (tester) async {
  await EdgeCaseTestHelpers.simulateConcurrentOperations([
    () async => await service.saveRecipe(recipe1),
    () async => await service.saveRecipe(recipe2),
  ]);

  // Verify both completed successfully
  // Verify no data corruption
});
```

### State Preservation

```dart
testWidgets('preserves form data on orientation change', (tester) async {
  // Fill form
  await tester.enterText(find.byKey(Key('recipeName')), 'Test Recipe');

  // Simulate orientation change
  tester.binding.window.physicalSizeTestValue = Size(800, 600);
  await tester.pumpAndSettle();

  // Verify data preserved
  expect(find.text('Test Recipe'), findsOneWidget);
});
```

## Key Assertions

- ✅ Rapid taps don't cause duplicate operations
- ✅ Only one dialog can be open at a time (or properly stacked)
- ✅ Navigation during async doesn't corrupt state
- ✅ Cancellation cleans up resources
- ✅ Form data preserved on orientation change
- ✅ App remains responsive with large datasets
- ✅ Layout adapts to different screen sizes

## EdgeCaseTestHelpers Methods

```dart
// Rapid interactions
await EdgeCaseTestHelpers.simulateRapidTaps(
  tester,
  target: find.text('Save'),
  tapCount: 10,
);

// Concurrent operations
await EdgeCaseTestHelpers.simulateConcurrentOperations([
  operation1,
  operation2,
]);

// Loading state verification
EdgeCaseTestHelpers.verifyLoadingState(tester);
EdgeCaseTestHelpers.verifyNotLoadingState(tester);
```

## Related Documentation

- [Edge Case Catalog](../../../docs/EDGE_CASE_CATALOG.md#interaction-patterns)
- [EdgeCaseTestHelpers](../../helpers/edge_case_test_helpers.dart)
