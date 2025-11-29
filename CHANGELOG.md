# Changelog

All notable changes to Gastrobrain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-11

### Added

#### Intelligent Recommendation Engine
- Multi-factor scoring system with 6 pluggable factors (frequency, protein rotation, rating, variety, difficulty, randomization)
- Temporal context awareness with weekday/weekend weight profiles
- Protein rotation system with graduated penalties to encourage dietary variety
- Meal plan integration - recommendations consider both planned and cooked meals
- Context-aware meal plan analysis service

#### Recipe & Ingredient Management
- Comprehensive recipe library with difficulty ratings, cook times, and serving sizes
- Multi-ingredient support for complex recipes with multiple protein sources
- Protein type tracking system with 10 protein types
- Ingredient database with categorization and localized names
- Custom ingredient support for items not in the database
- Bulk recipe entry tools for efficient data management

#### Meal Planning & History
- Weekly meal planning with date and meal type support
- Multi-recipe meal support (main dishes + side dishes)
- Cooking session tracking with notes and timestamps
- Meal history analytics tracking patterns and frequency
- Retroactive meal planning capability

#### Internationalization
- Complete bilingual support (English and Portuguese)
- ARB-based localization system
- Ingredient translation system with 200+ ingredients
- Localized categories and measurement units with enum-based system

#### Data Management
- Versioned database migration system with automatic schema evolution
- Recipe and ingredient data export in JSON format
- Data validation tools and scripts
- SQLite-based storage for easy backup and portability

#### UI/UX Improvements
- Refined add ingredient dialog with unified search and autocomplete
- Progressive disclosure for custom ingredients
- Responsive design with proper overflow handling
- Smart decimal formatting for quantities
- Consistent filtering and ordering UI patterns

### Changed

#### Architecture
- Implemented dependency injection with ServiceProvider pattern
- Established clean architecture with clear separation of concerns
- Added custom exception hierarchy for better error handling
- Integrated Provider pattern for state management

#### Testing Infrastructure
- Comprehensive test suite with 55+ unit/widget tests and 4 integration tests
- MockDatabaseHelper implementation for isolated testing
- CI/CD pipeline with GitHub Actions
- Parallel test execution support

### Documentation

- Added `RECOMMENDATION_ENGINE.md` - Complete recommendation system guide
- Added `ISSUE_WORKFLOW.md` - Git Flow and development practices
- Added `L10N_PROTOCOL.md` - Localization guidelines
- Added `Gastrobrain-Codebase-Overview.md` - Architecture overview
- Added `CHANGELOG.md` - Release notes and version history
- Updated `README.md` - Comprehensive v0.1.0 feature overview
- Updated `CLAUDE.md` - Project instructions for development

---

## [0.1.1] - 2025-11-28

### Added

#### Testing Infrastructure
- End-to-end testing framework with helper methods and best practices guide (#36)
- Comprehensive meal planning UI interaction tests (#220)
- Integration tests for full meal recording workflow (#78)
- Widget tests for CookMealScreen (#75)
- Unit tests for Meal and MealRecipe models with comprehensive edge cases (#74)
- Form field keys across all forms for improved testability and debugging (#219)
- Semantic keys to bottom navigation for maintainable E2E tests

#### Features
- Recipe name search/filter in Recipes tab (#212)
- Proper date localization in formatting methods with locale-aware display (#146)

### Changed

#### UI/UX Improvements
- Improved meal history screen layout and information density (#222)
  - Display recipe name clearly in app bar title
  - Removed redundant recipe names from meal cards
  - Shortened time display labels for better space efficiency
  - Enhanced layout for narrow mobile screens
- Sorted available recipes by name in meal recording dialogs
- Enhanced AddSideDishDialog layout with scrollable sections


### Fixed
- Show recipe names in meal cards when used as side dish (#222)
- Display side dish count instead of total recipe count (#222)
- Handle missing keystore properties gracefully in build.gradle.kts
- Update cook_meal_screen tests for locale-aware date formatting (#146)


### Documentation
- Added comprehensive E2E testing best practices guide
- Added development standards for form field keys

---

## [Unreleased]

---

**Note**: For detailed commit history, see the Git log. For development workflow and branching strategy, see `docs/ISSUE_WORKFLOW.md`.
