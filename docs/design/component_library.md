# Gastrobrain UI Component Library

> **Document Purpose:** Central reference for all UI components, patterns, and visual guidelines in Gastrobrain. Use this document as the starting point for any UI implementation work.

**Status:** Active Reference Document
**Created:** 2026-03-21
**Issue:** [#263 - Create UI Component Library Documentation](https://github.com/alemdisso/gastrobrain/issues/263)
**Milestone:** 0.1.14 - DB Housekeeping & Documentation

---

## Quick Reference

| Need | Go To |
|------|-------|
| Colors, spacing, typography constants | [Design Tokens](design-tokens.md) |
| Visual personality and principles | [Visual Identity](visual_identity.md) |
| How to use the Flutter theme system | [Theme Usage](theme_usage.md) |
| Buttons (all types) | [Button Patterns](#buttons) |
| Form inputs, dropdowns | [Input Patterns](#form-inputs) |
| Cards (meal, recipe) | [Cards](#cards) |
| AppBar, TabBar, BottomNav | [Navigation](#navigation-elements) |
| Typography examples | [Typography](#typography) |
| Color usage | [Colors](#colors) |
| Spacing system | [Spacing](#spacing) |

---

## Core Principle: Theme-First

**The theme handles visual styling automatically.** Do NOT override colors, borders, or typography inline. Specify only semantic properties (labels, validators, icons) and let `AppTheme.lightTheme` do the rest.

| Do | Don't |
|----|-------|
| `ElevatedButton(child: Text('Save'))` | `ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange))` |
| `TextFormField(decoration: InputDecoration(labelText: l10n.name))` | `TextFormField(decoration: InputDecoration(border: OutlineInputBorder()))` |
| `AppBar(title: Text(l10n.title))` | `AppBar(backgroundColor: Colors.white, titleTextStyle: TextStyle(...))` |

---

## Buttons

Full reference: [button_patterns.md](button_patterns.md)

### Hierarchy Overview

| Type | Widget | Use For |
|------|--------|---------|
| Primary | `ElevatedButton` | Main action (save, confirm, primary CTA) |
| Secondary | `TextButton` | Cancel, navigation, secondary options |
| Alternative | `OutlinedButton` | Actions between primary and secondary emphasis |
| Icon | `IconButton` | Compact actions, toolbar, list item actions |
| Destructive | `ButtonStyles.destructive` | Delete, discard — after confirmation |

### Primary Button

```dart
ElevatedButton(
  onPressed: () => _saveRecipe(),
  child: Text(AppLocalizations.of(context)!.save),
)
```

- Background: `DesignTokens.primary` (warm amber)
- Text: white
- Border radius: 8dp
- Min touch target: 48×48dp

### Secondary Button

```dart
TextButton(
  onPressed: () => Navigator.pop(context),
  child: Text(AppLocalizations.of(context)!.cancel),
)
```

- Background: transparent
- Text: `DesignTokens.primary`

### Outlined Button

```dart
OutlinedButton(
  onPressed: () => _viewDetails(),
  child: Text(AppLocalizations.of(context)!.viewDetails),
)
```

### Icon Button

```dart
IconButton(
  icon: const Icon(Icons.edit),
  onPressed: () => _editItem(),
  tooltip: AppLocalizations.of(context)!.edit,  // Required
)
```

**Always include `tooltip`** for accessibility.

### Destructive Buttons

```dart
import 'package:gastrobrain/core/theme/button_styles.dart';

// Primary destructive (confirmed delete)
ElevatedButton(
  onPressed: () => _deleteRecipe(),
  style: ButtonStyles.destructive,
  child: Text(AppLocalizations.of(context)!.delete),
)

// Secondary destructive (discard changes)
TextButton(
  onPressed: () => _discardChanges(),
  style: ButtonStyles.destructiveText,
  child: Text(AppLocalizations.of(context)!.discard),
)
```

**Rule:** Always confirm before executing destructive actions:

```dart
if (await context.confirmDestructiveAction(
  title: AppLocalizations.of(context)!.deleteRecipe,
  message: AppLocalizations.of(context)!.deleteRecipeConfirm(recipe.name),
  confirmLabel: AppLocalizations.of(context)!.delete,
)) {
  await _deleteRecipe();
}
```

### Common Button Patterns

**Dialog actions (standard):**
```dart
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text(AppLocalizations.of(context)!.cancel),
  ),
  ElevatedButton(
    onPressed: () { /* action */ Navigator.pop(context); },
    child: Text(AppLocalizations.of(context)!.confirm),
  ),
],
```

**Form save/cancel:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(AppLocalizations.of(context)!.cancel),
    ),
    SizedBox(width: DesignTokens.spacingMd),
    ElevatedButton(
      onPressed: _isValid ? () => _saveForm() : null,
      child: Text(AppLocalizations.of(context)!.save),
    ),
  ],
)
```

**List item actions:**
```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(item), tooltip: l10n.edit),
    IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(item), tooltip: l10n.delete),
  ],
)
```

### Anti-Patterns

```dart
// ❌ Custom color overrides
ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue))

// ❌ Multiple primary buttons competing
Row(children: [ElevatedButton(...), ElevatedButton(...), ElevatedButton(...)])

// ❌ Missing tooltip on IconButton
IconButton(icon: Icon(Icons.edit), onPressed: _edit)  // No tooltip!

// ❌ GestureDetector with small tap area
GestureDetector(onTap: _action, child: Container(padding: EdgeInsets.all(4), child: Text('Tap')))
```

---

## Form Inputs

Full reference: [input_patterns.md](input_patterns.md)

### Core Principle: No Visual Overrides

The theme (`InputDecorationTheme`) handles all borders, colors, and padding. Specify only:
- Semantic: `labelText`, `hintText`, `prefixIcon`, `suffixText`, `helperText`
- Behavior: `validator`, `keyboardType`, `maxLines`, `onChanged`

### TextFormField (In-Form Inputs)

```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.recipeName,
    // No border — theme applies it
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterRecipeName;
    }
    return null;
  },
)
```

**With icon and suffix:**
```dart
TextFormField(
  controller: _prepTimeController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.preparationTime,
    prefixIcon: const Icon(Icons.timer_outlined),
    suffixText: AppLocalizations.of(context)!.minutes,
  ),
  keyboardType: TextInputType.number,
)
```

**Multi-line:**
```dart
TextFormField(
  controller: _notesController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.notes,
    helperText: AppLocalizations.of(context)!.optional,
  ),
  maxLines: 3,
  keyboardType: TextInputType.multiline,
)
```

### TextField (Standalone / Search)

```dart
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.search,
    hintText: AppLocalizations.of(context)!.searchByName,
    prefixIcon: const Icon(Icons.search),
    suffixIcon: _query.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () { _searchController.clear(); setState(() => _query = ''); },
          )
        : null,
  ),
  onChanged: (value) => setState(() => _query = value),
)
```

### DropdownButtonFormField

```dart
DropdownButtonFormField<FrequencyType>(
  value: _selectedFrequency,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.desiredFrequency,
  ),
  items: frequencies.map((f) => DropdownMenuItem(
    value: f,
    child: Text(f.getLocalizedDisplayName(context)),
  )).toList(),
  onChanged: (value) { if (value != null) setState(() => _selectedFrequency = value); },
)
```

### Input States (Auto-applied by Theme)

| State | Border | Label |
|-------|--------|-------|
| Default | `DesignTokens.border` (warm gray) | `textSecondary` |
| Focused | `DesignTokens.primary` (amber) | `primary` |
| Error | `DesignTokens.error` (red) | error red |
| Disabled | Light gray, reduced opacity | — |

### Validation Patterns

```dart
// Required field
validator: (value) => (value == null || value.isEmpty)
    ? AppLocalizations.of(context)!.fieldRequired
    : null;

// Positive integer
validator: (value) {
  final n = int.tryParse(value ?? '');
  if (n == null || n < 1) return AppLocalizations.of(context)!.mustBePositiveNumber;
  return null;
}

// Optional but constrained
validator: (value) {
  if (value == null || value.isEmpty) return null; // Optional
  if (value.length < 3) return AppLocalizations.of(context)!.mustBeAtLeast3Characters;
  return null;
}
```

### Anti-Patterns

```dart
// ❌ Override borders
TextFormField(decoration: InputDecoration(border: OutlineInputBorder()))

// ❌ Hardcoded colors
TextFormField(decoration: InputDecoration(fillColor: Colors.grey[100]))

// ❌ Hardcoded strings
TextFormField(decoration: InputDecoration(labelText: 'Recipe Name'))

// ❌ Missing label
TextFormField(hintText: 'Enter name')  // Hint alone is not accessible
```

---

## Cards

Cards are the primary container for recipe and meal information.

### Card Anatomy

All cards use:
- Background: `DesignTokens.surface` (white)
- Border radius: `DesignTokens.borderRadiusMedium` (12dp)
- Elevation: Level 1 shadow
- Padding: `DesignTokens.spacingMd` (16dp) all sides (standard) or `DesignTokens.spacingLg` (24dp) for emphasized cards

### Standard Card

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(DesignTokens.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          item.subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  ),
)
```

### Recipe Card

Recipe cards display: name, category/type badge, difficulty, prep time, and frequency info.

```dart
Card(
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.spacingMd,
      vertical: DesignTokens.spacingSm,
    ),
    title: Text(recipe.name, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.category.getLocalizedDisplayName(context),
             style: Theme.of(context).textTheme.bodySmall),
        if (recipe.prepTime != null)
          Row(children: [
            const Icon(Icons.timer_outlined, size: DesignTokens.iconSizeSmall),
            const SizedBox(width: DesignTokens.spacingXs),
            Text('${recipe.prepTime} min', style: Theme.of(context).textTheme.bodySmall),
          ]),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(recipe), tooltip: l10n.edit),
        IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(recipe), tooltip: l10n.delete),
      ],
    ),
    onTap: () => _openDetails(recipe),
  ),
)
```

### Meal Plan Card

Meal plan cards are organized by date and meal type (lunch/dinner), with support for primary dish and optional side dishes.

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(DesignTokens.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: date + meal type
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate, style: Theme.of(context).textTheme.labelLarge),
            Chip(label: Text(mealType.getLocalizedDisplayName(context))),
          ],
        ),
        const Divider(height: DesignTokens.spacingMd),
        // Primary dish
        Text(primaryRecipe.name, style: Theme.of(context).textTheme.titleMedium),
        // Side dishes (if any)
        if (sideDishes.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spacingXs),
          ...sideDishes.map((s) => Text(
            '+ ${s.name}',
            style: Theme.of(context).textTheme.bodySmall,
          )),
        ],
      ],
    ),
  ),
)
```

### Empty State Cards

Use a centered layout with a large icon and helpful message:

```dart
Center(
  child: Padding(
    padding: const EdgeInsets.all(DesignTokens.spacingXXl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: DesignTokens.iconSizeXLarge,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          AppLocalizations.of(context)!.noRecipesFound,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          AppLocalizations.of(context)!.addFirstRecipeHint,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
)
```

---

## Navigation Elements

Full reference: [navigation_patterns.md](navigation_patterns.md)

### Bottom Navigation Bar

The primary navigation element — 4 tabs for main sections.

```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  items: [
    BottomNavigationBarItem(icon: const Icon(Icons.menu_book), label: l10n.recipes),
    BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: l10n.mealPlan),
    BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu), label: l10n.ingredients),
    const BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
  ],
)
```

**Do not add:** `type`, `backgroundColor`, `selectedItemColor`, `unselectedItemColor`, `elevation` — all from theme.

### AppBar

```dart
Scaffold(
  appBar: AppBar(
    title: Text(AppLocalizations.of(context)!.screenTitle),
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: _handleAdd,
        tooltip: AppLocalizations.of(context)!.addTooltip,
      ),
    ],
  ),
  body: ...,
)
```

**Do not add:** `backgroundColor`, `foregroundColor`, `elevation`, `titleTextStyle`.

### TabBar

```dart
appBar: AppBar(
  title: Text(l10n.screenTitle),
  bottom: TabBar(
    controller: _tabController,
    tabs: [
      Tab(icon: const Icon(Icons.list_alt), text: l10n.ingredients),
      Tab(icon: const Icon(Icons.description), text: l10n.instructions),
      Tab(icon: const Icon(Icons.info_outline), text: l10n.overview),
    ],
  ),
),
body: TabBarView(
  controller: _tabController,
  children: [_buildIngredientsTab(), _buildInstructionsTab(), _buildOverviewTab()],
),
```

### Back Button

```dart
// Standard (automatic — no code needed)
AppBar(title: Text(l10n.title))  // Material provides back button automatically

// Custom behavior (returning a value)
AppBar(
  title: Text(l10n.title),
  leading: BackButton(
    onPressed: () => Navigator.pop(context, _returnValue),
  ),
)
```

**Use `BackButton` widget, not `IconButton` with `Icons.arrow_back`.**

---

## Typography

Gastrobrain uses system fonts (San Francisco on iOS, Roboto on Android). Access via `Theme.of(context).textTheme`.

### Text Style Reference

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 32sp | Semibold | Hero headings (rare) |
| `displayLarge` | ~57sp | — | Reserved |
| `headlineLarge` / Heading 1 | 24sp | Semibold | Screen titles |
| `headlineMedium` / Heading 2 | 20sp | Semibold | Section titles, card headings |
| `headlineSmall` / Heading 3 | 18sp | Semibold | Subsection titles |
| `titleLarge` | 22sp | Medium | Large tile titles |
| `titleMedium` | 16sp | Medium | Card titles, emphasized text |
| `titleSmall` | 14sp | Medium | Smaller emphasized text |
| `bodyLarge` | 16sp | Regular | Emphasized body text |
| `bodyMedium` | 14sp | Regular | Main content |
| `bodySmall` | 12sp | Regular | Supporting text, metadata |
| `labelLarge` | 14sp | Medium | Button labels |
| `labelSmall` | 11sp | Regular | Captions, hints |

### Usage Examples

```dart
// Screen title
Text(AppLocalizations.of(context)!.recipes, style: Theme.of(context).textTheme.headlineMedium)

// Card title
Text(recipe.name, style: Theme.of(context).textTheme.titleMedium)

// Supporting metadata
Text('${recipe.prepTime} min', style: Theme.of(context).textTheme.bodySmall)

// Caption / hint
Text(AppLocalizations.of(context)!.optional, style: Theme.of(context).textTheme.labelSmall)
```

### Line Heights

| Use | Multiplier |
|-----|-----------|
| Headings | `1.2` (tight) |
| Body text | `1.5` (normal) |
| Long-form reading | `1.7` (relaxed) |

Portuguese strings tend to be longer — use relaxed line heights for reading-heavy screens.

---

## Colors

Full token definitions: [design-tokens.md](design-tokens.md)

Access via `Theme.of(context).colorScheme` or `DesignTokens` constants.

### Palette Summary

| Category | Token | Hex | Usage |
|----------|-------|-----|-------|
| **Primary** | `primary` | `#D97706` | Main actions, highlights, active states |
| **Primary Dark** | `primaryDark` | `#B45309` | Pressed/hover emphasis |
| **Accent** | `accent` | `#059669` | Success, fresh elements, secondary actions |
| **Background** | `background` | `#FAFAF9` | Main screen background |
| **Surface** | `surface` | `#FFFFFF` | Cards, elevated elements |
| **Surface Variant** | `surfaceVariant` | `#F5F5F4` | Subtle backgrounds, sections |
| **Border** | `border` | `#E7E5E4` | Dividers, card borders |
| **Text Primary** | `textPrimary` | `#1C1917` | Main content, headings |
| **Text Secondary** | `textSecondary` | `#57534E` | Supporting text, metadata |
| **Text Tertiary** | `textTertiary` | `#78716C` | Hints, captions |
| **Error** | `error` | `#DC2626` | Errors, destructive actions |
| **Warning** | `warning` | `#EA580C` | Cautions, attention needed |
| **Success** | `success` | `#059669` | Confirmations, completed items |

### Color Usage Guidelines

**Do:**
- Use `primary` for one dominant action per screen
- Use `accent/success` for positive confirmations
- Use `error` only for errors and destructive-action buttons
- Use warm neutrals (`surface`, `surfaceVariant`) for backgrounds

**Don't:**
- Use cold grays (`Colors.grey`) — prefer `DesignTokens.border` / `textTertiary`
- Use `Colors.blue` or any hardcoded Material colors
- Use `primary` for decorative elements (dilutes its semantic meaning)

---

## Spacing

Base unit: **8px**. All spacing values are multiples or derivatives of this unit.

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `spacingXXs` | 2px | Icon padding, very tight spaces |
| `spacingXs` | 4px | Icon gaps, compact spacing |
| `spacingSm` | 8px | Small gaps, list item spacing |
| `spacingMd` | 16px | Standard component padding, gap between fields |
| `spacingLg` | 24px | Section spacing, card padding |
| `spacingXl` | 32px | Major sections, screen margins |
| `spacingXXl` | 48px | Screen padding, major separations |

### Component Padding Standards

| Component | Padding |
|-----------|---------|
| Button (standard) | 12px vertical, 24px horizontal |
| Button (large) | 16px vertical, 32px horizontal |
| Card | 16px all sides |
| Card (emphasized) | 24px all sides |
| List item | 12px vertical, 16px horizontal |
| Input field | 12px vertical, 16px horizontal |
| Screen content | 16px horizontal |

### Spacing Between Components

```dart
// Between form fields
const SizedBox(height: DesignTokens.spacingMd)  // 16px

// Between sections
const SizedBox(height: DesignTokens.spacingLg)  // 24px

// Between icon and text
const SizedBox(width: DesignTokens.spacingXs)   // 4px

// Row of buttons
Row(
  children: [...],
  spacing: DesignTokens.spacingMd,  // Use Row.spacing if Flutter 3.7+
)
```

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `borderRadiusSmall` | 8px | Buttons, chips, small elements |
| `borderRadiusMedium` | 12px | Cards, inputs, standard components |
| `borderRadiusLarge` | 16px | Dialogs, large cards, modals |
| `borderRadiusXLarge` | 20px | Special features, hero elements |
| `borderRadiusCircular` | 999px | Avatars, round buttons, badges |

---

## Elevation & Shadow

| Level | Usage |
|-------|-------|
| Level 0 (none) | Flat elements on surface |
| Level 1 | Cards, subtle lift |
| Level 2 | Floating buttons, dropdowns |
| Level 3 | Dialogs, menus, modals |

Shadows use low opacity (`rgba(0,0,0,0.06–0.08)`) for warmth. Avoid harsh shadows.

---

## Icon Usage

Standard icons use Material Design icons from the `Icons` class.

| Size | Token | Value | Usage |
|------|-------|-------|-------|
| Small | `iconSizeSmall` | 16px | Inline icons, metadata |
| Medium | `iconSizeMedium` | 24px | Standard icons, navigation (default) |
| Large | `iconSizeLarge` | 32px | Feature icons, empty states |
| XLarge | `iconSizeXLarge` | 48px | Hero icons, illustrations |

```dart
// Standard (medium, theme-colored)
const Icon(Icons.edit)

// Explicit size for special use
Icon(Icons.restaurant, size: DesignTokens.iconSizeLarge, color: DesignTokens.primary)

// Empty state (large, subdued)
Icon(
  Icons.menu_book_outlined,
  size: DesignTokens.iconSizeXLarge,
  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
)
```

---

## Accessibility Checklist

For every new component:

- [ ] Minimum **48×48dp touch target** for all interactive elements
- [ ] **WCAG AA contrast** for all text (>4.5:1 for body, >3:1 for large text)
- [ ] **Labels** on all form inputs (not just hints)
- [ ] **Tooltips** on all `IconButton` widgets
- [ ] **Localized strings** — no hardcoded English or Portuguese
- [ ] **Semantic colors** — error = red, success = green, never decorative
- [ ] **Disabled state** — visual feedback + non-interactive (`onPressed: null`)

---

## Do's and Don'ts Summary

### Do

- Use theme widgets (`ElevatedButton`, `TextFormField`, `AppBar`, `BottomNavigationBar`) without style overrides
- Access theme via `Theme.of(context).textTheme` and `Theme.of(context).colorScheme`
- Use `DesignTokens` for spacing, border radius, and icon sizes
- Localize all user-facing strings via `AppLocalizations.of(context)!`
- Confirm before destructive actions
- Provide tooltips for icon buttons
- Use `BackButton` not `IconButton(icon: Icon(Icons.arrow_back))`

### Don't

- Hardcode colors (`Colors.orange`, `Colors.grey`, `Color(0xFF...)`)
- Override borders on inputs (`border: OutlineInputBorder()`)
- Use multiple `ElevatedButton` side-by-side (one primary per context)
- Skip labels on form inputs (accessibility requirement)
- Use `GestureDetector` for small tap targets (use button widgets instead)
- Mix `px` and `dp` — always use Flutter logical pixels (they're equivalent on 1x screens)

---

## File Reference

### Theme Files

| File | Purpose |
|------|---------|
| `lib/core/theme/design_tokens.dart` | Token constants (colors, spacing, typography, radii) |
| `lib/core/theme/app_theme.dart` | `ThemeData` configuration applying all tokens |
| `lib/core/theme/button_styles.dart` | `ButtonStyles` for destructive and special button variants |

### Design Documentation

| Document | Purpose |
|----------|---------|
| `docs/design/component_library.md` | This document — component overview and quick reference |
| `docs/design/design-tokens.md` | Full token definitions with rationale |
| `docs/design/visual_identity.md` | "Cultured & Flavorful" visual personality |
| `docs/design/theme_usage.md` | Flutter theme system usage guide |
| `docs/design/button_patterns.md` | Full button pattern reference |
| `docs/design/input_patterns.md` | Full input pattern reference |
| `docs/design/navigation_patterns.md` | Full navigation pattern reference |

---

## Migration Guide

When adding visual polish to existing screens, follow this checklist:

### Buttons
1. Replace `ElevatedButton.styleFrom(backgroundColor: ...)` → remove style entirely
2. Replace `IconButton(color: ...)` → remove color
3. Add missing `tooltip` to `IconButton` widgets
4. Replace `IconButton(icon: Icon(Icons.arrow_back))` → `BackButton()`

### Form Inputs
1. Remove `border`, `enabledBorder`, `focusedBorder` from `InputDecoration`
2. Remove `fillColor` from `InputDecoration`
3. Remove `labelStyle`, `hintStyle` from `InputDecoration`
4. Replace hardcoded strings with `AppLocalizations` keys
5. Ensure every input has `labelText`

### Navigation
1. Remove `backgroundColor`, `selectedItemColor`, etc. from `BottomNavigationBar`
2. Remove `backgroundColor`, `foregroundColor`, `elevation` from `AppBar`
3. Remove color/style props from `TabBar`

### Cards
1. Use `DesignTokens.spacingMd` / `spacingLg` for padding (not `EdgeInsets.all(8)`)
2. Use `Theme.of(context).textTheme` for text styles (not inline `TextStyle`)

---

**Last Updated:** 2026-03-21
**See Also:** [docs/README.md](../README.md) for the full documentation index
