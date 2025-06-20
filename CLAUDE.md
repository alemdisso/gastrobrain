# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gastrobrain is a Flutter-based meal planning and recipe management application that helps users organize their cooking with intelligent recipe recommendations. The app uses SQLite for local storage and features a sophisticated recommendation engine with multi-factor scoring.

## Development Workflow

### Preferred Working Style
When working on this codebase, follow a **deliberate, step-by-step approach**:

1. **Plan First**: Always outline what you intend to do before making changes
   - Create a clear plan using the TodoWrite tool to track tasks
   - Break complex changes into smaller, manageable steps
   - Explain your approach before implementing

2. **One File at a Time**: Focus on individual files rather than making sweeping changes
   - Read and understand the current file structure first
   - Make targeted, focused changes to single files
   - Test changes incrementally

3. **Steady Pace**: Maintain quality over speed
   - Take time to understand the existing code patterns
   - Follow established conventions and architecture
   - Avoid rushing through multiple files in one interaction

4. **Validate as You Go**: Check your work frequently
   - Run tests after making changes
   - Use `flutter analyze` to check for issues
   - Verify that changes integrate properly with existing code

### Implementation Process
1. **Analyze** - Read existing code to understand current implementation
2. **Plan** - Outline the changes needed using TodoWrite
3. **Implement** - Make focused changes to one file at a time
4. **Test** - Verify changes work correctly
5. **Document** - Update any relevant documentation or comments

This approach ensures code quality, maintains architectural consistency, and reduces the likelihood of introducing bugs.

## Issue Tackling Protocol

### Branch Naming Convention
Create branches based on issue type and number using this format:
`{type}/{issue-number}-{short-description}`

**Branch Types:**
- `feature/` - For enhancements and new functionality
- `bugfix/` - For bug fixes and corrections
- `testing/` - For adding or improving tests
- `refactor/` - For technical debt and architecture improvements
- `ui/` - For user interface improvements
- `docs/` - For documentation updates

**Examples:**
- `feature/{issue-number}-meal-type-recommendation-profiles`
- `bugfix/{issue-number}-recipe-stats-side-dish`
- `testing/{issue-number}-end-to-end-meal-edit`
- `refactor/{issue-number}-view-models-complex-displays`
- `ui/{issue-number}-refine-add-ingredient-dialog`

### Issue Workflow Process

#### 1. Starting Work on an Issue
```bash
# Check out latest main/develop branch
git checkout develop
git pull origin develop

# Create and switch to new branch
git checkout -b {type}/{issue-number}-{short-description}

# Check the issue details
gh issue view {issue-number}
```

#### 2. Development Process
1. **Analyze the Issue**: Read the GitHub issue carefully and understand requirements
2. **Plan Implementation**: Use TodoWrite tool to break down the work
3. **Follow Development Workflow**: Apply the step-by-step approach outlined above
4. **Commit Regularly**: Make small, focused commits with clear messages

#### 3. Commit Message Format
```
{type}: brief description (#{issue-number})

Optional longer description of changes made.

Closes #{issue-number}
```

**Template Examples:**
```
feature: add meal type-specific recommendation profiles (#{issue-number})

Implements lunch/dinner specific weight profiles for the 
recommendation engine with temporal context awareness.

Closes #{issue-number}
```

```
bugfix: fix recipe statistics when added as side dish (#{issue-number})

Updates meal recording logic to properly increment recipe 
statistics for both primary and side dishes.

Closes #{issue-number}
```

#### 4. Testing Before PR
```bash
# Run relevant tests
flutter test test/path/to/related/tests/

# Run full test suite if major changes
flutter test

# Check code quality
flutter analyze

# Test the app manually if UI changes
flutter run
```

#### 5. Integration Options

Choose the appropriate integration method based on the type and risk of your changes:

**Option A: Pull Request (Recommended for major features, releases, or complex changes)**
```bash
# Push branch to origin
git push origin {type}/{issue-number}-{short-description}

# Create PR via GitHub CLI
gh pr create --title "{Type}: {Brief description} (#{issue-number})" --body "{Description of changes}

## Changes
- {List of changes made}
- {Additional changes}

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Code analysis clean

Closes #{issue-number}"

# Review and merge the PR
gh pr merge --squash  # or --merge, or --rebase
```

**Option B: Direct Merge (For small fixes, documentation, quick iterations)**
```bash
# Switch to main and merge directly
git checkout main
git pull origin main
git merge {type}/{issue-number}-{short-description}
git push origin main
```

**When to Use Each Option:**
- **Use PRs for**: Major features, pre-release changes, complex modifications, anything that could break functionality
- **Use Direct Merge for**: Small bug fixes, documentation updates, minor UI tweaks, low-risk changes

#### 6. Branch Cleanup
After PR is merged:
```bash
# Switch back to main
git checkout main
git pull origin main

# Delete local branch
git branch -d {type}/{issue-number}-{short-description}

# Delete remote branch (if not auto-deleted)
git push origin --delete {type}/{issue-number}-{short-description}
```

### GitHub CLI Issue Commands
```bash
# List all open issues
gh issue list

# View specific issue details
gh issue view {issue-number}

# Create new issue
gh issue create --title "Issue title" --body "Issue description"

# Close issue (usually done via PR)
gh issue close {issue-number}

# Add labels to issue
gh issue edit {issue-number} --add-label "enhancement,✓✓"
```

This protocol ensures consistent branch management and clear traceability between issues and code changes.

## Common Development Commands

### Flutter Commands
- **Run the app**: `flutter run`
- **Build for release**: `flutter build apk` (Android), `flutter build ios` (iOS)
- **Install dependencies**: `flutter pub get`
- **Clean build**: `flutter clean && flutter pub get`
- **Run on specific device**: `flutter run -d <device_id>`

### Testing Commands
- **Run all tests**: `flutter test`
- **Run specific test file**: `flutter test test/path/to/test_file.dart`
- **Run integration tests**: `flutter test integration_test/`
- **Run tests with coverage**: `flutter test --coverage`
- **Run widget tests**: `flutter test test/widgets/`
- **Run unit tests**: `flutter test test/core/ test/models/ test/database/`

### Code Quality
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format lib/ test/ integration_test/`

## Architecture Overview

### Core Architecture
- **Clean dependency injection** via `ServiceProvider` pattern in `lib/core/di/`
- **SQLite database** with comprehensive schema managed by `DatabaseHelper`
- **Pluggable recommendation system** with configurable scoring factors
- **Multi-recipe meal planning** using junction table architecture

### Key Directories
- `lib/core/` - Core services (DI, recommendation engine, validators, errors)
- `lib/models/` - Data models with SQLite mapping
- `lib/database/` - Database layer and schema management
- `lib/screens/` - UI screens and navigation
- `lib/widgets/` - Reusable UI components
- `test/` - Unit and widget tests
- `integration_test/` - End-to-end integration tests

### Data Layer
- **Junction table pattern** for complex relationships (meal-recipe associations)
- **Recipe-centric design** with frequency tracking and categorization
- **Comprehensive meal tracking** with actual vs. expected time logging
- **Recommendation history** with serialization and user response tracking

### Recommendation System
The core of the application is a sophisticated recommendation engine with 6 pluggable factors:

1. **FrequencyFactor** (35%) - Prioritizes recipes based on desired cooking frequency
2. **ProteinRotationFactor** (30%) - Encourages protein variety 
3. **RatingFactor** (10%) - Considers user ratings
4. **VarietyEncouragementFactor** (10%) - Promotes less-frequently cooked recipes
5. **DifficultyFactor** (10%) - Adapts to weekday/weekend context
6. **RandomizationFactor** (5%) - Adds controlled variety

**Temporal Intelligence**: Automatic weekday (simplicity-focused) vs weekend (complexity-allowing) profiles.

### UI Architecture
- **Responsive design** adapting to phone, tablet, and landscape orientations
- **Multi-recipe meal planning** with three-stage selection flow
- **Visual recommendation feedback** with factor scoring badges and tooltips
- **Context-aware suggestions** throughout the meal planning workflow

## Database Schema

### Core Tables
- `recipes` - Recipe definitions with difficulty, timing, ratings, categories
- `ingredients` - Categorized ingredients with protein type classifications
- `recipe_ingredients` - Junction table with quantities and unit overrides
- `meals` - Actual cooking instances with success tracking
- `meal_recipes` - Junction table for multi-recipe meals

### Planning Tables
- `meal_plans` - Weekly plans (Friday-to-Thursday cycle)
- `meal_plan_items` - Individual meal slots within plans
- `meal_plan_item_recipes` - Junction table for planned multi-recipe meals

### History & Analytics
- `recommendation_history` - Serialized recommendation results with user responses

## Development Patterns

### Dependency Injection
Access services through the central `ServiceProvider`:
```dart
import 'package:gastrobrain/core/di/service_provider.dart';

final dbHelper = ServiceProvider.database.helper;
final recommendations = ServiceProvider.recommendations.service;
```

### Database Operations
Use `DatabaseHelper` methods with proper error handling:
```dart
try {
  final recipe = await dbHelper.getRecipe(id);
} on NotFoundException {
  // Handle not found
} on ValidationException {
  // Handle validation errors
} on GastrobrainException {
  // Handle general app errors
}
```

### Recommendation Usage
```dart
final recommendations = await recommendationService.getRecommendations(
  count: 5,
  forDate: DateTime.now(),
  mealType: 'dinner',
  weekdayMeal: true, // Applies weekday profile
);
```

### Testing Patterns
- Use `MockDatabaseHelper` for isolated unit tests
- Test recommendation factors individually and in combination
- Widget tests should cover responsive layouts
- Integration tests cover full user workflows

## Key Implementation Notes

### Multi-Recipe Meal System
The app supports complex meals with main dishes and side dishes through junction tables. When working with meals:
- Use `MealPlanItemRecipe` for planning phase
- Use `MealRecipe` for cooking phase  
- Both support `isPrimaryDish` flags for meal composition

### Temporal Context
The recommendation system automatically adapts based on day of week:
- **Weekdays**: Emphasize simplicity (difficulty weight: 20%)
- **Weekends**: Allow complexity (rating weight: 20%, variety: 15%)

### Error Handling
Custom exception hierarchy:
- `ValidationException` - Input validation failures
- `NotFoundException` - Entity not found
- `GastrobrainException` - General application errors

### Performance Considerations
- Recommendation caching with context-aware invalidation
- Bulk database operations for large datasets
- Optimized queries with proper indexing
- Lazy loading for improved startup

## Testing Strategy

### Unit Tests
Focus on business logic in `test/core/services/` and data models in `test/models/`.

### Widget Tests  
Test UI components in `test/widgets/` and screens in `test/screens/`.

### Integration Tests
Full user workflows in `integration_test/` covering:
- Meal planning flow
- Recipe recommendation integration
- Multi-recipe meal creation
- Editing and modification workflows

### Test Data
Use the mock database framework for isolated testing with realistic data simulation.