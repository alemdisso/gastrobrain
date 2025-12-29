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

For detailed workflows on issue management, GitHub Projects integration, and Git Flow processes, see **[docs/ISSUE_WORKFLOW.md](docs/ISSUE_WORKFLOW.md)**.

**Quick Reference:**
- Branch format: `{type}/{issue-number}-{short-description}`
- Commit format: `{type}: brief description (#{issue-number})`
- Always use TodoWrite when planning implementation
- Test before merging: `flutter test && flutter analyze`
- Merge to develop, then close issue and clean up branch

## Environment Notes

**Local Development (WSL)**: This project runs in a WSL environment for local development. For local code validation, use `flutter analyze` and `flutter test`. Note that `flutter build apk`, `flutter build ios`, and `flutter run` are not supported in the local WSL environment. Physical device testing and full builds must be done outside WSL (e.g., via GitHub Actions CI/CD, which successfully builds APKs).

## Architecture & Codebase

For comprehensive architecture details, data models, and testing infrastructure, see **[docs/Gastrobrain-Codebase-Overview.md](docs/Gastrobrain-Codebase-Overview.md)**.

**Key patterns to follow:**
- **Dependency injection**: Access services via `ServiceProvider`
- **Database operations**: Use `DatabaseHelper` with proper error handling (`NotFoundException`, `ValidationException`, `GastrobrainException`)
- **Multi-recipe meals**: Use `MealPlanItemRecipe` (planning) and `MealRecipe` (cooking) with `isPrimaryDish` flags
- **Testing**: Use `MockDatabaseHelper` for unit tests; integration tests use real database

## Localization (l10n)

All user-facing strings must be localized for English and Portuguese. See **[docs/L10N_PROTOCOL.md](docs/L10N_PROTOCOL.md)** for the complete localization workflow.

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

**Dialog Testing** (see [docs/DIALOG_TESTING_GUIDE.md](docs/DIALOG_TESTING_GUIDE.md)):

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
- See [docs/DIALOG_TESTING_GUIDE.md](docs/DIALOG_TESTING_GUIDE.md) for workarounds

**Regression Tests:**
- All dialog bugs documented in `test/regression/dialog_regression_test.dart`
- Includes controller disposal crash (commit 07058a2)
- Includes overflow issues (issue #246 - small screens)

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

