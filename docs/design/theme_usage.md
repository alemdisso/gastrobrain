# Gastrobrain Theme Usage Guide

> **Document Purpose:** Guide for developers on how to use the Gastrobrain theme system for consistent, maintainable UI implementation.

**Status:** Active Reference Document
**Created:** 2026-01-30
**Related:** [Visual Identity](visual_identity.md) | [Design Tokens](design_tokens.md) | [Issue #257](https://github.com/alemdisso/gastrobrain/issues/257)

---

## Overview

Gastrobrain uses a centralized theme system built on Flutter's ThemeData and Material Design 3. This ensures all UI elements follow the visual identity (warm, confident, cultured, clear, regionally rooted) automatically.

**Key Files:**
- `lib/core/theme/design_tokens.dart` - Token constants
- `lib/core/theme/app_theme.dart` - ThemeData configuration
- `lib/main.dart` - Theme application

---

## Quick Start

### Accessing Theme Values

**Always use `Theme.of(context)` to access theme values:**

```dart
import 'package:flutter/material.dart';

// ✅ CORRECT: Use theme
Text(
  'Recipe Title',
  style: Theme.of(context).textTheme.titleLarge,
)

Container(
  color: Theme.of(context).colorScheme.primary,
  child: child,
)

// ❌ INCORRECT: Hardcoded values
Text(
  'Recipe Title',
  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
)

Container(
  color: Colors.blue,
  child: child,
)
```

### Accessing Design Tokens Directly

**For spacing, border radius, and other non-themed values, use `DesignTokens`:**

```dart
import 'package:gastrobrain/core/theme/design_tokens.dart';

// Spacing
Padding(
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: child,
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
  ),
)

// Custom shadows
Container(
  decoration: BoxDecoration(
    boxShadow: DesignTokens.shadowLevel1,
  ),
)
```

---

## Common Patterns

### Colors

**Use ColorScheme instead of hardcoded colors:**

```dart
// Primary color for main actions
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  ),
  child: Text('Save'),
)

// Secondary/accent color for alternative actions
Container(
  color: Theme.of(context).colorScheme.secondary,
)

// Surface colors for cards and elevated elements
Card(
  color: Theme.of(context).colorScheme.surface,
)

// Semantic colors
Container(
  color: DesignTokens.success, // Success states
  // or DesignTokens.warning, DesignTokens.error, DesignTokens.info
)

// Text colors
Text(
  'Main content',
  style: TextStyle(color: DesignTokens.textPrimary),
)

Text(
  'Supporting text',
  style: TextStyle(color: DesignTokens.textSecondary),
)
```

### Typography

**Use TextTheme for all text styling:**

```dart
// Screen titles
Text(
  AppLocalizations.of(context)!.recipesTitle,
  style: Theme.of(context).textTheme.headlineLarge,
)

// Section headings
Text(
  'Ingredients',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Card titles
Text(
  recipe.name,
  style: Theme.of(context).textTheme.titleLarge,
)

// Body text
Text(
  recipe.description,
  style: Theme.of(context).textTheme.bodyMedium,
)

// Metadata/supporting text
Text(
  '${recipe.prepTime} min',
  style: Theme.of(context).textTheme.bodySmall,
)

// Labels and hints
Text(
  'Optional',
  style: Theme.of(context).textTheme.labelSmall,
)
```

**Customizing text styles (when needed):**

```dart
// Override specific properties with copyWith
Text(
  'Important',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontWeight: DesignTokens.weightBold,
    color: DesignTokens.error,
  ),
)
```

### Spacing

**Use DesignTokens spacing scale consistently:**

```dart
// Padding
Padding(
  padding: EdgeInsets.all(DesignTokens.spacingMd), // 16px
  child: child,
)

// Symmetric padding
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: DesignTokens.spacingMd,
    vertical: DesignTokens.spacingSm,
  ),
  child: child,
)

// Component-specific padding
Padding(
  padding: DesignTokens.cardPadding, // Predefined card padding
  child: child,
)

// Spacing between elements
Column(
  children: [
    Widget1(),
    SizedBox(height: DesignTokens.spacingSm), // 8px gap
    Widget2(),
    SizedBox(height: DesignTokens.spacingLg), // 24px gap
    Widget3(),
  ],
)
```

**Spacing Scale Reference:**
- `spacingXXs` (2px) - Very tight (rare)
- `spacingXs` (4px) - Icon gaps
- `spacingSm` (8px) - Small gaps
- `spacingMd` (16px) - Standard spacing ⭐ Most common
- `spacingLg` (24px) - Section spacing
- `spacingXl` (32px) - Major sections
- `spacingXXl` (48px) - Large separations

### Buttons

**Theme automatically styles standard button types:**

```dart
// Primary button (automatically styled)
ElevatedButton(
  onPressed: onPressed,
  child: Text(AppLocalizations.of(context)!.save),
)

// Secondary button (automatically styled)
OutlinedButton(
  onPressed: onPressed,
  child: Text(AppLocalizations.of(context)!.cancel),
)

// Tertiary/text button (automatically styled)
TextButton(
  onPressed: onPressed,
  child: Text(AppLocalizations.of(context)!.learnMore),
)

// Icon button (automatically styled)
IconButton(
  icon: Icon(Icons.edit),
  onPressed: onPressed,
)
```

**Custom button styling (when needed):**

```dart
// Override specific properties
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: DesignTokens.buttonLargePadding, // Larger button
  ),
  onPressed: onPressed,
  child: Text('Important Action'),
)
```

### Cards

**Use themed Card widget:**

```dart
// Basic card (automatically styled with elevation, radius, padding)
Card(
  child: Padding(
    padding: DesignTokens.cardPadding,
    child: Column(
      children: [
        Text('Title', style: Theme.of(context).textTheme.titleLarge),
        Text('Content', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)

// Custom card with Container (for more control)
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
    boxShadow: DesignTokens.shadowLevel1,
    border: Border.all(
      color: DesignTokens.border,
      width: DesignTokens.borderWidthHairline,
    ),
  ),
  padding: DesignTokens.cardPadding,
  child: child,
)
```

### Inputs

**TextFields use themed InputDecoration:**

```dart
// Basic input (automatically styled)
TextField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    hintText: AppLocalizations.of(context)!.recipeNameHint,
  ),
)

// Input with validation error
TextField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.servings,
    errorText: errorMessage, // Automatically styled with error color
  ),
)

// Dropdown (automatically styled)
DropdownButtonFormField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.category,
  ),
  items: items,
  onChanged: onChanged,
)
```

### Dialogs

**Use themed AlertDialog:**

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(AppLocalizations.of(context)!.confirmDelete),
    content: Text(AppLocalizations.of(context)!.confirmDeleteMessage(recipe.name)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(AppLocalizations.of(context)!.cancel),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(AppLocalizations.of(context)!.delete),
      ),
    ],
  ),
);
```

---

## Component Checklist

When creating or updating UI components, ensure:

### ✅ Colors
- [ ] No hardcoded `Colors.blue`, `Colors.red`, etc.
- [ ] Using `Theme.of(context).colorScheme.*` for themed colors
- [ ] Using `DesignTokens.*` for semantic colors (success, warning, error)

### ✅ Typography
- [ ] No hardcoded `fontSize`, `fontWeight` values
- [ ] Using `Theme.of(context).textTheme.*` for all text
- [ ] Using `copyWith()` when specific overrides needed

### ✅ Spacing
- [ ] No random padding/margin values (e.g., `8.5`, `23`, `17`)
- [ ] Using `DesignTokens.spacing*` scale consistently
- [ ] Using predefined padding constants for common components

### ✅ Borders & Shapes
- [ ] Using `DesignTokens.borderRadius*` for consistent rounding
- [ ] Using `DesignTokens.borderWidth*` for borders
- [ ] No arbitrary border radius values

### ✅ Shadows & Elevation
- [ ] Using `DesignTokens.elevation*` for Material elevation
- [ ] Using `DesignTokens.shadow*` for custom BoxShadow
- [ ] Appropriate elevation level for component hierarchy

### ✅ Icons
- [ ] Using `DesignTokens.iconSize*` for icon sizing
- [ ] Consistent icon sizes within similar contexts

---

## Best Practices

### DO ✅

1. **Always use Theme.of(context)**
   ```dart
   color: Theme.of(context).colorScheme.primary
   ```

2. **Use design tokens for spacing**
   ```dart
   padding: EdgeInsets.all(DesignTokens.spacingMd)
   ```

3. **Use TextTheme for typography**
   ```dart
   style: Theme.of(context).textTheme.headlineMedium
   ```

4. **Leverage predefined component padding**
   ```dart
   padding: DesignTokens.cardPadding
   ```

5. **Use semantic color names**
   ```dart
   color: DesignTokens.success // Instead of "green"
   ```

### DON'T ❌

1. **Hardcode colors**
   ```dart
   color: Colors.blue // ❌
   color: Color(0xFF123456) // ❌ (unless it's in design_tokens.dart)
   ```

2. **Use arbitrary numeric values**
   ```dart
   fontSize: 17.5 // ❌
   padding: EdgeInsets.all(23) // ❌
   borderRadius: BorderRadius.circular(9.3) // ❌
   ```

3. **Mix theme and hardcoded styles**
   ```dart
   Text(
     'Title',
     style: Theme.of(context).textTheme.titleLarge?.copyWith(
       color: Colors.blue, // ❌ Use theme color
     ),
   )
   ```

4. **Create one-off spacing values**
   ```dart
   SizedBox(height: 18) // ❌ Use spacingMd (16) or spacingLg (24)
   ```

5. **Skip Theme.of(context) for "convenience"**
   ```dart
   // ❌ Creates inconsistency
   final primaryColor = Color(0xFFD97706);

   // ✅ Always go through theme
   final primaryColor = Theme.of(context).colorScheme.primary;
   ```

---

## Testing Theme Usage

### Widget Tests

Wrap test widgets with `MaterialApp` and theme:

```dart
testWidgets('widget uses theme correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: MyWidget()),
    ),
  );

  // Test that theme colors are applied
  final container = tester.widget<Container>(find.byType(Container));
  expect(container.color, DesignTokens.primary);
});
```

### Visual Testing

- Test on different screen sizes (small, standard, large)
- Verify text is readable (contrast ratios)
- Check Portuguese text doesn't overflow (20-30% longer)
- Ensure touch targets are ≥44px

---

## Common Scenarios

### Scenario: Creating a New Screen

```dart
class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Automatically themed
        title: Text(AppLocalizations.of(context)!.screenTitle),
      ),
      body: Padding(
        padding: DesignTokens.screenPadding, // Standard screen padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section heading
            Text(
              'Section Title',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: DesignTokens.spacingMd),

            // Card
            Card(
              child: Padding(
                padding: DesignTokens.cardPadding,
                child: Text(
                  'Card content',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Scenario: Custom Styled Widget

```dart
class CustomRecipeCard extends StatelessWidget {
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        boxShadow: DesignTokens.shadowLevel1,
      ),
      padding: DesignTokens.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            recipe.name,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DesignTokens.spacingSm),

          // Metadata
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textSecondary,
              ),
              SizedBox(width: DesignTokens.spacingXs),
              Text(
                '${recipe.prepTime} min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Migration Guide

### Updating Existing Widgets

**Step 1:** Identify hardcoded values
```dart
// Before
Container(
  color: Colors.blue,
  padding: EdgeInsets.all(16),
  child: Text(
    'Title',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
)
```

**Step 2:** Replace with theme values
```dart
// After
Container(
  color: Theme.of(context).colorScheme.primary,
  padding: EdgeInsets.all(DesignTokens.spacingMd),
  child: Text(
    'Title',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)
```

**Step 3:** Test the changes
- Run `flutter analyze` (no errors)
- Run `flutter test` (all tests pass)
- Visual inspection on device/simulator

---

## Troubleshooting

### Theme values not applying?

**Issue:** Widget shows default Material colors instead of Gastrobrain theme.

**Solution:** Ensure your widget is wrapped in MaterialApp with theme:
```dart
MaterialApp(
  theme: AppTheme.lightTheme, // ✅
  home: MyWidget(),
)
```

### Can't access Theme.of(context)?

**Issue:** `Theme.of(context)` returns null or default values.

**Solution:** Widget must be a descendant of MaterialApp. Move the MaterialApp higher in the tree or use `Builder`:
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  home: Builder(
    builder: (context) => MyWidget(), // Now has theme context
  ),
)
```

### Colors look different than design tokens?

**Issue:** Colors don't match design_tokens.md specification.

**Solution:** Verify you're using the correct color:
- `colorScheme.primary` → DesignTokens.primary (#D97706)
- `colorScheme.secondary` → DesignTokens.accent (#059669)
- Check if deprecated `Colors.*` is being used

---

## Reference

### Quick Token Reference

**Colors:**
- Primary: Warm amber (#D97706)
- Secondary: Herb green (#059669)
- Surface: White (#FFFFFF)
- Background: Warm white (#FAFAF9)

**Typography Sizes:**
- Display: 32sp
- Heading 1: 24sp
- Heading 2: 20sp
- Heading 3: 18sp
- Body Large: 16sp
- Body: 14sp ⭐ Default
- Body Small: 12sp
- Caption: 11sp

**Spacing:**
- XXS: 2px
- XS: 4px
- SM: 8px
- MD: 16px ⭐ Most common
- LG: 24px
- XL: 32px
- XXL: 48px

**Border Radius:**
- Small: 8px
- Medium: 12px ⭐ Default
- Large: 16px
- XLarge: 20px

---

**Last Updated:** 2026-01-30
**Maintainer:** Gastrobrain Development Team
**Related Issues:** [#257 - Implement ThemeData Configuration](https://github.com/alemdisso/gastrobrain/issues/257)
