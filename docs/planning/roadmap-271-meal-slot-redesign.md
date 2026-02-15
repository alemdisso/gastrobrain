# Roadmap: #271 — Redesign Meal Slot Component

| Field       | Value                                      |
|-------------|--------------------------------------------|
| **Type**    | UX / UI Redesign                           |
| **Priority**| P1                                         |
| **Estimate**| 5 points                                   |
| **Milestone**| 0.1.9 - Meal Planning UX Redesign         |
| **Depends on**| #279 (color system) — ✅ merged          |
| **Branch**  | `ux/271-meal-slot-redesign`                |

## Overview

Redesign the meal slot component in the weekly plan screen for better visual hierarchy and space efficiency. The current design has an overly prominent meal type badge, shows too much metadata (difficulty stars, cooking time) in filled slots, and the empty state lacks clear interactive affordance.

## Prerequisites

- [x] #279 color system merged (status-based colors already in `DesignTokens`)
- [ ] Review current implementation in `lib/widgets/weekly_calendar_widget.dart` (method `_buildMealSection`, lines 516-718)
- [ ] Verify understanding of status-based color system in `lib/core/theme/design_tokens.dart`

---

## Phase 1: Analysis & Understanding

- [ ] Read `_buildMealSection()` in `weekly_calendar_widget.dart` (lines 516-718) — understand full widget tree
- [ ] Read current meal type badge implementation (lines 556-595) — understand sizing, colors, layout
- [ ] Read filled slot metadata rendering (lines 602-692) — difficulty stars, cooking time, recipe count badge
- [ ] Read empty slot rendering (lines 693-712) — current "Add meal" pattern
- [ ] Review `DesignTokens` meal colors (lines 64-99) — status colors + badge colors
- [ ] Review responsive breakpoints (phone/tablet/landscape handling)
- [ ] Review existing test coverage in `test/widgets/weekly_calendar_widget_test.dart`
- [ ] Sketch new layout for both empty and filled states (mental model or comments)

**Key questions to resolve during analysis:**
- How much space does the current meal type badge consume vs recipe name?
- What's the maximum recipe name length before wrapping becomes a problem?
- How does the multi-recipe badge ("+N more") interact with long names?

---

## Phase 2: Implementation

### 2.1 — Redesign Meal Type Indicator (both states)

**Goal:** De-emphasize from prominent badge to subtle label.

- [ ] Replace `Container` badge with a compact inline label (icon + small text)
- [ ] Reduce visual weight: smaller font, lighter color, no background container
- [ ] Keep sun/moon icon but reduce size
- [ ] Position consistently in both empty and filled states (top-left or inline prefix)
- [ ] Ensure `mealBadge`/`mealBadgeContent` tokens still apply (or update tokens if needed)

### 2.2 — Redesign Empty Slot

**Goal:** Clear interactive affordance, integrated action message.

- [ ] Make entire card obviously tappable (subtle border, slight elevation or dashed border)
- [ ] Center the "+ Add meal" message as the primary content
- [ ] Meal type as small label above or prefix to the action message
- [ ] Add visual feedback on tap (ink splash already exists via `InkWell`)
- [ ] Ensure card treatment is consistent with filled state shape/size

### 2.3 — Redesign Filled Slot

**Goal:** Maximize recipe name space, reduce metadata noise.

- [ ] **Remove** difficulty stars row (lines 664-676)
- [ ] **Remove** cooking time display (lines 677-690)
- [ ] Give recipe name full horizontal width (except cooked checkmark)
- [ ] Apply `maxLines: 2` + `TextOverflow.ellipsis` for long recipe names
- [ ] Move recipe count ("+N more") below recipe name instead of beside it
- [ ] Meal type as small label (same treatment as empty state)
- [ ] Keep cooked checkmark icon (green, positioned at trailing edge)

### 2.4 — Update Design Tokens (if needed)

- [ ] Add/update tokens for subtle meal type label styling (font size, opacity)
- [ ] Verify existing status colors still work with new layout
- [ ] Ensure consistent spacing tokens used throughout

### 2.5 — Localization

- [ ] Review existing keys — `addMeal`, `lunch`, `dinner`, `additionalRecipesCount` likely sufficient
- [ ] Add new keys only if new UI text is introduced
- [ ] Update both `app_en.arb` and `app_pt.arb` if changes needed
- [ ] Run `flutter gen-l10n`

### 2.6 — Validate

- [ ] Run `flutter analyze` — no warnings
- [ ] Visual check on emulator/device for both states
- [ ] Check all 3 slot states: empty, planned, cooked
- [ ] Check multi-recipe meals render correctly
- [ ] Check responsive behavior (small screen < 360px)

---

## Phase 3: Testing

### 3.1 — Update Existing Widget Tests

- [ ] Update `weekly_calendar_widget_test.dart` — tests that assert on difficulty stars / cooking time must be removed or updated
- [ ] Update color system tests if badge rendering changes
- [ ] Verify all existing tests still pass after updates

### 3.2 — New Widget Tests

- [ ] Test meal type indicator is subtle/consistent across empty and filled states
- [ ] Test recipe name uses `maxLines: 2` with ellipsis overflow
- [ ] Test recipe count badge appears below recipe name (not beside)
- [ ] Test difficulty stars and cooking time are NOT rendered
- [ ] Test empty slot shows centered add-meal message with card treatment
- [ ] Test long recipe name (30+ chars) truncates gracefully
- [ ] Test multi-recipe meal displays correctly with new layout

### 3.3 — Responsive Tests

- [ ] Test on small screen (320dp width) — no overflow
- [ ] Test on regular phone (360-400dp) — proper spacing
- [ ] Test on tablet (600dp+) — layout adapts correctly

### 3.4 — Regression Tests

- [ ] Tap on empty slot still triggers `onSlotTap` callback
- [ ] Tap on filled slot still triggers `onMealTap` callback
- [ ] Cooked checkmark still appears for cooked meals
- [ ] Week navigation still works
- [ ] Bottom action bar unaffected
- [ ] Multi-recipe badge ("+N more") still accurate

### 3.5 — Run Full Suite

- [ ] `flutter test` — all pass
- [ ] `flutter analyze` — clean

---

## Phase 4: Documentation & Cleanup

- [ ] Update code comments in `_buildMealSection()` if structure changed significantly
- [ ] Commit: `ux: redesign meal slot component for better hierarchy (#271)`
- [ ] Push to `ux/271-meal-slot-redesign`
- [ ] Merge to develop
- [ ] Close issue #271

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/widgets/weekly_calendar_widget.dart` | Main redesign — meal type indicator, empty/filled slot layout, remove metadata |
| `lib/core/theme/design_tokens.dart` | Add/update tokens for subtle label styling (if needed) |
| `lib/l10n/app_en.arb` | New localization keys (if new text introduced) |
| `lib/l10n/app_pt.arb` | Portuguese translations (if new text introduced) |
| `test/widgets/weekly_calendar_widget_test.dart` | Update tests for new layout, remove metadata assertions |
| `test/widgets/weekly_calendar_widget_multi_recipe_test.dart` | Update if recipe count badge position changes |

---

## Acceptance Criteria

From issue + implicit requirements:

- [ ] Meal type indicator de-emphasized and consistent across empty/filled states
- [ ] Empty slots have clear interactive affordance (obvious clickability)
- [ ] Filled slots prioritize recipe name with maximum horizontal space
- [ ] Difficulty stars and cooking time **removed** from filled slots
- [ ] Recipe count appears below recipe title (multi-recipe meals)
- [ ] Long recipe names handled gracefully (truncation with ellipsis, max 2 lines)
- [ ] Visual hierarchy clear: content > metadata > type indicator
- [ ] Works on various screen sizes (320dp to tablet)
- [ ] Interaction patterns preserved (tap empty → add, tap filled → options)
- [ ] Localized correctly in EN and PT-BR
- [ ] All tests pass (`flutter test && flutter analyze`)
- [ ] No visual regressions elsewhere on the screen
