# createTestableWidget() Pattern Documentation

## Overview

The `createTestableWidget()` helper function is a standard pattern used across all widget tests in the Gastrobrain project. It provides a consistent way to wrap test widgets with the necessary infrastructure for Flutter widget testing, including localization, Material Design context, and optional providers.

## Purpose

This helper function ensures that test widgets have access to:
- **Localization**: AppLocalizations for internationalized strings (English and Portuguese)
- **Material Design context**: MaterialApp for theme and navigation
- **Scaffold context**: Optional Scaffold for widgets that need it
- **State management**: Optional providers for widgets that depend on state

## Pattern Variations

### 1. Basic Pattern (Screen Tests)

Used for full-screen widgets that don't need a Scaffold wrapper.

**Location**: `test/screens/meal_history_screen_test.dart:20-36`

```dart
Widget createTestableWidget(Widget child,
    {Locale locale = const Locale('en', '')}) {
  return MaterialApp(
    locale: locale,
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
  );
}
```

**When to use:**
- Testing full-screen widgets (Screens)
- Testing widgets that provide their own Scaffold
- When locale testing is needed

**Example usage:**
```dart
await tester.pumpWidget(
  createTestableWidget(
    MealHistoryScreen(
      recipe: testRecipe,
      databaseHelper: mockDbHelper,
    ),
  ),
);
```

### 2. Widget Test Pattern (With Scaffold)

Used for smaller widgets that need a Scaffold parent for proper rendering.

**Location**: `test/widgets/recipe_card_test.dart:14-30`

```dart
Widget createTestableWidget(Widget child,
    {Locale locale = const Locale('en', '')}) {
  return MaterialApp(
    locale: locale,
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
    home: Scaffold(body: child),
  );
}
```

**When to use:**
- Testing individual widgets (Cards, Dialogs, etc.)
- Testing widgets that require Scaffold context (e.g., for SnackBars)
- Testing layout widgets

**Example usage:**
```dart
await tester.pumpWidget(
  createTestableWidget(
    RecipeCard(
      recipe: testRecipe,
      onEdit: () {},
      onDelete: () {},
      onCooked: () {},
      mealCount: 5,
      lastCooked: DateTime(2023, 12, 25),
    ),
  ),
);
```

### 3. Provider Pattern (With State Management)

Used for widgets that depend on Provider-based state management.

**Location**: `test/screens/meal_history_edit_test.dart:31-48`

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

**When to use:**
- Testing widgets that call `context.read<Provider>()`
- Testing widgets that depend on Provider state
- Testing screens with complex state management

**Example usage:**
```dart
await tester.pumpWidget(
  createTestableWidget(
    MealHistoryScreen(
      recipe: testRecipe,
      databaseHelper: mockDbHelper,
    ),
  ),
);
```

**Note**: This pattern requires a mock provider implementation:
```dart
class MockRecipeProvider extends RecipeProvider {
  @override
  Future<void> refreshMealStats() async {
    // No-op for testing
    return Future.value();
  }
}
```

### 4. Minimal Pattern (Without Locale Parameter)

Used when locale testing is not needed.

**Location**: `test/screens/weekly_plan_screen_test.dart:24-38`

```dart
Widget createTestableWidget(Widget child) {
  return MaterialApp(
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
  );
}
```

**When to use:**
- Testing widgets that don't need locale-specific behavior
- Testing business logic that's locale-independent

## Locale Testing

### Testing Both Locales

For widgets with localized content, test both English and Portuguese:

```dart
testWidgets('displays text in English', (WidgetTester tester) async {
  await tester.pumpWidget(
    createTestableWidget(
      MyWidget(),
      locale: const Locale('en', ''),
    ),
  );

  expect(find.text('English text'), findsOneWidget);
});

testWidgets('displays text in Portuguese', (WidgetTester tester) async {
  await tester.pumpWidget(
    createTestableWidget(
      MyWidget(),
      locale: const Locale('pt', ''),
    ),
  );

  expect(find.text('Texto em português'), findsOneWidget);
});
```

### Date Format Testing

Locale also affects date formatting:

```dart
// English: MM/DD/YYYY (12/25/2023)
createTestableWidget(widget, locale: const Locale('en', 'US'))

// Portuguese: DD/MM/YYYY (25/12/2023)
createTestableWidget(widget, locale: const Locale('pt', 'BR'))
```

## Implementation Guidelines

### When Creating New Test Files

1. **Choose the appropriate pattern** based on widget type:
   - Screens → Basic Pattern
   - Widgets → With Scaffold Pattern
   - State-dependent → Provider Pattern

2. **Always include localization delegates**:
   ```dart
   localizationsDelegates: const [
     AppLocalizations.delegate,
     GlobalMaterialLocalizations.delegate,
     GlobalWidgetsLocalizations.delegate,
     GlobalCupertinoLocalizations.delegate,
   ],
   ```

3. **Support both locales**:
   ```dart
   supportedLocales: const [
     Locale('en', ''),
     Locale('pt', ''),
   ],
   ```

4. **Add locale parameter for localized content**:
   ```dart
   {Locale locale = const Locale('en', '')}
   ```

### For Issue #124 (Meal Edit Feedback Tests)

Based on the roadmap requirements, the new test file should use:

**Pattern**: Basic Pattern with Scaffold (for SnackBar testing)

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

**Rationale**:
- Needs Provider for `RecipeProvider` dependency
- Tests SnackBar messages (requires MaterialApp/Scaffold context)
- Tests localized error/success messages

## Common Pitfalls

### 1. Missing Localization Context

❌ **Wrong**:
```dart
await tester.pumpWidget(MyWidget()); // No localization context
```

✅ **Correct**:
```dart
await tester.pumpWidget(
  createTestableWidget(MyWidget()),
);
```

### 2. Missing Scaffold for SnackBars

❌ **Wrong** (SnackBar won't display):
```dart
Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child); // No Scaffold
}
```

✅ **Correct**:
```dart
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child), // Scaffold provides SnackBar context
  );
}
```

### 3. Forgetting Provider Dependencies

❌ **Wrong** (will crash if widget uses Provider):
```dart
Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child); // No Provider
}
```

✅ **Correct**:
```dart
Widget createTestableWidget(Widget child) {
  return ChangeNotifierProvider<RecipeProvider>(
    create: (_) => MockRecipeProvider(),
    child: MaterialApp(home: child),
  );
}
```

## Examples From Codebase

| Test File | Pattern | Reason |
|-----------|---------|--------|
| `edit_recipe_screen_test.dart` | Basic with locale | Screen testing with date formats |
| `meal_history_edit_test.dart` | Provider pattern | Needs RecipeProvider for refreshMealStats() |
| `meal_history_screen_test.dart` | Basic with locale | Screen testing with date formats |
| `weekly_plan_screen_test.dart` | Minimal | No locale-specific tests |
| `recipe_card_test.dart` | With Scaffold | Widget needs Scaffold context |
| `recipe_card_rating_test.dart` | With Scaffold | Widget testing |
| `recipe_selection_card_test.dart` | With Scaffold | Widget testing |

## References

- Flutter Testing Guide: https://docs.flutter.dev/testing
- Provider Testing: https://pub.dev/packages/provider#testing
- Localization Testing: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#testing
