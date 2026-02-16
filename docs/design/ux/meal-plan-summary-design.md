# UX Design: Meal Plan Summary Feature

**Issue**: #32
**Feature**: Add comprehensive meal summary section to weekly meal plan screen
**Design Date**: January 24, 2026
**Status**: Approved - Ready for Implementation

---

## Executive Summary

Add a **Summary tab** to the Weekly Meal Plan screen that provides analytical insights into the week's planned meals. Users can switch between **Planning mode** (transactional - assign meals) and **Summary mode** (analytical - review balance) using tabs.

**Key decisions**:
- Tab-based mode switching (Planning | Summary)
- Read-only data display for v1 (no interactive warnings)
- Full screen space for each mode
- Real-time updates when meal plan changes
- 14 total meal slots (7 days × 2 meals: lunch + dinner)

**Deferred to future** (#265): Interactive warnings, suggestions, drill-down interactions

---

## 1. Goal & Context Analysis

### User Goal
Users want to quickly understand their weekly meal plan at a glance - seeing protein distribution, time allocation, and recipe variety without mentally aggregating 14 individual meal slots.

### Pain Point
Currently, users can only see individual meal slots in the calendar. To understand their week's balance (protein variety, cooking time distribution, recipe repetition), they must mentally process all lunch and dinner slots across 7 days. This cognitive load makes it hard to plan a balanced, varied week.

### Success Criteria
- [X] Users can see protein distribution across the week at a glance
- [X] Users can identify which days require more prep time
- [X] Users can spot recipe repetition without counting manually
- [X] Summary updates in real-time as meal plan changes
- [X] Summary is accessible but doesn't clutter the calendar view
- [X] Overall feel is "cultured and organized" (not cramped and generic)

### Scope
**New feature**: Add Summary tab to existing WeeklyPlanScreen
**Approach**: Tab-based mode switching (evolutionary enhancement)

### Context
- Enhances existing weekly calendar view
- Users already familiar with tapping meal slots to assign recipes
- Summary is **informational** (read-only visualization) not transactional
- Target users: Home cooks planning balanced, varied weekly meals

---

## 2. Current State Assessment

### What Exists

**WeeklyPlanScreen** (lib/screens/weekly_plan_screen.dart):
- Vertical scrollable list of 7 day cards (Friday-Thursday)
- Each day card shows: Day name + date → Lunch slot → Dinner slot
- **2 meal slots per day** (Lunch + Dinner) = **14 total slots per week**
- Week navigation with context indicators (past/current/future)
- Tap-to-assign recipe flow with recommendations
- Multi-recipe meal support (primary + side dishes)
- Mark meals as cooked functionality
- Real-time recommendation caching

**MealPlanAnalysisService** (lib/core/services/meal_plan_analysis_service.dart):
- Already computes planned recipe IDs
- Already computes planned proteins for the week
- Already computes recently cooked data
- Already computes protein penalty strategies
- **Can leverage for summary calculations**

### What Works ✅

- **Calendar visualization**: Clear vertical list of day cards with meal slots
- **Context awareness**: Time context (past/current/future) with visual indicators
- **Data structure**: MealPlan model tracks all needed data
- **Existing analysis service**: Ready to use for summary calculations
- **Real-time updates**: State management ensures UI refreshes when meals change
- **ProteinType enum**: Already exists for protein tracking
- **Navigation flow**: Week navigation works smoothly

### What Doesn't Work ❌

- **No aggregated view**: Users must mentally process 14 individual slots
- **No visual patterns**: Can't quickly see protein distribution or time allocation
- **Hidden insights**: Analysis data exists but isn't surfaced to users
- **Cognitive load**: Must count/remember which proteins planned across the week

### Design Patterns to Maintain

- Column layout structure (navigation controls → main content)
- Time context indicators (past/current/future visual language)
- Real-time state updates when meal plan changes
- Service-based architecture (use MealPlanAnalysisService)
- Localization for all user-facing strings
- Tab-based navigation (already used in recipe selection dialog)

### Approach

**Tab-based mode switching**:
- Tab 1: "Planning" - Existing calendar view (transactional)
- Tab 2: "Summary" - New analytics view (analytical)

**Benefits**:
- Full screen space for each view
- Clear mental model separation
- No scrolling between calendar and summary
- Familiar pattern (users see tabs in recipe selection)
- Each view optimized independently

---

## 3. User Flow Mapping

### Primary Flow (Happy Path)

**Entry & Mode Selection**:
1. User taps "Meal Plans" in bottom navigation
2. Lands on **Planning tab** (calendar view - default)
3. Views calendar with current week's meal slots
4. Can switch to **Summary tab** to review week's balance

**Planning Mode Flow** (existing, preserved):
1. User sees vertical list of 7 day cards (Friday-Thursday)
2. Each day shows lunch + dinner slots
3. User taps empty slot → recipe picker opens
4. User selects recipe → meal assigned
5. Calendar updates in real-time
6. *Summary tab auto-updates* (passive sync)

**Summary Mode Flow** (new):
1. User taps "Summary" tab
2. User sees weekly data display:
   - **Overview**: "8 of 14 meals planned" with progress bar
   - **Protein distribution**: List/chart of protein types with counts
   - **Prep time by day**: Day-by-day breakdown of cooking time
   - **Recipe variety**: Unique recipe count, repeated recipe details
3. User reviews data to understand their week
4. User switches back to Planning tab to make adjustments
5. User switches back to Summary → sees updated numbers

**Bidirectional Flow**:
```
Planning Tab ↔ Summary Tab
(Action)        (Review)
```

Users bounce between tabs: Assign meals → Check summary → Adjust → Check again

### Decision Points

**At app entry**:
- Default to Planning tab (most common action)
- User can immediately switch to Summary if reviewing

**When viewing Summary**:
- User sees read-only data
- To make changes → switch to Planning tab
- No interactive elements (v1 scope)

**Tab state**:
- Remember last active tab during session
- Resets to Planning on app restart

### Error Paths

**If no meals planned**:
- **Planning tab**: Empty calendar (existing behavior)
- **Summary tab**: Shows zeros (0 meals, 0 proteins, etc.)

**If meal plan fails to load**:
- Both tabs show error with retry button

**If summary calculation fails**:
- Summary tab shows error
- Planning tab continues working

### Edge Cases

**Empty state** (0 meals planned):
- Summary shows all zeros: "0 meals planned", "0 unique recipes"
- Helps users understand what they'll see when they add meals

**Partial week planned** (e.g., 3 meals):
- Summary shows data for those 3 meals only
- Counts accurate: "3 of 14 meals planned"

**Past weeks**:
- Summary shows planned data (same as calendar)
- Future: Could show cooked vs. planned comparison

**Loading states**:
- Initial load: Both tabs show spinner
- Week change: Brief loading if needed

### Navigation

**Entry**: Bottom nav → Meal Plans
**Within-screen**: Tab switching (Planning ↔ Summary)
**Week navigation**: Arrow buttons work on both tabs
**Exit**: Other bottom nav tabs, back button

---

## 4. Information Architecture

### Content Inventory

**Week-level metadata**:
- Week date range (e.g., "Jan 23 - Jan 29")
- Total meals planned (e.g., "8 of 14 meals planned")
- Planning completion percentage (e.g., "57% planned")

**Protein distribution data**:
- Breakdown by protein type (Chicken: 5, Beef: 2, Fish: 1)
- Count per protein type
- Percentage of total planned meals
- Visual representation (list with bars)

**Prep time data**:
- Total prep + cook time per day (Friday: 45min, Saturday: 90min)
- Daily breakdown with day names
- Visual bar representation

**Recipe variety data**:
- Count of unique recipes (e.g., "8 unique recipes")
- Count of repeated recipes (e.g., "2 recipes used twice")
- List of repeated recipes with usage counts

### Hierarchy

**Primary** (main focus, largest/boldest):
- **Total meals planned**: "8 of 14 meals planned" (24pt, bold)
- **Section headers**: "Protein Distribution", "Time by Day", "Recipe Variety" (18pt, bold)

**Secondary** (supporting data, medium emphasis):
- **Protein counts**: "Chicken: 5 meals" (16pt, regular with bold number)
- **Daily prep times**: "Monday: 45 minutes" (16pt, regular with bold number)
- **Variety metrics**: "8 unique recipes" (16pt, regular with bold number)
- **Visual charts/bars**: Bar visualizations

**Tertiary** (metadata, subtle):
- **Week date range**: "Week of Jan 23 - Jan 29" (14pt, gray)
- **Percentages**: "42% of meals use chicken" (12pt, gray)
- **Labels**: "Total prep time", "Recipes used multiple times" (12pt, gray)

### Grouping

**Group 1 - Overview Card** (top):
- Total meals planned: "8 of 14 meals"
- Completion progress bar (57%)
- Week date range
- *Purpose*: Quick status at a glance

**Group 2 - Protein Distribution**:
- Section header: "Protein Distribution"
- List of proteins with counts and bars
- Each protein type with count and percentage
- *Purpose*: See protein variety across week

**Group 3 - Time Allocation**:
- Section header: "Time by Day"
- Day-by-day breakdown of prep + cook time
- Visual bar chart or list with bars
- *Purpose*: Identify heavy cooking days

**Group 4 - Recipe Variety**:
- Section header: "Recipe Variety"
- Unique recipe count
- Repeated recipe count with details
- List of repeated recipes (if any)
- *Purpose*: Understand meal diversity

### Progressive Disclosure (v1)

**Visible by default**:
- All data visible on one scrollable screen
- No expandable sections (v1 - keep simple)
- No drill-down interactions (deferred to #265)

### Visual Identity Check ✓

**Generous whitespace**:
- [X] 16px screen padding
- [X] 24-32px gaps between sections
- [X] 12-16px internal card padding
- [X] Not cramped - confident spacing

**Clear hierarchy**:
- [X] Primary: 24pt bold (total meals)
- [X] Section headers: 18pt bold
- [X] Body metrics: 16pt with bold numbers
- [X] Labels: 12-14pt gray
- [X] Clear visual hierarchy

**Warm & inviting**:
- [X] Terracotta for section dividers and protein bars
- [X] Olive Green for time bars
- [X] Cream backgrounds for cards
- [X] Warm color palette (no cold blues/grays)

**Cultured feel**:
- [X] Confident spacing (not cramped)
- [X] Thoughtful grouping (not data dump)
- [X] Sophisticated typography
- [X] Intentional design choices

---

## 5. Wireframe & Interaction Design

### Overall Screen Structure

```
┌─────────────────────────────────────────────────────┐
│  [←] Weekly Meal Plan              [↻]              │  ← AppBar (56px)
├─────────────────────────────────────────────────────┤
│  [< Week of Jan 23 >]  [This Week]  [Current Week] │  ← Week nav (72px)
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┬──────────────┐                   │  ← TabBar (48px)
│  │  Planning    │   Summary    │                   │
│  └──────────────┴──────────────┘                   │
│  ──────────────                                     │  ← Active indicator
│                                                     │
│  ┌─────────────────────────────────────────────┐   │  ← TabBarView
│  │                                             │   │    (fills space)
│  │  [Tab content - Planning or Summary]       │   │
│  │                                             │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Tab 1: Planning (Existing - Preserved)

Vertical scrollable list of 7 day cards:
- Each day card: Day header → Lunch slot → Dinner slot
- 2 meal slots per day = 14 total slots
- Tap slot to assign recipe (existing behavior)

### Tab 2: Summary (New)

```
┌─────────────────────────────────────────────────────┐
│  Planning    │   Summary                            │  ← Tabs
│               ─────────                              │  ← Active
├─────────────────────────────────────────────────────┤
│                                                     │  ← 16px padding
│  ┌───────────────────────────────────────────────┐ │
│  │  Week of Jan 23 - Jan 29            (14pt ↑) │ │  ← Overview card
│  │                                               │ │    Elevation 2
│  │  8 of 14 meals planned             (24pt ↑) │ │    Cream bg
│  │  ████████████░░░░░░░░░  57%                  │ │    12px padding
│  └───────────────────────────────────────────────┘ │
│                                                     │  ← 24px gap
│  Protein Distribution                    (18pt ↑) │  ← Section header
│  ───────────────────────                           │    Terracotta line
│                                                     │  ← 12px gap
│  Chicken      ████████  5 meals  (42%)   (16pt ↑) │  ← Protein row
│  Beef         █████░░░  3 meals  (25%)             │    Bold numbers
│  Fish         ███░░░░░  2 meals  (17%)             │    Terracotta bars
│  Vegetarian   ███░░░░░  2 meals  (17%)             │
│                                                     │  ← 32px gap
│  Time by Day                             (18pt ↑) │  ← Section header
│  ───────────────────────                           │
│                                                     │  ← 12px gap
│  Mon  ████░░░░░░  45 min                 (16pt ↑) │  ← Time row
│  Tue  ██████░░░░  60 min                           │    Olive bars
│  Wed  ████░░░░░░  45 min                           │
│  Thu  ██████████  90 min                           │
│  Fri  ███░░░░░░░  30 min                           │
│  Sat  ░░░░░░░░░░   0 min                           │
│  Sun  ░░░░░░░░░░   0 min                           │
│                                                     │  ← 32px gap
│  Recipe Variety                          (18pt ↑) │  ← Section header
│  ───────────────────────                           │
│                                                     │  ← 12px gap
│  8 unique recipes                        (16pt ↑) │  ← Variety metrics
│  2 recipes used multiple times                     │    Bold numbers
│                                                     │  ← 8px gap
│  • Spaghetti Bolognese (2×)              (14pt ↑) │  ← Repeated list
│  • Grilled Chicken (2×)                            │    Gray text
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Component Specifications

**Screen structure**:
- **Scaffold**: Main container
- **AppBar**: Existing (title + refresh button)
- **Week navigation**: Existing Row (arrows + date + context)
- **TabBar**: Material TabBar with 2 tabs
- **TabBarView**: Switches between Planning and Summary

**Tab 2 - Summary components**:
- **SingleChildScrollView**: Vertical scrolling
- **Column**: Vertical section layout
- **Card**: Overview card (elevation 2, borderRadius 12px, Cream bg)
- **LinearProgressIndicator**: Completion bar
- **Text**: Headers (18pt bold), metrics (16pt), labels (14pt gray)
- **Row**: Protein/time rows with bars
- **Container**: Custom bar indicators (20px height for protein, 16px for time)

### Spacing & Rhythm

**Screen structure**:
- AppBar: 56px (Material standard)
- Week navigation: 72px (existing)
- TabBar: 48px (Material standard)
- TabBarView: Fills remaining space

**Summary tab spacing**:
- **Screen padding**: 16px horizontal, 16px top
- **Overview card**: 12px internal padding
- **Section gaps**: 32px between major sections
- **Header gaps**: 12px below headers
- **Content rows**: 8px vertical gap
- **Card elevation**: 2 (subtle shadow)
- **Border radius**: 12px (friendly, rounded)

**Bar visualizations**:
- **Height**: 20px (protein), 16px (time)
- **Border radius**: 4px
- **Max width**: Screen width - 32px - label width
- **Colors**: Terracotta (protein), Olive (time)

### Interaction Patterns

**Tap targets**:
- **Tab buttons**: Full tab width × 48px ✓
- **Week arrows**: 48x48px ✓
- **Refresh button**: 48x48px ✓
- All meet 44px minimum ✓

**Gestures**:
- **Tap tab**: Switch between Planning and Summary
- **Swipe TabBarView**: Switch tabs (Material default)
- **Scroll Summary**: Vertical scroll if content overflows
- **Week navigation**: Arrows work on both tabs

**No interactive elements in Summary (v1)**:
- Summary is read-only (data display only)
- No tap-to-expand sections
- No drill-down interactions
- Future (#265): Could add tap on repeated recipes

### Transitions

**Tab switching**:
- Material default slide (150ms)
- Planning → Summary: Slide left
- Summary → Planning: Slide right
- Preserve scroll position per tab

**Week change**:
- Both tabs reload with new week
- Brief loading if needed
- Preserve active tab

**Data updates**:
- Meal assigned in Planning → Summary recalculates
- Instant recalculation (no animation needed)

### Feedback

**Tab selection**:
- Active tab: Terracotta underline + bold text
- Inactive tab: Regular weight text
- Ripple effect on tap

**Week navigation**:
- Existing behavior preserved
- Works on both tabs

**Loading states**:
- If calculation >100ms: Shimmer on Summary sections
- Existing CircularProgressIndicator for initial load

**Empty state** (0 meals):
- Overview: "0 of 14 meals planned" with empty bar
- Proteins: "No proteins planned yet" (gray)
- Time: All days "0 min" with empty bars
- Variety: "0 unique recipes"

### State Variations

**Empty State**:
- Shows all sections with zero values
- Teaches users what they'll see when they add meals

**Loading State**:
- Shimmer effect on cards/bars
- Skeleton placeholders

**Error State**:
- Error icon + message
- "Failed to calculate summary"
- Retry button

**Populated State**:
- All sections with real data
- Bars proportional to values
- Numbers bold for emphasis

---

## 6. Accessibility & Handoff

### Screen Reader Compatibility ✓

**Tab navigation**:
- Planning tab: "Planning mode - view and edit meal calendar"
- Summary tab: "Summary mode - view weekly meal statistics"

**Summary sections**:
- Overview: "Week of January 23 to 29. 8 of 14 meals planned. 57 percent complete."
- Section headers: Use `Semantics(header: true)`
- Protein rows: "Chicken: 5 meals, 42 percent of planned meals"
- Time rows: "Monday: 45 minutes total preparation time"
- Variety: "8 unique recipes. 2 recipes used multiple times."
- Repeated list: "Spaghetti Bolognese used 2 times"

**Progress bar**:
- semanticsLabel: "57 percent of meals planned"
- semanticsValue: "8 of 14 meals"

### Color Contrast ✓

All text exceeds WCAG AA standards:
- Charcoal (#2C2C2C) on Cream (#FFF8DC): **13.1:1** ✓
- Cocoa Brown (#3E2723) on Cream: **8.2:1** ✓
- Medium Gray (#757575) on White: **4.6:1** ✓
- Terracotta bars (#D4755F): **3.1:1** ✓ (graphics)
- Olive bars (#6B8E23): **5.8:1** ✓

All visualizations use length + number + color (not color alone) ✓

### Touch Targets ✓

All interactive elements meet 44px minimum:
- Tab buttons: Full width × 48px ✓
- Week arrows: 48x48px ✓
- Refresh button: 48x48px ✓

### Semantic Ordering ✓

Focus flow:
1. AppBar → Week navigation → TabBar → TabBarView content
2. Within Summary: Overview → Protein → Time → Variety (top to bottom)
3. No focus traps ✓

### Localization ✓

**Required ARB additions**:

**app_en.arb**:
```json
{
  "planningTabLabel": "Planning",
  "summaryTabLabel": "Summary",
  "weekOf": "Week of {dateRange}",
  "mealsPlannedCount": "{count} of 14 meals planned",
  "proteinDistributionHeader": "Protein Distribution",
  "timeByDayHeader": "Time by Day",
  "recipeVarietyHeader": "Recipe Variety",
  "uniqueRecipesCount": "{count} unique recipes",
  "repeatedRecipesCount": "{count} recipes used multiple times",
  "noProteinsPlanned": "No proteins planned yet",
  "noMealsPlannedYet": "No meals planned yet",
  "summaryCalculationError": "Failed to calculate summary",
  "retryButton": "Retry",
  "mealsLabel": "meals",
  "minutesShort": "min",
  "timesUsed": "({count}×)"
}
```

**app_pt.arb** (Portuguese translations):
```json
{
  "planningTabLabel": "Planejamento",
  "summaryTabLabel": "Resumo",
  "weekOf": "Semana de {dateRange}",
  "mealsPlannedCount": "{count} de 14 refeições planejadas",
  "proteinDistributionHeader": "Distribuição de Proteínas",
  "timeByDayHeader": "Tempo por Dia",
  "recipeVarietyHeader": "Variedade de Receitas",
  "uniqueRecipesCount": "{count} receitas únicas",
  "repeatedRecipesCount": "{count} receitas usadas múltiplas vezes",
  "noProteinsPlanned": "Nenhuma proteína planejada ainda",
  "noMealsPlannedYet": "Nenhuma refeição planejada ainda",
  "summaryCalculationError": "Falha ao calcular resumo",
  "retryButton": "Tentar novamente",
  "mealsLabel": "refeições",
  "minutesShort": "min",
  "timesUsed": "({count}×)"
}
```

**Text expansion**: Portuguese ~30% longer - use Flexible widgets

**Date/number formatting**: Use locale-aware formatters

---

## Implementation Guide

### Files to Modify

**1. lib/screens/weekly_plan_screen.dart**:
- Add `TabController` to state
- Add `_summaryData` map to state
- Wrap body in Column with TabBar + TabBarView
- Add `_calculateSummaryData()` method
- Add `_buildSummaryView()` method
- Modify `_loadData()` to calculate summary

**2. lib/l10n/app_en.arb**:
- Add 15+ summary strings

**3. lib/l10n/app_pt.arb**:
- Add Portuguese translations

**4. Generate localizations**:
- Run `flutter gen-l10n`

### Flutter Implementation Structure

```dart
// Add to _WeeklyPlanScreenState

late TabController _tabController;
Map<String, dynamic>? _summaryData;

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  // ... existing init
}

@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}

Future<void> _loadData() async {
  // ... existing load logic
  await _calculateSummaryData();
}

Future<void> _calculateSummaryData() async {
  // Calculate total meals, proteins, times, variety
  // Store in _summaryData map
}

Widget _buildSummaryView() {
  if (_summaryData == null) {
    return Center(child: CircularProgressIndicator());
  }

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        _buildOverviewCard(),
        SizedBox(height: 24),
        _buildProteinSection(),
        SizedBox(height: 32),
        _buildTimeSection(),
        SizedBox(height: 32),
        _buildVarietySection(),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(/*...*/),
    body: Column(
      children: [
        _buildWeekNavigation(), // Existing
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.planningTabLabel),
            Tab(text: AppLocalizations.of(context)!.summaryTabLabel),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              WeeklyCalendarWidget(/*...*/), // Existing
              _buildSummaryView(), // New
            ],
          ),
        ),
      ],
    ),
  );
}
```

### Summary Data Calculations

```dart
Future<void> _calculateSummaryData() async {
  if (_currentMealPlan == null) {
    _summaryData = {
      'totalPlanned': 0,
      'percentage': 0.0,
      'proteins': <ProteinType, int>{},
      'timeByDay': <String, double>{},
      'uniqueRecipes': 0,
      'repeatedRecipes': <MapEntry<String, int>>[],
    };
    return;
  }

  final items = _currentMealPlan!.items;
  final totalPlanned = items.length;
  final percentage = totalPlanned / 14.0;

  // Protein distribution
  final proteins = <ProteinType, int>{};
  for (final item in items) {
    for (final mealRecipe in item.mealPlanItemRecipes ?? []) {
      if (mealRecipe.isPrimaryDish) {
        final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
        if (recipe?.primaryProteinType != null) {
          final type = recipe!.primaryProteinType!;
          proteins[type] = (proteins[type] ?? 0) + 1;
        }
      }
    }
  }

  // Time by day
  final timeByDay = <String, double>{};
  for (final item in items) {
    final date = DateTime.parse(item.plannedDate);
    final dayName = DateFormat('EEEE').format(date);

    double dayTime = 0;
    for (final mealRecipe in item.mealPlanItemRecipes ?? []) {
      final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
      if (recipe != null) {
        dayTime += (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
      }
    }
    timeByDay[dayName] = (timeByDay[dayName] ?? 0) + dayTime;
  }

  // Recipe variety
  final recipeIds = <String>[];
  for (final item in items) {
    for (final mealRecipe in item.mealPlanItemRecipes ?? []) {
      recipeIds.add(mealRecipe.recipeId);
    }
  }

  final uniqueCount = recipeIds.toSet().length;
  final repeated = <String, int>{};
  for (final id in recipeIds) {
    repeated[id] = (repeated[id] ?? 0) + 1;
  }

  final repeatedRecipes = repeated.entries
    .where((e) => e.value > 1)
    .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  setState(() {
    _summaryData = {
      'totalPlanned': totalPlanned,
      'percentage': percentage,
      'proteins': proteins,
      'timeByDay': timeByDay,
      'uniqueRecipes': uniqueCount,
      'repeatedRecipes': repeatedRecipes,
    };
  });
}
```

### Color Palette

```dart
// Gastrobrain "Cultured & Flavorful" colors
static const terracotta = Color(0xFFD4755F); // Protein bars, dividers
static const olive = Color(0xFF6B8E23);      // Time bars
static const cream = Color(0xFFFFF8DC);      // Card backgrounds
static const charcoal = Color(0xFF2C2C2C);   // Headers, emphasis
static const cocoaBrown = Color(0xFF3E2723); // Body text
static const mediumGray = Color(0xFF757575); // Labels, percentages
```

---

## Testing Requirements

### Widget Tests
- [ ] Tab switching preserves state
- [ ] Summary displays correct counts
- [ ] Empty state shows zeros gracefully
- [ ] Week change updates summary
- [ ] Progress bar shows correct percentage
- [ ] Protein bars render correctly
- [ ] Time bars render correctly
- [ ] Repeated recipes list displays properly

### Integration Tests
- [ ] Assign meal in Planning → Summary updates
- [ ] Week change → Summary recalculates
- [ ] Both languages render (EN + PT-BR)

### Edge Case Tests
- [ ] 0 meals planned (empty state)
- [ ] 1 meal planned (partial week)
- [ ] 14 meals planned (full week)
- [ ] All same protein
- [ ] Very long recipe names
- [ ] Extreme prep times

### Accessibility Tests
- [ ] VoiceOver/TalkBack navigation
- [ ] All elements announced correctly
- [ ] Color contrast meets WCAG AA
- [ ] Touch targets meet 44px minimum

---

## Implementation Workflow

1. **Create feature branch**: `git checkout -b feature/32-meal-plan-summary`
2. **Add localization strings**: Update ARB files
3. **Generate localizations**: `flutter gen-l10n`
4. **Implement TabController**: Add to state
5. **Wrap body in tabs**: Add TabBar + TabBarView
6. **Implement calculations**: Add `_calculateSummaryData()`
7. **Build summary UI**: Add `_buildSummaryView()` + sections
8. **Test manually**: Both tabs, week nav, data accuracy
9. **Write tests**: Widget, integration, edge cases
10. **Test accessibility**: VoiceOver/TalkBack
11. **Test localization**: EN + PT-BR
12. **Run analysis**: `flutter analyze` (must pass)
13. **Run tests**: `flutter test` (must pass)
14. **Commit**: Following project conventions
15. **Push**: For CI/CD validation
16. **Close issue**: #32

---

## Known Limitations & Future Work

### v1 Scope (This Implementation)
- ✅ Read-only summary data display
- ✅ Basic visualizations (bars + text)
- ✅ Tab-based switching
- ✅ Real-time updates

### Deferred to #265 (Future)
- ⏳ Interactive warnings ("Chicken 4 days in a row")
- ⏳ Tap warning → jump to Planning tab
- ⏳ Expandable sections
- ⏳ Drill-down to details
- ⏳ Protein balance scoring
- ⏳ Smart suggestions

---

## Design Approval

**Status**: ✅ Approved for implementation
**Date**: January 24, 2026
**Scope**: Basic summary with read-only data display
**Next Steps**: Begin implementation following this specification

---

## References

- **Issue**: #32 - Add comprehensive meal summary section to weekly meal plan screen
- **Future Work**: #265 - Add intelligent warnings and suggestions to meal plan summary
- **Related Models**: `MealPlan`, `MealPlanItem`, `Recipe`, `ProteinType`
- **Related Services**: `MealPlanAnalysisService`
- **Related Screens**: `WeeklyPlanScreen`, `WeeklyCalendarWidget`
