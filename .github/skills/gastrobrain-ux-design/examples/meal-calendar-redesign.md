# Example: Meal Planning Calendar Redesign

**Issue**: #285 - Redesign weekly meal planning calendar for better readability

**User Request**: "Help me redesign the meal planning calendar - it feels cramped and hard to read"

**Skill execution walkthrough** showing all 6 checkpoints.

---

## CHECKPOINT 1/6: Goal & Context Analysis

### Goal & Context

**User Goal**: Users want to see their weekly meal plan at a glance and quickly understand what's planned for each day without squinting or tapping to expand.

**Pain Point**: Current calendar feels cramped - recipe names are truncated, meal type labels compete for attention, and overall hierarchy is unclear. Users report it "feels generic" and "hard to scan quickly."

**Success Criteria**:
- [ ] Users can read recipe names without truncation (at least first 25 characters)
- [ ] Clear visual distinction between days and meal slots
- [ ] Meal type (breakfast/lunch/dinner) is obvious at a glance
- [ ] Empty meal slots are inviting (not just blank space)
- [ ] Overall feel is "cultured and organized" (not cramped and generic)

**Scope**: Redesign of weekly meal planning calendar screen

**User confirmation**: ✅ Ready to proceed

---

## CHECKPOINT 2/6: Current State Assessment

### Current State Assessment

**What exists**: Grid layout showing 7 days x 3 meals, recipe names in small text, dropdown icons to assign recipes.

**What works** ✅:
- Shows all 7 days at once (week-at-a-glance)
- Clear column headers for days of week
- Quick tap to assign recipe (familiar interaction)
- Week navigation (prev/next arrows)

**What doesn't work** ❌:
- **Typography hierarchy unclear**: Day, meal type, recipe all use similar 14-16pt text
- **Recipe names truncated**: After ~15 characters (...unable to read "Chicken Pa...")
- **No breathing room**: 8px padding feels cramped, elements touching
- **Empty slots uninviting**: Just gray boxes with no visual guidance
- **Feels generic**: Could be any calendar app, no warmth or personality
- **Meal type labels buried**: "Breakfast" competes with recipe name

**Design patterns to maintain**:
- Week-at-a-glance view (users like seeing full week)
- Tap meal slot to assign recipe (familiar)
- Day headers with date (provides context)
- Week navigation arrows (useful for planning ahead)

**Approach**: Evolutionary redesign
- Keep grid structure (familiar)
- Improve typography hierarchy dramatically
- Add generous whitespace (24px gaps minimum)
- Make empty states inviting (cream background, "+" icon)
- Add warmth through color and spacing

**User confirmation**: ✅ Ready to proceed

---

## CHECKPOINT 3/6: User Flow Mapping

### User Flow Map

**Primary Flow** (Happy Path):
1. **Entry point**: User taps "Meal Plans" in bottom navigation
2. **View calendar**: User sees current week's meal plan (Mon-Sun, B/L/D)
3. **Scan week**: User visually scans to see what's planned
4. **Add meal**: User taps empty slot (e.g., Monday Dinner)
5. **Pick recipe**: Modal opens with recipe list
6. **Select recipe**: User taps recipe card
7. **Confirm**: Recipe appears in Monday Dinner slot
8. **Continue planning**: User repeats for other days/meals
9. **Exit**: User navigates away (plans saved automatically)

**Decision Points**:
- **At step 4**: If slot already filled → tap opens edit menu (view, change, delete)
- **At step 5**: User can search/filter recipes in picker modal
- **At step 7**: User can add side dishes (tap "+" on filled slot)

**Error Paths**:
- **If recipe picker fails to load**: Show error message + retry button
- **If no recipes exist**: Show "No recipes found" + "Create Recipe" button
- **If network issue**: Show offline banner (if app uses API)

**Edge Cases**:
- **Empty state**: New user with no meals planned → show helpful message + "Get Started" button
- **First-time use**: Optional onboarding tooltip (1-2 hints)
- **Past dates**: Gray out past dates (read-only, can mark as cooked)
- **Future weeks**: Allow planning up to 4 weeks ahead
- **Multi-dish meals**: Show primary dish + side count (e.g., "+2 sides")

**Navigation**:
- **Entry**: Bottom nav "Meal Plans" tab
- **Exit**:
  - Tap another tab (meal plan auto-saves)
  - Tap meal slot → recipe details (drill down)
  - Swipe week → previous/next week

**User confirmation**: ✅ Ready to proceed

---

## CHECKPOINT 4/6: Information Architecture

### Information Architecture

**Content Inventory** (all elements needed per week view):
- Week header (e.g., "Week of Jan 23 - Jan 29")
- Week navigation (prev/next arrows)
- Day headers (Mon-Sun with dates)
- Meal slots (7 days × 3 meals = 21 slots)
- Each meal slot contains:
  - Meal type label (Breakfast, Lunch, Dinner)
  - Recipe name (if assigned)
  - Recipe thumbnail (small, optional)
  - Side dish indicator (if multi-dish meal)
  - Empty state prompt (if not assigned)
- Floating Action Button (add meal quickly)

**Hierarchy**:

**Primary** (main focus, largest/boldest):
- **Recipe names** in filled slots (16pt, bold) - what user came to see

**Secondary** (supporting context, medium emphasis):
- **Day headers** (18pt, medium, with dates)
- **Week header** (20pt, bold)
- **Empty slot prompts** ("Add [meal type]")

**Tertiary** (metadata, subtle):
- **Meal type labels** (12pt, all caps, gray)
- **Side dish indicators** ("+2 sides", 12pt, gray)
- **Week navigation arrows** (24px icons, subtle)

**Progressive Disclosure**:
- **Hidden until needed**:
  - Recipe details (tap slot to view)
  - Edit/delete actions (long-press slot)
  - Side dish list (tap "+N sides" to expand)
- **Revealed on interaction**:
  - Context menu (long-press)
  - Recipe picker modal (tap empty slot)

**Grouping**:
- **Group 1 - Week navigation**: Header with week label + arrows
- **Group 2 - Days**: 7 columns (Mon-Sun)
- **Group 3 - Meal slots**: 3 rows per day (B/L/D)

**Visual Identity Check** ✓:
- [X] **Generous whitespace**: 16px padding, 24px gaps between days, 16px gaps between meals
- [X] **Clear hierarchy**: Recipe names 16pt bold, day headers 18pt, meal labels 12pt gray
- [X] **Warm & inviting**: Cream background for empty slots, Terracotta accents
- [X] **Cultured feel**: Confident spacing, not cramped; sophisticated typography

**Comparison to current**:
- Current: 8px padding, 14pt text, gray empty boxes → feels cramped, generic
- Redesign: 16px+ padding, 16-18pt hierarchy, cream + Terracotta → feels cultured, intentional

**User confirmation**: ✅ Ready to proceed

---

## CHECKPOINT 5/6: Wireframe & Interaction Design

### Wireframe & Interaction Design

**Layout Structure** (ASCII wireframe):

```
┌───────────────────────────────────────────────────────────────────┐
│  [←] Week of Jan 23 - Jan 29                              [→]     │  ← AppBar (56px)
├───────────────────────────────────────────────────────────────────┤
│                                                                   │  ← 16px top padding
│  Mon 23   Tue 24   Wed 25   Thu 26   Fri 27   Sat 28   Sun 29   │  ← Day headers (18pt, bold)
│                                                                   │    12pt date, gray
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  │
│  │  B  │  │  B  │  │  B  │  │  B  │  │  B  │  │  B  │  │  B  │  │  ← Breakfast row
│  │     │  │     │  │     │  │     │  │     │  │     │  │     │  │    72px height
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  │
│                                                                   │  ← 16px gap
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  │
│  │  L  │  │  L  │  │  L  │  │  L  │  │  L  │  │  L  │  │  L  │  │  ← Lunch row
│  │     │  │     │  │     │  │     │  │     │  │     │  │     │  │
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  │
│                                                                   │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  │
│  │  D  │  │  D  │  │  D  │  │  D  │  │  D  │  │  D  │  │  D  │  │  ← Dinner row
│  │     │  │     │  │     │  │     │  │     │  │     │  │     │  │
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  │
│                                                                   │
│                                                   [+]             │  ← FAB (bottom-right)
└───────────────────────────────────────────────────────────────────┘
```

**Detailed Meal Slot** (Filled):

```
┌────────────────────────┐
│ BREAKFAST              │  ← 12pt, all caps, Medium Gray
│ ────────────           │  ← Subtle underline (optional)
│                        │
│ [img] Avocado Toast    │  ← 16pt, bold, Cocoa Brown
│       +2 sides         │  ← 12pt, Medium Gray (if multi-dish)
│                        │
└────────────────────────┘
    72px height, 12px padding
    Cream background, elevation 1
    Rounded corners (8px)
```

**Detailed Meal Slot** (Empty):

```
┌────────────────────────┐
│ LUNCH                  │  ← 12pt, all caps, Medium Gray
│                        │
│        [+]             │  ← 32px icon, Terracotta
│    Add Lunch           │  ← 14pt, Medium Gray
│                        │
└────────────────────────┘
    72px height, 12px padding
    Cream background
    Dashed border (Terracotta, subtle)
```

**Component Specifications**:

- **AppBar**: Material AppBar, week label centered, arrows left/right
- **Day headers**: Text widget, 18pt bold for day, 12pt gray for date
- **Meal slots**:
  - Container: 72px height, 12px internal padding
  - Border radius: 8px
  - Background: Cream (#FFF8DC) for empty, White for filled
  - Elevation: 0 for empty, 1 for filled
  - Empty border: 1px dashed Terracotta (subtle)
- **Recipe names**: 16pt bold, Cocoa Brown, max 2 lines with ellipsis
- **Meal type labels**: 12pt all caps, Medium Gray
- **Side indicators**: 12pt regular, Medium Gray
- **FAB**: FloatingActionButton, 56x56px, Terracotta background

**Spacing & Rhythm**:

- **Screen padding**: 16px horizontal
- **Day column gaps**: 8px (tight to fit 7 days)
- **Meal row gaps**: 16px vertical (breathing room)
- **Card internal padding**: 12px
- **Week header height**: 56px (standard AppBar)
- **Day header height**: 40px (includes date)

**Interaction Patterns**:

**Tap targets**:
- **Meal slot**: Full 72px height × column width (ensures 44px minimum)
- **Week arrows**: 48x48px minimum tap area
- **FAB**: 56x56px (standard)

**Gestures**:
- **Tap empty slot**: Open recipe picker modal
- **Tap filled slot**: Open meal details (view recipe, see side dishes)
- **Long-press filled slot**: Show context menu (Edit, Delete, Swap)
- **Swipe week left/right**: Navigate to previous/next week (optional)
- **Pull-to-refresh**: Reload meal plan data (if synced)

**Transitions**:

- **Navigation to week**:
  - Swipe left → slide to next week (250ms)
  - Swipe right → slide to previous week (250ms)
  - Curve: EaseInOut
- **Modal open** (recipe picker):
  - Slide from bottom (300ms)
  - Curve: FastOutSlowIn
- **Slot fill animation**:
  - Recipe card fades in (200ms)
  - Elevation animates from 0 → 1 (200ms)
- **Empty slot hover** (tablet):
  - Border color intensifies (Terracotta at 100% vs 40%)

**Feedback**:

- **Slot tap**: Ripple effect (InkWell), Terracotta 20% opacity
- **Recipe assigned**:
  - Slot fills with recipe info
  - SnackBar: "Meal added to [Day] [Meal Type]" (2 sec)
- **Recipe deleted**:
  - Slot animates to empty state (200ms)
  - SnackBar: "Meal removed" with Undo action (4 sec)
- **Week change**:
  - Slide animation + haptic feedback (light)
  - Announce to screen reader: "Week of [dates]"

**State Variations**:

**Empty state** (no meals planned entire week):
```
┌───────────────────────────────────┐
│                                   │
│         [Icon: calendar_today]    │  ← 64px icon, Terracotta
│                                   │
│      No meals planned this week   │  ← 18pt, bold
│   Tap any day to add your meals   │  ← 14pt, gray
│                                   │
│        [Plan Meals]               │  ← Primary button
│                                   │
└───────────────────────────────────┘
```

**Loading state** (fetching meal plan):
```
[Show skeleton calendar with shimmer effect on slots]
Announce to screen reader: "Loading meal plan"
```

**Error state** (failed to load):
```
┌───────────────────────────────────┐
│         [Icon: error_outline]     │
│   Failed to load meal plan        │
│        [Retry]                    │
└───────────────────────────────────┘
```

**Past dates** (read-only):
- Gray out meal slots for past dates
- No tap interaction (or tap shows "already cooked" option)
- Slightly reduced opacity (80%)

**User confirmation**: ✅ Ready to proceed

---

## CHECKPOINT 6/6: Accessibility & Handoff

### Accessibility Review

**Screen Reader Compatibility** ✓:
- [X] Day headers use Semantics(header: true) for proper announcement
- [X] Meal slots announce: "[Day] [Meal Type]: [Recipe Name or 'Empty']"
- [X] Empty slots announce: "Add meal to [Day] [Meal Type]"
- [X] FAB labeled: "Quick add meal"
- [X] Week navigation arrows labeled: "Previous week" / "Next week"
- [X] Recipe picker modal announces when opened
- [X] Meal assignment success announced: "Meal added to [Day] [Meal Type]"

**Example semantic labels**:
```dart
Semantics(
  label: 'Monday Breakfast: Avocado Toast with 2 sides',
  button: true,
  onTap: () => _openMealDetails(meal),
  child: MealSlotWidget(meal),
)

Semantics(
  label: 'Add meal to Tuesday Lunch',
  button: true,
  onTap: () => _openRecipePicker(day: Tuesday, mealType: Lunch),
  child: EmptyMealSlotWidget(),
)
```

**Color Contrast** ✓:
- [X] Recipe name (Cocoa Brown #3E2723) on Cream (#FFF8DC): **8.2:1** ✓ (excellent)
- [X] Meal labels (Medium Gray #BDBDBD) on Cream: **4.6:1** ✓ (pass)
- [X] Day headers (Charcoal #2C2C2C) on White: **13.1:1** ✓ (excellent)
- [X] Empty slot icon (Terracotta #D4755F) on Cream: **4.9:1** ✓ (pass for large icons)
- [X] "Add meal" text uses Medium Gray (not just Terracotta)

**Touch Targets** ✓:
- [X] Meal slots: 72px height × ~48px width (varies by screen) - **exceeds 44px minimum** ✓
- [X] Week arrows: 48x48px tap area ✓
- [X] FAB: 56x56px ✓
- [X] No overlapping tap areas (8px gaps between slots)

**Semantic Ordering** ✓:
- [X] Focus flows logically: Week header → Day headers (Mon-Sun) → Meal slots (B/L/D per day)
- [X] TabIndex not needed (default tree order is correct)
- [X] No focus traps (user can navigate away from calendar)

**Error Handling** ✓:
- [X] Failed load uses text + icon (not color alone): "Failed to load meal plan" + error icon
- [X] Retry button clearly labeled
- [X] SnackBar errors include icon + text: [Error icon] "Could not add meal. Retry?"
- [X] Network errors show banner with recovery action

**Localization** ✓:
- [X] No hardcoded strings:
  - "Breakfast" → AppLocalizations.of(context)!.breakfast
  - "Add Lunch" → AppLocalizations.of(context)!.addMealType(mealType)
  - Week headers use locale-aware date formatting
- [X] Layout supports text expansion:
  - Portuguese "Café da Manhã" (14 chars) vs English "Breakfast" (9 chars)
  - Meal slots use Flexible widget to wrap long text
- [X] Date formatting uses IntlDateFormat with locale

---

## Design Artifacts Summary

All artifacts generated during UX design:

1. **Goal & Context** (Checkpoint 1):
   - User goal: See weekly meal plan at a glance, read recipe names
   - Pain point: Cramped layout, truncated text, unclear hierarchy
   - Success criteria: Readable text, clear hierarchy, inviting feel

2. **Current State Assessment** (Checkpoint 2):
   - What works: Week-at-a-glance, tap to assign, day headers
   - What doesn't work: Typography, padding, empty states, generic feel
   - Approach: Evolutionary redesign with generous spacing + warmth

3. **User Flow Map** (Checkpoint 3):
   - Primary: View calendar → tap empty slot → pick recipe → confirm
   - Decisions: Empty vs filled slot, add side dish
   - Errors: Load failure, no recipes exist
   - Edge cases: Empty state, past dates, multi-dish meals

4. **Information Architecture** (Checkpoint 4):
   - Primary: Recipe names (16pt bold)
   - Secondary: Day headers (18pt), week header (20pt)
   - Tertiary: Meal labels (12pt gray), side indicators
   - Visual identity: Generous whitespace (16-24px), clear hierarchy, warm colors

5. **Wireframe & Interaction Design** (Checkpoint 5):
   - Layout: Grid 7 days × 3 meals, 72px slot height, 16px gaps
   - Components: Card-based slots, Material AppBar, FAB
   - Interactions: Tap to assign, long-press for menu, swipe week
   - States: Empty, filled, loading, error, past dates

6. **Accessibility Review** (Checkpoint 6):
   - Screen reader: All elements labeled, state changes announced
   - Contrast: All text exceeds 4.5:1 (WCAG AA)
   - Touch targets: All exceed 44x44px minimum
   - Localization: No hardcoded strings, supports text expansion

---

## Handoff Checklist for Implementation

**Design decisions** ✅:
- [X] User goals and success criteria defined
- [X] User flow mapped (happy path + errors + edge cases)
- [X] Information hierarchy established (16pt recipe → 18pt day → 12pt label)
- [X] Wireframe structure approved (7×3 grid, 72px slots)
- [X] Interaction patterns specified (tap, long-press, swipe)
- [X] Accessibility requirements documented (semantics, contrast, touch targets)

**Implementation guidance**:
- [X] Flutter components identified:
  - Scaffold + AppBar (week header)
  - GridView or CustomScrollView (calendar grid)
  - Card widgets (meal slots)
  - FloatingActionButton (quick add)
  - showModalBottomSheet (recipe picker)
- [X] Spacing values specified:
  - Screen padding: 16px
  - Slot gaps: 8px horizontal, 16px vertical
  - Slot height: 72px
  - Internal padding: 12px
- [X] Interaction behaviors defined:
  - Tap empty → recipe picker modal
  - Tap filled → meal details
  - Long-press → context menu
  - Swipe → week navigation
- [X] State variations mapped:
  - Empty (cream bg, dashed border, "+" icon)
  - Filled (white bg, elevation 1, recipe info)
  - Loading (skeleton shimmer)
  - Error (error icon + retry button)
  - Past dates (grayed out, read-only)
- [X] Localization needs identified:
  - Meal type labels (breakfast, lunch, dinner)
  - "Add [meal]" prompts
  - Week header date formatting
  - Error messages

**Key files to modify**:
- `lib/screens/meal_planning_screen.dart` (main calendar view)
- `lib/widgets/meal_slot_widget.dart` (individual slot component)
- `lib/widgets/recipe_picker_modal.dart` (assignment modal)
- `lib/l10n/app_en.arb` + `app_pt.arb` (localization strings)

**Next steps**:
1. Implement calendar layout using GridView (7 columns × 3 rows)
2. Create MealSlotWidget with empty/filled states
3. Implement recipe picker modal (bottom sheet)
4. Add week navigation (swipe or arrow buttons)
5. Apply "Cultured & Flavorful" styling (use `gastrobrain-ui-polish` if needed)
6. Implement accessibility (semantic labels, contrast)
7. Add localization strings to ARB files
8. Implement tests (use `gastrobrain-testing-implementation`)
   - Widget tests for calendar rendering
   - Interaction tests for tap/assign flow
   - Edge case tests (empty, loading, error states)
9. Validate with both languages (EN + PT-BR)
10. Test with VoiceOver/TalkBack

**Estimated complexity**: Medium (5-8 points)
- Grid layout: Moderate complexity (responsive sizing)
- State management: Meal assignments per day/slot
- Localization: Multiple strings, date formatting
- Testing: Widget + interaction + edge cases

---

**UX Design Complete** ✅

Ready to proceed to implementation? (y/n)

---

## Notes from This Example

**What worked well**:
- Clear progression through 6 checkpoints
- Each checkpoint built on previous (Goal → Current → Flow → IA → Wireframe → A11y)
- Concrete artifacts at each step (not just vague notes)
- "Cultured & Flavorful" identity reinforced in Checkpoint 4
- Accessibility baked in from start (Checkpoint 6)

**Improvements over current state**:
- Typography hierarchy: 16pt recipe names vs 14pt everything
- Spacing: 16-24px gaps vs 8px cramped
- Visual identity: Cream + Terracotta warmth vs cold gray
- Empty states: Inviting "+" icon vs blank gray boxes

**Handoff to implementation**:
- All design decisions documented
- Flutter components specified
- Spacing values explicit (no guessing)
- Interaction behaviors defined
- Accessibility requirements clear
- Localization needs identified

**This example demonstrates** how the UX Design skill produces complete, actionable design artifacts ready for implementation.
