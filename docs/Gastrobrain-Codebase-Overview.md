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

### Data Export & Translation Services
- **IngredientExportService**: Exports ingredient data to JSON format
- **RecipeExportService**: Exports recipes with full ingredient data to JSON
- **IngredientTranslationService**: Translates ingredients from English to Portuguese using reviewed translation data

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
The application maintains comprehensive test coverage with **55 unit/widget tests** and **4 integration tests**, ensuring reliability and maintainability across all application layers.

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

#### UI Component Testing
- **Screen Tests** (`test/screens/`):
  - `weekly_plan_screen_test.dart`: Meal planning interface
  - `cook_meal_screen_test.dart`: Cooking workflow
  - `meal_history_screen_test.dart`: Historical meal tracking
  - `add_recipe_screen_test.dart`: Recipe creation flow

- **Widget Tests** (`test/widgets/`):
  - `weekly_calendar_widget_test.dart`: Calendar functionality
  - `recipe_card_test.dart`: Recipe display components
  - `add_ingredient_dialog_test.dart`: Ingredient management
  - `edit_meal_recording_dialog_test.dart`: Meal editing interface

#### Model & Data Tests
- **Model Validation** (`test/models/`):
  - All core models (Recipe, Meal, MealPlan, etc.)
  - Junction table relationships testing
  - Data serialization and validation
  - User response tracking and recommendation results

### Integration Tests (`integration_test/` directory)

#### End-to-End Workflows
- **`meal_planning_flow_test.dart`**: Complete meal planning workflow from start to finish
- **`edit_meal_flow_test.dart`**: Meal modification and tracking workflows
- **`recommendation_integration_test.dart`**: Full recommendation system integration
- **`meal_plan_analysis_integration_test.dart`**: Meal plan analysis system testing

### Testing Architecture & Patterns

#### Mock Framework
- **`MockDatabaseHelper`**: Comprehensive database mocking for isolated testing
- **Dependency Injection Pattern**: Widgets accept optional `DatabaseHelper` parameters for test injection
- **Parallel Test Execution**: Tests run concurrently without database locking issues

#### Testing Utilities
- **`test_utils/test_setup.dart`**: Centralized test configuration and setup
- **`test_utils/test_app_wrapper.dart`**: Widget testing utilities with localization support
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

# Run integration tests
flutter test integration_test/

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

The application follows clean architecture principles with clear separation between data models, business logic, and presentation layers, making it extensible for future feature additions.

