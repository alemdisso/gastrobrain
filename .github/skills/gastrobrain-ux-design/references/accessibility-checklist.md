# Accessibility Checklist for Flutter

WCAG 2.1 AA standards adapted for Flutter development in Gastrobrain.

## Overview

Every screen and feature in Gastrobrain must be accessible to users with:
- **Visual impairments**: Screen readers, magnification, high contrast
- **Motor impairments**: Large touch targets, no precise gestures required
- **Cognitive impairments**: Clear language, consistent patterns, forgiving errors

**Minimum standard**: WCAG 2.1 Level AA

## Screen Reader Compatibility

### Semantic Widgets (Required)

✅ **Use semantic widgets** - Flutter has built-in accessibility:
```dart
// GOOD - Semantic widgets announce themselves
Text('Recipe Name')
ElevatedButton(onPressed: () {}, child: Text('Save'))
IconButton(icon: Icon(Icons.delete), onPressed: () {})

// BAD - Just containers (screen reader doesn't understand)
GestureDetector(
  onTap: () {},
  child: Container(
    child: Text('Save'), // Not announced as button
  ),
)
```

### Labels for Interactive Elements

✅ **All interactive elements must have labels**:
```dart
// Icon buttons need semantic labels
IconButton(
  icon: Icon(Icons.favorite),
  tooltip: 'Add to favorites', // Visible on long-press
  onPressed: () {},
  // Automatically uses tooltip as semantic label
)

// Images need semantic labels
Image.asset(
  'recipe.jpg',
  semanticLabel: 'Chocolate cake with strawberries',
)

// Custom widgets need Semantics wrapper
GestureDetector(
  onTap: () {},
  child: Semantics(
    label: 'Delete recipe',
    button: true, // Announces as button
    child: Icon(Icons.delete),
  ),
)
```

### Semantic Properties

**Common semantic properties**:
```dart
Semantics(
  label: 'Recipe difficulty: Easy',        // What screen reader says
  hint: 'Tap to change difficulty',       // Additional guidance
  button: true,                            // Announces as button
  enabled: true,                           // Announces if disabled
  header: true,                            // Announces as heading
  textField: true,                         // Announces as text field
  value: 'Easy',                           // Current value
  increasedValue: 'Medium',                // What increases to
  decreasedValue: null,                    // Can't decrease
  onIncrease: () {},                       // Increment action
  onDecrease: null,                        // Decrement action (disabled)
  child: /*...*/,
)
```

### Announcements for Dynamic Changes

✅ **Announce dynamic changes** to screen reader:
```dart
import 'package:flutter/semantics.dart';

// When data loads
SemanticsService.announce(
  '15 recipes loaded',
  TextDirection.ltr,
);

// When action succeeds
SemanticsService.announce(
  'Recipe saved successfully',
  TextDirection.ltr,
);

// When error occurs
SemanticsService.announce(
  'Error: Failed to save recipe. Please try again.',
  TextDirection.ltr,
);
```

### Form Fields

✅ **Form fields must be labeled**:
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Recipe Name',           // Visual and semantic label
    hintText: 'e.g., Chocolate Cake',   // Additional guidance
    helperText: 'Enter the full recipe name', // Extra context
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Recipe name is required';  // Error announced
    }
    return null;
  },
)
```

## Color Contrast

### Text Contrast Ratios (WCAG AA)

**Requirements**:
- Normal text (< 24pt): **4.5:1** minimum
- Large text (≥ 24pt or ≥ 18pt bold): **3:1** minimum
- UI components and icons: **3:1** minimum

**Gastrobrain palette compliance**:
```
✅ Cocoa Brown (#3E2723) on Cream (#FFF8DC): 8.2:1   (excellent)
✅ Charcoal (#2C2C2C) on White (#FFFFFF): 13.1:1     (excellent)
✅ Terracotta (#D4755F) on White: 4.9:1              (pass for body text)
✅ Olive Green (#6B8E23) on White: 5.8:1             (pass for body text)
⚠️ Saffron Yellow (#F4C430) on White: 1.8:1          (FAIL - use for backgrounds only)
✅ White on Terracotta: 4.9:1                        (pass for button text)
✅ White on Olive Green: 5.8:1                       (pass for button text)
```

### Testing Contrast

**Online tools**:
- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
- Coolors Contrast Checker: https://coolors.co/contrast-checker

**During design**:
1. Check every text color against its background
2. Check icon colors against backgrounds
3. Check disabled state colors (must still be distinguishable)

### Non-Color Indicators

❌ **Don't rely on color alone**:
```dart
// BAD - Only color indicates error
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.red), // Only visual cue
  ),
  child: TextField(),
)

// GOOD - Color + text + icon
Column(
  children: [
    TextField(
      decoration: InputDecoration(
        errorText: 'Recipe name is required', // Text indicator
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red), // Color
        ),
        prefixIcon: Icon(Icons.error, color: Colors.red), // Icon
      ),
    ),
  ],
)
```

## Touch Targets

### Minimum Size (iOS HIG & Material)

**Requirements**:
- All tappable elements: **44x44 dp minimum** (iOS HIG)
- Material Design: **48x48 dp minimum**
- **Use 48x48 dp** as Gastrobrain standard (larger is better)

### Ensuring Minimum Size

✅ **IconButton** (default 48x48):
```dart
IconButton(
  icon: Icon(Icons.delete, size: 24),
  onPressed: () {},
  constraints: BoxConstraints(minWidth: 48, minHeight: 48), // Enforced
)
```

✅ **Custom button** (wrap in SizedBox):
```dart
SizedBox(
  width: 48,
  height: 48,
  child: GestureDetector(
    onTap: () {},
    child: Center(child: Icon(Icons.delete)),
  ),
)
```

✅ **List items** (minimum 48 height):
```dart
ListTile(
  title: Text('Recipe Name'),
  onTap: () {},
  minVerticalPadding: 12, // Ensures min 48px height with standard text
)
```

### Spacing Between Targets

**Requirements**:
- Minimum **8dp gap** between adjacent touch targets
- Prefer **12-16dp gap** for better usability

❌ **Bad (targets too close)**:
```dart
Row(
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () {}),
    IconButton(icon: Icon(Icons.delete), onPressed: () {}), // Touching
  ],
)
```

✅ **Good (adequate spacing)**:
```dart
Row(
  children: [
    IconButton(icon: Icon(Icons.edit), onPressed: () {}),
    SizedBox(width: 12),
    IconButton(icon: Icon(Icons.delete), onPressed: () {}),
  ],
)
```

## Focus Management

### Logical Focus Order

✅ **Focus should flow logically** (top → bottom, left → right):
```dart
// Default focus order follows widget tree (usually correct)
Column(
  children: [
    TextField(), // Focused first
    TextField(), // Focused second
    ElevatedButton(), // Focused third
  ],
)
```

✅ **Override with FocusTraversalOrder if needed**:
```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1.0),
        child: TextField(),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2.0),
        child: TextField(),
      ),
    ],
  ),
)
```

### No Focus Traps

❌ **Don't trap focus** - user must be able to navigate away:
```dart
// BAD - Modal with no way to dismiss
showDialog(
  context: context,
  barrierDismissible: false, // Can't tap outside
  builder: (context) => AlertDialog(
    content: Text('Loading...'),
    // No actions, no way to close
  ),
);

// GOOD - Always provide escape
showDialog(
  context: context,
  barrierDismissible: true, // Can tap outside
  builder: (context) => AlertDialog(
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'), // Explicit close
      ),
    ],
  ),
);
```

### Initial Focus

✅ **Set initial focus for forms**:
```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus(); // Focus first field
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _nameFocus,
      decoration: InputDecoration(labelText: 'Recipe Name'),
    );
  }
}
```

## Error Handling

### Clear Error Messages

✅ **Errors must be specific and actionable**:
```dart
// BAD - Vague error
return 'Invalid input';

// GOOD - Specific and actionable
return 'Recipe name must be at least 3 characters';

// BETTER - Explains why and how to fix
return 'Recipe name is too short. Please enter at least 3 characters.';
```

### Multiple Error Indicators

✅ **Use text + color + icon** (not just color):
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Servings',
    errorText: isError ? 'Servings must be at least 1' : null, // Text
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2), // Color
    ),
    prefixIcon: isError ? Icon(Icons.error, color: Colors.red) : null, // Icon
  ),
)
```

### Error Recovery

✅ **Always provide a way to recover**:
```dart
// Error state with retry action
if (hasError) {
  return Column(
    children: [
      Icon(Icons.error_outline, size: 48, color: Colors.red),
      SizedBox(height: 16),
      Text('Failed to load recipes'),
      SizedBox(height: 8),
      ElevatedButton(
        onPressed: _retry,
        child: Text('Retry'),
      ),
    ],
  );
}
```

## Loading States

### Announce Loading

✅ **Announce loading to screen reader**:
```dart
if (isLoading) {
  SemanticsService.announce('Loading recipes', TextDirection.ltr);
  return CircularProgressIndicator(
    semanticsLabel: 'Loading recipes',
  );
}
```

### Skeleton Screens

✅ **Use skeleton screens** instead of blank screens:
```dart
if (isLoading) {
  return ListView.builder(
    itemCount: 3,
    itemBuilder: (context, index) => _SkeletonRecipeCard(),
  );
}

class _SkeletonRecipeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading recipe ${index + 1}',
      child: Card(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 120),
        ),
      ),
    );
  }
}
```

## Localization

### No Hardcoded Strings

❌ **Never hardcode user-facing strings**:
```dart
// BAD
Text('Recipe Name')

// GOOD
Text(AppLocalizations.of(context)!.recipeName)
```

### Text Expansion

✅ **Account for text expansion** (Portuguese can be 30% longer):
```dart
// Use flexible layouts
Row(
  children: [
    Flexible( // Not Expanded - allows wrapping
      child: Text(AppLocalizations.of(context)!.longLabel),
    ),
  ],
)

// Test with longest language
Text(
  AppLocalizations.of(context)!.buttonLabel,
  maxLines: 2, // Allow wrapping if needed
  overflow: TextOverflow.ellipsis,
)
```

### Date/Number Formatting

✅ **Use locale-aware formatting**:
```dart
import 'package:intl/intl.dart';

// Dates
final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());
Text(dateFormat.format(DateTime.now()));

// Numbers
final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
Text(numberFormat.format(1234.56));
```

## Testing Accessibility

### Manual Testing

**iOS (VoiceOver)**:
1. Settings → Accessibility → VoiceOver → On
2. Swipe right/left to navigate elements
3. Double-tap to activate
4. Verify all elements are announced correctly

**Android (TalkBack)**:
1. Settings → Accessibility → TalkBack → On
2. Swipe right/left to navigate elements
3. Double-tap to activate
4. Verify all elements are announced correctly

### Automated Testing

✅ **Use Flutter's semantics tests**:
```dart
testWidgets('Recipe card has semantic labels', (tester) async {
  await tester.pumpWidget(MyApp());

  // Find by semantic label
  expect(find.bySemanticsLabel('Recipe: Chocolate Cake'), findsOneWidget);

  // Verify button semantics
  final button = tester.getSemantics(find.byType(IconButton).first);
  expect(button.hasAction(SemanticsAction.tap), isTrue);
  expect(button.label, 'Add to favorites');
});
```

## Checklist for Every Screen

Use this checklist when designing/reviewing screens:

### Screen Reader
- [ ] All interactive elements have semantic labels
- [ ] Images have meaningful semantic labels (not "image.jpg")
- [ ] Semantic widgets used (Text, Button, etc.) not just Containers
- [ ] Dynamic changes are announced (loading, errors, success)
- [ ] Form fields have clear labels
- [ ] Error messages are announced

### Color & Contrast
- [ ] All text meets 4.5:1 contrast (or 3:1 for large text)
- [ ] Icons meet 3:1 contrast
- [ ] Errors use text + icon (not color alone)
- [ ] Disabled states are distinguishable

### Touch Targets
- [ ] All buttons/icons are at least 48x48 dp
- [ ] Minimum 8dp gap between adjacent targets
- [ ] No overlapping tap areas

### Focus
- [ ] Logical focus order (top → bottom, left → right)
- [ ] No focus traps (can always navigate away)
- [ ] Initial focus set for forms
- [ ] Focus indicators visible

### Errors
- [ ] Error messages are specific and actionable
- [ ] Errors use text + color + icon
- [ ] Recovery actions provided (retry, cancel, etc.)

### Loading
- [ ] Loading states announced to screen reader
- [ ] Skeleton screens used (not blank screens)
- [ ] Timeout handling (what if loading fails?)

### Localization
- [ ] No hardcoded strings
- [ ] Layout supports text expansion (Portuguese 30% longer)
- [ ] Date/number formatting uses locale

---

**Test every screen with VoiceOver/TalkBack** before considering it complete.

**Accessibility is not optional** - it's a core requirement for all Gastrobrain features.
