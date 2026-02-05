# Input Patterns for Gastrobrain

This document describes standardized form input patterns used throughout Gastrobrain. All inputs follow the centralized theme configuration and design tokens, ensuring consistent visual styling without custom decoration overrides.

## Core Principle: Theme-First Approach

**All form inputs automatically inherit styling from the theme.** Do NOT override visual properties like borders, colors, or padding. The theme (`InputDecorationTheme`) handles all visual aspects consistently.

**What to specify:**
- Semantic properties: `labelText`, `hintText`, `prefixIcon`, `suffixText`, `helperText`
- Behavior: `validator`, `keyboardType`, `maxLines`, `onChanged`

**What NOT to specify:**
- Visual styling: `border`, `fillColor`, `borderRadius`, `contentPadding`
- The theme handles these automatically

---

## Input Types

### TextFormField (Form Text Inputs)

**Use for:** Text inputs within a `Form` widget that require validation.

**Automatically applied by theme:**
- Outlined border with rounded corners (8dp)
- Border colors for all states (default, focused, error, disabled)
- Label and hint text styling
- Error message styling
- Content padding
- Fill color

**Example:**
```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    // NO border property - theme applies it automatically
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterRecipeName;
    }
    return null;
  },
)
```

**With additional semantic properties:**
```dart
TextFormField(
  controller: _notesController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.notes,
    hintText: AppLocalizations.of(context)!.enterNotesHere,
    helperText: AppLocalizations.of(context)!.optional,
    // Theme handles all visual styling
  ),
  maxLines: 3,
  keyboardType: TextInputType.multiline,
)
```

**Number input with suffix:**
```dart
TextFormField(
  controller: _prepTimeController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.preparationTime,
    suffixText: AppLocalizations.of(context)!.minutes,
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      final minutes = int.tryParse(value);
      if (minutes == null || minutes < 0) {
        return AppLocalizations.of(context)!.pleaseEnterValidTime;
      }
    }
    return null;
  },
)
```

**Common uses:**
- Recipe/ingredient names
- Notes and descriptions
- Numeric inputs (time, servings, quantities)
- Multi-line text areas

---

### TextField (Standalone Text Inputs)

**Use for:** Text inputs outside of forms, typically for search or filtering.

**Difference from TextFormField:**
- Not tied to a `Form` widget
- No built-in validation (use `onChanged` for custom validation)
- Lighter weight for simple inputs

**Example (search field):**
```dart
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.searchRecipes,
    hintText: AppLocalizations.of(context)!.searchByName,
    prefixIcon: const Icon(Icons.search),
    // Theme applies borders and styling
  ),
  onChanged: (value) {
    setState(() {
      _searchQuery = value;
    });
  },
)
```

**Common uses:**
- Search fields
- Filter inputs
- Non-validated text entry
- Real-time input (onChanged behavior)

---

### DropdownButtonFormField (Form Dropdowns)

**Use for:** Dropdown selectors within forms with validation.

**Automatically applied by theme:**
- Same InputDecoration styling as TextFormField
- Borders, padding, label styling all from theme

**Example:**
```dart
DropdownButtonFormField<FrequencyType>(
  value: _selectedFrequency,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.desiredFrequency,
    // Theme applies all visual styling
  ),
  items: frequencies.map((frequency) {
    return DropdownMenuItem<FrequencyType>(
      value: frequency,
      child: Text(frequency.getLocalizedDisplayName(context)),
    );
  }).toList(),
  onChanged: (FrequencyType? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFrequency = newValue;
      });
    }
  },
)
```

**Common uses:**
- Category selection
- Frequency selection
- Unit selection
- Enum value selection

---

## Input States

All input states are automatically styled by the theme:

### Default State
- Border: Light gray (`DesignTokens.border`)
- Fill: Surface color (`DesignTokens.surface`)
- Label: Secondary text color

### Focused State
- Border: Primary color, slightly thicker (`DesignTokens.primary`, 1dp)
- Label: Primary color
- Clear visual feedback for active input

### Error State
- Border: Error red (`DesignTokens.error`)
- Error message displayed below input
- Error text styled automatically

### Disabled State
- Border: Light gray (same as default)
- Reduced opacity
- Visual distinction from enabled inputs

---

## Validation Patterns

### Basic Required Field
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return AppLocalizations.of(context)!.fieldRequired;
  }
  return null;
}
```

### Numeric Validation
```dart
validator: (value) {
  if (value != null && value.isNotEmpty) {
    final number = int.tryParse(value);
    if (number == null || number < 0) {
      return AppLocalizations.of(context)!.pleaseEnterValidNumber;
    }
  }
  return null;
}
```

### Conditional Validation
```dart
validator: (value) {
  // Optional field - no error if empty
  if (value == null || value.isEmpty) {
    return null;
  }

  // But if provided, must be valid
  if (value.length < 3) {
    return AppLocalizations.of(context)!.mustBeAtLeast3Characters;
  }

  return null;
}
```

---

## Accessibility Guidelines

### 1. Labels

**Always provide labels** for form inputs:
```dart
decoration: InputDecoration(
  labelText: AppLocalizations.of(context)!.recipeName, // Required
)
```

Labels automatically:
- Float above input when focused or filled
- Provide context for screen readers
- Meet WCAG accessibility requirements

### 2. Hint Text

Use hint text to provide examples or additional guidance:
```dart
decoration: InputDecoration(
  labelText: AppLocalizations.of(context)!.ingredientName,
  hintText: AppLocalizations.of(context)!.exampleTomato, // Optional guidance
)
```

### 3. Helper Text

Use helper text for persistent guidance:
```dart
decoration: InputDecoration(
  labelText: AppLocalizations.of(context)!.notes,
  helperText: AppLocalizations.of(context)!.optional, // Persistent guidance
)
```

### 4. Error Messages

Error messages should be:
- Clear and actionable
- Localized
- Specific to the validation failure

```dart
// Good error messages
return AppLocalizations.of(context)!.pleaseEnterRecipeName;
return AppLocalizations.of(context)!.mustBePositiveNumber;

// Bad error messages (avoid these)
return 'Invalid';
return 'Error';
```

### 5. Contrast Requirements

All input styling meets **WCAG AA contrast requirements**:
- Text to background: >4.5:1
- Border to background: >3:1
- Focus indicators clearly visible

---

## Common Patterns

### Form with Multiple Inputs
```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.recipeName,
        ),
        validator: (value) => value?.isEmpty == true
            ? AppLocalizations.of(context)!.required
            : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<RecipeCategory>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.category,
        ),
        items: categories.map((cat) => DropdownMenuItem(
          value: cat,
          child: Text(cat.getLocalizedDisplayName(context)),
        )).toList(),
        onChanged: (value) => setState(() => _selectedCategory = value),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.notes,
          helperText: AppLocalizations.of(context)!.optional,
        ),
        maxLines: 3,
      ),
    ],
  ),
)
```

### Search Field Pattern
```dart
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.search,
    hintText: AppLocalizations.of(context)!.searchByName,
    prefixIcon: const Icon(Icons.search),
    suffixIcon: _searchQuery.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
        : null,
  ),
  onChanged: (value) => setState(() => _searchQuery = value),
)
```

### Number Input with Constraints
```dart
TextFormField(
  controller: _servingsController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.servings,
    suffixText: AppLocalizations.of(context)!.people,
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    final servings = int.tryParse(value ?? '');
    if (servings == null || servings < 1) {
      return AppLocalizations.of(context)!.mustBeAtLeast1;
    }
    if (servings > 100) {
      return AppLocalizations.of(context)!.mustBeLessThan100;
    }
    return null;
  },
)
```

---

## Anti-Patterns (Don't Do This)

### ❌ Custom Border Styling

```dart
// DON'T - Override theme borders
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    border: const OutlineInputBorder(), // Remove this!
    enabledBorder: OutlineInputBorder(...), // Remove this!
    focusedBorder: OutlineInputBorder(...), // Remove this!
  ),
)

// DO - Let theme handle styling
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    // Theme applies borders automatically
  ),
)
```

### ❌ Custom Colors

```dart
// DON'T - Custom colors
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    fillColor: Colors.grey[100], // Remove this!
    labelStyle: TextStyle(color: Colors.blue), // Remove this!
  ),
)

// DO - Use theme colors
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    // Theme applies colors automatically
  ),
)
```

### ❌ Missing Labels

```dart
// DON'T - No label
TextFormField(
  hintText: 'Enter name', // Hint alone is not accessible
)

// DO - Always provide label
TextFormField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.name,
    hintText: AppLocalizations.of(context)!.enterNameHint,
  ),
)
```

### ❌ Hardcoded Strings

```dart
// DON'T - Hardcoded strings
TextFormField(
  decoration: InputDecoration(
    labelText: 'Recipe Name', // Not localized!
  ),
)

// DO - Use localized strings
TextFormField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
  ),
)
```

### ❌ Generic Error Messages

```dart
// DON'T - Generic errors
validator: (value) {
  if (value?.isEmpty == true) {
    return 'Invalid'; // Not helpful!
  }
  return null;
}

// DO - Specific, actionable errors
validator: (value) {
  if (value?.isEmpty == true) {
    return AppLocalizations.of(context)!.pleaseEnterRecipeName;
  }
  return null;
}
```

---

## Testing Input Patterns

When testing form inputs, verify:

1. **Visual appearance**: Inputs display with correct theme styling
2. **States**: All states (default, focused, error, disabled) work correctly
3. **Validation**: Error messages display and clear properly
4. **Accessibility**: Labels and hints are present and readable
5. **Localization**: All text is properly localized
6. **Keyboard behavior**: Appropriate keyboards appear for input type

---

## Migration Guide

When updating existing inputs to use theme patterns:

### Before (Custom Styling)
```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    border: const OutlineInputBorder(), // Remove this line
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey), // Remove this
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue), // Remove this
    ),
  ),
  validator: (value) => /* ... */,
)
```

### After (Theme Styling)
```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    // Border styling removed - theme applies it automatically
  ),
  validator: (value) => /* ... */,
)
```

**Steps:**
1. Remove `border` property
2. Remove all border variant properties (`enabledBorder`, `focusedBorder`, etc.)
3. Remove `fillColor` if present
4. Keep semantic properties (`labelText`, `hintText`, `prefixIcon`, etc.)
5. Test to verify theme styling applies correctly

---

## Reference

- **Theme Configuration**: `lib/core/theme/app_theme.dart` (lines 255-314: `inputDecorationTheme`)
- **Design Tokens**: `lib/core/theme/design_tokens.dart`
- **Button Patterns**: `docs/design/button_patterns.md`
- **Visual Identity**: `docs/design/visual_identity.md`

---

## Summary

**Key Principles:**
1. **Never override visual styling** - the theme handles it
2. **Always provide labels** - essential for accessibility
3. **Use localized strings** - all text must support i18n
4. **Provide clear validation** - specific, actionable error messages
5. **Choose the right input type** - TextFormField for forms, TextField for search/filter
6. **Trust the theme** - consistent styling across the entire app
