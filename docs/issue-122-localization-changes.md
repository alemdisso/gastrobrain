# Issue #122: Localization String Changes

## Strings to Remove

These strings will no longer be used after refactoring:

### English (app_en.arb)
```json
"fromDatabase": "From Database",
"custom": "Custom",
"overrideDefaultUnit": "Override default unit",
```

### Portuguese (app_pt.arb)
```json
"fromDatabase": "Do Banco de Dados",
"custom": "Personalizado",
"overrideDefaultUnit": "Substituir unidade padrão",
```

## Strings to Add

### New: searchOrCreateIngredient
**Purpose**: Unified search field placeholder

**English (app_en.arb)**
```json
"searchOrCreateIngredient": "Search or create ingredient...",
"@searchOrCreateIngredient": {
  "description": "Placeholder for unified ingredient search field"
},
```

**Portuguese (app_pt.arb)**
```json
"searchOrCreateIngredient": "Buscar ou criar ingrediente...",
"@searchOrCreateIngredient": {
  "description": "Placeholder for unified ingredient search field"
},
```

### New: createAsNew
**Purpose**: Contextual "create new" option in search results (parameterized)

**English (app_en.arb)**
```json
"createAsNew": "Create \"{term}\" as new",
"@createAsNew": {
  "description": "Option to create a new ingredient from search term",
  "placeholders": {
    "term": {
      "type": "String",
      "example": "tomato"
    }
  }
},
```

**Portuguese (app_pt.arb)**
```json
"createAsNew": "Criar \"{term}\" como novo",
"@createAsNew": {
  "description": "Option to create a new ingredient from search term",
  "placeholders": {
    "term": {
      "type": "String",
      "example": "tomate"
    }
  }
},
```

### New: useCustomIngredient
**Purpose**: Bottom link for progressive disclosure of custom ingredient mode

**English (app_en.arb)**
```json
"useCustomIngredient": "Use custom ingredient",
"@useCustomIngredient": {
  "description": "Link to switch to custom ingredient mode"
},
```

**Portuguese (app_pt.arb)**
```json
"useCustomIngredient": "Usar ingrediente personalizado",
"@useCustomIngredient": {
  "description": "Link to switch to custom ingredient mode"
},
```

### New: ingredientLabel
**Purpose**: Label for the unified search/autocomplete field

**English (app_en.arb)**
```json
"ingredientLabel": "Ingredient",
"@ingredientLabel": {
  "description": "Label for ingredient selection field"
},
```

**Portuguese (app_pt.arb)**
```json
"ingredientLabel": "Ingrediente",
"@ingredientLabel": {
  "description": "Label for ingredient selection field"
},
```

## Strings to Keep (No Changes)

These strings remain in use with current wording:

```
✓ addIngredient: "Add Ingredient" / "Adicionar Ingrediente"
✓ editIngredient: "Edit Ingredient" / "Editar Ingrediente"
✓ ingredientName: "Ingredient Name" / "Nome do Ingrediente"
✓ categoryLabel: "Category" / "Categoria"
✓ quantity: "Quantity" / "Quantidade"
✓ unit: "Unit" / "Unidade"
✓ unitOptional: "Unit (Optional)" / "Unidade (Opcional)"
✓ noUnit: "No unit" / "Sem unidade"
✓ preparationNotesOptional: "Preparation Notes (Optional)" / "Notas de Preparo (Opcional)"
✓ preparationNotesHint: "e.g., finely chopped, diced, etc." / "ex: picado, em cubos, etc."
✓ pleaseSelectAnIngredient: "Please select an ingredient" / "Por favor, selecione um ingrediente"
✓ pleaseEnterIngredientName: "Please enter an ingredient name" / "Por favor, insira o nome do ingrediente"
✓ pleaseEnterQuantity: "Please enter a quantity" / "Por favor, insira a quantidade"
✓ pleaseEnterValidNumber: "Please enter a valid number" / "Por favor, insira um número válido"
✓ cancel: "Cancel" / "Cancelar"
✓ add: "Add" / "Adicionar"
✓ saveChanges: "Save Changes" / "Salvar Alterações"
```

## Strings That May Be Modified (TBD)

These strings might need rewording depending on final implementation:

### searchIngredients
**Current**: "Search ingredients..." / "Buscar ingredientes..."
**Consideration**: May be replaced by `searchOrCreateIngredient`
**Decision**: Keep for now, can deprecate later

### typeToSearch
**Current**: "Type to search..." / "Digite para buscar..."
**Consideration**: May be replaced by `searchOrCreateIngredient`
**Decision**: Keep for now, can deprecate later

### selectIngredient
**Current**: "Select Ingredient" / "Selecionar Ingrediente"
**Consideration**: May not be needed if using autocomplete
**Decision**: Keep for now, might be used as label or hint

### createNewIngredient
**Current**: "Create New Ingredient" / "Criar Novo Ingrediente"
**Consideration**: Different from `createAsNew` (button vs contextual option)
**Decision**: Keep for `AddNewIngredientDialog` title, use `createAsNew` in results

## Usage in Code

### Current Usage (to be replaced)

```dart
// Line 316
label: Text(AppLocalizations.of(context)!.fromDatabase),  // REMOVE

// Line 320
label: Text(AppLocalizations.of(context)!.custom),        // REMOVE

// Line 387
labelText: AppLocalizations.of(context)!.searchIngredients,  // KEEP or REPLACE

// Line 392
hintText: AppLocalizations.of(context)!.typeToSearch,        // KEEP or REPLACE

// Line 404
labelText: AppLocalizations.of(context)!.selectIngredient,   // KEEP or REPLACE

// Line 442
label: Text(AppLocalizations.of(context)!.createNewIngredient),  // REPLACE

// Line 575
Text(AppLocalizations.of(context)!.overrideDefaultUnit),  // REMOVE
```

### New Usage (after refactoring)

```dart
// Unified search field
TextField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.ingredientLabel,
    hintText: AppLocalizations.of(context)!.searchOrCreateIngredient,
    prefixIcon: Icon(Icons.search),
  ),
)

// In autocomplete results builder
Text(AppLocalizations.of(context)!.createAsNew(searchTerm))

// Bottom link
TextButton.icon(
  icon: Icon(Icons.settings),
  label: Text(AppLocalizations.of(context)!.useCustomIngredient),
)
```

## Implementation Checklist

### Phase 2: Localization Updates

- [ ] Add new strings to `lib/l10n/app_en.arb`:
  - [ ] `searchOrCreateIngredient`
  - [ ] `createAsNew` (with placeholder)
  - [ ] `useCustomIngredient`
  - [ ] `ingredientLabel`

- [ ] Add new strings to `lib/l10n/app_pt.arb`:
  - [ ] `searchOrCreateIngredient`
  - [ ] `createAsNew` (with placeholder)
  - [ ] `useCustomIngredient`
  - [ ] `ingredientLabel`

- [ ] Run `flutter gen-l10n` to generate localization code

- [ ] Verify generated files in `.dart_tool/flutter_gen/gen_l10n/`

- [ ] Test parameterized string usage:
  ```dart
  AppLocalizations.of(context)!.createAsNew("tomate")
  // Should output: "Criar \"tomate\" como novo" (pt)
  // Should output: "Create \"tomate\" as new" (en)
  ```

- [ ] Mark deprecated strings (optional, for documentation):
  - [ ] Add comment in ARB: "DEPRECATED: Use searchOrCreateIngredient"
  - [ ] Consider removal in future PR after validation

- [ ] Run `flutter analyze` to check for any localization errors

## Notes

### Parameterized Strings in Flutter
Flutter's localization system supports named placeholders using `{name}` syntax.

**ARB Definition:**
```json
"createAsNew": "Create \"{term}\" as new",
"@createAsNew": {
  "placeholders": {
    "term": {
      "type": "String"
    }
  }
}
```

**Usage in Code:**
```dart
AppLocalizations.of(context)!.createAsNew(searchTerm)
```

### String Removal Strategy
Rather than immediately removing deprecated strings, consider:
1. Add new strings and use them in refactored code
2. Leave old strings in place but unused
3. Verify app works correctly with new strings
4. Remove deprecated strings in a follow-up commit (easy rollback)

This provides safety net if we need to reference old implementation.
