<!-- markdownlint-disable -->
# 📋 Database Migration Testing & Data Translation Plan

## 🎯 **Objective**
Test the migration system (#144) and create a strategy to translate mixed English ingredients + Portuguese recipes while preserving all meal history and planning data.

## 🏗️ **Current Migration System Capabilities**

### ✅ **Implemented Features** (from #144)
- **Version-based migration tracking** via `schema_migrations` table
- **Migration runner** with progress callbacks and error handling  
- **Automatic backup** before migrations with rollback support
- **Data validation** and integrity checks post-migration
- **Base migration framework** with `up()` and `down()` methods
- **Initial schema migration** (001) as baseline

### 🔧 **Migration System Components**
```
lib/core/migration/
├── migration.dart (Abstract base class)
├── migration_runner.dart (Execution engine) 
├── migrations/
│   └── 001_initial_schema.dart (Baseline)
└── [Future migrations here]
```

## 📊 **Your Data Translation Challenge**

### **Current State**
- **Ingredients**: Mixed English names in database
- **Recipes**: Portuguese names and content  
- **Meal History**: References ingredient/recipe IDs with cooking dates
- **Goal**: Standardize everything to Portuguese without losing history

### **Risk Assessment**
- 🔴 **HIGH RISK**: Losing meal history and cooking statistics
- 🟡 **MEDIUM RISK**: Breaking ingredient-recipe relationships
- 🟢 **LOW RISK**: Translation accuracy (can be refined iteratively)

## 🧪 **Migration Testing Strategy**

### **Phase 1: Migration System Validation (1-2 hours)**

#### **Test Environment Setup**
```bash
# 1. Create test database copy
cp your_app_database.db test_migration.db

# 2. Create minimal test data
# - 3-5 ingredients (mixed English/Portuguese)  
# - 2-3 recipes referencing those ingredients
# - 1-2 meal records with cooking history
```

#### **Basic Migration Testing**
1. **Schema Version Detection**
   ```dart
   final needsMigration = await migrationRunner.needsMigration();
   final currentVersion = await migrationRunner.getCurrentVersion();
   ```

2. **Backup Creation Test**
   - Trigger a test migration
   - Verify backup file is created in app documents
   - Compare backup with original database

3. **Migration Execution Test**
   - Run `001_initial_schema.dart` on fresh database
   - Verify all tables are created correctly
   - Check foreign key constraints are working

4. **Rollback Testing**
   - Create intentionally failing migration
   - Verify rollback restores original state
   - Test error handling and user feedback

### **Phase 2: Data Translation Migration Design (2-3 hours)**

#### **Create Translation Migration (002_translate_to_portuguese.dart)**

**Strategy: Smart ID Mapping with Name-Based Matching**

```dart
class TranslateToPortugueseMigration extends Migration {
  @override
  int get version => 2;
  
  @override
  String get description => 'Translate ingredients and recipes to Portuguese';
  
  @override
  bool get requiresBackup => true; // CRITICAL: Backup required
  
  @override
  Future<void> up(DatabaseExecutor db) async {
    // Step 1: Create translation mapping tables
    await _createTranslationTables(db);
    
    // Step 2: Load Portuguese ingredient translations
    await _loadIngredientTranslations(db);
    
    // Step 3: Update ingredients with Portuguese names
    await _translateIngredients(db);
    
    // Step 4: Update recipe references (if needed)
    await _updateRecipeIngredientReferences(db);
    
    // Step 5: Validate data integrity
    await _validateTranslation(db);
  }
}
```

#### **Translation Data Sources**
1. **Create Portuguese ingredient mapping**:
   ```json
   {
     "onion": "cebola",
     "garlic": "alho", 
     "tomato": "tomate",
     "chicken": "frango",
     // ... complete mapping
   }
   ```

2. **Asset-based translation files**:
   ```
   assets/
   ├── ingredients-translation-en-pt.json
   └── recipe-categories-translation.json
   ```

### **Phase 3: Safe Production Migration (30 minutes)**

#### **Pre-Migration Checklist**
- [ ] **Full device backup** (entire app data directory)
- [ ] **Database export** to human-readable format for verification
- [ ] **Test migration** on database copy
- [ ] **Rollback plan** prepared and tested
- [ ] **Validation queries** written to check data integrity

#### **Migration Execution Process**
```bash
# 1. Export current data for verification
flutter run --debug  # Open debug console
# Run data export commands

# 2. Run migration with monitoring
# App will automatically detect and run pending migrations
# Monitor progress through UI or logs

# 3. Post-migration validation
# Check ingredient names are in Portuguese
# Verify meal history still links correctly
# Test recipe ingredient relationships
```

#### **Validation Queries**
```sql
-- Check ingredient translation worked
SELECT name, category, protein_type FROM ingredients LIMIT 10;

-- Verify meal history integrity  
SELECT m.cooked_at, r.name, i.name 
FROM meals m 
JOIN recipes r ON m.recipe_id = r.id
JOIN recipe_ingredients ri ON r.id = ri.recipe_id
JOIN ingredients i ON ri.ingredient_id = i.id
LIMIT 5;

-- Count data before/after
SELECT 'ingredients' as table_name, COUNT(*) as count FROM ingredients
UNION ALL
SELECT 'recipes', COUNT(*) FROM recipes
UNION ALL  
SELECT 'meals', COUNT(*) FROM meals;
```

## 🚀 **Implementation Steps**

### **Step 1: Test Migration System (This Week)**
1. **Create test database** with sample mixed-language data
2. **Run migration system** on test data  
3. **Verify backup/restore** functionality works
4. **Test error scenarios** and rollback

### **Step 2: Create Translation Migration (Next Week)**  
1. **Build ingredient translation mapping** (English → Portuguese)
2. **Implement 002_translate_to_portuguese.dart** migration
3. **Test on sample data** with your actual ingredient/recipe patterns
4. **Refine translation accuracy**

### **Step 3: Production Migration (When Ready)**
1. **Full device backup**
2. **Run migration** on your actual app data
3. **Validate results** using test queries
4. **Enjoy fully Portuguese-localized app** with preserved history!

## 🛡️ **Safety Measures**

### **Multiple Backup Layers**
1. **Automatic migration backup** (built into migration system)
2. **Manual database export** before starting
3. **Full app data backup** at device level
4. **Exported text files** with critical meal history

### **Rollback Options**
1. **Migration rollback** (if migration fails)
2. **Database restore** from backup file  
3. **App data restore** from device backup
4. **Manual reconstruction** from exported text (last resort)

### **Validation Steps**
- Ingredient count matches before/after
- All recipes still reference valid ingredients  
- Meal history dates and recipe links intact
- Portuguese translations are accurate and consistent

## 📈 **Future Migration Benefits**

Once this system is proven with your translation migration, you can use it for:

- **Adding new ingredient categories** without breaking existing recipes
- **Schema changes** for new features (shopping lists, nutrition, etc.)
- **Data quality improvements** (duplicate cleanup, categorization)
- **Seeding data updates** without losing user data

The migration system turns database evolution from a risky manual process into a **reliable, repeatable, and safe** operation.

---

**Ready to start with Phase 1 testing?** We can begin by creating a small test database with your actual data patterns and running the migration system to ensure everything works correctly.