# Issue #295 — UX: Plan Today scrolls weekly plan to today's slot

| Field       | Value                                               |
|-------------|-----------------------------------------------------|
| Type        | Feature / UX                                        |
| Priority    | P2 (Medium)                                         |
| Size        | S (1-2 hours)                                       |
| Estimate    | 3 points                                            |
| Milestone   | 0.2.3 - UX Polish                                   |
| Status      | In progress                                         |
| Dependencies| None — l10n key `planTodaysMeal` already exists     |

---

## Overview

When the user taps "Plan Today" on the Dashboard, the Weekly Plan tab should open and
automatically animate to today's day row. Currently the tab always loads at Friday
(top of week). The feature mirrors the existing `DashboardScreenState.refreshData()`
GlobalKey pattern.

**Root cause of prior failure (#134):** `addPostFrameCallback` fired while
`_isLoading = true` — the `ListView` wasn't rendered yet, so `maxScrollExtent` was 0.
Fix: trigger the scroll *after* `_loadData()` sets `_isLoading = false`.

---

## Phase 1: Analysis & Understanding ✅

- [x] Read issue description and acceptance criteria
- [x] Trace `_HomePageState` GlobalKey pattern (`_dashboardKey`)
- [x] Confirm `WeeklyPlanScreen` is NOT persistent — re-mounted on each tab switch
- [x] Identify timing bug: scroll attempted before `ListView` is rendered
- [x] Confirm `planTodaysMeal` l10n key exists in both ARB files
- [x] Confirm `_scrollController` is already owned by `_WeeklyPlanScreenState` and passed to `WeeklyCalendarWidget`
- [x] Map weekday → day index formula: `(DateTime.now().weekday + 2) % 7`
  - Mon(1)→3, Tue(2)→4, Wed(3)→5, Thu(4)→6, Fri(5)→0, Sat(6)→1, Sun(7)→2
- [x] Confirm scroll offset formula: `(dayIndex / 6.0) * maxScrollExtent`
- [x] Confirm QuickActionsPanel is the right location for the new button

---

## Phase 2: Implementation

### 2.1 — `lib/screens/weekly_plan_screen.dart`

- [ ] Make state class public: rename `_WeeklyPlanScreenState` → `WeeklyPlanScreenState`
- [ ] Add flag: `bool _pendingScrollToToday = false;`
- [ ] Add public method `scrollToToday()`:
  - If `_currentWeekContext != TimeContext.current` → call `_jumpToCurrentWeek()` (already triggers `_loadData()`)
  - Set `_pendingScrollToToday = true`
  - If already on current week and `!_isLoading` → call `_scheduleScrollToToday()`
- [ ] In `_loadData()`, after `setState(() { _isLoading = false; })`, add:
  ```dart
  if (_pendingScrollToToday) {
    _pendingScrollToToday = false;
    _scheduleScrollToToday();
  }
  ```
- [ ] Add private method `_scheduleScrollToToday()`:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scrollController.hasClients) return;
    final today = DateTime.now();
    final dayIndex = (today.weekday + 2) % 7;
    if (dayIndex == 0) return; // Already at top (Friday)
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent == 0) return; // Failsafe
    final offset = (dayIndex / 6.0) * maxExtent;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  });
  ```
- [ ] Run `flutter analyze`

### 2.2 — `lib/screens/home_screen.dart`

- [ ] Add `GlobalKey<WeeklyPlanScreenState> _weeklyPlanKey = GlobalKey();`
- [ ] Change `const WeeklyPlanScreen()` → `WeeklyPlanScreen(key: _weeklyPlanKey)`
- [ ] Add `_onPlanToday()` method:
  ```dart
  void _onPlanToday() {
    _navigateToTab(1);
    // Post-frame so the tab switch setState has flushed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weeklyPlanKey.currentState?.scrollToToday();
    });
  }
  ```
- [ ] Add `onPlanToday: _onPlanToday` to `DashboardScreen(...)` instantiation
- [ ] Run `flutter analyze`

### 2.3 — `lib/screens/dashboard_screen.dart`

- [ ] Add `final VoidCallback? onPlanToday;` constructor parameter
- [ ] Pass `onPlanToday` to `QuickActionsPanel` (and/or wherever the button lives)
- [ ] Run `flutter analyze`

### 2.4 — `lib/widgets/dashboard/quick_actions_panel.dart`

- [ ] Add `final VoidCallback? onPlanToday;` parameter
- [ ] Change layout from single `Row` (3 items) to 2×2 grid to fit 4 buttons cleanly:
  - Row 1: "Plan Today" (`planTodaysMeal`) + "View This Week" (`viewThisWeek`)
  - Row 2: "Add Recipe" (`addRecipe`) + "Browse Recipes" (`browseRecipes`)
- [ ] Use `Icons.today` for the Plan Today button, `DesignTokens.success` color (visually distinct from View This Week)
- [ ] Run `flutter analyze`

### 2.5 — No localization changes needed
- `planTodaysMeal` already exists in `app_en.arb` and `app_pt.arb`

---

## Phase 3: Testing

### 3.1 — Unit / widget tests

- [ ] `test/widget/weekly_plan_screen_test.dart` — add:
  - [ ] `scrollToToday() sets _pendingScrollToToday and clears on load`
  - [ ] `scrollToToday() when not on current week triggers _jumpToCurrentWeek`
  - [ ] `scrollToToday() on Friday (dayIndex=0) does not call animateTo`
- [ ] `test/widget/home_screen_test.dart` — add:
  - [ ] `_onPlanToday switches to tab 1`
  - [ ] `_onPlanToday calls scrollToToday on WeeklyPlanScreenState`
- [ ] `test/widget/dashboard/quick_actions_panel_test.dart` — add:
  - [ ] `Plan Today button is rendered`
  - [ ] `Tapping Plan Today calls onPlanToday callback`
  - [ ] `onPlanToday = null does not throw`

### 3.2 — Run full test suite
- [ ] `flutter test`
- [ ] `flutter analyze`

### 3.3 — Manual / virtual device test (REQUIRED — cannot be replaced by unit tests)
- [ ] Launch app on Android emulator or physical device
- [ ] **Happy path – weekday**: Open app on any day Mon–Thu. Tap "Plan Today" on Dashboard. Verify calendar animates to today's row.
- [ ] **Happy path – Friday**: Open app on a Friday. Tap "Plan Today". Verify no scroll occurs (already at top).
- [ ] **Other week displayed**: Navigate to next week in Weekly Plan. Return to Dashboard. Tap "Plan Today". Verify it jumps back to current week AND scrolls to today.
- [ ] **Normal navigation unaffected**: Tap the Meal Plan tab directly (not via Plan Today). Verify it loads at Friday (no scroll).
- [ ] **"View This Week" unaffected**: Tap "View This Week" on Dashboard. Verify it loads at Friday (no scroll).
- [ ] **Animation quality**: Verify scroll is smooth (~400ms, easeInOut). No jump/flash.
- [ ] **PT locale**: Switch device to Portuguese. Verify button label reads "Planejar Hoje".

---

## Phase 4: Documentation & Cleanup

- [ ] Run final `flutter analyze && flutter test`
- [ ] Commit: `feature: Plan Today scrolls weekly plan to today's slot (#295)`
- [ ] Push branch and merge to `develop`
- [ ] Close issue #295
- [ ] Delete feature branch

---

## Files to Modify

```
lib/screens/weekly_plan_screen.dart          — public state, scrollToToday(), pending flag
lib/screens/home_screen.dart                 — _weeklyPlanKey, _onPlanToday()
lib/screens/dashboard_screen.dart            — onPlanToday param
lib/widgets/dashboard/quick_actions_panel.dart — Plan Today button, 2×2 layout
```

---

## Acceptance Criteria (from issue)

- [ ] Dashboard has a "Plan Today" quick action button
- [ ] Tapping it navigates to the Meal Plan tab AND scrolls to today's day slot
- [ ] If today is Friday (already at top), no scroll occurs
- [ ] If viewing a different week, jumps to current week first, then scrolls
- [ ] Normal navigation (tab tap, "View This Week") still loads at Friday as before
- [ ] Smooth scroll animation (~400ms, easeInOut curve)
