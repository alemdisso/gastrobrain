# Issue #134 — Landing Page MVP

## Overview

| Field | Value |
|-------|-------|
| **Issue** | #134 — UX: Add dedicated landing page to improve initial user experience and feature discoverability |
| **Type** | Feature (Enhancement) |
| **Priority** | P1 |
| **Size** | M (5 points) |
| **Milestone** | 0.1.10 — Landing Page & Documentation |
| **Branch** | `feature/134-landing-page` |

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

The app currently drops users into the Recipes tab on startup, missing an opportunity to showcase Gastrobrain's capabilities (AI recommendations, meal planning, multi-recipe meals). A new dashboard/landing screen should serve as the primary entry point with quick actions, summary statistics, and feature discoverability. The navigation should be restructured from 4 tabs to 3 tabs, demoting Tools to an overflow menu and combining Recipes + Ingredients into a "Content" tab.

### Technical Design Decision

**Selected Approach:** 3-Tab Clean

Restructure to 3 bottom tabs: **Dashboard | Meal Plan | Content**. Content tab uses a top `TabBar` to switch between Recipes and Ingredients. Tools becomes accessible via a gear icon (⚙️) in the AppBar, navigating to `ToolsScreen` as a pushed route.

```
Bottom Nav (3 tabs):
├─ 🏠 Dashboard (new, default)
├─ 📅 Meal Plan (existing WeeklyPlanScreen)
└─ 📖 Content
     ├─ Tab: Recipes (existing RecipesScreen)
     └─ Tab: Ingredients (existing IngredientsScreen)

Tools: AppBar gear icon → pushes ToolsScreen as full page
```

**Rationale:**
- 3 tabs is optimal for mobile — each tab gets more visual weight and touch area
- Recipes + Ingredients logically grouped as "content management"
- Tools is admin/dev utility, not a daily workflow — overflow menu is standard pattern
- Cleaner information architecture aligns with "Cultured & Clear" visual identity
- Solo developer = no muscle-memory migration concerns

**Alternative Considered:**
- **4-Tab Swap** (Dashboard replaces Tools, keep Recipes/Ingredients as separate tabs): Rejected because it missed the opportunity to simplify navigation and didn't address Ingredients feeling secondary.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Screen with DI | `lib/screens/weekly_plan_screen.dart:37-80` | Optional `databaseHelper` param, `ServiceProvider` in `initState` |
| Card layout | `lib/screens/tools_screen.dart:527-544` | `_buildSectionHeader()` with icon + title, Card with content |
| Design tokens | `lib/core/theme/design_tokens.dart` | All spacing, colors, typography |
| Summary service | `lib/core/services/meal_plan_summary_service.dart` | `MealPlanSummaryService.calculateSummary()` for weekly stats |
| Tab navigation | `lib/screens/home_screen.dart:34-60` | `BottomNavigationBar` with conditional AppBar |

### Data Sources for Dashboard

| Data Need | Source | Method |
|-----------|--------|--------|
| Recipe count | `DatabaseHelper` | `getRecipesCount()` |
| Recent meals | `DatabaseHelper` | `getRecentMeals(limit: 3)` |
| Current week plan | `DatabaseHelper` | `getMealPlanForWeek(DateTime.now())` |
| Plan summary | `MealPlanSummaryService` | `calculateSummary(plan)` |
| Today's planned items | `DatabaseHelper` | `getMealPlanItemsForDate(today)` |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| New user — zero data | Hero + quick actions visible; summary cards show friendly "Get started" prompts |
| Partial data (recipes, no plan) | Cards show individual CTAs per missing data type |
| No current week plan | "No plan yet — create one?" with CTA; uses `MealPlanSummary.empty()` |
| Dashboard stale after navigation | Refresh data when Dashboard tab re-selected |
| Content tab scroll position | `AutomaticKeepAliveClientMixin` on Recipes/Ingredients sub-tabs |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Dashboard data loading slows startup | Medium | Async load with skeleton; queries are lightweight counts |
| Nested TabBar in Content conflicts with bottom nav | Low | Well-established Flutter pattern with `DefaultTabController` |
| Breaking existing navigation tests | Medium | Update tab index references and test keys |
| Tools hardcoded string not localized | Low | Localize when moving to overflow menu |

### Testing Requirements

**Widget Tests:**
- [ ] Dashboard renders with full data (recipes, meals, plan exist)
- [ ] Dashboard renders empty states (no data at all)
- [ ] Dashboard renders partial data (recipes but no plan)
- [ ] Quick action buttons navigate to correct destinations
- [ ] Content tab switches between Recipes and Ingredients
- [ ] Tools accessible from overflow menu
- [ ] Dashboard refresh when returning from other tabs

**Edge Case Tests:**
- [ ] Empty state — zero recipes, zero meals
- [ ] Null meal plan for current week

---

## Phase 2: Implementation

### Step 1: Create branch and restructure navigation

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Create: `lib/screens/content_screen.dart`

**What to do:**
- Create feature branch `feature/134-landing-page`
- Create `ContentScreen` — `DefaultTabController` with 2 tabs (Recipes, Ingredients)
- Restructure `home_screen.dart` to 3 tabs: Dashboard (placeholder), Meal Plan, Content
- Remove Tools from bottom nav; add gear icon in AppBar that pushes `ToolsScreen`
- Dashboard tab initially shows a placeholder widget

**Verification:**
- [ ] App launches, 3 tabs visible
- [ ] Content tab shows Recipes/Ingredients with top TabBar
- [ ] Tools accessible via gear icon in AppBar
- [ ] `flutter analyze` clean

### Step 2: Create Dashboard screen with data loading

**Files:**
- Create: `lib/screens/dashboard_screen.dart`

**What to do:**
- StatefulWidget with optional `DatabaseHelper` for testing DI
- `initState`: async load recipe count, current week plan, recent meals
- State variables: `_isLoading`, `_recipeCount`, `_currentPlan`, `_recentMeals`
- Body: `SingleChildScrollView` with Column — sections added in steps 3-5
- Loading skeleton while data fetches

**Verification:**
- [ ] Dashboard loads data on startup without errors
- [ ] Loading indicator shown briefly, then content
- [ ] `flutter analyze` clean

### Step 3: Build Hero Section + Quick Actions

**Files:**
- Create: `lib/widgets/dashboard/hero_section.dart`
- Create: `lib/widgets/dashboard/quick_actions_panel.dart`

**What to do:**
- Hero: App tagline, brief recommendation engine description, "Plan This Week" CTA
- Quick Actions: 2x2 grid — Plan Today, This Week, Add Recipe, Browse Recipes
- Navigation callbacks passed from DashboardScreen
- Use `DesignTokens` for all styling

**Verification:**
- [ ] Hero section renders with tagline and CTA
- [ ] Quick action buttons render in grid
- [ ] Tapping actions triggers navigation callbacks
- [ ] `flutter analyze` clean

### Step 4: Build Summary Cards

**Files:**
- Create: `lib/widgets/dashboard/summary_cards.dart`

**What to do:**
- Recipe collection card (count + "Browse" link)
- This week's plan card (X/14 meals planned, or empty state)
- Recent meals card (last 2-3 cooked, or empty state)
- Each card handles its own empty state gracefully

**Verification:**
- [ ] Cards render with actual data
- [ ] Empty states show friendly CTAs
- [ ] `flutter analyze` clean

### Step 5: Localization

**Files:**
- Modify: `lib/l10n/app_en.arb` (~25 strings)
- Modify: `lib/l10n/app_pt.arb` (~25 strings)

**What to do:**
- Add all dashboard-related strings in both EN and PT
- Localize the previously hardcoded "Tools" string
- Run `flutter gen-l10n`

**Verification:**
- [ ] `flutter gen-l10n` runs clean
- [ ] All strings render in both EN and PT
- [ ] No hardcoded strings in new code

### Step 6: Dashboard refresh logic

**What to do:**
- Refresh dashboard data when tab is re-selected (tab change callback in `home_screen.dart`)
- Consider listening to `RecipeProvider` / `MealPlanProvider` for reactive updates

**Verification:**
- [ ] Add recipe → return to Dashboard → count updated
- [ ] Plan meal → return to Dashboard → plan status updated

### Step 7: Testing

**Files:**
- Create: `test/screens/dashboard_screen_test.dart`
- Create: `test/screens/content_screen_test.dart`

**What to do:**
- Widget tests for dashboard with full data, empty states, partial data
- Widget tests for quick action navigation
- Widget tests for Content tab switching
- Verify Tools accessible from overflow menu

**Verification:**
- [ ] All tests pass
- [ ] `flutter test` green
- [ ] `flutter analyze` clean

---

## Phase 3: Testing

*Detailed test implementation deferred to `gastrobrain-testing-implementation` skill.*

---

## Phase 4: Documentation & Review

- [ ] Update `docs/architecture/Gastrobrain-Codebase-Overview.md` with new navigation structure
- [ ] Code review with `gastrobrain-code-review` skill
- [ ] Merge to develop

---

## Files Summary

**To Create:**
- `lib/screens/dashboard_screen.dart`
- `lib/screens/content_screen.dart`
- `lib/widgets/dashboard/hero_section.dart`
- `lib/widgets/dashboard/quick_actions_panel.dart`
- `lib/widgets/dashboard/summary_cards.dart`
- `test/screens/dashboard_screen_test.dart`
- `test/screens/content_screen_test.dart`

**To Modify:**
- `lib/screens/home_screen.dart` (navigation restructure)
- `lib/l10n/app_en.arb` (~25 strings)
- `lib/l10n/app_pt.arb` (~25 strings)

---

*Phase 1 analysis completed on 2026-02-17*
*Ready for Phase 2 implementation*
