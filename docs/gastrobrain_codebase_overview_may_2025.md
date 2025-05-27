# Gastrobrain Codebase Overview - May 2025

## Project Context
Gastrobrain is a meal planning and recipe management application built with Flutter. It helps users organize their cooking with features for recipe management, meal planning, and tracking cooking history. The system includes an intelligent recommendation engine that suggests recipes based on factors like cooking frequency, protein rotation, and user preferences.

## Core Data Models

### Recipe Management
- **Recipe**: Stores recipe details including name, frequency preference, notes, difficulty rating (1-5), cooking times, user ratings, and category
- **Ingredient**: Represents ingredients with categories (10 distinct types), optional units, and protein types
- **RecipeIngredient**: Links recipes to ingredients with quantities, notes, and optional unit overrides

### Meal Planning & Tracking
- **MealPlan**: Manages weekly meal plans (starting on Friday) with notes and timestamps
- **MealPlanItem**: Individual meal slots (lunch/dinner) within a plan
- **MealPlanItemRecipe**: Junction table connecting meal plan items to recipes (supports multiple recipes per meal)
- **Meal**: Tracks actual cooking instances with servings, actual times, and success ratings  
- **MealRecipe**: Junction table for meals with multiple recipes (main dish + side dishes)

### Recommendation System
- **RecipeRecommendation**: Handles recipe scoring and user responses to recommendations
- **RecommendationResults**: Container for recommendation queries with metadata and timestamps
- **RecommendationFactor**: Abstract class for implementing scoring algorithms

### Supporting Models
- **ProteinType**: Enum for different protein types (beef, chicken, fish, etc.)
- **FrequencyType**: Enum for desired cooking frequencies (daily, weekly, monthly, etc.)
- **UserResponse**: Enum for tracking user responses to recommendations (accepted, rejected, saved, ignored)
- **RecipeCategory**: Enum for recipe categories (main dishes, side dishes, desserts, etc.)

## Services & Core Logic

### Database Management
- **DatabaseHelper**: SQLite-based data access layer with CRUD operations, migrations, and complex queries
- **DatabaseProvider**: Singleton pattern for database access
- **IdGenerator**: UUID generation utility

### Recommendation System
- **RecommendationService**: Core service that orchestrates the recommendation process
- **RecommendationDatabaseQueries**: Specialized queries for the recommendation engine
- **RecommendationServiceExtension**: Extension methods for DatabaseHelper
- **Scoring Factors**:
  - **FrequencyFactor** (35%): Prioritizes recipes based on desired frequency
  - **ProteinRotationFactor** (30%): Encourages protein variety
  - **RatingFactor** (10%): Considers user ratings
  - **VarietyEncouragementFactor** (10%): Promotes less-cooked recipes
  - **DifficultyFactor** (10%): Favors simpler recipes for weekdays
  - **RandomizationFactor** (5%): Adds variety to recommendations

### Dependency Injection
- **ServiceProvider**: Central access point for services
- **DatabaseProvider**: Singleton for database access
- **RecommendationProvider**: Singleton for recommendation services

### Utility Services
- **SnackbarService**: Handles user notifications
- **EntityValidator**: Validates data models and business rules
- **GastrobrainException**: Custom exception hierarchy

## User Interface

### Main Navigation
- **HomePage**: Navigation hub with tabs for Recipes and Weekly Plan
- **RecipeCard**: Expandable recipe cards with quick actions and statistics

### Recipe Management
- **AddRecipeScreen**: Recipe creation with ingredient management and category selection
- **EditRecipeScreen**: Recipe modification
- **RecipeIngredientsScreen**: Detailed ingredient view with editing capabilities
- **MealHistoryScreen**: Tracks cooking history for each recipe

### Meal Planning
- **WeeklyPlanScreen**: Week view (Friday-Thursday) with meal slot management
- **WeeklyCalendarWidget**: Responsive calendar with multiple layouts (phone/tablet)
- **MealRecordingDialog**: Records cooking details when marking meals as cooked
- **RecipeRecommendationCard**: Displays score-based recipe recommendations with visual indicators

### Multi-Recipe Management
- **Recipe Selection Dialog**: Enhanced dialog supporting multi-recipe meal planning
  - Three-stage flow: Recipe Selection → Menu → Multi-Recipe Mode
  - Primary recipe selection with optional side dish addition
  - Pre-population for editing existing multi-recipe meals
- **Multi-Recipe Display**: Calendar shows primary recipe name with "+X more" badges

### Dialogs & Components
- **AddIngredientDialog**: Ingredient addition with custom/database options
- **AddNewIngredientDialog**: New ingredient creation
- **RecipeSelectionDialog**: Multi-stage dialog for recipe selection and multi-recipe planning

## Key Features

### Recipe Management
- Create, edit, and delete recipes with category classification
- Manage ingredients with categories and protein types
- Track difficulty, cooking times, and personal ratings
- Maintain cooking history with actual vs. expected times

### Multi-Recipe Meal Planning
- **Primary + Side Dishes**: Plan meals with main dish and multiple side dishes
- **Three-Stage Selection**: Choose main recipe → decide to add sides → select additional recipes
- **Visual Planning**: Calendar displays primary recipe with "+X more" indicator for multi-recipe meals
- **Flexible Management**: Add, remove, or modify recipes in planned meals
- **Category-Aware**: Leverages recipe categories for better meal composition

### Multi-Recipe Meal Tracking
- **Complex Meal Recording**: Record meals with multiple recipes (main + sides)
- **Post-Cooking Management**: Add side dishes to already cooked meals
- **Junction Table Architecture**: Supports flexible meal-recipe relationships
- **Primary Dish Designation**: Distinguishes between main dishes and side dishes

### Recommendation System
- Intelligent recommendation algorithm that considers multiple factors:
  - Frequency-based recommendations that prioritize recipes due to be cooked
  - Protein rotation to encourage variety in meal proteins
  - Difficulty-adjusted for weekday vs. weekend cooking
  - Rating-based sorting for quality preferences
  - Variety encouragement to prevent monotony
  - Randomization factor to keep suggestions fresh
- Visual indicators showing recommendation strength and reasoning
- Adaptive profiles for weekday/weekend cooking
- Context-aware recommendations that consider already planned meals

### Performance Optimizations
- Caching for recommendation results
- Optimized database queries to minimize load
- Bulk data fetching for recommendation context
- Responsive UI even with large recipe collections

### Testing Framework
- Comprehensive unit tests for models and services
- Widget tests for UI components
- Integration tests for recommendation system and multi-recipe functionality
- Mock database for isolated testing

## Architecture Overview

The application follows clean architecture principles with clear separation between:
- **Data Layer**: SQLite database, models, and data access
- **Business Logic**: Services and validators
- **Presentation Layer**: Screens and widgets

Dependency injection is used throughout the app to support testability and maintainability.

The recommendation system follows a pluggable architecture where scoring factors can be:
- Added or removed at runtime
- Weighted differently for various contexts (weekday/weekend)
- Extended with new factors through a consistent interface

### Multi-Recipe Architecture
The multi-recipe functionality is built on a junction table architecture:
- **Planning Phase**: `MealPlanItemRecipe` junction table connects meal plan items to multiple recipes
- **Cooking Phase**: `MealRecipe` junction table connects actual meals to multiple recipes
- **Primary Dish Support**: Both junction tables support `isPrimaryDish` flag for main/side distinction
- **Backward Compatibility**: Maintains support for single-recipe meals while enabling multi-recipe complexity

Performance optimizations include caching recommendations, bulk data fetching, and efficient database queries to support large recipe collections without compromising UI responsiveness. The multi-recipe UI provides intuitive three-stage selection flows and clear visual indicators for complex meals.