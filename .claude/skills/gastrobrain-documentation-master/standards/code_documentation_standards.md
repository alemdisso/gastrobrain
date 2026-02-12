# Code Documentation Standards

Standards for dartdoc comments and inline code documentation in the Gastrobrain codebase.

---

## Dartdoc Comment Requirements

### What MUST Have Dartdoc

| Element | Required | Notes |
|---------|----------|-------|
| Public classes | Yes | Brief + detailed description |
| Public methods | Yes | Description + params + returns + throws |
| Public fields/properties | Yes | Brief description |
| Public enums | Yes | Enum purpose + each value |
| Public typedefs | Yes | What the type represents |
| Private classes (complex) | Recommended | If logic is non-obvious |
| Private methods (complex) | Recommended | If logic is non-obvious |

### What Does NOT Need Dartdoc

- Simple private fields with obvious names
- Getters/setters with obvious behavior
- Override methods that don't change behavior
- Test files (use descriptive test names instead)

---

## Class Documentation

### Standard Pattern

```dart
/// Brief one-line description ending with a period.
///
/// Detailed explanation of what this class does, when to use it,
/// and any important behavioral notes. Can span multiple paragraphs.
///
/// This class follows the [PatternName] pattern and is accessed
/// via [ServiceProvider.category.serviceName].
///
/// Example:
/// ```dart
/// final instance = MyClass(dependency: dep);
/// final result = await instance.doSomething();
/// ```
///
/// See also:
/// * [RelatedClass] for similar functionality
/// * [DependencyClass] which this class uses
class MyClass {
  // ...
}
```

### Widget Classes

```dart
/// Dropdown widget for selecting [MealType].
///
/// Displays localized meal type options following the same pattern
/// as [FrequencyDropdown]. Supports nullable selection for backward
/// compatibility with existing meals that have no type assigned.
///
/// Example:
/// ```dart
/// MealTypeDropdown(
///   value: currentMealType,
///   onChanged: (MealType? newType) {
///     setState(() => _mealType = newType);
///   },
/// )
/// ```
class MealTypeDropdown extends StatelessWidget {
  // ...
}
```

### Model Classes

```dart
/// Represents a meal record in the system.
///
/// A meal contains one or more recipes (a primary dish and optional
/// side dishes) and is associated with a specific date. Meals can
/// be categorized by [mealType] for filtering and recommendations.
///
/// Database table: `meals`
/// Junction table: `meal_recipes` (links to [Recipe] via [MealRecipe])
class Meal {
  // ...
}
```

### Service Classes

```dart
/// Service for generating recipe recommendations.
///
/// Uses a multi-factor scoring system that considers recipe ratings,
/// variety, difficulty, and temporal context (weekday vs weekend).
/// Results are cached with context-aware invalidation.
///
/// Access via: `ServiceProvider.recommendations.service`
///
/// See also:
/// * [RecommendationFactor] for individual scoring factors
/// * [TemporalContext] for time-based adjustments
class RecommendationService {
  // ...
}
```

---

## Method Documentation

### Standard Pattern

```dart
/// Brief description of what this method does.
///
/// Detailed explanation of behavior, side effects, and important
/// notes about when/how to use this method.
///
/// The [paramName] parameter controls [behavior].
/// If [optionalParam] is null, defaults to [default behavior].
///
/// Returns a [ReturnType] containing [description].
/// Returns null if [condition].
///
/// Throws [NotFoundException] if the entity with [id] doesn't exist.
/// Throws [ValidationException] if [paramName] is invalid.
///
/// Example:
/// ```dart
/// final result = await service.methodName(
///   id: recipeId,
///   includeRelated: true,
/// );
/// ```
Future<ReturnType?> methodName({
  required String id,
  bool includeRelated = false,
}) async {
  // ...
}
```

### Simple Methods (One-Liner OK)

```dart
/// Returns the total number of recipes in the database.
Future<int> getRecipeCount() async => _db.count('recipes');

/// Whether this meal has any side dishes.
bool get hasSideDishes => recipes.where((r) => !r.isPrimaryDish).isNotEmpty;
```

### Factory/Constructor Methods

```dart
/// Creates a [Meal] from a database row map.
///
/// The [map] must contain keys: 'id', 'date', 'meal_type'.
/// The 'meal_type' value is parsed via [MealType.fromString],
/// returning null for unrecognized values (backward compatibility).
factory Meal.fromMap(Map<String, dynamic> map) {
  // ...
}
```

---

## Field Documentation

### Standard Pattern

```dart
/// Unique identifier for this meal.
final String id;

/// Date when this meal was consumed or planned.
final DateTime date;

/// Type/category of this meal (optional).
///
/// Can be null for backward compatibility with existing meals
/// recorded before the meal type feature was added.
/// When null, UI displays "Not specified".
final MealType? mealType;
```

### Enum Values

```dart
/// Categories for organizing meals by time of day.
enum MealType {
  /// Morning meal, typically 6-10 AM.
  breakfast,

  /// Midday meal, typically 11 AM - 2 PM.
  lunch,

  /// Evening meal, typically 5-9 PM.
  dinner,

  /// Between-meal snack, any time of day.
  snack,
}
```

---

## Inline Comments

### When to Use Inline Comments

- Complex algorithms or business logic
- Non-obvious workarounds with explanation
- TODO items with issue references
- Performance-critical sections explaining optimization choices

### Good Inline Comments

```dart
// Weight difficulty more heavily on weekdays to favor simpler meals
final difficultyWeight = isWeekday ? 0.20 : 0.10;

// Cache key includes date and meal type for context-aware invalidation
final cacheKey = '${date.toIso8601String()}_${mealType?.name ?? "any"}';

// TODO(#237): Extract to MealEditService when consolidating edit logic
```

### Bad Inline Comments (Avoid)

```dart
// Get the recipe  (describes obvious code)
final recipe = await getRecipe(id);

// Set to true  (restates the code)
isLoading = true;

// Loop through recipes  (obvious from code structure)
for (final recipe in recipes) { ... }
```

---

## Cross-Referencing

### Linking to Other Elements

```dart
/// Uses [DatabaseHelper.getRecipe] to fetch the recipe data.
/// Applies [RecommendationFactor] scoring from [RecommendationService].
/// See also [MealPlanItemRecipe] for the planning phase equivalent.
```

### Linking to Documentation

```dart
/// For testing patterns, see `docs/testing/DIALOG_TESTING_GUIDE.md`.
/// For edge case coverage, see `docs/testing/EDGE_CASE_TESTING_GUIDE.md`.
```

---

## Common Patterns

### Nullable Fields

Always explain WHY a field is nullable:

```dart
/// The recipe's preparation time in minutes.
///
/// Null when the user hasn't specified prep time, which is allowed
/// for quick recipe entry. UI displays "Not set" when null.
final int? prepTimeMinutes;
```

### Callback Parameters

```dart
/// Called when the user selects a new meal type.
///
/// The callback receives null when the user clears the selection.
final ValueChanged<MealType?> onChanged;
```

### Boolean Flags

```dart
/// Whether this recipe is the primary dish in a multi-recipe meal.
///
/// In a meal with multiple recipes, exactly one must be the primary
/// dish (`isPrimaryDish = true`). All others are side dishes.
final bool isPrimaryDish;
```

---

## Verification

Run `dart doc` or check in IDE to verify:
- No broken `[references]` in dartdoc
- All public APIs have documentation
- Examples in dartdoc are syntactically valid
- No dangling `See also` references
