# Common UX Patterns in Gastrobrain

Reusable interaction patterns that maintain consistency across the app.

## Recipe Browsing

### Recipe Card Pattern

**Usage**: Displaying recipes in lists, grids, or search results

**Structure**:
```
┌─────────────────────────────────┐
│  [Image 16:9 ratio]             │  ← Recipe photo (rounded top)
├─────────────────────────────────┤
│  Recipe Name (18pt, bold)       │  ← Primary info
│  Difficulty • Time • Servings   │  ← Metadata (12pt, gray)
│  [Optional tags/labels]         │  ← Secondary info
└─────────────────────────────────┘
```

**Interaction**:
- **Tap card**: Navigate to recipe details
- **Long-press**: Show context menu (edit, delete, share)
- **Favorite icon**: Toggle favorite status (top-right of image)

**States**:
- Default: Elevation 2, cream background
- Pressed: Ripple effect (Terracotta 20% opacity)
- Favorited: Filled heart icon (Terracotta)

**Responsive**:
- Mobile: Single column, full-width cards
- Tablet: 2-column grid, fixed-width cards (max 400px)

---

### Recipe Filters Pattern

**Usage**: Filtering recipe lists by criteria

**Structure**:
```
[Search bar (full-width)]
[Chip: Meal Type ▼] [Chip: Difficulty ▼] [Chip: Tags ▼]
```

**Interaction**:
- **Tap chip**: Open dropdown/modal with options
- **Select option**: Apply filter immediately (no "Apply" button)
- **Clear filter**: Tap "X" on active chip
- **Multiple filters**: Combine with AND logic

**States**:
- Inactive: Outlined chip, gray border
- Active: Filled chip, Terracotta background, white text
- Disabled: Grayed out (if no results)

**Empty state**:
If filters produce no results, show:
```
[Icon: filter_list_off]
No recipes match your filters
[Button: Clear Filters]
```

---

### Recipe Search Pattern

**Usage**: Text-based recipe search

**Interaction**:
- **Debounced**: 300ms delay after typing stops
- **Search in**: Recipe name, ingredients, tags
- **Real-time results**: Update list as user types
- **Clear button**: "X" icon appears when text entered

**States**:
- Empty: Show popular/recent recipes
- Searching: Show loading shimmer
- Results: Show filtered recipe cards
- No results: "No recipes found for '[query]'" + suggest clearing filters

---

## Meal Planning

### Calendar View Pattern

**Usage**: Weekly meal planning calendar

**Structure**:
```
┌────────────────────────────────────────────────┐
│  Mon   Tue   Wed   Thu   Fri   Sat   Sun      │  ← Day headers (24pt, bold)
├────────────────────────────────────────────────┤
│  [B]   [B]   [B]   [B]   [B]   [B]   [B]      │  ← Breakfast slots
│  [L]   [L]   [L]   [L]   [L]   [L]   [L]      │  ← Lunch slots
│  [D]   [D]   [D]   [D]   [D]   [D]   [D]      │  ← Dinner slots
└────────────────────────────────────────────────┘
```

**Interaction**:
- **Tap meal slot**: Open recipe picker modal
- **Long-press meal**: Show context menu (edit, delete, swap)
- **Swipe week**: Navigate to previous/next week
- **Pinch**: Zoom to day view (future enhancement)

**States**:
- Empty slot: Cream background, "+" icon, "Add meal" hint
- Filled slot: Recipe name (16pt), thumbnail (small)
- Multi-dish slot: Primary dish + "(+2 sides)" label
- Past date: Grayed out (read-only)

**Empty state**:
If entire week is empty, show center message:
```
[Icon: calendar_today]
No meals planned this week
[Button: Plan Meals]
```

---

### Meal Slot Pattern

**Usage**: Individual meal slot in calendar

**Structure**:
```
Breakfast                    ← Label (12pt, gray)
─────────────────────────
[Thumbnail] Recipe Name      ← Primary dish (16pt, bold)
            +2 sides         ← Side dishes indicator (12pt, gray)
```

**Interaction**:
- **Tap**: Open meal details (view all dishes)
- **Tap "+"**: Add side dish to existing meal
- **Swipe right**: Mark as cooked
- **Swipe left**: Delete meal

**States**:
- Empty: "+" icon centered, "Add [meal type]" hint
- Single dish: Recipe name + thumbnail
- Multi-dish: Primary dish + side count
- Cooked: Checkmark badge, subtle opacity

---

### Recipe Picker Modal

**Usage**: Assigning a recipe to a meal slot

**Structure**:
```
┌─────────────────────────────────┐
│  Add [Meal Type]           [X]  │  ← Header
├─────────────────────────────────┤
│  [Search bar]                   │
│  [Filters: All • Favorites]     │
├─────────────────────────────────┤
│  [Recipe card 1]                │  ← Scrollable list
│  [Recipe card 2]                │
│  [Recipe card 3]                │
└─────────────────────────────────┘
```

**Interaction**:
- **Tap recipe**: Select and close modal
- **Search**: Filter recipes in real-time
- **Scroll**: Infinite scroll (load more)
- **Cancel**: Tap "X" or tap outside modal

**States**:
- Loading: Skeleton recipe cards (3 placeholders)
- Empty: "No recipes found" + "Create Recipe" button
- Selected: Recipe card highlighted (Terracotta border)

---

## Forms & Dialogs

### Form Validation Pattern

**Usage**: All forms (recipe creation, meal planning, settings)

**Validation approach**:
- **Real-time validation**: As user types (debounced 500ms)
- **Inline errors**: Below each field (red text, error icon)
- **Submit validation**: Final check on "Save" button tap
- **Focus on error**: Auto-scroll to first error field

**Error message format**:
```
[Field label]
[Input field with red border]
[Icon: error] [Specific error message]
```

**Example**:
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Recipe Name',
    errorText: error, // "Recipe name must be at least 3 characters"
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
    prefixIcon: error != null ? Icon(Icons.error, color: Colors.red) : null,
  ),
  validator: (value) => value.length < 3 ? 'Recipe name must be at least 3 characters' : null,
)
```

---

### Confirmation Dialog Pattern

**Usage**: Confirming destructive actions (delete, discard)

**Structure**:
```
┌─────────────────────────────────┐
│  [Icon: warning/delete]         │
│                                 │
│  Confirm [Action]               │  ← Header (24pt, bold)
│  Are you sure you want to       │
│  delete this recipe?            │  ← Body (16pt)
│  This cannot be undone.         │
│                                 │
│  [Cancel]  [Delete Recipe]      │  ← Actions
└─────────────────────────────────┘
```

**Interaction**:
- **Cancel button**: TextButton (left, gray)
- **Confirm button**: ElevatedButton (right, red for destructive)
- **Tap outside**: Dismiss (same as Cancel)
- **Back button**: Dismiss (same as Cancel)

**Button colors by action**:
- Destructive (delete, discard): Error Red (#D32F2F)
- Safe (archive, move): Terracotta (#D4755F)
- Neutral (cancel, close): Cocoa Brown (#3E2723)

---

### Bottom Sheet Pattern

**Usage**: Quick actions, filters, pickers

**Structure**:
```
┌─────────────────────────────────┐
│  [Drag handle]                  │  ← Subtle gray bar
│                                 │
│  [Sheet Title]             [X]  │  ← Header (18pt, bold)
├─────────────────────────────────┤
│  [Content area]                 │  ← Main content
│                                 │
│  [Action buttons]               │  ← Bottom actions
└─────────────────────────────────┘
```

**Interaction**:
- **Drag down**: Dismiss sheet
- **Tap outside**: Dismiss sheet
- **Back button**: Dismiss sheet
- **Action buttons**: Confirm or dismiss

**Heights**:
- Compact: 40% screen height (quick actions)
- Medium: 60% screen height (forms)
- Full: 90% screen height (complex pickers)

---

## Navigation Patterns

### Hierarchical Navigation

**Pattern**: Home → List → Detail → Edit

**Example** (Recipe flow):
```
Home Screen
  └─> Recipe List Screen
        └─> Recipe Details Screen
              └─> Edit Recipe Screen
```

**Interaction**:
- **Back button**: Return to previous screen
- **Up button (AppBar)**: Return to previous screen
- **System back gesture**: Return to previous screen

**State preservation**:
- Return to same scroll position in list
- Preserve filters/search query
- Show updated data (if edited)

---

### Tab-Based Navigation

**Pattern**: Main sections accessible via bottom navigation

**Tabs** (Gastrobrain):
```
[Recipes] [Meal Plans] [Shopping] [Settings]
```

**Interaction**:
- **Tap tab**: Switch to that section (keeps state)
- **Tap active tab**: Scroll to top (if already in section)
- **Badge**: Show count (e.g., shopping list items)

**Tab order**:
1. Recipes (most frequently used)
2. Meal Plans (core feature)
3. Shopping (derived feature)
4. Settings (least frequent)

---

### Modal Navigation

**Pattern**: Focused task that overlays current screen

**Use for**:
- Creating new items (recipe, meal, ingredient)
- Editing items (recipe details, meal plan)
- Confirming actions (delete, discard changes)
- Selecting from list (recipe picker, date picker)

**Interaction**:
- **Full-screen modal**: Slide from bottom, AppBar with "Cancel"/"Save"
- **Dialog**: Fade-in center, "Cancel"/"Confirm" buttons
- **Bottom sheet**: Slide from bottom, drag to dismiss

**Discard changes**:
If user made changes and taps "Cancel":
```
┌─────────────────────────────────┐
│  Discard Changes?               │
│  You have unsaved changes.      │
│  [Keep Editing] [Discard]       │
└─────────────────────────────────┘
```

---

## Feedback Patterns

### Success Feedback

**SnackBar** (transient message):
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 8),
        Text('Recipe saved successfully'),
      ],
    ),
    backgroundColor: Color(0xFF388E3C), // Success Green
    duration: Duration(seconds: 2),
  ),
);
```

**When to use**:
- Item saved/created
- Item deleted
- Settings updated
- Action completed

---

### Error Feedback

**SnackBar with action**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.error, color: Colors.white),
        SizedBox(width: 8),
        Expanded(child: Text('Failed to save recipe')),
      ],
    ),
    backgroundColor: Color(0xFFD32F2F), // Error Red
    action: SnackBarAction(
      label: 'Retry',
      textColor: Colors.white,
      onPressed: _retryAction,
    ),
    duration: Duration(seconds: 4),
  ),
);
```

**When to use**:
- Network errors
- Database failures
- Validation errors (global)

---

### Loading Feedback

**Inline loading** (within content):
```dart
if (isLoading) {
  return Center(
    child: CircularProgressIndicator(
      semanticsLabel: 'Loading recipes',
    ),
  );
}
```

**Skeleton loading** (better UX):
```dart
if (isLoading) {
  return ListView.builder(
    itemCount: 3,
    itemBuilder: (context, index) => SkeletonRecipeCard(),
  );
}
```

**Button loading** (disable + spinner):
```dart
ElevatedButton(
  onPressed: isLoading ? null : _saveRecipe,
  child: isLoading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Text('Save Recipe'),
)
```

---

## Empty States

### No Data Pattern

**Structure**:
```
[Illustration or icon (64px)]
[Message (16pt, centered)]
[Action button (if applicable)]
```

**Example** (No recipes):
```
┌─────────────────────────────────┐
│                                 │
│        [Icon: restaurant]       │  ← 64px icon
│                                 │
│     No recipes yet              │  ← 18pt, bold
│     Add your first recipe to    │  ← 14pt, gray
│     get started with meal       │
│     planning                    │
│                                 │
│     [Add Recipe]                │  ← Primary button
│                                 │
└─────────────────────────────────┘
```

**Tone**: Friendly and actionable (not just "Empty")

---

### No Search Results Pattern

**Structure**:
```
[Icon: search_off]
No recipes found for "[search query]"
Try a different search or clear filters
[Clear Filters] (if filters active)
```

**Helpful hints**:
- Suggest removing filters
- Suggest broader search terms
- Offer to create recipe if appropriate

---

### First-Time Use Pattern

**Onboarding** (optional for complex features):
```
┌─────────────────────────────────┐
│  Welcome to Meal Planning!      │
│                                 │
│  Plan your meals for the week   │
│  and we'll generate a shopping  │
│  list automatically.            │
│                                 │
│  [Skip]         [Get Started]   │
└─────────────────────────────────┘
```

**Use sparingly** - prefer discoverable UI over lengthy onboarding.

---

## Edge Case Patterns

### Very Long Text

**Recipe names, ingredients**:
- Use ellipsis after 2 lines max
- Show full text on tap (expand)
- Use tooltip on hover (desktop)

```dart
Text(
  recipe.name,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

---

### Very Large Numbers

**Servings, ingredient quantities**:
- Format with locale-aware separators
- Use abbreviations for very large (e.g., "1.2k")

```dart
final formatter = NumberFormat.compact(locale: 'en_US');
Text(formatter.format(1234)); // "1.2K"
```

---

### Offline Mode

**No network** (if app uses API):
```
[Icon: cloud_off]
No internet connection
You're viewing cached data
[Retry]
```

**Disable actions** that require network:
- Grayed out buttons
- Tooltip: "Network required"

---

## Pattern Selection Guide

**When browsing items**: Use Recipe Card Pattern
**When filtering**: Use Filters Pattern
**When searching**: Use Search Pattern
**When planning**: Use Calendar View Pattern
**When assigning**: Use Picker Modal Pattern
**When creating/editing**: Use Form Validation Pattern
**When confirming**: Use Confirmation Dialog Pattern
**When showing success**: Use Success Feedback Pattern
**When showing error**: Use Error Feedback Pattern
**When loading**: Use Skeleton Loading Pattern
**When empty**: Use No Data Pattern

---

**Consistency is key** - reuse these patterns across the app for familiarity and ease of use.
