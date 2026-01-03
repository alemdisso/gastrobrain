<!-- markdownlint-disable -->
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gastrobrain is a Flutter-based meal planning and recipe management application that helps users organize their cooking with recipe recommendations. The app uses SQLite for local storage and features a recommendation engine with multi-factor scoring.

## Development Workflow

Follow a **deliberate, step-by-step approach**:

1. **Analyze** - Understand existing code and architecture before making changes
2. **Plan** - Use TodoWrite to break work into manageable steps; explain your approach
3. **Implement** - Make focused, targeted changes; don't bite off more than you can chew
4. **Validate** - Test incrementally; run `flutter analyze` and relevant tests
5. **Document** - Update comments and documentation as needed

### Key Principles
- **Quality over speed** - Follow established patterns and conventions
- **Manageable scope** - Break large changes into smaller, achievable steps
- **Incremental testing** - Verify changes work before expanding scope

This approach maintains code quality, architectural consistency, and reduces bugs.

## Issue Management

For detailed workflows on issue management, GitHub Projects integration, and Git Flow processes, see **[docs/workflows/ISSUE_WORKFLOW.md](docs/workflows/ISSUE_WORKFLOW.md)**.

**Quick Reference:**
- Branch format: `{type}/{issue-number}-{short-description}`
- Commit format: `{type}: brief description (#{issue-number})`
- Always use TodoWrite when planning implementation
- Test before merging: `flutter test && flutter analyze`
- Merge to develop, then close issue and clean up branch

## Environment Notes

**Local Development (WSL)**: This project runs in a WSL environment for local development. For local code validation, use `flutter analyze` and `flutter test`. Note that `flutter build apk`, `flutter build ios`, and `flutter run` are not supported in the local WSL environment. Physical device testing and full builds must be done outside WSL (e.g., via GitHub Actions CI/CD, which successfully builds APKs).

## Architecture & Codebase

For comprehensive architecture details, data models, and testing infrastructure, see **[docs/architecture/Gastrobrain-Codebase-Overview.md](docs/architecture/Gastrobrain-Codebase-Overview.md)**.

**Key patterns to follow:**
- **Dependency injection**: Access services via `ServiceProvider`
- **Database operations**: Use `DatabaseHelper` with proper error handling (`NotFoundException`, `ValidationException`, `GastrobrainException`)
- **Multi-recipe meals**: Use `MealPlanItemRecipe` (planning) and `MealRecipe` (cooking) with `isPrimaryDish` flags
- **Testing**: Use `MockDatabaseHelper` for unit tests; integration tests use real database

## Localization (l10n)

All user-facing strings must be localized for English and Portuguese. See **[docs/workflows/L10N_PROTOCOL.md](docs/workflows/L10N_PROTOCOL.md)** for the complete localization workflow.

**Critical rules:**
- NEVER use hardcoded strings in UI code
- Always add strings to BOTH `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb`
- Run `flutter gen-l10n` after any ARB file changes
- Use `AppLocalizations.of(context)!.stringKey` in code

## Development Patterns

### Dependency Injection
Access services through the central `ServiceProvider`:
```dart
import 'package:gastrobrain/core/di/service_provider.dart';

final dbHelper = ServiceProvider.database.helper;
final recommendations = ServiceProvider.recommendations.service;
```

### Database Operations
Use `DatabaseHelper` methods with proper error handling:
```dart
try {
  final recipe = await dbHelper.getRecipe(id);
} on NotFoundException {
  // Handle not found
} on ValidationException {
  // Handle validation errors
} on GastrobrainException {
  // Handle general app errors
}
```

### Recommendation Usage
```dart
final recommendations = await recommendationService.getRecommendations(
  count: 5,
  forDate: DateTime.now(),
  mealType: 'dinner',
  weekdayMeal: true, // Applies weekday profile
);
```

### Testing Patterns

**General Testing:**
- Use `MockDatabaseHelper` for isolated unit tests
- Test recommendation factors individually and in combination
- Widget tests should cover responsive layouts
- Integration tests cover full user workflows

**Error Simulation Testing** (see [docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md](docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md)):

`MockDatabaseHelper` supports comprehensive error simulation for testing error handling:

```dart
// Configure mock to fail on next operation
mockDb.failOnOperation('getAllIngredients');

// Next call throws exception
await mockDb.getAllIngredients(); // Throws Exception('Simulated database error')
```

Key capabilities:
- 22+ supported database methods (recipes, meals, ingredients, meal plans)
- Custom exceptions for specific error types
- Auto-reset after throwing for easy test writing
- See documentation for complete method list and usage patterns

**Dialog Testing** (see [docs/testing/DIALOG_TESTING_GUIDE.md](docs/testing/DIALOG_TESTING_GUIDE.md)):

All dialog tests must follow these patterns:

```dart
// 1. Setup
setUp(() {
  mockDbHelper = TestSetup.setupMockDatabase();
});

// 2. Test return values
testWidgets('returns correct data on save', (tester) async {
  final result = await DialogTestHelpers.openDialogAndCapture<Map>(
    tester,
    dialogBuilder: (context) => MyDialog(databaseHelper: mockDbHelper),
  );

  await DialogTestHelpers.fillDialogForm(tester, {'Field': 'Value'});
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  expect(result.hasValue, isTrue);
  expect(result.value!['field'], equals('Value'));
});

// 3. Test cancellation (CRITICAL)
testWidgets('returns null when cancelled', (tester) async {
  final result = await DialogTestHelpers.openDialogAndCapture<Map>(
    tester,
    dialogBuilder: (context) => MyDialog(databaseHelper: mockDbHelper),
  );

  await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
  await tester.pumpAndSettle();

  expect(result.value, isNull);
  expect(mockDbHelper.dataUnchanged, isTrue); // No side effects
});

// 4. Test alternative dismissal methods
testWidgets('safely disposes on back button', (tester) async {
  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => MyDialog(),
  );

  await DialogTestHelpers.pressBackButton(tester);
  await tester.pumpAndSettle();
  // Test passes if no controller disposal crash
});
```

**Critical Dialog Testing Rules:**
1. **Always test cancellation** - Controller disposal crashes only occur on cancel, not save
2. **Test all dismissal methods** - Cancel button, back button, tap outside
3. **Verify no side effects** - Database unchanged after cancellation
4. **Use DialogTestHelpers** - Consistent, reliable dialog interactions
5. **Use DialogFixtures** - Standardized test data
6. **Check DI support** - Some dialogs lack dependency injection (see guide)

**Known Dialog Testing Limitations:**
- `MealRecordingDialog` - No DI support (issue #237)
- `AddSideDishDialog` - Doesn't load DB directly
- Nested dialogs - Deferred to issue #245
- See [docs/testing/DIALOG_TESTING_GUIDE.md](docs/testing/DIALOG_TESTING_GUIDE.md) for workarounds

**Regression Tests:**
- All dialog bugs documented in `test/regression/dialog_regression_test.dart`
- Includes controller disposal crash (commit 07058a2)
- Includes overflow issues (issue #246 - small screens)

**Edge Case Testing** (see [docs/testing/EDGE_CASE_TESTING_GUIDE.md](docs/testing/EDGE_CASE_TESTING_GUIDE.md) and [docs/testing/EDGE_CASE_CATALOG.md](docs/testing/EDGE_CASE_CATALOG.md)):

**REQUIRED**: All new features must include edge case tests. See the testing guide for comprehensive instructions.

All new features must include edge case tests covering:

```dart
// 1. Empty states
testWidgets('shows helpful empty state with no recipes', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();
  // mockDb has no recipes by default

  await tester.pumpWidget(/*...*/);

  EdgeCaseTestHelpers.verifyEmptyState(
    tester,
    expectedMessage: 'No recipes found',
  );
});

// 2. Boundary conditions
testWidgets('rejects servings = 0', (tester) async {
  await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
    tester,
    fieldLabel: 'Servings',
    boundaryType: BoundaryType.zero,
  );

  await EdgeCaseTestHelpers.triggerFormValidation(tester, submitButtonText: 'Save');

  EdgeCaseTestHelpers.verifyValidationError(
    tester,
    expectedError: 'Servings must be at least 1',
  );
});

// 3. Error scenarios
testWidgets('handles database error gracefully', (tester) async {
  ErrorInjectionHelpers.injectDatabaseError(
    mockDb,
    ErrorType.insertFailed,
    operation: 'insertRecipe',
  );

  // Attempt operation...
  EdgeCaseTestHelpers.verifyErrorDisplayed(tester, expectedError: 'Failed to save');
  EdgeCaseTestHelpers.verifyRecoveryPath(tester, recoveryButtonText: 'Retry');
});
```

**Critical Edge Case Testing Rules:**
1. **Test empty states** - Every list/collection screen must handle empty data
2. **Test boundary values** - Use `BoundaryValues` fixtures for consistency
3. **Test error recovery** - Don't just test errors occur, test recovery works
4. **Inject errors properly** - Use `ErrorInjectionHelpers`, reset in tearDown
5. **Verify data integrity** - No orphaned records, no partial updates on errors

**Edge Case Testing Workflow** (for all new features):
1. **Identify**: Review [EDGE_CASE_CATALOG.md](docs/testing/EDGE_CASE_CATALOG.md) for relevant categories
2. **Plan**: Document new edge cases in catalog before implementing
3. **Implement**: Use templates from [EDGE_CASE_TESTING_GUIDE.md](docs/testing/EDGE_CASE_TESTING_GUIDE.md)
4. **Verify**: All edge case tests must pass before merging

**Edge Case Test Organization:**
- `test/edge_cases/empty_states/` - Empty data scenarios
- `test/edge_cases/boundary_conditions/` - Extreme values
- `test/edge_cases/error_scenarios/` - Error handling
- `test/edge_cases/interaction_patterns/` - Unusual user interactions
- `test/edge_cases/data_integrity/` - Data consistency

## Key Implementation Notes

### Multi-Recipe Meal System
The app supports complex meals with main dishes and side dishes through junction tables. When working with meals:
- Use `MealPlanItemRecipe` for planning phase
- Use `MealRecipe` for cooking phase  
- Both support `isPrimaryDish` flags for meal composition

### Temporal Context
The recommendation system automatically adapts based on day of week:
- **Weekdays**: Emphasize simplicity (difficulty weight: 20%)
- **Weekends**: Allow complexity (rating weight: 20%, variety: 15%)

### Error Handling
Custom exception hierarchy:
- `ValidationException` - Input validation failures
- `NotFoundException` - Entity not found
- `GastrobrainException` - General application errors

### Performance Considerations
- Recommendation caching with context-aware invalidation
- Bulk database operations for large datasets
- Optimized queries with proper indexing
- Lazy loading for improved startup

