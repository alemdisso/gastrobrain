# Button Patterns for Gastrobrain

This document describes standardized button patterns used throughout Gastrobrain. All buttons follow design tokens and establish clear visual hierarchy for user actions.

## Button Types

### Primary Buttons (`ElevatedButton`)

**Use for:** Main actions, primary calls-to-action

**Default styling** (automatically applied by theme):
- Background: Primary color (warm amber/paprika)
- Text: White
- Elevation: 1dp shadow
- Border radius: Small (8dp)
- Minimum size: 48x48dp touch target

**Example:**
```dart
ElevatedButton(
  onPressed: () => _saveRecipe(),
  child: Text('Save Recipe'),
)
```

**Common uses:**
- Save/Submit forms
- Confirm actions
- Primary CTAs ("Add Recipe", "Generate Shopping List")

---

### Secondary Buttons (`TextButton`)

**Use for:** Less prominent actions, navigation, cancellation

**Default styling** (automatically applied by theme):
- Background: Transparent
- Text: Primary color
- No elevation
- Minimum size: 48x48dp touch target

**Example:**
```dart
TextButton(
  onPressed: () => Navigator.pop(context),
  child: Text('Cancel'),
)
```

**Common uses:**
- Cancel/Dismiss dialogs
- Navigation actions
- Secondary options in forms

---

### Alternative Buttons (`OutlinedButton`)

**Use for:** Actions that need more emphasis than text buttons but less than primary

**Default styling** (automatically applied by theme):
- Background: Transparent
- Border: Primary color (1dp)
- Text: Primary color
- Border radius: Small (8dp)
- Minimum size: 48x48dp touch target

**Example:**
```dart
OutlinedButton(
  onPressed: () => _viewDetails(),
  child: Text('View Details'),
)
```

**Common uses:**
- Alternative actions
- Secondary CTAs
- Filter/sort options

---

### Icon Buttons (`IconButton`)

**Use for:** Compact actions, toolbar actions, list item actions

**Default styling** (automatically applied by theme):
- Background: Transparent
- Icon color: Secondary text color
- Icon size: 24dp
- Minimum size: 48x48dp touch target

**Example:**
```dart
IconButton(
  icon: Icon(Icons.edit),
  onPressed: () => _editItem(),
  tooltip: 'Edit',
)
```

**Common uses:**
- Edit/delete list items
- Navigation (back, close)
- Toolbar actions
- Compact actions in cards

**Important:** Always provide `tooltip` for accessibility.

---

## Special Cases

### Destructive Actions

**Use for:** Actions that delete data or have irreversible consequences

#### Primary Destructive (`ButtonStyles.destructive`)

**When to use:**
- Confirmed delete actions (after user confirms in dialog)
- Primary destructive action that needs emphasis

**Example:**
```dart
import 'package:gastrobrain/core/theme/button_styles.dart';

ElevatedButton(
  onPressed: () => _deleteRecipe(),
  style: ButtonStyles.destructive,
  child: Text('Delete Recipe'),
)
```

#### Secondary Destructive (`ButtonStyles.destructiveText`)

**When to use:**
- Discard changes
- Cancel with data loss
- Less prominent destructive actions

**Example:**
```dart
TextButton(
  onPressed: () => _discardChanges(),
  style: ButtonStyles.destructiveText,
  child: Text('Discard Changes'),
)
```

#### Outlined Destructive (`ButtonStyles.destructiveOutlined`)

**When to use:**
- Remove/delete actions that need moderate emphasis

**Example:**
```dart
OutlinedButton(
  onPressed: () => _removeIngredient(),
  style: ButtonStyles.destructiveOutlined,
  child: Text('Remove'),
)
```

### Confirmation Pattern

For destructive actions, always confirm with user first:

```dart
// Using the helper extension
if (await context.confirmDestructiveAction(
  title: 'Delete Recipe',
  message: 'Are you sure you want to delete "${recipe.name}"? This cannot be undone.',
  confirmLabel: 'Delete',
)) {
  await _deleteRecipe();
}

// Or manually with AlertDialog
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete Recipe'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ButtonStyles.destructive,
        child: Text('Delete'),
      ),
    ],
  ),
);
if (confirmed == true) {
  await _deleteRecipe();
}
```

---

## Button Sizing and Spacing

### Touch Targets

All buttons enforce **minimum 48x48dp touch target** for accessibility (WCAG 2.1 Level AAA).

The theme automatically ensures this for standard buttons. Custom buttons using `ButtonStyles` also enforce this minimum.

### Padding

Standard button padding (defined in `DesignTokens.buttonPadding`):
- Horizontal: 24dp
- Vertical: 12dp

This provides comfortable tap targets and clear visual boundaries.

### Spacing Between Buttons

When placing multiple buttons together:

**Horizontal (dialog actions, button rows):**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  spacing: DesignTokens.spacingMd, // 16dp
  children: [
    TextButton(/*...*/),
    ElevatedButton(/*...*/),
  ],
)
```

**Vertical (form buttons, stacked actions):**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: DesignTokens.spacingSm, // 12dp
  children: [
    ElevatedButton(/*...*/),
    TextButton(/*...*/),
  ],
)
```

---

## Accessibility Guidelines

### 1. Contrast Ratios

All button styles meet **WCAG AA contrast requirements**:
- Primary buttons: White text on primary color (>4.5:1)
- Destructive buttons: White text on error red (>4.5:1)
- Text buttons: Primary/error color on surface (>4.5:1)

### 2. Touch Targets

Minimum **48x48dp touch target** enforced by theme and `ButtonStyles`.

### 3. Labels

- Use clear, action-oriented labels ("Save Recipe" not "OK")
- Keep labels concise (1-3 words)
- Always provide `tooltip` for `IconButton`

### 4. Disabled State

Disabled buttons have reduced opacity and cannot receive focus:
```dart
ElevatedButton(
  onPressed: isValid ? () => _save() : null, // null = disabled
  child: Text('Save'),
)
```

---

## Common Patterns

### Dialog Actions

Standard pattern for dialog buttons:

```dart
AlertDialog(
  title: Text('Dialog Title'),
  content: Text('Dialog content here'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    ElevatedButton(
      onPressed: () {
        // Perform action
        Navigator.pop(context);
      },
      child: Text('Confirm'),
    ),
  ],
)
```

### Form Actions

Standard pattern for form save/cancel:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    SizedBox(width: DesignTokens.spacingMd),
    ElevatedButton(
      onPressed: _formKey.currentState?.validate() == true
          ? () => _saveForm()
          : null,
      child: Text('Save'),
    ),
  ],
)
```

### List Item Actions

Standard pattern for edit/delete in list items:

```dart
ListTile(
  title: Text(item.name),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => _editItem(item),
        tooltip: 'Edit',
      ),
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _confirmDeleteItem(item),
        tooltip: 'Delete',
      ),
    ],
  ),
)
```

---

## Anti-Patterns (Don't Do This)

### ❌ Custom Styling for Standard Actions

```dart
// DON'T - Custom styling for standard actions
ElevatedButton(
  onPressed: _save,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Use theme colors
    padding: EdgeInsets.all(20),  // Use design tokens
  ),
  child: Text('Save'),
)

// DO - Use theme defaults
ElevatedButton(
  onPressed: _save,
  child: Text('Save'),
)
```

### ❌ Inconsistent Button Types

```dart
// DON'T - Using different button types for same action across app
// In screen A:
ElevatedButton(child: Text('Cancel'))

// In screen B:
TextButton(child: Text('Cancel'))

// DO - Be consistent (Cancel = TextButton, Save = ElevatedButton)
```

### ❌ Too Many Primary Buttons

```dart
// DON'T - Multiple primary actions competing for attention
Row(
  children: [
    ElevatedButton(child: Text('Action 1')),
    ElevatedButton(child: Text('Action 2')),
    ElevatedButton(child: Text('Action 3')),
  ],
)

// DO - One primary, others secondary
Row(
  children: [
    TextButton(child: Text('Cancel')),
    TextButton(child: Text('Skip')),
    ElevatedButton(child: Text('Continue')),
  ],
)
```

### ❌ Missing Touch Targets

```dart
// DON'T - Custom buttons with small touch targets
GestureDetector(
  onTap: _action,
  child: Container(
    padding: EdgeInsets.all(4), // Too small!
    child: Text('Tap me'),
  ),
)

// DO - Use proper button widgets with 48x48dp minimum
TextButton(
  onPressed: _action,
  child: Text('Tap me'),
)
```

---

## Testing Buttons

When testing button behavior, verify:

1. **Accessibility**: Minimum 48x48dp touch target
2. **Contrast**: Text meets WCAG AA (4.5:1 minimum)
3. **Disabled state**: Visual feedback and no interaction when disabled
4. **Destructive actions**: Always confirmed before execution
5. **Touch targets**: No overlapping interactive elements
6. **Consistency**: Same actions use same button types across app

---

## Reference

- **Design Tokens**: `lib/core/theme/design_tokens.dart`
- **Theme Configuration**: `lib/core/theme/app_theme.dart`
- **Button Styles**: `lib/core/theme/button_styles.dart`
- **Visual Identity**: `docs/design/visual_identity.md`
