# Gastrobrain

A personal cooking companion app that helps you plan, organize, and track your culinary journey.

## About

Gastrobrain is a Flutter-based mobile application designed to assist home cooks in managing their recipes, planning meals, and organizing shopping. It focuses on providing a personal, workbook-like approach to recipe management while supporting both daily cooking needs and special occasions.

## Features

### Current Features
- Recipe management with difficulty and rating tracking
- Ingredient system with comprehensive categorization
- Meal history tracking and success rate monitoring
- Shopping list organization by venue type
- Protein type tracking and rotation
- Cooking session logging

### Planned Features
- Weekly meal planning tools
- Advanced timeline planning for complex meals
- Shopping venue-specific list generation
- Recipe modification and version tracking
- Culinary knowledge base integration

## Getting Started

### Prerequisites
- Flutter SDK
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

3. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── models/         # Data models
├── screens/        # UI screens
├── widgets/        # Reusable widgets
├── database/       # Database helpers
├── utils/          # Utility functions
└── core/           # Core functionality
```

## Database Schema

The app uses SQLite for local storage with the following main entities:
- Recipes
- Ingredients
- Meals
- RecipeIngredients

## Contributing

This project is currently in early development and not open for contributions. Stay tuned for updates.

## Development Status

Current Version: v0.0.1
- Basic recipe management
- Ingredient system implementation
- Meal history tracking
- Initial planning tools

## Tech Stack

- Flutter/Dart
- SQLite
- Material Design

## Roadmap

1. Phase 1 (Current)
   - Core functionality refinement
   - Data model optimization
   - Basic UI improvements
   - Essential planning features

2. Phase 2 (Planned)
   - Advanced meal planning
   - Shopping list enhancements
   - Timeline planning tools
   - Recipe versioning

3. Future Phases
   - Knowledge base integration
   - Community features
   - Regional cuisine exploration
   - Recipe sharing capabilities

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by home cooking experiences during COVID-19 lockdown
- Built with assistance from Anthropic's Claude AI
- Special thanks to all home cooks who inspired this project

## Contact

For questions or feedback, please open an issue in the repository.

---
*Note: This project is under active development. Features and documentation may change frequently.*