<!-- markdownlint-disable -->
# Gastrobrain Codebase Overview

## Project Context
Gastrobrain is a comprehensive meal planning and recipe management application built with Flutter. It provides intelligent recipe recommendations, multi-language support (English/Portuguese), and sophisticated meal planning features with multi-recipe meal support. The application uses local SQLite storage and features a pluggable recommendation engine with temporal intelligence.

## Core Data Models

### Recipe Management
- **Recipe**: Stores recipe details including name, frequency preference, notes, difficulty rating (1-5), cooking times, and user ratings
- **Ingredient**: Represents ingredients with categories, optional units, and protein types
- **RecipeIngredient**: Links recipes to ingredients with quantities, notes, and optional unit overrides

### Meal Planning & Tracking
- **MealPlan**: Manages weekly meal plans (starting on Friday) with notes and timestamps
- **MealPlanItem**: Individual meal slots (lunch/dinner) within a plan
- **MealPlanItemRecipe**: Junction table connecting meal plan items to recipes (supports multiple recipes per meal)
- **Meal**: Tracks actual cooking instances with servings, actual times, and success ratings
- **MealRecipe**: Junction table for meals with multiple recipes (main dish + side dishes)

### Supporting Models
- **ProteinType**: Enum for different protein types (beef, chicken, fish, etc.)
- **FrequencyType**: Enum for desired cooking frequencies (daily, weekly, monthly, etc.)
- **RecipeRecommendation**: Handles recipe scoring and user responses
- **RecommendationResults**: Container for recommendation queries with metadata

## Services & Core Logic

### Database Management
- **DatabaseHelper**: SQLite-based data access layer with CRUD operations, migrations, and complex queries
- **DatabaseProvider**: Singleton pattern for database access
- **MigrationRunner**: Database schema migration system with versioned migrations
- **IdGenerator**: UUID generation utility

### Recommendation System
- **RecommendationService**: Core service with pluggable scoring factors and temporal intelligence
- **MealPlanAnalysisService**: Analyzes both planned and recently cooked meals for context-aware recommendations
- **Scoring Factors**:
  - FrequencyFactor (35%): Prioritizes recipes based on desired frequency
  - ProteinRotationFactor (30%): Encourages protein variety with graduated penalties
  - RatingFactor (10%): Considers user ratings
  - VarietyEncouragementFactor (10%): Promotes less-cooked recipes
  - DifficultyFactor (10%): Favors simpler recipes for weekdays
  - UserFeedbackFactor: Learns from user responses to recommendations
  - RandomizationFactor (5%): Adds variety to recommendations
- **DatabaseQueries**: Optimized queries for recommendation data fetching
- **ProteinPenaltyStrategy**: Sophisticated protein rotation with graduated scoring

### Ingredient Management Services
- **IngredientMatchingService**: Multi-stage ingredient matching with confidence scoring
  - 6-stage matching pipeline: exact → case-insensitive → normalized → prefix → fuzzy → translation
  - Plural form singularization for Portuguese and English
  - Handles 23+ irregular plurals (ovos→ovo, tomatoes→tomato, knives→knife)
  - Pattern-based singularization:
    - Portuguese: -ões/-ães/-ãos→-ão, -ns→-m, -is→-l, -res→-r, -zes→-z, regular -s
    - English: -ies→-y, -ves→-f/-fe, -oes→-o, -es (after sibilants), regular -s
  - Compound word support (batatas doces → batata doce)
  - Smart disambiguation (Portuguese -ões vs English -oes by consonant/vowel detection)
  - Achieves 90%+ confidence for plural-to-singular matches
  - First-letter indexing for performance optimization
- **IngredientExportService**: Exports ingredient data to JSON format
- **RecipeExportService**: Exports recipes with full ingredient data to JSON
- **IngredientTranslationService**: Translates ingredients from English to Portuguese using reviewed translation data

### Meal Management Services
- **MealEditService**: Centralized meal editing and recording operations
  - Consolidates meal editing logic from multiple screens into single source of truth
  - `updateMealWithRecipes()`: Updates meal records with new values and recipe associations
  - `recordMealWithRecipes()`: Records new meals with primary and additional recipes
  - Handles atomic operations for meal + recipe association updates
  - Proper dependency injection via ServiceProvider
  - Consistent error handling and transaction support

### Provider Architecture
- **RecipeProvider**: State management for recipe operations
- **MealProvider**: State management for meal tracking
- **MealPlanProvider**: State management for meal planning
- **Repository Pattern**: Base repositories for consistent data access

### Utility Services
- **ServiceProvider**: Central dependency injection hub with provider access
- **SnackbarService**: Handles user notifications and feedback
- **EntityValidator**: Validates data models and business rules
- **LocalizedErrorMessages**: Internationalized error handling
- **GastrobrainException**: Custom exception hierarchy

## User Interface

### Main Navigation
- **HomePage**: Navigation hub with tabs for Recipes and Weekly Plan
- **RecipeCard**: Expandable recipe cards with quick actions and statistics

### Recipe Management
- **AddRecipeScreen**: Recipe creation with ingredient management and localization
- **EditRecipeScreen**: Recipe modification with validation
- **RecipeIngredientsScreen**: Detailed ingredient view with editing capabilities
- **MealHistoryScreen**: Tracks cooking history for each recipe with edit capabilities
  - Improved layout with recipe name prominently displayed in app bar
  - Streamlined meal cards without redundant information
  - Compact time display for better space efficiency on mobile devices
- **IngredientsScreen**: Comprehensive ingredient management interface

### Meal Planning
- **WeeklyPlanScreen**: Week view (Friday-Thursday) with meal slot management and multi-recipe support
- **WeeklyCalendarWidget**: Responsive calendar with multiple layouts (phone/tablet/landscape)
- **CookMealScreen**: Dedicated cooking interface with meal completion tracking

### Development & Utility Screens
- **ToolsScreen**: Development utilities for data export and ingredient translation
- **MigrationScreen**: Database migration interface for schema updates

### Dialogs & Components
- **AddIngredientDialog**: Ingredient addition with custom/database options
- **AddNewIngredientDialog**: New ingredient creation with category selection
- **AddSideDishDialog**: Side dish addition for multi-recipe meals
- **MealRecordingDialog**: Comprehensive meal tracking with multiple recipe support
- **EditMealRecordingDialog**: Edit completed meal records
- **MealCookedDialog**: Quick meal completion interface

## Key Features

### Recipe Management
- Create, edit, and delete recipes with full localization support
- Search and filter recipes by name for quick access
- Manage ingredients with categories, protein types, and measurement units
- Track difficulty, cooking times, and personal ratings
- Maintain cooking history with actual vs. expected times
- Edit and modify historical meal records

### Meal Planning
- Weekly view starting on Friday with responsive layout
- Lunch and dinner slots for each day
- Recipe recommendations based on intelligent algorithms with temporal context
- Mark meals as cooked with detailed tracking and multi-recipe support
- Supports multiple recipes per meal (main dish + sides)
- Dedicated cooking interface with progress tracking

### Recommendation System
- Context-aware recipe suggestions with dual-context analysis (planned + cooked)
- Sophisticated protein rotation with graduated penalty scoring
- Considers protein rotation, cooking frequency, and weekday vs. weekend profiles
- User response tracking for continuous improvement
- Performance-optimized with caching and meal plan analysis
- Temporal intelligence for weekday simplicity vs. weekend complexity

### Internationalization
- Full bilingual support (English/Portuguese)
- Localized UI strings and error messages
- Proper date and time localization with locale-aware formatting
- Ingredient translation capabilities with reviewed translation data
- ARB-based localization system with Flutter's built-in i18n

### Data Management & Export
- Local SQLite storage with migration system
- Database versioning and automated schema updates
- JSON import/export capabilities for recipes and ingredients
- Data export utilities for external management
- Ingredient translation system with CSV-based reviewed data
- Comprehensive entity validation with localized error handling

### Development Tools
- Integrated development utilities screen
- Database migration interface
- Data export tools for recipes and ingredients
- Ingredient translation utilities for English-to-Portuguese conversion

## Testing Infrastructure

### Test Coverage Overview
The application maintains comprehensive test coverage with **600+ unit/widget tests** (including 458+ edge case tests from Issue #39, 122 dialog tests) and **8+ end-to-end/integration tests**, ensuring reliability and maintainability across all application layers. The testing infrastructure includes robust dialog testing utilities, comprehensive edge case testing framework, E2E testing framework with helper methods, regression test suite, and comprehensive coverage of critical user workflows.

**Test Breakdown:**
- **Edge Case Tests** (Issue #39): 458+ tests across empty states, boundary conditions, error scenarios, interaction patterns, and data integrity
- **Dialog Tests**: 122 tests across 6 dialogs (return values, cancellation, disposal, validation, error handling)
- **Service/Core Tests**: 40+ tests (recommendations, database, ingredient matching)
- **UI/Widget Tests**: 20+ tests (screens, components, navigation)
- **Integration Tests**: 8+ E2E workflow tests
- **Regression Tests**: Historical bug prevention (controller disposal, overflow issues)

### Unit & Widget Tests (`test/` directory)

#### Core Services Testing
- **Recommendation System Tests** (15+ test files):
  - Individual recommendation factor testing (`*_factor_test.dart`)
  - Factor integration testing (`*_integration_test.dart`)
  - Advanced filtering and protein rotation logic
  - Temporal context and user feedback testing
  - Complete recommendation service testing

- **Database Layer Tests**:
  - `database_helper_*_test.dart`: Core database operations
  - Model validation and data integrity tests
  - Migration system testing

- **Service Layer Tests**:
  - `meal_plan_analysis_service_test.dart`: Meal planning analysis
  - `ingredient_export_service_test.dart`: Data export functionality
  - `ingredient_matching_service_test.dart`: Multi-stage matching with 91 tests including 28 plural form tests

#### UI Component Testing
- **Screen Tests** (`test/screens/`):
  - `weekly_plan_screen_test.dart`: Meal planning interface
  - `cook_meal_screen_test.dart`: Cooking workflow
  - `meal_history_screen_test.dart`: Historical meal tracking
  - `add_recipe_screen_test.dart`: Recipe creation flow

- **Screen Edge Case Tests** (`test/edge_cases/screens/`):
  - `meal_history_screen_edge_cases_test.dart`: 21 tests - Various history lengths, meal data variations, data integrity
  - `weekly_plan_screen_edge_cases_test.dart`: 9 tests - Fully populated weeks, large datasets (100+ meals), data integrity
  - Tests cover empty states, boundary conditions, and data integrity scenarios
  - See [docs/EDGE_CASE_CATALOG.md](EDGE_CASE_CATALOG.md) and [docs/EDGE_CASE_TESTING_GUIDE.md](EDGE_CASE_TESTING_GUIDE.md)

- **Widget Tests** (`test/widgets/`):
  - `weekly_calendar_widget_test.dart`: Calendar functionality
  - `recipe_card_test.dart`: Recipe display components
  - `recipe_card_rating_test.dart`: Recipe rating display and interactions

- **Dialog Tests** (`test/widgets/`, **100+ tests** across 6 dialogs):
  - `meal_cooked_dialog_test.dart`: 12 tests - Cooking details capture
  - `add_ingredient_dialog_test.dart`: 14 tests - Ingredient selection and creation
  - `meal_recording_dialog_test.dart`: 20 tests - Meal planning workflow
  - `add_side_dish_dialog_test.dart`: 24 tests - Multi-recipe meal composition
  - `add_new_ingredient_dialog_test.dart`: 9 tests - Ingredient creation
  - `edit_meal_recording_dialog_test.dart`: 21 tests - Meal modification
  - All dialogs tested for: return values, cancellation, controller disposal, validation, error handling
  - See [docs/DIALOG_TESTING_GUIDE.md](DIALOG_TESTING_GUIDE.md) for patterns and best practices

#### Model & Data Tests
- **Model Validation** (`test/models/`):
  - All core models (Recipe, Meal, MealPlan, etc.)
  - Junction table relationships testing
  - Data serialization and validation
  - User response tracking and recommendation results

### Integration Tests (`integration_test/` directory)

#### End-to-End Workflows
The application features a comprehensive E2E testing framework with reusable helper methods, best practices documentation, and coverage of critical user workflows.

**Core Workflow Tests:**
- **`app_launch_test.dart`**: Basic app initialization and home screen rendering
- **`tab_navigation_test.dart`**: Navigation between main app tabs
- **`recipe_creation_test.dart`**: Complete recipe creation workflow with form validation
- **`recipe_editing_test.dart`**: Recipe modification and update workflows
- **`meal_recording_test.dart`**: End-to-end meal recording workflow including navigation and data persistence
- **`meal_planning_ui_test.dart`**: Comprehensive meal planning UI interactions including calendar slots, recipe selection, and multi-recipe meals
- **`weekly_meal_planning_test.dart`**: Complete weekly meal planning workflow from start to finish

**System Integration Tests:**
- **`recommendation_integration_test.dart`**: Full recommendation system integration
- **`meal_plan_analysis_integration_test.dart`**: Meal plan analysis system testing

**E2E Testing Infrastructure:**
- Reusable helper methods for common operations (navigation, form filling, recipe creation)
- Comprehensive best practices guide (`docs/E2E_TESTING.md`)
- Form field keys for reliable test selectors
- Diagnostic utilities for debugging test failures

### Testing Architecture & Patterns

#### Mock Framework
- **`MockDatabaseHelper`**: Comprehensive database mocking for isolated testing
- **Dependency Injection Pattern**: Widgets accept optional `DatabaseHelper` parameters for test injection
- **Parallel Test Execution**: Tests run concurrently without database locking issues

#### Testing Utilities
- **`test_utils/test_setup.dart`**: Centralized test configuration and setup
- **`test_utils/test_app_wrapper.dart`**: Widget testing utilities with localization support
- **`test/helpers/dialog_test_helpers.dart`**: 18 helper methods for dialog testing
  - `openDialogAndCapture<T>()`: Opens dialog and captures return value
  - `tapDialogButton()`, `fillTextField()`, `fillDialogForm()`: User interactions
  - `pressBackButton()`, `tapOutsideDialog()`: Alternative dismissal methods
  - `verifyDialogCancelled()`, `verifyNoSideEffects()`: Assertion helpers
- **`test/test_utils/dialog_fixtures.dart`**: Standardized test data factories
  - `createTestRecipe()`, `createPrimaryRecipe()`, `createSideRecipe()`
  - `createMultipleRecipes()`, `createMultipleIngredients()`
  - Consistent test data across all dialog tests
- **`test/regression/dialog_regression_test.dart`**: Regression tests for known dialog bugs
  - Controller disposal crash (commit 07058a2)
  - RenderFlex overflow on small screens (issue #246)
  - Links to historical bug fixes with commit hashes

#### Edge Case Testing Infrastructure

The application includes comprehensive edge case testing utilities for testing boundary conditions, error scenarios, and unusual interaction patterns (Issue #39).

**Edge Case Test Helpers:**
- **`test/helpers/edge_case_test_helpers.dart`**: Core utilities for edge case testing
  - `verifyEmptyState()`: Verify empty state displays correctly
  - `fillWithBoundaryValue()`: Fill fields with extreme values
  - `simulateRapidTaps()`: Test rapid user interactions
  - `verifyErrorDisplayed()`: Check error messages
  - `verifyRecoveryPath()`: Verify recovery actions available
  - `verifyLoadingState()`: Check loading indicators
  - `triggerFormValidation()`: Trigger and verify validation

**Boundary Value Fixtures:**
- **`test/fixtures/boundary_fixtures.dart`**: Standardized extreme values
  - Text boundaries: `emptyString`, `veryLongText` (1000 chars), `extremelyLongText` (10000 chars)
  - Numeric boundaries: `zero`, `negative`, `maxReasonable`, `decimal`
  - Special values: `specialChars`, `withEmoji`, `withUnicode`, `sqlInjection`
  - Collection sizes: `listEmpty`, `listVeryLarge` (1000+ items)
  - Pre-configured sets: `recipeBoundaries`, `mealBoundaries`, `ingredientBoundaries`

**Error Injection Helpers:**
- **`test/helpers/error_injection_helpers.dart`**: Simulate errors for testing
  - `injectDatabaseError()`: Trigger database failures
  - `simulateConstraintViolation()`: FK/unique violations
  - `simulateDatabaseLocked()`: Concurrent access errors
  - `simulateTimeout()`: Timeout scenarios
  - `resetErrorInjection()`: Clean up after tests
  - `ValidationErrorHelpers`: Create validation error messages
  - `RecoveryPathHelpers`: Verify error recovery workflows

**Edge Case Test Organization:**
- **`test/edge_cases/empty_states/`**: Empty data scenarios (no recipes, no ingredients, etc.)
- **`test/edge_cases/boundary_conditions/`**: Extreme values (0, negative, 10000+ chars)
- **`test/edge_cases/error_scenarios/`**: Error handling (DB failures, validation errors)
- **`test/edge_cases/interaction_patterns/`**: Unusual interactions (rapid taps, concurrent actions)
- **`test/edge_cases/data_integrity/`**: Data consistency (orphaned records, transactions)

**Edge Case Catalog:**
- **`docs/EDGE_CASE_CATALOG.md`**: Comprehensive catalog of 150+ edge cases
  - Organized by category with priority levels (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low)
  - Tracks coverage status (✅ Tested, ⏳ Planned, 🐛 Known Issue)
  - Documents known issues and regression tests
  - Updated as new edge cases are discovered

**Edge Case Testing Principles:**
1. **Test empty states**: Every list/collection screen must handle empty data gracefully
2. **Use boundary fixtures**: Use `BoundaryValues` for consistent extreme value testing
3. **Test error recovery**: Verify recovery paths work, not just that errors occur
4. **Inject errors properly**: Use `ErrorInjectionHelpers`, always reset in `tearDown()`
5. **Verify data integrity**: No orphaned records, no partial updates on errors

- **Isolated Test Environment**: Each test uses fresh mock instances to prevent state pollution

#### Key Testing Principles
- **Test Isolation**: No shared state between tests
- **Mock-First Approach**: All database interactions use mocks in unit/widget tests
- **Real Database Integration**: Integration tests use actual database operations
- **Localization Testing**: All UI tests include proper localization setup

### Testing Commands

#### Running Tests
```bash
# Run all unit and widget tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run all E2E/integration tests
flutter test integration_test/

# Run specific E2E test
flutter test integration_test/meal_planning_ui_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests by category
flutter test test/core/services/          # Service layer tests
flutter test test/widgets/                # Widget tests
flutter test test/screens/                # Screen tests
flutter test test/models/                 # Model tests
```

#### Test Quality
- **Comprehensive Coverage**: Tests cover all critical business logic and UI workflows
- **Performance Testing**: Recommendation algorithm performance testing included
- **Error Handling**: Exception scenarios and edge cases covered
- **User Experience Testing**: Complete user journeys validated through integration tests

The testing infrastructure ensures code quality, prevents regressions, and validates both individual components and complete user workflows. The mock-based approach allows for fast, reliable test execution while integration tests verify real-world functionality.

## Development Standards

### Form Field Keys

**Status:** Adopted standard as of 2025-11-25 | **Tracking:** [#219 - Form Field Key Refactoring](https://github.com/alemdisso/gastrobrain/issues/219)

All form fields should have explicit keys for improved testability, debugging, and state management. This is a general development best practice that provides benefits beyond testing.

#### Why Use Form Field Keys?

- **Testing Reliability**: E2E and widget tests can deterministically find specific fields
- **Accessibility**: Improves screen reader and assistive technology support
- **Debugging**: Easier widget identification in Flutter DevTools
- **State Preservation**: Helps Flutter maintain form state correctly during rebuilds
- **Code Clarity**: Self-documenting code that explicitly identifies fields

#### Naming Convention

Use descriptive, snake_case keys that identify the form and field:

**Pattern:** `{screen}_{field}_field`

**Examples:**
```dart
// Add Recipe Screen
Key('add_recipe_name_field')
Key('add_recipe_notes_field')
Key('add_recipe_instructions_field')
Key('add_recipe_prep_time_field')
Key('add_recipe_cook_time_field')

// Edit Recipe Screen
Key('edit_recipe_name_field')
Key('edit_recipe_notes_field')

// Meal Planning
Key('meal_plan_notes_field')
Key('meal_plan_date_field')
```

#### Implementation Examples

**TextFormField with Key:**
```dart
TextFormField(
  key: const Key('add_recipe_name_field'),
  controller: _nameController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    border: const OutlineInputBorder(),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterRecipeName;
    }
    return null;
  },
)
```

**DropdownButtonFormField with Key:**
```dart
DropdownButtonFormField<RecipeCategory>(
  key: const Key('add_recipe_category_field'),
  value: _selectedCategory,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.category,
  ),
  items: RecipeCategory.values.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category.getLocalizedDisplayName(context)),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => _selectedCategory = value!);
  },
)
```

#### Testing with Keys

**Finding Fields in Tests:**
```dart
// E2E Test
await tester.enterText(
  find.byKey(const Key('add_recipe_name_field')),
  'Test Recipe Name'
);

// Widget Test
final nameField = find.byKey(const Key('add_recipe_name_field'));
expect(nameField, findsOneWidget);

// Verify field content
final textField = tester.widget<TextFormField>(nameField);
expect(textField.controller?.text, equals('Test Recipe Name'));
```

#### When to Use Keys

**Always use keys for:**
- ✅ All form input fields (TextFormField, DropdownButtonFormField, etc.)
- ✅ Interactive buttons in forms (save, cancel, add, remove)
- ✅ Dynamic form sections that can be added/removed
- ✅ Fields that will be tested in E2E or widget tests

**Optional for:**
- ⚪ Static display widgets (Text, Icon)
- ⚪ Simple layout widgets (Row, Column, Container)
- ⚪ Navigation elements already identified by other means

#### Adoption Strategy

**Current Standard (v0.1.1+):**
- All new forms and fields MUST include keys
- All major existing forms have been updated with keys
- Code reviews verify key presence and naming convention compliance
- Follow snake_case naming convention: `{screen}_{field}_field`

**Completed Migration (v0.1.1):**
- ✅ Added keys to all major form screens and dialogs
- ✅ Updated E2E tests to use key-based selectors
- ✅ Added semantic keys to navigation elements
- ✅ Documented best practices and naming conventions

**Migration Checklist per Form:**
- [x] Add keys to all TextFormField widgets
- [x] Add keys to all DropdownButtonFormField widgets
- [x] Add keys to save/submit buttons
- [x] Add keys to any dynamic field collections
- [x] Update associated tests to use keys instead of indices
- [x] Document any non-standard key patterns

#### Current Status

**Forms with Keys:** Implemented across major forms (as of v0.1.1 - 2025-11-28)

**Forms with form field keys:**
- `lib/screens/add_recipe_screen.dart`
- `lib/screens/edit_recipe_screen.dart`
- `lib/widgets/add_new_ingredient_dialog.dart`
- `lib/widgets/add_ingredient_dialog.dart`
- `lib/widgets/edit_meal_plan_item_dialog.dart`
- `lib/widgets/meal_recording_dialog.dart`
- `lib/widgets/edit_meal_recording_dialog.dart`
- Bottom navigation tabs with semantic keys

**Testing Impact:**
- E2E tests now use key-based field access for reliable test execution
- Tests are robust to form layout changes
- Improved test maintainability and debugging capabilities
- Enhanced accessibility support

## Development Tools & Utilities

### Bulk Recipe Update Screen (Temporary)
A development utility screen located at `lib/screens/bulk_recipe_update_screen.dart` for bulk ingredient updates. This is a temporary tool that will eventually be deleted, but contains reusable parsing logic.

**Current Status:** ~1,400 lines mixing UI, parsing, matching, and database operations

**Planned Refactoring:** Extract reusable components while keeping temporary screen functional

### Planned Component Extraction

#### Phase 1: IngredientParserService (Priority: High)
**Goal:** Create production-ready parsing infrastructure

**New Service:** `lib/core/services/ingredient_parser_service.dart`
- Parse raw ingredient strings into structured data
- Context-aware parsing (handle "de" in Portuguese)
- Use MeasurementUnit model instead of hardcoded mappings
- Integration with IngredientMatchingService

**API Design:**
```dart
class IngredientParserService {
  void initialize(AppLocalizations localizations);
  ParsedIngredientResult parseIngredientLine(String line);
  (MeasurementUnit?, String) matchUnitAtStart(String text);
}

class ParsedIngredientResult {
  final double quantity;
  final MeasurementUnit? unit;
  final String name;
  final String? notes;
  final List<IngredientMatch> matches;
  final IngredientMatch? selectedMatch;
}
```

**Benefits:**
- Reusable in Add/Edit Recipe screens
- Unit testable independently
- Single source of truth for parsing rules
- Eliminates hardcoded unit mappings

#### Phase 2: ParsedIngredientRow Widget (Priority: Medium)
**Goal:** Create reusable UI component with proper lifecycle

**New Widget:** `lib/widgets/parsed_ingredient_row.dart`
- Display and edit single parsed ingredient
- Proper StatefulWidget with TextEditingController lifecycle
- Fixes cursor jumping issues
- Match selection and ingredient creation triggers

**Benefits:**
- Fixes TextEditingController anti-pattern
- Fixes cursor jumping bugs
- Reusable across ingredient editing features
- Easier to test

#### Phase 3: Bug Fixes (Priority: As Needed)
**Temporary Screen Improvements:**
- Fix overflow issues at lines 1460 and 1632
- Add "Create New" option for low confidence matches
- Implement full replace strategy on re-parse
- Keep screen functional without over-engineering

### Components to Keep in Temporary Screen
These are specific to bulk update workflow and won't be extracted:
- Recipe selection UI
- Recipe metadata display (collapsible preview)
- Existing ingredients display
- Navigation controls (Previous/Next)
- Session tracking for bulk updates

### Refactoring Strategy
**Philosophy:** Extract what will be reused, fix what's broken, keep temporary code "good enough"

**Implementation Order:**
1. Extract IngredientParserService (reusable, production-ready)
2. Extract ParsedIngredientRow widget (optional, fixes bugs)
3. Fix remaining screen-specific bugs (quick wins)

**Success Metrics:**
- IngredientParserService ready for production use
- Parsing uses MeasurementUnit model (not hardcoded)
- Context-aware parsing works correctly
- Temporary screen reduced to <900 lines
- Clear path to delete screen later without losing valuable code

**Future Usage:**
```dart
// In Add/Edit Recipe screens:
final parserService = IngredientParserService(
  matchingService: matchingService,
);
parserService.initialize(localizations);

final result = parserService.parseIngredientLine(userInput);

// Use with extracted widget
ParsedIngredientRow(
  ingredient: result.toParsedIngredient(),
  onUpdate: (index, {...}) => handleUpdate(),
  onRemove: () => handleRemove(),
  onCreateNew: () => showCreateDialog(),
)
```

The application follows clean architecture principles with clear separation between data models, business logic, and presentation layers, making it extensible for future feature additions.

