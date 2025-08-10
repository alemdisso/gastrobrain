<!-- markdownlint-disable -->
# 📋 Gastrobrain Development Sprint Plan

## 🎯 Current Sprint: Database Migration Strategy (#144)

**Branch**: `feature/144-database-migration-strategy`  
**Base**: Built on top of state management foundations from feature/6  
**Status**: Active  
**Priority**: P1-High (Foundational)

## 📊 Sprint Context & Background

### 🏗️ **Architectural Foundation Already Built**
We have successfully implemented a robust state management foundation:

- ✅ **Repository Pattern**: RecipeRepository and MealRepository with caching
- ✅ **Provider Architecture**: RecipeProvider and MealProvider for state management  
- ✅ **Cache Management**: 5-minute timeout, invalidation methods, error handling
- ✅ **UI Integration**: HomeScreen fully converted to use RecipeProvider
- ✅ **Error Handling**: Custom GastrobrainException hierarchy
- ✅ **MultiProvider Setup**: Main.dart configured for scalable provider architecture

### 🎬 **Previous Work Completed**
**Branch**: `feature/6-implement-proper-state-management` (2 commits)

1. **Commit 1d6b862**: State management with Provider pattern
   - RecipeRepository, RecipeProvider implementation
   - HomeScreen refactored to use providers
   - Loading states, error handling, pull-to-refresh
   - 753+ lines added across 11 files

2. **Commit 996e0ed**: MealProvider for meal state management  
   - MealRepository and MealProvider implementation
   - CRUD operations for meals and meal recipes
   - 571+ lines added across 3 files

## 🎯 **Current Sprint Objectives**

### **Primary Goal**: Implement Database Migration Strategy
Build a robust migration system that preserves user data while allowing schema evolution, specifically designed to work with our existing Repository/Provider architecture.

### **Key Requirements from Issue #144**:
1. **Migration Framework**: Version-based schema evolution tracking
2. **Data Preservation**: Maintain meal history and recipe relationships  
3. **Repository Integration**: Work with our existing caching architecture
4. **Provider Support**: UI feedback during migration process
5. **Rollback Capability**: Safety measures for failed migrations
6. **Testing Framework**: Validate migrations with realistic data

## 📝 **Technical Implementation Plan**

### **Phase 1: Migration Infrastructure**
**Files to Create/Modify**:

1. **`lib/core/migration/migration.dart`**
   ```dart
   abstract class Migration {
     int get version;
     String get description;
     Future<void> up(Database db);
     Future<void> down(Database db);
   }
   ```

2. **`lib/core/migration/migration_runner.dart`**
   ```dart
   class MigrationRunner {
     Future<void> runPendingMigrations();
     Future<void> rollbackMigration(int version);
     Future<bool> needsMigration();
   }
   ```

3. **Update `lib/database/database_helper.dart`**
   - Add schema_migrations table
   - Integrate migration runner
   - Update database initialization

### **Phase 2: Repository Integration**
**Files to Modify**:

1. **`lib/core/repositories/base_repository.dart`**
   - Add migration-aware methods
   - Cache invalidation during migrations

2. **`lib/core/repositories/recipe_repository.dart`**
   - Pre/post-migration cache management
   - Data validation methods

3. **`lib/core/repositories/meal_repository.dart`**  
   - Migration-aware caching
   - Relationship preservation logic

### **Phase 3: Provider UI Support**
**Files to Create**:

1. **`lib/core/providers/migration_provider.dart`**
   ```dart
   class MigrationProvider extends ChangeNotifier {
     bool get isMigrating;
     double get migrationProgress;  
     String get currentMigrationDescription;
     GastrobrainException? get migrationError;
   }
   ```

### **Phase 4: Migration Implementation**
**Files to Create**:

1. **`lib/core/migration/migrations/`** - Individual migration files
   - `001_initial_schema.dart`
   - `002_improve_ingredient_categorization.dart` 
   - `003_recipe_data_refresh.dart`

## 🔗 **Integration with Existing Architecture**

### **Repository Benefits for Migration**:
- ✅ **Centralized Data Access**: All DB calls go through repositories
- ✅ **Cache Invalidation**: Built-in methods for clearing stale data
- ✅ **Error Handling**: Consistent exception patterns
- ✅ **State Management**: Providers can show migration progress

### **Provider Benefits for Migration**:
- ✅ **UI Feedback**: Loading states, progress indicators
- ✅ **Error Display**: User-friendly error messages
- ✅ **State Synchronization**: Reactive UI updates
- ✅ **User Experience**: Smooth migration process

## 🚀 **Post-Migration Sprint Plan**

### **Phase 5: Complete State Management (#6)**
**Branch**: Merge migration work back to `feature/6-implement-proper-state-management`

**Remaining Tasks**:
1. **MealPlanProvider Implementation**
   - Create MealPlanRepository 
   - Create MealPlanProvider
   - Add to MultiProvider setup

2. **Screen Refactoring**
   - WeeklyPlanScreen → Use MealPlanProvider
   - CookMealScreen → Use MealProvider  
   - Remaining screens progressive updates

3. **Testing & Validation**
   - Integration testing of provider architecture
   - Performance testing of caching system
   - User experience validation

### **Phase 6: UI Enhancement Issues**
**Parallel/Sequential Implementation**:

1. **Issue #140 - Recipe Card Action Icons** (Independent - can be parallel)
   - Update Icons.restaurant → Icons.play_arrow
   - Update Icons.food_bank → Icons.list_alt
   - Improve tooltip clarity

2. **Issue #122 - Refine Add Ingredient Dialog UI** (Independent - can be parallel)
   - Simplify primary interface
   - Progressive disclosure for advanced options
   - Streamline ingredient selection flow

3. **Issue #138 - Standardize Filtering/Ordering UI** (Dependent on #6)
   - Convert sorting to AlertDialog pattern
   - Ensure consistency with filtering dialog
   - Integration with RecipeProvider filtering

## 📁 **File Structure Overview**

### **Current Architecture** (Already Built):
```
lib/
├── core/
│   ├── di/service_provider.dart ✅
│   ├── providers/
│   │   ├── recipe_provider.dart ✅
│   │   └── meal_provider.dart ✅
│   ├── repositories/
│   │   ├── base_repository.dart ✅
│   │   ├── recipe_repository.dart ✅
│   │   └── meal_repository.dart ✅
│   └── errors/gastrobrain_exceptions.dart ✅
└── screens/home_screen.dart ✅ (Refactored)
```

### **Migration Implementation** (To Be Built):
```
lib/
├── core/
│   ├── migration/
│   │   ├── migration.dart [NEW]
│   │   ├── migration_runner.dart [NEW]
│   │   └── migrations/
│   │       ├── 001_initial_schema.dart [NEW]
│   │       └── 002_improve_categorization.dart [NEW]
│   └── providers/
│       └── migration_provider.dart [NEW]
└── database/database_helper.dart [UPDATE]
```

## 🔄 **Git Workflow & Branch Management**

### **Current Branch Structure**:
```
develop (main development branch)
├── feature/6-implement-proper-state-management (2 commits, complete foundation)
    └── feature/144-database-migration-strategy (current branch)
```

### **Merge Strategy**:
1. Complete migration implementation in `feature/144-database-migration-strategy`
2. Merge migration work back to `feature/6-implement-proper-state-management`  
3. Complete remaining state management tasks
4. Merge consolidated work to `develop`
5. Create new branches for UI issues (#140, #122, #138)

### **Commit Message Format** (Established):
```
<type>: <description> (#<issue-number>)

<detailed description>

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 🎯 **Success Criteria**

### **Migration System Requirements**:
- [ ] Version-based migration tracking
- [ ] Automatic backup before migrations  
- [ ] Data preservation with relationship mapping
- [ ] Integration with Repository/Provider architecture
- [ ] User-friendly migration UI with progress feedback
- [ ] Rollback capability for failed migrations
- [ ] Comprehensive testing framework
- [ ] Documentation for creating new migrations

### **Integration Requirements**:
- [ ] Repository cache invalidation during migrations
- [ ] Provider-based migration progress UI
- [ ] Error handling consistent with existing patterns  
- [ ] Performance maintained with caching system
- [ ] No regression in existing functionality

## 🚨 **Critical Dependencies**

### **Blockers**:
- None - migration work builds on existing foundation

### **Dependencies**:
- ✅ Repository pattern (already implemented)
- ✅ Provider architecture (already implemented)  
- ✅ Error handling system (already implemented)
- ✅ Database helper foundation (already exists)

## 📊 **Progress Tracking**

### **Current Status**: 
- State Management Foundation: **100% Complete**
- Migration System: **0% - Starting**
- Remaining State Management: **Pending Migration**
- UI Issues: **Pending Architecture**

### **Estimated Timeline**:
- **Migration Implementation**: ~1-2 development sessions
- **Complete State Management**: ~1 development session  
- **UI Issues**: ~1 session each (can be parallel)

## 🔧 **Development Environment**

### **Platform**: WSL (No GUI testing available)
### **Testing Strategy**: Code analysis, build validation, architecture verification
### **Validation**: `flutter analyze`, `flutter build apk --debug`

## 📋 **Quick Start for Fresh Sessions**

### **Environment Setup**:
```bash
cd /home/rodrigo_machado/dev/gastrobrain
git status  # Should show feature/144-database-migration-strategy
flutter analyze  # Verify no critical errors
```

### **Current Working Files**:
- **Primary**: `lib/database/database_helper.dart` (add migration system)
- **New**: Migration framework files (see file structure above)
- **Integration**: Update repositories and providers for migration support

### **Key Context**:
- We have solid Repository/Provider foundation
- Migration system should integrate with existing architecture  
- Focus on data preservation and user experience
- Repository caching and Provider UI feedback are key advantages

---

**Next Action**: Begin implementing migration framework in DatabaseHelper and create Migration abstract class.