# Gastrobrain

[![codecov](https://codecov.io/gh/alemdisso/gastrobrain/graph/badge.svg)](https://codecov.io/gh/alemdisso/gastrobrain)

A personal cooking companion app that helps you plan, organize, and track your culinary journey with intelligent recommendations and comprehensive meal management.

## About

Gastrobrain is a Flutter-based mobile application designed to assist home cooks in managing their recipes, planning meals, and organizing shopping. It focuses on providing a personal, workbook-like approach to recipe management with sophisticated recommendation algorithms that encourage dietary variety and help maintain cooking routines.

## Features

### Recipe Management

- **Comprehensive Recipe Library** - Store recipes with difficulty ratings, cook times, serving sizes, and categories
- **Recipe Search & Filtering** - Find recipes by name, difficulty, rating, frequency, and category with visual filter indicators
- **Unified Recipe Details** - Tabbed view showing overview, ingredients, instructions, and meal history
- **Multi-Ingredient Support** - Track recipes with multiple protein sources and complex ingredient lists
- **Protein Type Tracking** - Monitor and rotate protein usage for dietary variety
- **Rating System** - Rate recipes from 1-5 stars to improve recommendations
- **Bulk Recipe Update** - Development tool for efficient ingredient parsing and recipe enrichment

### Intelligent Recommendations

- **Smart Recommendation Engine** - Multi-factor scoring system (7 factors) based on:
  - Recipe frequency and due dates
  - Protein rotation (encourages dietary variety)
  - User ratings and preferences
  - Variety encouragement (promotes exploration)
  - Temporal context (weekday/weekend adaptations)
  - User feedback learning (historical success tracking)
  - Controlled randomization for variety
- **Context-Aware Suggestions** - Recommendations adapt to meal type, date, and cooking patterns
- **Protein Rotation System** - Graduated penalties discourage protein repetition

### Meal Planning & History

- **Weekly Meal Planning** - Plan meals with multi-recipe support (main dishes + sides)
- **Meal Type Selection** - Categorize meals as breakfast, brunch, lunch, dinner, or snack
- **Cooking Session Tracking** - Log when recipes are cooked with actual times, servings, and notes
- **Meal Plan Summary** - Weekly analytics with protein distribution, cooking time allocation, and variety metrics
- **Meal History Analytics** - Track cooking patterns, success rates, and frequency with improved UI layout
- **Retroactive Planning** - Plan meals after cooking for accurate history

### Ingredients & Shopping

- **Ingredient Database** - Comprehensive categorization with protein type tracking
- **Shopping List Generation** - Generate shopping lists from weekly meal plans with automatic ingredient aggregation
- **Ingredient Refinement** - Curate ingredients before creating shopping list (select/deselect items)
- **Category Grouping** - Shopping items organized by category (Produce, Proteins, Dairy, etc.)
- **Shopping Progress** - Checkbox tracking with "to buy" filters and "hide to taste" option
- **Localized Units** - Support for metric and customary measurements with fraction display
- **Smart Quantity Display** - Automatic fraction formatting (e.g., 1/2, 1/4, 3/4) for common values
- **Enhanced Parser** - Supports Portuguese measurement units including 'maço' (bunch)
- **Custom Ingredients** - Add custom ingredients when needed
- **Recipe Ingredient Management** - Link ingredients to recipes with quantities and preparation notes

### Localization

- **Bilingual Support** - Full English and Portuguese localization
- **Date & Time Formatting** - Proper locale-aware date and time display
- **Ingredient Translation** - Built-in translation system for ingredient names and categories

### Data Management

- **Database Migrations** - Versioned schema evolution with automatic migrations
- **Complete Backup & Restore** - JSON-based export/import system with data integrity validation
- **Recipe Import Tool** - Restore recipes from bundled or custom backup files
- **Data Export** - Export recipes and ingredients in human-readable JSON format
- **Cross-Platform Compatibility** - File picker integration for Android/iOS backup handling
- **Backup-Friendly** - SQLite database for easy backup and portability

## Getting Started

### Prerequisites

- Flutter SDK (3.x or higher)
- Dart SDK
- SQLite support
- Android Studio or VS Code with Flutter plugins

### Installation

1. Clone the repository

   ```bash
   git clone https://github.com/yourusername/gastrobrain.git
   ```

2. Install dependencies

   ```bash
   cd gastrobrain
   flutter pub get
   ```

3. Generate localizations

   ```bash
   flutter gen-l10n
   ```

4. Run the app

   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run all E2E/integration tests
flutter test integration_test/

# Run specific E2E test
flutter test integration_test/meal_planning_ui_test.dart

# Run with coverage
flutter test --coverage

# Analyze code quality
flutter analyze
```

### Test Coverage

Generate and view coverage reports locally:

```bash
# Generate coverage
flutter test --coverage

# View summary (requires lcov)
lcov --summary coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html  # Linux
```

**Installing lcov:**
```bash
# Ubuntu/Debian/WSL
sudo apt-get install lcov
```

**Current coverage:** [![codecov](https://codecov.io/gh/alemdisso/gastrobrain/graph/badge.svg)](https://codecov.io/gh/alemdisso/gastrobrain)

**Full report:** [Codecov Dashboard](https://codecov.io/gh/alemdisso/gastrobrain)

## Project Structure

```text
lib/
├── core/                  # Core functionality
│   ├── di/               # Dependency injection (ServiceProvider)
│   ├── errors/           # Custom exception hierarchy
│   ├── migration/        # Database migration system
│   ├── providers/        # State management (Provider pattern)
│   ├── repositories/     # Cached data access layer
│   ├── services/         # Business logic services
│   ├── theme/            # Design tokens, app theme, button styles
│   └── validators/       # Entity validation
├── database/             # Database layer (DatabaseHelper)
├── models/               # Data models (21 models)
├── screens/              # UI screens (15 screens)
├── services/             # Additional services (shopping list)
├── widgets/              # Reusable widgets & dialogs (15 widgets)
├── l10n/                 # Localization files (EN/PT, 478+ keys)
└── utils/                # Utility functions

docs/                     # Documentation
├── architecture/         # System architecture & design
├── design/               # Visual identity, design tokens, UX
├── testing/              # Testing guides & resources
├── workflows/            # Development processes
├── planning/             # Milestones, sprints, feature specs
├── issues/               # Issue-level analysis & roadmaps
└── archive/              # Historical documents
```

## Development Status

**Current Version: v0.1.7** - UI Polish & Design System

### Major Achievements

- ✅ Modern architecture with dependency injection (ServiceProvider pattern)
- ✅ Comprehensive testing infrastructure (1670+ tests, Codecov integration)
- ✅ Full bilingual support (English/Portuguese) with 478+ localized strings
- ✅ Advanced recommendation engine with 7 scoring factors and temporal intelligence
- ✅ Database migration system (5 migrations) with backup/restore functionality
- ✅ Shopping list generation from meal plans with ingredient refinement
- ✅ Meal plan summary analytics with protein distribution tracking
- ✅ CI/CD pipeline with GitHub Actions (automated release builds)
- ✅ Multi-ingredient and multi-recipe meal support (main + side dishes)
- ✅ Design token system with Material 3 theme and visual identity
- ✅ Recipe search, filtering (difficulty, rating, frequency, category), and sorting
- ✅ Unified recipe details screen with tabbed view (overview, ingredients, instructions, history)
- ✅ Bulk recipe update tool with ingredient parsing and fuzzy matching
- ✅ Enhanced ingredient parser with Portuguese measurement units and fraction display

### Future Milestones

- **v0.2.0** - Advanced features (enhanced meal planning, analytics)
- **v0.3.0** - Beta-ready phase with multi-user foundations
- **v0.4.0** - Server-client architecture for broader user base
- **v1.0.0** - Community platform with recipe sharing

## Tech Stack

- **Framework**: Flutter/Dart
- **Database**: SQLite with sqflite package
- **State Management**: Provider pattern
- **Architecture**: Clean architecture with dependency injection
- **Testing**: flutter_test, mockito, integration_test
- **Localization**: ARB-based l10n system
- **CI/CD**: GitHub Actions

## Documentation

- [**Documentation Index**](docs/README.md) - Complete documentation index and quick links
- [**Codebase Overview**](docs/architecture/Gastrobrain-Codebase-Overview.md) - Architecture and patterns
- [**Recommendation Engine**](docs/architecture/RECOMMENDATION_ENGINE.md) - Complete guide to the recommendation system
- [**Design System**](docs/design/) - Visual identity, design tokens, theme usage, component patterns
- [**Testing Guides**](docs/testing/) - Dialog testing, edge case testing, and test patterns
- [**Issue Workflow**](docs/workflows/ISSUE_WORKFLOW.md) - Development workflow and Git Flow practices
- [**Release Workflow**](docs/workflows/RELEASE_WORKFLOW.md) - Release process and versioning
- [**L10N Protocol**](docs/workflows/L10N_PROTOCOL.md) - Localization guidelines
- [**Changelog**](CHANGELOG.md) - Release notes and version history

## Contributing

This project is currently in early development and not open for contributions. Stay tuned for updates.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by home cooking experiences during COVID-19 lockdown
- Built with assistance from Anthropic's Claude AI
- Special thanks to all home cooks who inspired this project

## Contact

For questions or feedback, please open an issue in the repository.

---

**Note**: This project is under active development. Features and documentation may change frequently.
