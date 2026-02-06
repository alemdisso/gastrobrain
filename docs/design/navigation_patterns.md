# Navigation Patterns

**Last Updated**: 2026-02-06
**Issue**: #262 - Standardize Navigation Element Styles
**Status**: Complete

## Overview

This document defines the navigation patterns used in Gastrobrain. All navigation elements follow design tokens and theme configuration to ensure consistent styling across the app.

**Key Principle**: Navigation elements should **never use inline styling**. All appearance is controlled through `AppTheme.lightTheme` configuration.

---

## Bottom Navigation Bar

### Pattern

The bottom navigation bar is the primary navigation element in Gastrobrain, providing access to the 4 main sections of the app.

### Implementation

```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  items: [
    BottomNavigationBarItem(
      icon: const Icon(Icons.menu_book),
      label: AppLocalizations.of(context)!.recipes,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.calendar_today),
      label: AppLocalizations.of(context)!.mealPlan,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.restaurant_menu),
      label: AppLocalizations.of(context)!.ingredients,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.build),
      label: 'Tools',
    ),
  ],
)
```

### ✅ Correct Usage

- **No** `type` property (uses theme: `BottomNavigationBarType.fixed`)
- **No** `backgroundColor` property (uses theme: `DesignTokens.surface`)
- **No** `selectedItemColor` property (uses theme: `DesignTokens.primary`)
- **No** `unselectedItemColor` property (uses theme: `DesignTokens.textSecondary`)
- **No** `elevation` property (uses theme: `DesignTokens.elevation2`)
- **Use localized labels** via `AppLocalizations`
- **Include test keys** for important tabs (e.g., `key: Key('recipes_tab_icon')`)

### ❌ Incorrect Usage

```dart
// DON'T: Override theme properties
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,  // ❌ Hardcoded
  backgroundColor: Colors.white,         // ❌ Hardcoded
  selectedItemColor: Colors.orange,     // ❌ Hardcoded
  unselectedItemColor: Colors.grey,     // ❌ Hardcoded
  items: [...],
)
```

### Theme Configuration

Location: `lib/core/theme/app_theme.dart` (lines 335-350)

```dart
bottomNavigationBarTheme: const BottomNavigationBarThemeData(
  backgroundColor: DesignTokens.surface,
  selectedItemColor: DesignTokens.primary,
  unselectedItemColor: DesignTokens.textSecondary,
  selectedLabelStyle: TextStyle(
    fontSize: DesignTokens.captionSize,
    fontWeight: DesignTokens.weightMedium,
  ),
  unselectedLabelStyle: TextStyle(
    fontSize: DesignTokens.captionSize,
    fontWeight: DesignTokens.weightRegular,
  ),
  type: BottomNavigationBarType.fixed,
  elevation: DesignTokens.elevation2,
),
```

**Design Tokens Used**:
- Colors: `surface`, `primary`, `textSecondary`
- Typography: `captionSize`, `weightMedium`, `weightRegular`
- Elevation: `elevation2`

---

## AppBar

### Pattern

AppBar provides screen titles and contextual actions. Screens should use AppBar without inline styling.

### Implementation

```dart
Scaffold(
  appBar: AppBar(
    title: Text(AppLocalizations.of(context)!.screenTitle),
    actions: [
      IconButton(
        icon: const Icon(Icons.action_icon),
        onPressed: _handleAction,
        tooltip: AppLocalizations.of(context)!.actionTooltip,
      ),
    ],
  ),
  body: ...,
)
```

### ✅ Correct Usage

- **No** `backgroundColor` property (uses theme: `DesignTokens.surface`)
- **No** `foregroundColor` property (uses theme: `DesignTokens.textPrimary`)
- **No** `elevation` property (uses theme: `0` for flat design)
- **No** `titleTextStyle` property (uses theme)
- **Use localized titles** via `AppLocalizations`
- **Use Material icons** from `Icons` class
- **Include tooltips** for icon buttons

### Special Cases

#### AppBar with TabBar

```dart
appBar: AppBar(
  title: Text(AppLocalizations.of(context)!.screenTitle),
  bottom: TabBar(
    controller: _tabController,
    tabs: [
      Tab(icon: const Icon(Icons.tab_icon), text: l10n.tabLabel),
      // ... more tabs
    ],
  ),
),
```

#### AppBar with Custom Bottom

```dart
appBar: AppBar(
  title: Text(AppLocalizations.of(context)!.screenTitle),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: // Custom widget (e.g., filter chips)
  ),
),
```

### ❌ Incorrect Usage

```dart
// DON'T: Override theme properties
AppBar(
  backgroundColor: Colors.white,       // ❌ Hardcoded
  foregroundColor: Colors.black,       // ❌ Hardcoded
  elevation: 4,                        // ❌ Hardcoded
  titleTextStyle: TextStyle(...),      // ❌ Custom style
  title: const Text('Hardcoded Title'), // ❌ Not localized
)
```

### Theme Configuration

Location: `lib/core/theme/app_theme.dart` (lines 166-178)

```dart
appBarTheme: const AppBarTheme(
  backgroundColor: DesignTokens.surface,
  foregroundColor: DesignTokens.textPrimary,
  elevation: 0,
  centerTitle: false,
  titleTextStyle: TextStyle(
    fontSize: DesignTokens.heading2Size,
    fontWeight: DesignTokens.weightSemibold,
    height: DesignTokens.tightLineHeight,
    color: DesignTokens.textPrimary,
  ),
),
```

**Design Tokens Used**:
- Colors: `surface`, `textPrimary`
- Typography: `heading2Size`, `weightSemibold`, `tightLineHeight`
- Elevation: `0` (flat design)

---

## TabBar

### Pattern

TabBar provides navigation between related content within a screen. Used in `recipe_details_screen.dart` and `recipe_selection_dialog.dart`.

### Implementation

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.screenTitle),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: const Icon(Icons.list_alt),
            text: AppLocalizations.of(context)!.ingredients,
          ),
          Tab(
            icon: const Icon(Icons.description),
            text: AppLocalizations.of(context)!.instructions,
          ),
          Tab(
            icon: const Icon(Icons.info_outline),
            text: AppLocalizations.of(context)!.overview,
          ),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildIngredientsTab(),
        _buildInstructionsTab(),
        _buildOverviewTab(),
      ],
    ),
  ),
)
```

### ✅ Correct Usage

- **No** `labelColor` property (uses theme: `DesignTokens.primary`)
- **No** `unselectedLabelColor` property (uses theme: `DesignTokens.textSecondary`)
- **No** `indicator` property (uses theme: `UnderlineTabIndicator`)
- **No** `labelStyle` property (uses theme)
- **Use localized labels** via `AppLocalizations`
- **Use Material icons** for tab icons (optional)
- **Use TabController** for programmatic control

### ❌ Incorrect Usage

```dart
// DON'T: Override theme properties
TabBar(
  labelColor: Colors.orange,           // ❌ Hardcoded
  unselectedLabelColor: Colors.grey,   // ❌ Hardcoded
  indicator: BoxDecoration(...),       // ❌ Custom indicator
  labelStyle: TextStyle(...),          // ❌ Custom style
  tabs: [
    Tab(text: 'Hardcoded'),            // ❌ Not localized
  ],
)
```

### Theme Configuration

Location: `lib/core/theme/app_theme.dart` (lines 409-429)

```dart
tabBarTheme: const TabBarThemeData(
  indicatorColor: DesignTokens.primary,
  indicatorSize: TabBarIndicatorSize.tab,
  labelColor: DesignTokens.primary,
  unselectedLabelColor: DesignTokens.textSecondary,
  labelStyle: TextStyle(
    fontSize: DesignTokens.bodySmallSize,
    fontWeight: DesignTokens.weightMedium,
  ),
  unselectedLabelStyle: TextStyle(
    fontSize: DesignTokens.bodySmallSize,
    fontWeight: DesignTokens.weightRegular,
  ),
  indicator: UnderlineTabIndicator(
    borderSide: BorderSide(
      color: DesignTokens.primary,
      width: DesignTokens.borderWidthThin,
    ),
  ),
),
```

**Design Tokens Used**:
- Colors: `primary`, `textSecondary`
- Typography: `bodySmallSize`, `weightMedium`, `weightRegular`
- Borders: `borderWidthThin`

---

## Back Button

### Pattern

Back buttons allow users to navigate to the previous screen. Use `BackButton` widget for consistency.

### Standard Usage (Default Behavior)

Most screens don't need explicit back button - Material automatically provides one:

```dart
Scaffold(
  appBar: AppBar(
    title: Text(AppLocalizations.of(context)!.screenTitle),
    // No leading - Material provides back button automatically
  ),
  body: ...,
)
```

### Custom Back Behavior

When you need custom behavior (e.g., returning a value on back):

```dart
Scaffold(
  appBar: AppBar(
    title: Text(AppLocalizations.of(context)!.screenTitle),
    leading: BackButton(
      onPressed: () {
        Navigator.pop(context, customReturnValue);
      },
    ),
  ),
  body: ...,
)
```

### ✅ Correct Usage

- **Use `BackButton` widget** (not `IconButton`)
- **No** `color` property (uses theme: `DesignTokens.textSecondary`)
- **No** `icon` property (uses Material's default back icon)
- **Provide `onPressed`** only when custom behavior needed
- **Combine with `PopScope`** for comprehensive back handling

### ❌ Incorrect Usage

```dart
// DON'T: Use IconButton for back navigation
leading: IconButton(
  icon: const Icon(Icons.arrow_back),  // ❌ Custom implementation
  color: Colors.black,                  // ❌ Hardcoded color
  onPressed: () => Navigator.pop(context),
)

// DO: Use BackButton widget
leading: BackButton(
  onPressed: () => Navigator.pop(context, value),
)
```

### Complete Example with PopScope

For screens that need to handle back navigation with data:

```dart
PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop && _hasChanges) {
      // Side effect - parent will refresh
    }
  },
  child: Scaffold(
    appBar: AppBar(
      title: Text(widget.recipe.name),
      leading: BackButton(
        onPressed: () {
          Navigator.pop(context, _hasChanges);
        },
      ),
    ),
    body: ...,
  ),
)
```

### Theme Configuration

Back button uses the `iconButtonTheme`:

Location: `lib/core/theme/app_theme.dart` (lines 246-253)

```dart
iconButtonTheme: IconButtonThemeData(
  style: IconButton.styleFrom(
    foregroundColor: DesignTokens.textSecondary,
    disabledForegroundColor: DesignTokens.textDisabled,
    iconSize: DesignTokens.iconSizeMedium,
  ),
),
```

**Design Tokens Used**:
- Colors: `textSecondary`, `textDisabled`
- Sizing: `iconSizeMedium` (24px)

---

## Icon Buttons

### Pattern

Icon buttons provide actions in AppBar, toolbars, and other UI contexts.

### Implementation

```dart
IconButton(
  icon: const Icon(Icons.action_icon),
  onPressed: _handleAction,
  tooltip: AppLocalizations.of(context)!.actionTooltip,
)
```

### ✅ Correct Usage

- **No** `color` property (uses theme: `DesignTokens.textSecondary`)
- **No** `iconSize` property (uses theme: `DesignTokens.iconSizeMedium`)
- **Use Material icons** from `Icons` class
- **Include tooltips** for accessibility
- **Localize tooltips** via `AppLocalizations`
- **Disable when appropriate** (set `onPressed: null`)

### ❌ Incorrect Usage

```dart
// DON'T: Override theme properties
IconButton(
  icon: const Icon(Icons.settings),
  color: Colors.grey,              // ❌ Hardcoded
  iconSize: 28,                    // ❌ Hardcoded
  tooltip: 'Settings',             // ❌ Not localized
  onPressed: _openSettings,
)
```

---

## Custom Navigation Widgets

### Week Navigation Widget

The `WeekNavigationWidget` demonstrates proper theme usage for custom navigation:

Location: `lib/widgets/week_navigation_widget.dart`

```dart
IconButton(
  icon: const Icon(Icons.chevron_left),
  onPressed: onPreviousWeek,
  tooltip: AppLocalizations.of(context)!.previousWeek,
)
```

**Key Points**:
- ✅ Uses `Theme.of(context).colorScheme` for colors
- ✅ Uses `Theme.of(context).textTheme` for typography
- ✅ Uses `DesignTokens` for spacing
- ✅ No hardcoded values

---

## Localization Requirements

All navigation labels **must be localized**:

### ARB Files

Add strings to both `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb`:

```json
{
  "screenTitle": "Screen Title",
  "@screenTitle": {
    "description": "Title for screen"
  },
  "actionTooltip": "Action description",
  "@actionTooltip": {
    "description": "Tooltip for action button"
  }
}
```

### Usage in Code

```dart
AppLocalizations.of(context)!.screenTitle
```

### Generate Localization Code

After updating ARB files:

```bash
flutter gen-l10n
```

---

## Testing Navigation

### Widget Tests

Test that navigation elements use theme:

```dart
testWidgets('BottomNavigationBar uses theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          items: [...],
        ),
      ),
    ),
  );

  final bottomNavBar = tester.widget<BottomNavigationBar>(
    find.byType(BottomNavigationBar)
  );

  // Verify no inline overrides
  expect(bottomNavBar.selectedItemColor, isNull);
  expect(bottomNavBar.unselectedItemColor, isNull);
  expect(bottomNavBar.backgroundColor, isNull);
});
```

### Integration Tests

Test navigation flows work correctly:

```dart
testWidgets('tab navigation works', (tester) async {
  await tester.pumpWidget(const GastrobrainApp());

  // Tap tab
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Verify navigation occurred
  expect(find.text('Meal Plan Content'), findsOneWidget);
});
```

---

## Design Token Reference

All navigation elements use these design tokens:

### Colors
- `DesignTokens.surface` - Background for navigation bars
- `DesignTokens.primary` - Selected/active state
- `DesignTokens.textPrimary` - Primary text and icons
- `DesignTokens.textSecondary` - Unselected/inactive state
- `DesignTokens.textTertiary` - Disabled state

### Typography
- `DesignTokens.heading2Size` (20sp) - AppBar titles
- `DesignTokens.bodySmallSize` (12sp) - TabBar labels
- `DesignTokens.captionSize` (11sp) - BottomNavBar labels
- `DesignTokens.weightSemibold` (600) - AppBar titles
- `DesignTokens.weightMedium` (500) - Selected labels
- `DesignTokens.weightRegular` (400) - Unselected labels

### Spacing & Sizing
- `DesignTokens.iconSizeMedium` (24px) - Standard icon size
- `DesignTokens.borderWidthThin` (2px) - TabBar indicator
- `DesignTokens.elevation2` (4px) - BottomNavBar elevation

For complete design token reference, see `lib/core/theme/design_tokens.dart` and `docs/design/design-tokens.md`.

---

## Migration Guide

### Removing Hardcoded Navigation Styles

If you find navigation with inline styling:

**Before**:
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  selectedItemColor: Colors.orange,
  currentIndex: _selectedIndex,
  items: [...],
)
```

**After**:
```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  items: [...],
)
```

### Converting IconButton to BackButton

**Before**:
```dart
leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    Navigator.pop(context, value);
  },
)
```

**After**:
```dart
leading: BackButton(
  onPressed: () {
    Navigator.pop(context, value);
  },
)
```

---

## Related Documentation

- **Design Tokens**: `docs/design/design-tokens.md`
- **Visual Identity**: `docs/design/visual_identity.md`
- **Theme Usage**: `docs/design/theme_usage.md`
- **Button Patterns**: `docs/design/button_patterns.md`
- **Input Patterns**: `docs/design/input_patterns.md`

---

## Compliance Checklist

When implementing navigation:

- [ ] No `backgroundColor`, `foregroundColor`, or color properties
- [ ] No `elevation` properties (unless specific design requirement)
- [ ] No typography overrides (`labelStyle`, `titleTextStyle`, etc.)
- [ ] All labels localized via `AppLocalizations`
- [ ] Uses Material icons from `Icons` class
- [ ] Includes tooltips for icon buttons
- [ ] Test keys included for important navigation elements
- [ ] Widget tests verify theme usage
- [ ] `flutter analyze` passes with no warnings

---

**Last Reviewed**: 2026-02-06
**Compliance**: 100%
**Status**: All navigation elements standardized ✅
