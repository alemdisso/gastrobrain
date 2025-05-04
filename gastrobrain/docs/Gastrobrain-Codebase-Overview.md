Here's the content for your project documentation:

# Gastrobrain Codebase Overview

## Project Context
Gastrobrain is a meal planning and recipe management application built with Flutter. It helps users organize their cooking with features for recipe management, meal planning, and tracking cooking history.

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
- **IdGenerator**: UUID generation utility

### Recommendation System
- **RecommendationService**: Core service with pluggable scoring factors
- **Scoring Factors**:
  - FrequencyFactor (35%): Prioritizes recipes based on desired frequency
  - ProteinRotationFactor (30%): Encourages protein variety
  - RatingFactor (10%): Considers user ratings
  - VarietyEncouragementFactor (10%): Promotes less-cooked recipes
  - DifficultyFactor (10%): Favors simpler recipes for weekdays
  - RandomizationFactor (5%): Adds variety to recommendations
- **DatabaseQueries**: Optimized queries for recommendation data fetching

### Utility Services
- **ServiceProvider**: Central access point for services
- **SnackbarService**: Handles user notifications
- **EntityValidator**: Validates data models and business rules
- **GastrobrainException**: Custom exception hierarchy

## User Interface

### Main Navigation
- **HomePage**: Navigation hub with tabs for Recipes and Weekly Plan
- **RecipeCard**: Expandable recipe cards with quick actions and statistics

### Recipe Management
- **AddRecipeScreen**: Recipe creation with ingredient management
- **EditRecipeScreen**: Recipe modification
- **RecipeIngredientsScreen**: Detailed ingredient view with editing capabilities
- **MealHistoryScreen**: Tracks cooking history for each recipe

### Meal Planning
- **WeeklyPlanScreen**: Week view (Friday-Thursday) with meal slot management
- **WeeklyCalendarWidget**: Responsive calendar with multiple layouts (phone/tablet)
- **MealRecordingDialog**: Records cooking details when marking meals as cooked

### Dialogs & Components
- **AddIngredientDialog**: Ingredient addition with custom/database options
- **AddNewIngredientDialog**: New ingredient creation
- **MealRecordingDialog**: Comprehensive meal tracking with multiple recipe support

## Key Features

### Recipe Management
- Create, edit, and delete recipes
- Manage ingredients with categories and protein types
- Track difficulty, cooking times, and personal ratings
- Maintain cooking history with actual vs. expected times

### Meal Planning
- Weekly view starting on Friday
- Lunch and dinner slots for each day
- Recipe recommendations based on intelligent algorithms
- Mark meals as cooked with detailed tracking
- Supports multiple recipes per meal (main dish + sides)

### Recommendation System
- Context-aware recipe suggestions
- Considers protein rotation, cooking frequency, and weekday vs. weekend
- User response tracking for continuous improvement
- Performance-optimized with caching

### Data Management
- Local SQLite storage
- Database versioning and migrations
- JSON import/export capabilities
- Comprehensive entity validation

The application follows clean architecture principles with clear separation between data models, business logic, and presentation layers, making it extensible for future feature additions.

