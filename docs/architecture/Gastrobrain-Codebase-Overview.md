<!-- markdownlint-disable -->
# Gastrobrain Codebase Overview

## Project Context
Gastrobrain is a comprehensive meal planning and recipe management application built with Flutter. It provides intelligent recipe recommendations, multi-language support (English/Portuguese), and sophisticated meal planning features with multi-recipe meal support. The application uses local SQLite storage and features a pluggable recommendation engine with temporal intelligence.

## Core Data Models

### Recipe Management
- **Recipe**: Stores recipe details including name, frequency preference, notes, difficulty rating (1-5), cooking times, and user ratings
- **Ingredient**: Represents ingredients with categories, optional units, and protein types
- **RecipeIngredient**: Links recipes to ingredients with quantities, notes, and optional unit overrides

### Tagging System
- **TagType**: Taxonomy categories for tags (e.g., cuisine, dietary restriction, occasion)
- **Tag**: Individual tags linked to a TagType; applied to recipes for filtering and discovery

### Meal Planning & Tracking
- **MealPlan**: Manages weekly meal plans (starting on Friday) with notes and timestamps
- **MealPlanItem**: Individual meal slots (lunch/dinner) within a plan
- **MealPlanItemRecipe**: Junction table connecting meal plan items to recipes (supports multiple recipes per meal)
- **MealPlanItemIngredient**: Ingredient overrides at the meal plan item level
- **Meal**: Tracks actual cooking instances with servings, actual times, and success ratings
- **MealRecipe**: Junction table for meals with multiple recipes (main dish + side dishes)
- **MealIngredient**: Ingredient overrides at the cooked meal level

### Shopping
- **ShoppingList**: Persistent shopping list linked to a meal plan
- **ShoppingListItem**: Individual items with category, unit, quantity, and checked state

### Supporting Models
- **ProteinType**: Enum for different protein types (beef, chicken, fish, etc.)
- **FrequencyType**: Enum for desired cooking frequencies (daily, weekly, monthly, etc.)
- **RecipeRecommendation**: Handles recipe scoring and user responses
- **RecommendationResults**: Container for recommendation queries with metadata
- **MealPlanSummary / PlannedMealInfo / RecipeRepetition**: Weekly analytics aggregates
- **IngredientMatch**: Result of the ingredient matching pipeline with confidence score

## Services & Core Logic

### Database Management

#### DAO Layer (Domain-Specific Data Access)
Extracted from `DatabaseHelper` in milestone 0.2.12. Each DAO owns CRUD and query logic for its domain:

- **IngredientDao**: Ingredient CRUD, alias management, recipe-ingredient relationships
- **MealDao**: Meal recording, meal-recipe associations, history queries
- **MealPlanDao**: Meal plan and meal plan item operations, weekly plan queries
- **RecipeDao**: Recipe CRUD, search, filtering, frequency-based ordering
- **RecommendationDao**: Recommendation data access, scoring data queries, user feedback persistence
- **ShoppingListDao**: Shopping list persistence, item toggle tracking, category grouping queries

All DAOs receive a `Future<Database> Function()` factory via constructor injection.

#### Core Database Infrastructure
- **DatabaseHelper**: Orchestrates DAOs; handles migrations, transactions, and cross-domain operations
- **DatabaseProvider**: Singleton pattern for database access throughout the app
- **MigrationRunner**: Database schema migration system with versioned migrations, auto-rollback on failure, and persistent error recording
- **IdGenerator**: UUID generation utility

### Recommendation System
- **RecommendationService**: Core service with pluggable scoring factors and temporal intelligence
- **MealPlanAnalysisService**: Analyzes both planned and recently cooked meals for context-aware recommendations
- **RecommendationCacheService**: Cache layer with context-aware invalidation for recommendation results

**Scoring Factors:**
- **FrequencyFactor** (35%): Prioritizes recipes based on desired frequency
- **ProteinRotationFactor** (30%): Encourages protein variety with graduated penalties
- **RatingFactor** (10%): Considers user ratings
- **VarietyEncouragementFactor** (10%): Promotes less-cooked recipes
- **DifficultyFactor** (10%): Favors simpler recipes for weekdays
- **RecipeProximityFactor**: Proximity-based avoidance — penalizes recently planned/cooked recipes
- **MealRoleFactor**: Considers whether a recipe is typically a main dish or side dish
- **UserFeedbackFactor**: Learns from user responses to recommendations
- **RandomizationFactor** (5%): Adds variety to recommendations

- **DatabaseQueries**: Optimized queries for recommendation data fetching
- **ProteinPenaltyStrategy**: Sophisticated protein rotation with graduated scoring

### Ingredient Management Services
- **IngredientMatchingService**: Multi-stage ingredient matching with confidence scoring
  - 6-stage matching pipeline: exact → case-insensitive → normalized → prefix → fuzzy → translation
  - Plural form singularization for Portuguese and English (23+ irregular plurals)
  - Compound word support (batatas doces → batata doce)
  - Achieves 90%+ confidence for plural-to-singular matches
  - First-letter indexing for performance optimization
- **IngredientParserService**: Parses raw ingredient strings into structured data (quantity, unit, name, notes)
  - Context-aware parsing for Portuguese (handles "de" prepositions, descriptors, implicit units)
  - Uses `MeasurementUnit` model instead of hardcoded mappings
  - Integrates with `IngredientMatchingService` for match suggestions
  - Registered in `ServiceProvider`; reusable in recipe creation and bulk edit flows
- **IngredientExportService**: Exports ingredient data to JSON format
- **IngredientImportService**: Imports ingredients from JSON, with deduplication
- **IngredientTranslationService**: Translates ingredients from English to Portuguese using reviewed CSV data
- **IngredientDuplicateChecker**: Detects and flags duplicate ingredient entries
- **IngredientAggregatorService**: Aggregates ingredients across multiple recipes for shopping lists

### Shopping List & Summary Services
- **ShoppingListService**: Shopping list generation from meal plans with ingredient aggregation, category grouping, and toggle tracking
- **MealPlanSummaryService**: Weekly meal plan analytics (protein distribution, cooking time allocation, variety metrics)
- **MealPlanService**: Meal plan lifecycle management (create, archive, query current plan)
- **MealActionService**: Meal interaction handlers for common meal operations

### Meal Management Services
- **MealEditService**: Centralized meal editing and recording operations
  - `updateMealWithRecipes()`: Updates meal records with new values and recipe associations
  - `recordMealWithRecipes()`: Records new meals with primary and additional recipes
  - Handles atomic operations for meal + recipe association updates

### Recipe Import/Export Services
- **RecipeExportService**: Exports recipes with full ingredient data to JSON
- **RecipeImportService**: Imports recipes from JSON with ingredient matching and deduplication

### Data Safety Services
- **DatabaseBackupService**: Complete database backup and restore using JSON format
  - Creates a single JSON file containing ALL application data (tags, recipes, ingredients, meal plans, meals)
  - Supports share/export via `share_plus`
  - Restore replaces all data atomically

### Tag Services
- **TagDuplicateChecker**: Detects duplicate tags before insertion

### Utility Services
- **UnitConverter**: Smart metric conversion with intelligent rounding for quantity display
- **ServiceProvider**: Central dependency injection hub with provider access
- **SnackbarService**: Handles user notifications and feedback
- **EntityValidator**: Validates data models and business rules
- **LocalizedErrorMessages**: Internationalized error handling
- **GastrobrainException**: Custom exception hierarchy

### Provider Architecture
- **RecipeProvider**: State management for recipe operations
- **MealProvider**: State management for meal tracking
- **MealPlanProvider**: State management for meal planning
- **Repository Pattern**: Base repositories for consistent data access

### Theme & Design System
- **AppTheme**: Comprehensive Material 3 theme configuration (light theme; dark theme foundation)
- **DesignTokens**: Centralized design tokens (colors, typography, spacing, border radii, elevations, shadows)
- **ButtonStyles**: Reusable button styles (primary, secondary, destructive)
- Visual identity: Warm, Confident, Cultured & Flavorful, Clear, Rooted
- Color palette: Amber/paprika primary, emerald/herb green accent
- 8px-based spacing system with 7 levels (XXS to XXL)
- See `docs/design/` for the full design system documentation

## User Interface

### Main Navigation
- **HomeScreen**: Navigation hub with bottom tab bar (Dashboard, Recipes, Meal Plan, Ingredients, Tools)
- **DashboardScreen**: Landing page with hero section, recent meal summary cards, and quick action panel
- **ContentScreen**: Shell that wraps tab content for consistent layout

### Recipe Management
- **RecipesScreen**: Recipe list with search, filter, and tap navigation to details
- **RecipeCard**: Recipe list items with stats (meal count, last cooked, rating) and tap navigation
- **RecipeDetailsScreen**: Unified tabbed view (4 tabs: overview, ingredients, instructions, meal history) with delete functionality
- **RecipeFormScreen**: Unified recipe creation and editing — create mode follows phased progressive-disclosure flow (Phase 1: basics stub → Phase 4: ingredients); edit mode shows three independent ExpansionTile sections (Basics, Ingredients, More details) each with per-section save (#370)
- **RecipeEditorScreen**: Rich ingredient editor screen — used for both bulk update and recipe enrichment flows; componentized in 0.2.12
- **RecipeDetailsIngredientsTab**: Detailed ingredient view with editing capabilities (active; distinct from `RecipeIngredientsScreen` which is dead code)
- **MealHistoryScreen**: Tracks cooking history for each recipe with edit capabilities
- **IngredientsScreen**: Comprehensive ingredient management with search, add, edit, delete
- **IngredientDetailScreen**: Detailed ingredient view

### Meal Planning & Shopping
- **WeeklyPlanScreen**: Week view (Friday-Thursday) with meal slot management, multi-recipe support, recommendation integration, shopping list generation, and weekly summary
- **WeeklyCalendarWidget**: Responsive calendar with multiple layouts (phone/tablet/landscape)
- **WeeklySummaryWidget**: Inline weekly analytics (protein distribution, cooking times, variety)
- **WeekNavigationWidget**: Navigation controls for moving between weeks
- **CookMealScreen**: Dedicated cooking interface with meal type selection and completion tracking
- **ShoppingListScreen**: Shopping list with category grouping, checkbox tracking, "to buy" filter, and "hide to taste" option
- **ShoppingListPreviewScreen**: Preview ingredients before creating a shopping list
- **ShoppingListRefinementScreen**: Curate ingredients (select/deselect) before finalizing a shopping list

### System & Utility Screens
- **ToolsScreen**: Development utilities for database backup/restore, recipe import/export, ingredient export, and bulk recipe update
- **MigrationScreen**: Database migration interface for schema updates
- **MigrationErrorScreen**: Blocking error screen displayed when a fatal migration failure cannot be auto-recovered; prevents app launch with broken state

### Dialogs & Components
- **RecipeSelectionDialog**: Recipe selection with two tabs ("Try This" recommendations + "All Recipes" with search/filter)
- **MealTypeDialog**: Meal type selection (breakfast, brunch, lunch, dinner, snack)
- **AddIngredientDialog**: Ingredient addition with custom/database options
- **AddNewIngredientDialog**: New ingredient creation with category selection
- **UnifiedAddSideDialog**: Unified side dish add flow (replaces legacy AddSideDishDialog)
- **MealRecordingDialog**: Comprehensive meal tracking with multiple recipe support
- **EditMealRecordingDialog**: Edit completed meal records
- **RecipeFilterDialog**: Advanced recipe filtering by tags, protein type, difficulty
- **RecipeSelectionCard**: Card widget for recipe selection flows
- **TagPickerWidget**: Tag selection/management UI component
- **ServingsStepper**: Stepper control for servings quantity input
- **AddShoppingItemDialog**: Manual item addition to a shopping list
- **WeeklyCalendarWidget**: Calendar display for the weekly plan

### Recipe Editor Sub-Widgets (`lib/widgets/recipe_editor/`)
Extracted from `RecipeEditorScreen` in milestone 0.2.12:
- **ExistingIngredientsDisplay**: Shows current recipe ingredients with edit/delete
- **IngredientRow**: Single parsed ingredient row with quantity, unit, name, notes
- **ParsedIngredient**: Ingredient in parsed/matched state with confidence indicator
- **RecipeEnrichmentProgressCard**: Progress tracker for bulk recipe enrichment sessions
- **RecipeMetadataDisplay**: Collapsible recipe header with key metadata

### Dashboard Sub-Widgets (`lib/widgets/dashboard/`)
- **HeroSection**: Top-of-dashboard hero with greeting and current plan status
- **SummaryCards**: Quick-glance metric cards (meals this week, protein balance, etc.)
- **QuickActionsPanel**: Common actions (add meal, view plan, generate shopping list)

## Key Features

### Recipe Management
- Create, edit, and delete recipes with full localization support
- Search and filter recipes by name, tags, protein type, and difficulty
- Manage ingredients with categories, protein types, and measurement units
- Tag system for cuisine, dietary restrictions, and occasions
- Track difficulty, cooking times, and personal ratings
- Maintain cooking history with actual vs. expected times
- Edit and modify historical meal records

### Meal Planning
- Weekly view starting on Friday with responsive layout
- Lunch and dinner slots for each day
- Recipe recommendations based on intelligent algorithms with temporal context
- Meal type selection (breakfast, brunch, lunch, dinner, snack)
- Mark meals as cooked with detailed tracking and multi-recipe support
- Supports multiple recipes per meal (main dish + sides)
- Dedicated cooking interface with progress tracking
- Weekly summary analytics (protein distribution, cooking times, variety metrics)
- Temporal meal status display (planned/cooked/overdue)

### Shopping Lists
- Generate shopping lists from weekly meal plans
- Preview and refine ingredient list before creating (select/deselect items)
- Category-based grouping (Produce, Proteins, Dairy, etc.)
- Checkbox tracking with "to buy" vs completed states
- Filter by "to buy only" and "hide to taste" options
- Manual item addition
- Localized categories and units

### Recommendation System
- Context-aware recipe suggestions with dual-context analysis (planned + cooked)
- Sophisticated protein rotation with graduated penalty scoring
- Proximity-based avoidance for recently planned/cooked recipes
- Meal role awareness (main dish vs side dish suitability)
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

### Data Management & Safety
- Local SQLite storage with migration system and versioned schema history
- **Auto-rollback on migration failure**: `MigrationRunner` records failures persistently and rolls back to the last known good schema version automatically
- **Fatal migration errors** route to `MigrationErrorScreen` — the app never launches with broken state or fails silently
- Database backup and restore via JSON export/import (share via system share sheet)
- JSON import/export for recipes and ingredients
- Ingredient translation system with CSV-based reviewed data
- Comprehensive entity validation with localized error handling

### Development Tools
- Integrated utilities screen (Tools tab)
- Database backup and restore (JSON-based)
- Recipe import/export (JSON format)
- Ingredient export (JSON format)
- Recipe editor with ingredient parsing and fuzzy matching
- Database migration interface with version tracking

## Testing Infrastructure

### Test Coverage Overview
The application maintains comprehensive test coverage with **2047+ unit/widget tests** (including 501+ edge case tests, 229+ dialog/widget tests, 1313+ core/service/model tests) and **73+ end-to-end/integration tests**.

> For up-to-date counts run `bash scripts/count-tests.sh`. See [TEST_GOVERNANCE.md](../testing/TEST_GOVERNANCE.md) for update cadence.

**Test Breakdown:**
- **Edge Case Tests** (Issue #39): 501+ tests across 30 files — empty states, boundary conditions, error scenarios, interaction patterns, data integrity
- **Dialog / Widget Tests**: 229+ tests across 17 files — return values, cancellation, disposal, validation, error handling
- **Core / Service / Model Tests**: 1313+ tests across 87 files — recommendations, database, ingredient matching, meal planning, shopping list
- **Integration / E2E Tests**: 73+ workflow tests across 21 files
- **Regression Tests**: 4 tests preventing recurrence of known bugs

### Unit & Widget Tests (`test/` directory)

#### Core Services Testing
- **Recommendation System Tests** (15+ test files): Individual factor testing, integration testing, filtering, protein rotation, temporal context
- **Database Layer Tests**: `database_helper_*_test.dart` — core operations, model validation, migration system
- **Service Layer Tests**: `meal_plan_analysis_service_test.dart`, `ingredient_export_service_test.dart`, `ingredient_matching_service_test.dart` (91 tests including 28 plural form tests)

#### UI Component Testing
- **Screen Tests** (`test/screens/`): `weekly_plan_screen_test.dart`, `cook_meal_screen_test.dart`, `meal_history_screen_test.dart`, `recipe_form_screen_test.dart`
- **Screen Edge Case Tests** (`test/edge_cases/screens/`): 21 meal history edge case tests, 9 weekly plan edge case tests
- **Dialog Tests** (`test/widgets/`, 100+ tests across 6 dialogs): `meal_cooked_dialog_test.dart`, `add_ingredient_dialog_test.dart`, `meal_recording_dialog_test.dart`, `add_side_dish_dialog_test.dart`, `add_new_ingredient_dialog_test.dart`, `edit_meal_recording_dialog_test.dart`

#### Model & Data Tests
- All core models (Recipe, Meal, MealPlan, Tag, TagType, ShoppingList, etc.)
- Junction table relationships, data serialization, recommendation results

### Integration Tests (`integration_test/` directory)

**Core Workflow Tests:**
- `app_launch_test.dart`, `tab_navigation_test.dart`
- `recipe_creation_test.dart`, `recipe_editing_test.dart`
- `meal_recording_test.dart`, `meal_planning_ui_test.dart`, `weekly_meal_planning_test.dart`

**System Integration Tests:**
- `recommendation_integration_test.dart`
- `meal_plan_analysis_integration_test.dart`

### Testing Architecture & Patterns

#### Mock Framework
- **`MockDatabaseHelper`**: Comprehensive database mocking — 22+ supported methods, custom exceptions, auto-reset after throw
- **Dependency Injection Pattern**: Widgets accept optional `DatabaseHelper` parameters for test injection
- **Error Simulation**: `mockDb.failOnOperation('methodName')` — see `docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md`

#### Testing Utilities
- **`test_utils/test_setup.dart`**: Centralized test configuration
- **`test_utils/test_app_wrapper.dart`**: Widget testing utilities with localization support
- **`test/helpers/dialog_test_helpers.dart`**: 18 helper methods for dialog testing
- **`test/test_utils/dialog_fixtures.dart`**: Standardized test data factories
- **`test/regression/dialog_regression_test.dart`**: Regression tests for known dialog bugs
- **`test/helpers/edge_case_test_helpers.dart`**: Edge case testing utilities
- **`test/fixtures/boundary_fixtures.dart`**: Boundary value fixtures (empty, very long, special chars, SQL injection, etc.)
- **`test/helpers/error_injection_helpers.dart`**: Error simulation for testing

#### Key Testing Principles
- **Test Isolation**: No shared state between tests
- **Mock-First**: All database interactions use mocks in unit/widget tests
- **Real Database Integration**: Integration tests use actual database operations
- **Localization Testing**: All UI tests include proper localization setup
- **One Test at a Time**: Write one test, run it, verify it passes, then write the next

## Development Standards

### Form Field Keys

All form fields must have explicit keys for testability, accessibility, and debugging.

**Pattern:** `{screen}_{field}_field`

```dart
TextFormField(
  key: const Key('add_recipe_name_field'),
  controller: _nameController,
  // ...
)
```

**Always use keys for:**
- All form input fields (TextFormField, DropdownButtonFormField, etc.)
- Interactive buttons in forms (save, cancel, add, remove)
- Dynamic form sections that can be added/removed

### Code Quality Watchdog

A Code Quality Watchdog (defined in `lib/CLAUDE.md` and subdirectory `CLAUDE.md` files) automatically flags threshold violations to `.github/refactoring-backlog.md`:

| Smell | Default Threshold | Severity |
|-------|-------------------|----------|
| File length | > 300 lines | 🟡 High |
| File length | > 500 lines | 🔴 Critical |
| Method length | > 50 lines | 🟡 High |
| Method length | > 100 lines | 🔴 Critical |

Services have stricter thresholds (> 200 lines: High, > 350 lines: Critical). The backlog is reviewed during Sprint Planning as part of the 20% quality allocation.

## Development Tools & Utilities

The application follows clean architecture principles with clear separation between data models, business logic, and presentation layers. The DAO pattern (introduced in 0.2.12) keeps `DatabaseHelper` as an orchestration layer while domain-specific data access logic lives in focused DAO classes, making the codebase extensible and testable.
