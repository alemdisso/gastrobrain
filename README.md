# Gastrobrain

A personal cooking companion app that helps you plan, organize, and track your culinary journey with intelligent recommendations and comprehensive meal management.

## About

Gastrobrain is a Flutter-based mobile application designed to assist home cooks in managing their recipes, planning meals, and organizing shopping. It focuses on providing a personal, workbook-like approach to recipe management with sophisticated recommendation algorithms that encourage dietary variety and help maintain cooking routines.

## Features

### Recipe Management

- **Comprehensive Recipe Library** - Store recipes with difficulty ratings, cook times, and serving sizes
- **Multi-Ingredient Support** - Track recipes with multiple protein sources and complex ingredient lists
- **Protein Type Tracking** - Monitor and rotate protein usage for dietary variety
- **Rating System** - Rate recipes from 1-5 stars to improve recommendations

### Intelligent Recommendations

- **Smart Recommendation Engine** - Multi-factor scoring system based on:
  - Recipe frequency and due dates
  - Protein rotation (encourages dietary variety)
  - User ratings and preferences
  - Variety encouragement (promotes exploration)
  - Temporal context (weekday/weekend adaptations)
- **Context-Aware Suggestions** - Recommendations adapt to meal type, date, and cooking patterns
- **Protein Rotation System** - Graduated penalties discourage protein repetition

### Meal Planning & History

- **Weekly Meal Planning** - Plan meals with multi-recipe support (main dishes + sides)
- **Cooking Session Tracking** - Log when recipes are cooked with notes
- **Meal History Analytics** - Track cooking patterns, success rates, and frequency
- **Retroactive Planning** - Plan meals after cooking for accurate history

### Ingredients & Shopping

- **Ingredient Database** - Comprehensive categorization with protein type tracking
- **Localized Units** - Support for metric and customary measurements
- **Custom Ingredients** - Add custom ingredients when needed
- **Recipe Ingredient Management** - Link ingredients to recipes with quantities and preparation notes

### Localization

- **Bilingual Support** - Full English and Portuguese localization
- **Ingredient Translation** - Built-in translation system for ingredient names and categories

### Data Management

- **Database Migrations** - Versioned schema evolution with automatic migrations
- **Data Export** - Export recipes and ingredients in JSON format
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
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## Project Structure

```text
lib/
├── core/                  # Core functionality
│   ├── di/               # Dependency injection
│   ├── services/         # Business logic services
│   └── exceptions/       # Custom exceptions
├── database/             # Database layer
│   └── migrations/       # Schema migrations
├── models/               # Data models
├── screens/              # UI screens
├── widgets/              # Reusable widgets
├── l10n/                 # Localization files (ARB)
└── utils/                # Utility functions

docs/                     # Documentation
├── RECOMMENDATION_ENGINE.md  # Recommendation system docs
├── ISSUE_WORKFLOW.md        # Development workflow
├── L10N_PROTOCOL.md         # Localization guidelines
└── Gastrobrain-Codebase-Overview.md  # Architecture overview
```

## Development Status

**Current Version: v0.1.0** - Personal Meal Planning Excellence

### Major Achievements

- ✅ Modern architecture with dependency injection
- ✅ Comprehensive testing infrastructure (55+ tests)
- ✅ Full bilingual support (English/Portuguese)
- ✅ Advanced recommendation engine with 6 scoring factors
- ✅ Database migration system
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Multi-ingredient and multi-recipe meal support

### What's Next (v0.1.1 - Stability & Polish)

- Performance optimization and profiling
- Enhanced test coverage
- UI polish and animations
- Release preparation and deployment readiness

### Future Milestones

- **v0.2.0** - Beta-ready phase with multi-user foundations
- **v0.3.0** - Server-client architecture for broader user base
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

- [**Recommendation Engine**](docs/RECOMMENDATION_ENGINE.md) - Complete guide to the recommendation system
- [**Issue Workflow**](docs/ISSUE_WORKFLOW.md) - Development workflow and Git Flow practices
- [**L10N Protocol**](docs/L10N_PROTOCOL.md) - Localization guidelines
- [**Codebase Overview**](docs/Gastrobrain-Codebase-Overview.md) - Architecture and patterns

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
