# Gastrobrain Codebase Overview - June 2025

## Project Context
Gastrobrain is a meal planning and recipe management application built with Flutter. It helps users organize their cooking with features for recipe management, meal planning, and tracking cooking history. The system includes an intelligent recommendation engine that suggests recipes based on factors like cooking frequency, protein rotation, and user preferences.

## Architectural Overview

### Dependency Injection System
The application uses a clean dependency injection pattern:
- **ServiceProvider**: Central hub for accessing all application services
- **DatabaseProvider**: Singleton pattern for database access with testing support
- **RecommendationProvider**: Singleton for recommendation services

### Core Services Architecture
- **DatabaseHelper**: Comprehensive SQLite-based data access layer
- **RecommendationService**: Orchestrates intelligent recipe recommendations
- **SnackbarService**: Centralized user notification system
- **EntityValidator**: Validates data models and business rules

## Data Models

### Recipe Management
- **Recipe**: Core recipe entity with name, frequency preference, difficulty rating (1-5), cooking times, user ratings, and category classification
- **RecipeCategory**: Enum supporting 12 categories (main dishes, side dishes, sandwiches, complete meals, breakfast items, desserts, soups/stews, salads, sauces, dips, snacks, uncategorized)
- **Ingredient**: Categorized ingredients with 10 distinct types, optional units, and protein type classifications
- **RecipeIngredient**: Junction model linking recipes to ingredients with quantities, notes, and unit overrides

### Multi-Recipe Meal System
- **MealPlan**: Weekly meal plans starting on Friday with comprehensive meal item management
- **MealPlanItem**: Individual meal slots (lunch/dinner) within a plan
- **MealPlanItemRecipe**: Junction table connecting meal plan items to multiple recipes (supports complex meals with main dish + side dishes)
- **Meal**: Tracks actual cooking instances with detailed metrics (servings, actual times, success ratings, modification timestamps)
- **MealRecipe**: Junction table for meals with multiple recipes, supporting primary dish designation

### Recommendation System
- **RecipeRecommendation**: Recipe scoring container with factor breakdown and user response tracking
- **RecommendationResults**: Complete recommendation query results with metadata and serialization support
- **RecommendationFactor**: Abstract base class for pluggable scoring algorithms

### Supporting Models
- **ProteinType**: Enum distinguishing main proteins (beef, chicken, pork, fish, seafood) from special categories (charcuterie, offal, plant-based, other)
- **FrequencyType**: Cooking frequency preferences (daily, weekly, biweekly, monthly, bimonthly, rarely)
- **UserResponse**: Tracking user reactions to recommendations (accepted, rejected, saved, ignored)

## Services & Core Logic

### Database Management
- **DatabaseHelper**: Comprehensive SQLite implementation with:
  - Advanced CRUD operations with transaction support
  - Complex relationship queries optimized for performance
  - Migration system supporting schema evolution
  - Junction table architecture for flexible relationships
  - Recommendation history persistence with serialization

### Recommendation Engine
- **RecommendationService**: Intelligent recommendation orchestration with:
  - **Pluggable Factor System**: 6 configurable scoring factors
  - **Temporal Adaptation**: Automatic weekday/weekend profile switching
  - **Context-Aware Filtering**: Protein avoidance, difficulty constraints, meal type differentiation
  - **Performance Optimization**: Caching and bulk query strategies

#### Scoring Factors (Weighted Algorithm)
1. **FrequencyFactor** (35%): Prioritizes recipes based on desired cooking frequency and last cooked date
2. **ProteinRotationFactor** (30%): Encourages protein variety with graduated penalties for recent usage
3. **RatingFactor** (10%): Considers user ratings with neutral scoring for unrated recipes
4. **VarietyEncouragementFactor** (10%): Promotes less-frequently cooked recipes
5. **DifficultyFactor** (10%): Adapts complexity preferences based on weekday/weekend context
6. **RandomizationFactor** (5%): Adds controlled variety to prevent identical recommendations

### Advanced Features
- **Temporal Context**: Automatic weekday (simplicity-focused) vs weekend (complexity-allowing) recommendation profiles
- **Slot-Specific Recommendations**: Context-aware suggestions considering day of week, meal type, and current meal plan
- **Recommendation History**: Complete serialization and persistence of recommendation results with user response tracking
- **Multi-Recipe Support**: Complex meal planning with primary dishes and multiple side dishes

## User Interface Architecture

### Navigation & Layout
- **HomePage**: Tabbed navigation hub (Recipes, Weekly Plan, Ingredients)
- **Responsive Design**: Adaptive layouts for phone, tablet, and landscape orientations
- **RecipeCard**: Expandable cards with comprehensive recipe information and quick actions

### Recipe Management
- **AddRecipeScreen**: Complete recipe creation with ingredient management and category selection
- **EditRecipeScreen**: Full recipe modification capabilities
- **RecipeIngredientsScreen**: Detailed ingredient view with inline editing
- **MealHistoryScreen**: Comprehensive cooking history with multi-recipe meal tracking

### Advanced Meal Planning
- **WeeklyPlanScreen**: Friday-to-Thursday week view with intelligent recommendation integration
- **WeeklyCalendarWidget**: Responsive calendar supporting multiple layouts:
  - **Phone**: Vertical day-by-day layout
  - **Tablet**: Side-by-side day selector with detailed meal view
  - **Landscape**: Compact grid layout for smaller devices

### Multi-Recipe Interface
- **Recipe Selection Dialog**: Three-stage selection flow:
  1. **Recipe Selection**: Choose from "Try This" (recommendations) or "All Recipes" tabs
  2. **Menu Options**: Save single recipe or add side dishes
  3. **Multi-Recipe Mode**: Add/remove side dishes with primary dish designation
- **Visual Indicators**: Clear differentiation between main dishes and side dishes throughout the interface

### Recommendation UI
- **RecipeSelectionCard**: Visual recommendation cards with:
  - **Factor Scoring Badges**: Timing/Variety, Quality, Effort indicators
  - **Smart Tooltips**: Detailed explanations of recommendation reasoning
  - **Color-coded Feedback**: Intuitive visual scoring system
- **Recommendation Integration**: Seamless integration throughout meal planning workflow

### Dialog Systems
- **MealRecordingDialog**: Multi-recipe meal tracking with side dish management
- **EditMealRecordingDialog**: Complete meal modification capabilities
- **AddIngredientDialog**: Advanced ingredient addition with custom ingredient support
- **AddNewIngredientDialog**: Comprehensive ingredient creation

## Key Features

### Recipe Management
- **Comprehensive CRUD**: Create, edit, delete recipes with full category classification
- **Advanced Ingredient System**: 10 categories with protein type specifications
- **Multi-Metric Tracking**: Difficulty, cooking times, personal ratings, cooking frequency
- **Detailed History**: Complete cooking history with actual vs. expected time tracking

### Multi-Recipe Meal Planning & Tracking
- **Complex Meal Planning**: Plan meals with main dishes and multiple side dishes
- **Three-Stage Selection**: Intuitive recipe selection flow with optional complexity
- **Visual Planning**: Calendar displays primary recipe with "+X more" indicators
- **Flexible Management**: Add, remove, or modify recipes in planned meals
- **Category-Aware Planning**: Leverages recipe categories for optimal meal composition

### Intelligent Recommendation System
The recommendation engine provides context-aware recipe suggestions through:

#### Multi-Factor Scoring
- **Frequency Analysis**: Prioritizes recipes due to be cooked based on user-defined frequencies
- **Protein Rotation**: Encourages dietary variety by tracking and rotating protein types
- **Quality Preference**: Incorporates user ratings to suggest preferred recipes
- **Variety Encouragement**: Prevents cooking monotony by promoting less-used recipes
- **Difficulty Adaptation**: Adjusts complexity based on weekday (simple) vs weekend (complex) contexts
- **Controlled Randomization**: Maintains recommendation freshness while ensuring consistency

#### Temporal Intelligence
- **Weekday Profiles**: Favor simpler, quicker recipes (higher difficulty factor weight: 20%)
- **Weekend Profiles**: Allow complexity and experimentation (higher rating/variety weights)
- **Day-Specific Context**: Considers day of week for appropriate meal suggestions

#### Advanced Filtering
- **Protein Avoidance**: Analyzes current meal plan to avoid recently used protein types
- **Context-Aware Exclusions**: Filters based on meal type, difficulty constraints, and frequency preferences
- **Slot-Specific Recommendations**: Generates suggestions tailored to specific meal plan slots

### Performance Optimizations
- **Recommendation Caching**: Intelligent caching with context-aware invalidation
- **Bulk Data Operations**: Optimized database queries to minimize load
- **Responsive UI**: Maintains fluidity even with large recipe collections
- **Smart Prefetching**: Recipe details loaded proactively for improved UX

### Testing Infrastructure
- **Comprehensive Test Coverage**: Unit, widget, and integration tests across all major components
- **Mock Database Framework**: Isolated testing environment with realistic data simulation
- **Recommendation Testing**: Specialized tests for algorithm correctness and factor interactions
- **UI Testing**: Widget tests for responsive layouts and user interactions

## Architecture Patterns

### Clean Architecture Implementation
- **Data Layer**: SQLite database with comprehensive model definitions
- **Business Logic Layer**: Services with clear separation of concerns
- **Presentation Layer**: Responsive UI components with proper state management

### Junction Table Architecture
The multi-recipe functionality leverages a sophisticated junction table system:
- **Planning Phase**: `MealPlanItemRecipe` connects meal plan items to multiple recipes
- **Cooking Phase**: `MealRecipe` connects actual meals to multiple recipes
- **Primary Dish Support**: Both junction tables support `isPrimaryDish` flags
- **Backward Compatibility**: Maintains support for single-recipe meals while enabling complex multi-recipe functionality

### Recommendation System Architecture
- **Pluggable Factors**: Modular scoring components that can be added, removed, or reweighted
- **Context-Driven**: Recommendations adapt based on temporal context, meal type, and current meal plan
- **Extensible Design**: Clear interfaces for adding new recommendation factors
- **Performance-Focused**: Caching and optimization strategies for responsive user experience

### Testing Strategy
- **Layered Testing**: Unit tests for business logic, widget tests for UI, integration tests for workflows
- **Mock Infrastructure**: Comprehensive mocking system for isolated component testing
- **Factor Testing**: Specialized tests ensuring recommendation algorithm correctness
- **Responsive Testing**: UI tests across different screen sizes and orientations

## Performance Characteristics

### Database Optimization
- **Efficient Queries**: Optimized joins and indexed lookups for complex relationships
- **Bulk Operations**: Batch processing for improved performance with large datasets
- **Connection Pooling**: Proper database connection management
- **Migration Support**: Schema evolution without data loss

### UI Performance
- **Responsive Design**: Adaptive layouts that scale from phone to tablet
- **Efficient Rendering**: Optimized list views and card components
- **Smart Caching**: Recipe and recommendation caching for improved responsiveness
- **Lazy Loading**: Progressive data loading for better initial app startup

### Recommendation Performance
- **Algorithmic Efficiency**: Optimized scoring calculations with minimal database queries
- **Context Caching**: Intelligent caching of recommendation contexts
- **Bulk Processing**: Efficient evaluation of large recipe collections
- **Cache Invalidation**: Smart cache management based on meal plan changes

## Version Information
**Current Version**: v0.0.2 (Development)
**Status**: Active Development with Recommendation System Integration
**Architecture Maturity**: Production-ready foundation with advanced feature implementation

**Key Achievements in June 2025**:
- Complete recommendation system integration with weekly planning
- Multi-recipe meal planning and tracking capabilities
- Advanced UI components with visual recommendation feedback
- Comprehensive testing framework covering all major functionality
- Performance optimizations for responsive user experience

## Summary

The Gastrobrain codebase has evolved into a mature, well-architected meal planning solution with sophisticated recommendation capabilities, comprehensive multi-recipe support, and a responsive, intuitive user interface. The June 2025 architecture represents a significant advancement from the foundational work established in earlier versions, with particular emphasis on:

### Architectural Sophistication
- **Clean dependency injection** with service provider pattern
- **Junction table architecture** enabling complex meal relationships
- **Pluggable recommendation system** with configurable factors
- **Comprehensive testing framework** ensuring reliability

### User Experience Excellence
- **Responsive design** adapting to phone, tablet, and landscape orientations
- **Intelligent recommendations** with visual feedback and explanations
- **Multi-recipe meal planning** with intuitive three-stage selection
- **Context-aware suggestions** considering temporal and meal type factors

### Technical Excellence
- **Performance optimizations** including caching and bulk operations
- **Advanced data modeling** supporting complex relationships
- **Comprehensive error handling** with custom exception hierarchy
- **Extensible architecture** supporting future feature additions

The current implementation balances feature richness with maintainability, providing a solid foundation for continued development while delivering a sophisticated user experience for meal planning and recipe management.