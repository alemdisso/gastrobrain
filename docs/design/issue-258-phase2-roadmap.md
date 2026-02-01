# Issue #258: Phase 2 Implementation Roadmap

**Status:** Ready to Execute
**Created:** 2026-02-01
**Branch:** `feature/258-polish-weekly-meal-planning-screen`
**Phase 1:** ✅ Complete (refactoring done - 1,019 lines)
**Phase 2:** 🎯 Ready to start

---

## Overview

Phase 2 consists of two sequential workstreams:

1. **Phase 2A: UX Redesign (Days 4-6)** - Restructure information architecture
2. **Phase 2B: Visual Polish (Day 7)** - Apply design tokens to redesigned structure

**Rationale for sequencing:** Polish the final design, not a temporary structure. Redesigning first avoids rework.

---

## Phase 2A: UX Redesign (Information Architecture)

**Goal:** Transform Planning/Summary tabs into Planning-always-visible with bottom sheet tools.

**Duration:** 4-6 hours
**Approach:** Checkpoint-driven implementation with verification at each step

---

### Checkpoint 1: Remove Tab Architecture ✓

**Objective:** Eliminate TabBar/TabBarView, make planning always visible.

**Tasks:**
1. Remove `TabController` from state (line 63)
   - Remove initialization in `initState()` (line 81)
   - Remove disposal in `dispose()` (line 1014)
2. In `build()` method (lines 944-1008):
   - Remove `TabBar` widget (lines 970-976)
   - Remove `TabBarView` wrapper (lines 982-999)
   - Replace with direct `WeeklyCalendarWidget` (always visible)
3. Remove `_buildSummaryView()` method (used in tab, will move to bottom sheet)

**Before:**
```dart
Column([
  WeekNavigationWidget(),
  TabBar(tabs: [Planning, Summary]),
  Expanded(
    TabBarView([
      WeeklyCalendarWidget(),
      _buildSummaryView(),
    ])
  ),
])
```

**After:**
```dart
Column([
  WeekNavigationWidget(),
  Expanded(
    WeeklyCalendarWidget(), // Always visible
  ),
])
```

**Verification:**
- [ ] Build succeeds
- [ ] Planning calendar visible on screen launch
- [ ] Week navigation still functional
- [ ] No tab bar visible

**Files modified:**
- `lib/screens/weekly_plan_screen.dart`

---

### Checkpoint 2: Add Persistent Bottom Bar ✓

**Objective:** Add persistent bottom bar with Summary and Shopping List buttons.

**Tasks:**
1. Add bottom sheet state to `_WeeklyPlanScreenState`:
   ```dart
   bool _isSummarySheetOpen = false;
   bool _isShoppingSheetOpen = false;
   ```

2. Create `_buildBottomBar()` method:
   ```dart
   Widget _buildBottomBar(BuildContext context) {
     return Container(
       height: 56,
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surface,
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.1),
             blurRadius: 8,
             offset: Offset(0, -2),
           ),
         ],
       ),
       child: Row(
         children: [
           Expanded(
             child: TextButton.icon(
               onPressed: _openSummarySheet,
               icon: Icon(Icons.analytics_outlined),
               label: Text(AppLocalizations.of(context)!.summaryTabLabel),
               style: TextButton.styleFrom(
                 foregroundColor: _isSummarySheetOpen
                   ? Theme.of(context).colorScheme.primary
                   : null,
               ),
             ),
           ),
           VerticalDivider(width: 1, thickness: 1),
           Expanded(
             child: TextButton.icon(
               onPressed: _openShoppingSheet,
               icon: Icon(Icons.shopping_cart_outlined),
               label: Text(AppLocalizations.of(context)!.shoppingListLabel),
               style: TextButton.styleFrom(
                 foregroundColor: _isShoppingSheetOpen
                   ? Theme.of(context).colorScheme.primary
                   : null,
               ),
             ),
           ),
         ],
       ),
     );
   }
   ```

3. Add placeholder methods:
   ```dart
   void _openSummarySheet() {
     // TODO: Implement in Checkpoint 3
   }

   void _openShoppingSheet() {
     // TODO: Implement in Checkpoint 4
   }
   ```

4. Update `build()` to add bottom bar:
   ```dart
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(...),
       body: Column([
         WeekNavigationWidget(),
         Expanded(WeeklyCalendarWidget()),
       ]),
       bottomNavigationBar: _buildBottomBar(), // NEW
     );
   }
   ```

**Verification:**
- [ ] Bottom bar visible with 2 buttons
- [ ] Buttons show correct icons and labels
- [ ] Buttons are tappable (no-op for now)
- [ ] Bottom bar has elevation/shadow
- [ ] Min height 56px (Material standard)

**Files modified:**
- `lib/screens/weekly_plan_screen.dart`

**Localization needed:**
- Check if `shoppingListLabel` exists in ARB files (may need to add)

---

### Checkpoint 3: Implement Summary Bottom Sheet ✓

**Objective:** Open Summary content in dismissible bottom sheet.

**Tasks:**
1. Implement `_openSummarySheet()`:
   ```dart
   void _openSummarySheet() {
     setState(() => _isSummarySheetOpen = true);

     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (context) => DraggableScrollableSheet(
         initialChildSize: 0.6,
         minChildSize: 0.3,
         maxChildSize: 0.9,
         builder: (context, scrollController) => Container(
           decoration: BoxDecoration(
             color: Theme.of(context).colorScheme.surface,
             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
           ),
           child: Column(
             children: [
               // Handle bar
               Container(
                 margin: EdgeInsets.symmetric(vertical: 8),
                 width: 40,
                 height: 4,
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                   borderRadius: BorderRadius.circular(2),
                 ),
               ),
               // Header
               Padding(
                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       AppLocalizations.of(context)!.summaryTabLabel,
                       style: Theme.of(context).textTheme.titleLarge,
                     ),
                     IconButton(
                       icon: Icon(Icons.close),
                       onPressed: () => Navigator.pop(context),
                     ),
                   ],
                 ),
               ),
               Divider(height: 1),
               // Summary content
               Expanded(
                 child: WeeklySummaryWidget(
                   summaryData: _summaryData,
                   weekStartDate: _currentWeekStart,
                   scrollController: scrollController,
                 ),
               ),
             ],
           ),
         ),
       ),
     ).whenComplete(() {
       setState(() => _isSummarySheetOpen = false);
     });
   }
   ```

2. Update `WeeklySummaryWidget` to accept `scrollController` parameter:
   - Modify widget constructor
   - Use provided controller in `SingleChildScrollView`

**Verification:**
- [ ] Tap "Summary" → bottom sheet slides up
- [ ] Sheet shows summary data (protein, time, variety)
- [ ] Drag down → sheet dismisses
- [ ] Tap outside → sheet dismisses
- [ ] Close button → sheet dismisses
- [ ] Button changes color when sheet open
- [ ] Planning calendar still visible behind scrim

**Files modified:**
- `lib/screens/weekly_plan_screen.dart`
- `lib/widgets/weekly_summary_widget.dart`

---

### Checkpoint 4: Implement Shopping List Bottom Sheet ✓

**Objective:** Open Shopping List options in bottom sheet with three modes.

**Tasks:**
1. Create `_buildShoppingListOptions()` method:
   ```dart
   Widget _buildShoppingListOptions(BuildContext context) {
     return Container(
       padding: EdgeInsets.all(16),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           Text(
             AppLocalizations.of(context)!.shoppingListLabel,
             style: Theme.of(context).textTheme.titleLarge,
             textAlign: TextAlign.center,
           ),
           SizedBox(height: 24),

           // Preview option
           Card(
             child: ListTile(
               leading: Icon(Icons.preview),
               title: Text('Preview Ingredients'), // TODO: Localize
               subtitle: Text('See what you\'d need to buy'),
               trailing: Icon(Icons.chevron_right),
               onTap: () {
                 Navigator.pop(context);
                 _showShoppingPreview();
               },
             ),
           ),
           SizedBox(height: 12),

           // Generate option
           Card(
             child: ListTile(
               leading: Icon(Icons.add_shopping_cart),
               title: Text('Generate Shopping List'),
               subtitle: Text('Create list for shopping'),
               trailing: Icon(Icons.chevron_right),
               onTap: () {
                 Navigator.pop(context);
                 _handleGenerateShoppingList();
               },
             ),
           ),
           SizedBox(height: 12),

           // View existing option (conditional)
           if (_hasExistingShoppingList())
             Card(
               child: ListTile(
                 leading: Icon(Icons.list),
                 title: Text('View Existing List'),
                 subtitle: Text('Open current shopping list'),
                 trailing: Icon(Icons.chevron_right),
                 onTap: () {
                   Navigator.pop(context);
                   _navigateToShoppingList();
                 },
               ),
             ),

           SizedBox(height: 12),
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('Cancel'),
           ),
         ],
       ),
     );
   }
   ```

2. Implement `_openShoppingSheet()`:
   ```dart
   void _openShoppingSheet() {
     setState(() => _isShoppingSheetOpen = true);

     showModalBottomSheet(
       context: context,
       backgroundColor: Colors.transparent,
       builder: (context) => Container(
         decoration: BoxDecoration(
           color: Theme.of(context).colorScheme.surface,
           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
         ),
         child: _buildShoppingListOptions(context),
       ),
     ).whenComplete(() {
       setState(() => _isShoppingSheetOpen = false);
     });
   }
   ```

3. Implement `_showShoppingPreview()` (placeholder for now):
   ```dart
   void _showShoppingPreview() {
     // TODO: Implement preview mode (future enhancement)
     // For now, just show a SnackBar
     SnackBarService.showInfo(
       context,
       'Preview mode coming soon!', // TODO: Localize
     );
   }
   ```

4. Implement `_hasExistingShoppingList()`:
   ```dart
   bool _hasExistingShoppingList() {
     // Check if there's an active shopping list for current week
     // TODO: Implement proper check via service
     return false; // Placeholder
   }
   ```

5. Implement `_navigateToShoppingList()`:
   ```dart
   void _navigateToShoppingList() {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => ShoppingListScreen(),
       ),
     );
   }
   ```

**Verification:**
- [ ] Tap "Shopping List" → options sheet appears
- [ ] Three options visible (Preview, Generate, View)
- [ ] Tap "Generate" → existing flow works (navigate to shopping list)
- [ ] Tap "Preview" → shows "coming soon" message
- [ ] Tap "Cancel" → sheet dismisses
- [ ] Tap outside → sheet dismisses
- [ ] Button changes color when sheet open

**Files modified:**
- `lib/screens/weekly_plan_screen.dart`

**Notes:**
- Preview mode is future enhancement (Stage 1 from UX doc)
- Current implementation supports Stage 3 (Generate/View)
- Localization strings needed for new options

---

### Checkpoint 5: Remove FloatingActionButton ✓

**Objective:** Remove old FAB (replaced by bottom bar button).

**Tasks:**
1. Remove `floatingActionButton` from `Scaffold` (lines 1003-1007)
2. Verify `_handleGenerateShoppingList()` is still called from new bottom sheet

**Before:**
```dart
Scaffold(
  appBar: ...,
  body: ...,
  floatingActionButton: FloatingActionButton.extended(...),
)
```

**After:**
```dart
Scaffold(
  appBar: ...,
  body: ...,
  bottomNavigationBar: _buildBottomBar(),
)
```

**Verification:**
- [ ] No FAB visible on screen
- [ ] Shopping list generation still works via bottom bar
- [ ] More screen space for planning calendar

**Files modified:**
- `lib/screens/weekly_plan_screen.dart`

---

### Checkpoint 6: Update WeekNavigationWidget Styling ✓

**Objective:** Simplify navigation hierarchy (2-row layout, conditional jump button).

**Current structure (WeekNavigationWidget):**
- Complex information hierarchy (5 competing elements)
- Jump to current week hidden in badge tap

**New structure:**
- **Row 1:** [←] Week date [Context badge] [→]
- **Row 2 (conditional):** Relative time + [Jump ⌂] button

**Tasks:**
1. Open `lib/widgets/week_navigation_widget.dart`
2. Review current `build()` implementation
3. Restructure to 2-row layout:
   ```dart
   Column(
     children: [
       // Row 1 - Always visible
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           IconButton(
             icon: Icon(Icons.chevron_left),
             onPressed: onPreviousWeek,
           ),
           Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text('Week of $formattedDate'),
               SizedBox(width: 8),
               _buildContextBadge(),
             ],
           ),
           IconButton(
             icon: Icon(Icons.chevron_right),
             onPressed: onNextWeek,
           ),
         ],
       ),

       // Row 2 - Conditional (only when not current week)
       if (timeContext != TimeContext.current)
         Padding(
           padding: EdgeInsets.only(top: 8),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(
                 _getRelativeTimeText(),
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                 ),
               ),
               IconButton(
                 icon: Icon(Icons.home, size: 20),
                 onPressed: onJumpToCurrentWeek,
                 tooltip: 'Jump to current week', // TODO: Localize
               ),
             ],
           ),
         ),
     ],
   )
   ```

4. Simplify context badge (reduce visual weight):
   ```dart
   Widget _buildContextBadge() {
     return Container(
       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: _getContextColor().withOpacity(0.2),
         borderRadius: BorderRadius.circular(4),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(_getContextIcon(), size: 14),
           SizedBox(width: 4),
           Text(
             _getContextLabel(),
             style: Theme.of(context).textTheme.bodySmall,
           ),
         ],
       ),
     );
   }
   ```

**Verification:**
- [ ] Week navigation shows simplified layout
- [ ] Jump button only appears when past/future
- [ ] Jump button has home icon (discoverable)
- [ ] Context badge is subtle (not competing with week date)
- [ ] Relative time text is gray/secondary
- [ ] All navigation functions work

**Files modified:**
- `lib/widgets/week_navigation_widget.dart`

**Design reference:**
- See `docs/design/issue-258-ux-redesign.md` lines 533-551

---

### Phase 2A Testing ✓

**Widget Tests:**
```dart
// test/screens/weekly_plan_screen_test.dart

testWidgets('shows planning calendar without tabs', (tester) async {
  await tester.pumpWidget(/*...*/);

  expect(find.byType(TabBar), findsNothing);
  expect(find.byType(WeeklyCalendarWidget), findsOneWidget);
});

testWidgets('shows persistent bottom bar with two buttons', (tester) async {
  await tester.pumpWidget(/*...*/);

  expect(find.text('Summary'), findsOneWidget);
  expect(find.text('Shopping List'), findsOneWidget);
});

testWidgets('opens summary bottom sheet on tap', (tester) async {
  await tester.pumpWidget(/*...*/);

  await tester.tap(find.text('Summary'));
  await tester.pumpAndSettle();

  expect(find.byType(WeeklySummaryWidget), findsOneWidget);
  expect(find.byType(ModalBottomSheet), findsOneWidget);
});

testWidgets('dismisses bottom sheet on drag down', (tester) async {
  await tester.pumpWidget(/*...*/);

  await tester.tap(find.text('Summary'));
  await tester.pumpAndSettle();

  await tester.drag(find.byType(DraggableScrollableSheet), Offset(0, 500));
  await tester.pumpAndSettle();

  expect(find.byType(WeeklySummaryWidget), findsNothing);
});

testWidgets('shopping list sheet shows three options', (tester) async {
  await tester.pumpWidget(/*...*/);

  await tester.tap(find.text('Shopping List'));
  await tester.pumpAndSettle();

  expect(find.text('Preview Ingredients'), findsOneWidget);
  expect(find.text('Generate Shopping List'), findsOneWidget);
});
```

**Manual Testing Checklist:**
- [ ] Planning calendar visible on launch
- [ ] Week navigation works (arrows, jump button)
- [ ] Summary button opens sheet
- [ ] Summary sheet shows correct data
- [ ] Summary sheet dismisses (drag, tap outside, close button)
- [ ] Shopping button opens options sheet
- [ ] Generate option works (creates shopping list)
- [ ] Preview shows "coming soon" message
- [ ] No FAB visible
- [ ] Bottom bar buttons change color when sheets open
- [ ] Test on EN and PT-BR locales

---

## Phase 2B: Visual Polish (Design Tokens)

**Goal:** Apply consistent visual identity using design tokens.

**Duration:** 2-3 hours
**Prerequisites:** Phase 2A complete and tested

---

### Checkpoint 7: Apply Color Tokens ✓

**Objective:** Replace all hardcoded colors with DesignTokens palette.

**Files to modify:**
1. `lib/screens/weekly_plan_screen.dart`
2. `lib/widgets/weekly_calendar_widget.dart`
3. `lib/widgets/week_navigation_widget.dart`
4. `lib/widgets/weekly_summary_widget.dart`

**Color replacements:**

**weekly_plan_screen.dart:**
- Bottom bar shadow: Use `Theme.of(context).shadowColor`
- Sheet background: Use `Theme.of(context).colorScheme.surface`
- Handle bar: Use `Theme.of(context).colorScheme.onSurfaceVariant`

**weekly_calendar_widget.dart:**
- Context colors (lines 226-246):
  - `Colors.grey.withAlpha(25)` → `DesignTokens.disabled.withOpacity(0.1)`
  - `Colors.grey.withAlpha(128)` → `DesignTokens.disabled`
  - `Theme.of(context).colorScheme.primary.withAlpha(15)` → Keep (uses theme)

**weekly_summary_widget.dart:**
- Icon colors:
  - `Color(0xFF6B8E23)` → `DesignTokens.accent` or custom token
  - `Color(0xFF2C2C2C)` → `DesignTokens.textPrimary`
  - `Color(0xFFD4755F)` → `DesignTokens.primary` or custom
- Text colors:
  - `Colors.grey[700]` → `DesignTokens.textSecondary`

**week_navigation_widget.dart:**
- Context badge background: Use theme colors with opacity
- Button colors: Use `Theme.of(context).colorScheme.primary`

**Verification:**
- [ ] No hardcoded Color() constructors in modified files
- [ ] All colors use DesignTokens or Theme
- [ ] Visual appearance consistent with design system
- [ ] Dark mode support (if applicable)

---

### Checkpoint 8: Apply Typography Tokens ✓

**Objective:** Replace hardcoded font sizes and weights with textTheme.

**Typography replacements:**

**weekly_summary_widget.dart:**
- `fontSize: 16, fontWeight: FontWeight.w600` → `Theme.of(context).textTheme.titleMedium`
- `fontSize: 14, fontWeight: FontWeight.w500` → `Theme.of(context).textTheme.bodyLarge`
- `fontSize: 18, fontWeight: FontWeight.bold` → `Theme.of(context).textTheme.headlineSmall`
- `fontSize: 14` → `Theme.of(context).textTheme.bodyMedium`

**week_navigation_widget.dart:**
- Week date: Use `textTheme.bodyLarge`
- Context badge: Use `textTheme.bodySmall`
- Relative time: Use `textTheme.bodySmall` with secondary color

**weekly_calendar_widget.dart:**
- Recipe names: Use `textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)`
- Metadata: Use `textTheme.bodySmall`

**Verification:**
- [ ] No hardcoded fontSize values
- [ ] No hardcoded FontWeight values
- [ ] Text hierarchy clear and consistent
- [ ] All text uses textTheme

---

### Checkpoint 9: Apply Spacing Tokens ✓

**Objective:** Replace hardcoded spacing with DesignTokens spacing scale.

**Spacing replacements:**

**Common patterns:**
- `EdgeInsets.all(16)` → `EdgeInsets.all(DesignTokens.spacingMd)`
- `EdgeInsets.symmetric(horizontal: 16)` → `EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd)`
- `SizedBox(height: 20)` → `SizedBox(height: DesignTokens.spacingLg)`
- `SizedBox(height: 24)` → `SizedBox(height: DesignTokens.spacingLg)`
- `SizedBox(height: 8)` → `SizedBox(height: DesignTokens.spacingSm)`
- `SizedBox(height: 12)` → `SizedBox(height: DesignTokens.spacingMd)`

**Apply to:**
- Bottom bar padding
- Bottom sheet padding
- Card padding
- Section gaps in summary
- Navigation widget padding

**Verification:**
- [ ] No hardcoded EdgeInsets values
- [ ] No hardcoded SizedBox values
- [ ] Spacing feels consistent and balanced
- [ ] Visual rhythm established

---

### Checkpoint 10: Polish Components ✓

**Objective:** Refine elevation, shadows, and visual details.

**Tasks:**
1. **Bottom bar elevation:**
   - Use `elevation: DesignTokens.elevationMd`
   - Or Material 3 elevation tokens

2. **Bottom sheet elevation:**
   - Use Material 3 default (already handled by showModalBottomSheet)

3. **Card elevation:**
   - Meal cards: `elevation: DesignTokens.elevationSm`
   - Summary cards: `elevation: DesignTokens.elevationSm`

4. **Border radius:**
   - Bottom sheet: `BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg))`
   - Cards: `BorderRadius.circular(DesignTokens.radiusMd)`
   - Badges: `BorderRadius.circular(DesignTokens.radiusSm)`

5. **Meal type badges (Almoço/Jantar):**
   - Consistent padding
   - Consistent background opacity
   - Icon size: 16px
   - Use meal type colors from theme

**Verification:**
- [ ] Elevation feels appropriate (not too heavy)
- [ ] Shadows subtle and consistent
- [ ] Border radius consistent across components
- [ ] Badges visually balanced

---

### Phase 2B Testing ✓

**Visual Testing Checklist:**
- [ ] Compare before/after screenshots
- [ ] Verify colors match design system
- [ ] Verify typography hierarchy
- [ ] Verify spacing consistency
- [ ] Test on different screen sizes (small, medium, large)
- [ ] Test with long text (Portuguese locale)
- [ ] Test dark mode (if supported)
- [ ] Verify touch targets ≥44px
- [ ] Verify no visual regressions

**Automated Testing:**
```bash
flutter analyze
flutter test
```

- [ ] All tests passing
- [ ] No analyzer warnings
- [ ] Code coverage maintained

---

## Final Deliverables

**Code:**
- [ ] UX redesign implemented (bottom sheets, persistent bottom bar)
- [ ] Visual polish applied (design tokens throughout)
- [ ] All tests passing (existing + new widget tests)
- [ ] No analyzer warnings

**Documentation:**
- [ ] Screenshots: Before/after comparison
- [ ] Pattern documentation for bottom sheet usage
- [ ] Updated component documentation if needed

**Verification:**
- [ ] Manual testing complete (all flows)
- [ ] Visual testing complete (EN + PT-BR)
- [ ] Responsive testing complete
- [ ] Accessibility check (touch targets, contrast)

---

## Issue Completion

Once all checkpoints complete:

1. **Commit changes:**
   ```bash
   git add .
   git commit -m "feat: redesign weekly plan screen with bottom sheet tools and visual polish (#258)"
   ```

2. **Push for testing:**
   ```bash
   git push origin feature/258-polish-weekly-meal-planning-screen
   ```

3. **Test on device** (via GitHub Actions or local)

4. **Merge to develop:**
   ```bash
   git checkout develop
   git merge feature/258-polish-weekly-meal-planning-screen
   git push origin develop
   ```

5. **Close issue:**
   ```bash
   gh issue close 258 --comment "Phase 2 complete: UX redesign + visual polish applied. Planning now always visible with bottom sheet tools pattern. All design tokens applied."
   ```

6. **Clean up branch:**
   ```bash
   git branch -d feature/258-polish-weekly-meal-planning-screen
   ```

---

**Status:** Ready to execute
**Next Step:** Begin Phase 2A, Checkpoint 1
**Estimated Total Time:** 6-9 hours
**Created:** 2026-02-01
