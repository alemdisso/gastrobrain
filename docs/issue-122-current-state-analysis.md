# Issue #122: Current State Analysis

## Dialog State Machine

### State Variables (lib/widgets/add_ingredient_dialog.dart)

```dart
// Controllers
_searchController (line 41)          // Search text input
_quantityController (line 39)        // Quantity numeric input
_notesController (line 40)           // Preparation notes
_customNameController (line 55)      // Custom ingredient name

// State flags
_isLoading (line 47)                 // Loading ingredients from DB
_isSaving (line 48)                  // Saving ingredient to recipe
_isCustomIngredient (line 57)        // Toggle: Database vs Custom
_useCustomUnit (line 44)             // Toggle: Use unit override

// Data
_availableIngredients (line 45)      // All ingredients from DB
_filteredIngredients (line 42)       // Filtered by search
_selectedIngredient (line 46)        // Currently selected ingredient
_selectedUnitOverride (line 43)      // Selected unit override
_selectedCategory (line 58)          // Custom ingredient category
```

### State Transitions

#### Initial Load
```
initState()
  ↓
_isLoading = true
  ↓
_loadIngredients()
  ↓
Database: getAllIngredients()
  ↓
Sort alphabetically
  ↓
_availableIngredients = ingredients
_filteredIngredients = ingredients
_isLoading = false
```

#### Editing Existing Ingredient
```
initState() with existingIngredient != null
  ↓
Check: custom_name present?
  ├─ YES: Custom ingredient
  │   ├─ _isCustomIngredient = true
  │   ├─ Pre-fill: _customNameController
  │   ├─ Pre-fill: _selectedCategory
  │   ├─ Pre-fill: _selectedUnitOverride
  │   └─ Skip loading ingredients
  │
  └─ NO: Database ingredient
      ├─ Pre-fill: _quantityController
      ├─ Pre-fill: _notesController
      ├─ Check: unit_override present?
      │   └─ YES: _useCustomUnit = true
      ├─ Load ingredients from DB
      └─ Find and select ingredient by ID
```

#### Search Flow (Database Mode)
```
User types in _searchController
  ↓
_filterIngredients(query)
  ↓
Filter _availableIngredients by name (case-insensitive)
  ↓
Update _filteredIngredients
  ↓
Dropdown rebuilds with filtered list
```

#### Toggle: Database ↔ Custom
```
SegmentedButton clicked
  ↓
setState: _isCustomIngredient = !_isCustomIngredient
  ↓
UI rebuilds:
  ├─ Database mode: Show search + dropdown + "Create New" button
  └─ Custom mode: Show name field + category dropdown
```

#### Create New Ingredient (from Database mode)
```
"Create New Ingredient" button clicked
  ↓
showDialog(AddNewIngredientDialog)
  ↓
User fills form and saves
  ↓
Returns: Ingredient object
  ↓
Add to _availableIngredients
Set as _selectedIngredient
```

#### Unit Override Flow (Database mode)
```
Checkbox: "Override default unit"
  ↓
_useCustomUnit = true
  ↓
UI shows unit dropdown
  ↓
User selects unit
  ↓
_selectedUnitOverride = unit.value
```

#### Save Flow
```
"Add" button clicked
  ↓
Validate form
  ↓
_isSaving = true
  ↓
Check mode:
  ├─ Custom Ingredient:
  │   └─ Create RecipeIngredient(
  │         ingredientId: null,
  │         customName: _customNameController.text,
  │         customCategory: _selectedCategory.value,
  │         customUnit: _selectedUnitOverride
  │       )
  │
  └─ Database Ingredient:
      ├─ Validate: _selectedIngredient not null
      ├─ Validate: quantity > 0
      └─ Create RecipeIngredient(
            ingredientId: _selectedIngredient.id,
            quantity: quantity,
            unitOverride: _useCustomUnit ? _selectedUnitOverride : null,
            notes: _notesController.text
          )
  ↓
onSave callback OR database.addIngredientToRecipe()
  ↓
Navigator.pop(context, result)
```

## Data Flow

### Input Sources
1. **Database**: `DatabaseHelper.getAllIngredients()` → `List<Ingredient>`
2. **User Input**: Search, quantity, unit, notes, custom fields
3. **Props**: `recipe`, `existingIngredient`, `recipeIngredientId`, `databaseHelper`

### Output
- **onSave callback**: Returns `RecipeIngredient` object
- **Direct save**: Calls `DatabaseHelper.addIngredientToRecipe()` or `updateRecipeIngredient()`

### Data Transformations

#### Database Ingredient → RecipeIngredient
```dart
RecipeIngredient(
  id: generated or existing,
  recipeId: widget.recipe.id,
  ingredientId: _selectedIngredient.id,           // Links to ingredients table
  quantity: parsed from _quantityController,
  notes: _notesController.text or null,
  unitOverride: _useCustomUnit ? _selectedUnitOverride : null,
  customName: null,                                // Not used for DB ingredients
  customCategory: null,
  customUnit: null
)
```

#### Custom Ingredient → RecipeIngredient
```dart
RecipeIngredient(
  id: generated or existing,
  recipeId: widget.recipe.id,
  ingredientId: null,                              // No link to ingredients table
  quantity: parsed from _quantityController,
  notes: _notesController.text or null,
  unitOverride: null,                              // Not used for custom
  customName: _customNameController.text,
  customCategory: _selectedCategory.value,
  customUnit: _selectedUnitOverride                // Optional
)
```

## UI Structure (Current)

```
AlertDialog
├─ Title: "Add Ingredient" or "Edit Ingredient"
│
├─ Content: Form > SingleChildScrollView > Column
│   │
│   ├─ [1] SegmentedButton (lines 308-333)
│   │   ├─ "From Database"
│   │   └─ "Custom"
│   │
│   ├─ [2a] IF Custom: (lines 337-379)
│   │   ├─ TextFormField: Ingredient Name
│   │   └─ DropdownButtonFormField: Category
│   │
│   ├─ [2b] IF Database: (lines 380-444)
│   │   ├─ TextField: Search (with onChanged)
│   │   ├─ DropdownButtonFormField: Select Ingredient
│   │   └─ TextButton.icon: "Create New Ingredient"
│   │
│   ├─ [3] Row: Quantity + Unit (lines 449-556)
│   │   ├─ TextFormField: Quantity
│   │   └─ IF Custom:
│   │       │   └─ DropdownButtonFormField: Unit (optional)
│   │       └─ IF Database:
│   │           ├─ IF _useCustomUnit:
│   │           │   └─ DropdownButtonFormField: Unit
│   │           └─ ELSE:
│   │               └─ InputDecorator: Display default unit
│   │
│   ├─ [4] IF Database: Checkbox + Label (lines 559-579)
│   │   └─ "Override default unit"
│   │
│   └─ [5] TextFormField: Preparation Notes (lines 582-593)
│
└─ Actions
    ├─ TextButton: "Cancel"
    └─ ElevatedButton: "Add" or "Save Changes"
```

## Problem Areas Identified

### 1. Cognitive Load - SegmentedButton (lines 308-333)
- Takes 26 lines of code
- Always visible despite 1% use case
- Creates false equivalence between common (database) and rare (custom) flows

### 2. Confusing Search UX (lines 380-437)
- **Two separate fields**: Search + Dropdown
- Not obvious that search filters dropdown
- Search field has no visual feedback
- Dropdown shows all items if search empty

### 3. Complex Unit Override (lines 449-579)
- **Conditional rendering**: 3 different UI states for unit field
- **Checkbox requirement**: Extra step for simple task
- **Lines of code**: 130 lines for quantity + unit section
- **State management**: _useCustomUnit flag adds complexity

### 4. "Create New" Button Placement (lines 439-444)
- Sits between search and quantity fields
- Breaks visual flow
- Not contextual to search results

### 5. State Complexity
- **7 controllers**: 4 TextEditingControllers + 3 state variables
- **4 boolean flags**: _isLoading, _isSaving, _isCustomIngredient, _useCustomUnit
- **Multiple conditional renders**: IF _isCustomIngredient, IF _useCustomUnit, etc.

## Current Localization Strings

### Used in Dialog (lib/l10n/app_en.arb)
```json
"addIngredient": "Add Ingredient"
"editIngredient": "Edit Ingredient"
"fromDatabase": "From Database"                    // TO REMOVE
"custom": "Custom"                                  // TO REMOVE
"searchIngredients": "Search ingredients..."        // TO MODIFY
"typeToSearch": "Type to search..."                 // TO MODIFY
"selectIngredient": "Select Ingredient"             // TO MODIFY
"createNewIngredient": "Create New Ingredient"      // TO MODIFY
"ingredientName": "Ingredient Name"
"categoryLabel": "Category"
"quantity": "Quantity"
"unit": "Unit"
"unitOptional": "Unit (Optional)"
"noUnit": "No unit"
"overrideDefaultUnit": "Override default unit"      // TO REMOVE
"preparationNotesOptional": "Preparation Notes (Optional)"
"preparationNotesHint": "e.g., finely chopped, diced, etc."
"pleaseSelectAnIngredient": "Please select an ingredient"
"pleaseEnterIngredientName": "Please enter an ingredient name"
"pleaseEnterQuantity": "Please enter a quantity"
"pleaseEnterValidNumber": "Please enter a valid number"
"cancel": "Cancel"
"add": "Add"
"saveChanges": "Save Changes"
```

### New Strings Needed
```json
"searchOrCreateIngredient": "Search or create ingredient..."
"createNewWithTerm": "Create '{term}' as new"      // Parameterized
"useCustomIngredient": "Use custom ingredient"
```

## Dependencies

### Direct Imports
```dart
flutter/material.dart
../models/recipe.dart
../models/ingredient.dart
../models/recipe_ingredient.dart
../models/measurement_unit.dart
../models/ingredient_category.dart
../database/database_helper.dart
add_new_ingredient_dialog.dart
../utils/id_generator.dart
../core/errors/gastrobrain_exceptions.dart
../core/validators/entity_validator.dart
../core/services/snackbar_service.dart
../l10n/app_localizations.dart
../core/di/service_provider.dart
```

### Called By
- `lib/screens/add_recipe_screen.dart` (line 1)
- `lib/screens/recipe_ingredients_screen.dart` (line 7)

### Calls
- `AddNewIngredientDialog` (lines 268-282)
- `DatabaseHelper.getAllIngredients()` (line 238)
- `DatabaseHelper.addIngredientToRecipe()` (line 178)
- `DatabaseHelper.updateRecipeIngredient()` (line 175)
- `EntityValidator.validateRecipeIngredient()` (lines 150-154)
- `SnackbarService.showError()` (multiple locations)
- `IdGenerator.generateId()` (line 135)

## Key Insights for Refactoring

1. **State can be simplified**: Remove _isCustomIngredient early, remove _useCustomUnit entirely
2. **Search + Dropdown can merge**: Use Autocomplete widget with custom results builder
3. **Unit field can be always visible**: Pre-fill with default, detect changes at save time
4. **Custom mode can be hidden**: Progressive disclosure via bottom link
5. **Create New can be contextual**: Show in search results instead of separate button
6. **Existing logic is sound**: Save flow, validation, error handling are all good
7. **API is stable**: Constructor params, onSave callback don't need to change

## Risk Mitigation

### Low Risk Changes
- Removing SegmentedButton (isolated component)
- Removing Checkbox (isolated component)
- Adding new localization strings (additive)

### Medium Risk Changes
- Merging search + dropdown (new component architecture)
- Always-visible unit dropdown (changes conditional logic)
- Progressive disclosure for custom (changes layout flow)

### Testing Strategy
- Keep all existing test scenarios
- Add tests for new autocomplete behavior
- Test edit mode extensively (most complex state)
- Manual testing on real device for UX validation
