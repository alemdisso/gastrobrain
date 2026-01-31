# Issue #258: Weekly Meal Planning Screen - UX Redesign

**Status:** In Progress - UX Discovery Phase
**Created:** 2026-01-31
**Branch:** `feature/258-polish-weekly-meal-planning-screen`
**Related:** [issue-258-analysis.md](./issue-258-analysis.md)

---

## Executive Summary

Refactoring phase is complete. Now addressing UX/UI polish. User feedback reveals fundamental information architecture issues beyond visual styling:

1. **Week navigation feels clumsy** (hierarchy/layout problems)
2. **Shopping list button too prominent** (visual weight issue)
3. **Planning/Summary tabs compete for attention** (should be primary + tools, not equal tabs)

**Core insight:** Planning should be primary focus, with Summary and Shopping List as auxiliary tools - not peer tabs.

---

## UX Discovery Process

Following checkpoint-based UX design methodology.

### CHECKPOINT 1/6: Goal & Context Analysis

#### User Goal
Users want to quickly plan their weekly meals by viewing the week at a glance, filling meal slots with recipes, and occasionally checking summary metrics or generating a shopping list—**without those secondary tools distracting from the primary planning task**.

#### Pain Points
1. **Week navigation feels clumsy** - Something about the navigation area doesn't feel natural
2. **Shopping list button too prominent** - FloatingActionButton takes up significant space and draws too much attention
3. **Planning/Summary tabs fight for attention** - TabBar treats Planning and Summary as equal peers, pulling focus away from planning

#### Success Criteria
- [ ] Week navigation feels natural and unobtrusive
- [ ] Shopping list generation is accessible but doesn't dominate the screen
- [ ] Summary information is available as a supporting tool, not a competing view
- [ ] Planning calendar remains the primary, always-visible focus
- [ ] Users can quickly access tools (summary, shopping list) without leaving planning context

#### Scope
Redesign of Weekly Meal Planning screen information architecture - reorganize hierarchy to keep planning primary with summary/shopping as auxiliary tools.

---

## Navigation Investigation Findings

### Usage Pattern Discovery

**Actual navigation behavior:**
- **90% of the time**: Current week ↔ Next week (planning ahead)
- **Occasionally**: 2-3 weeks into future (special planning)
- **Rarely**: Deep into past (future use case: "find that week when we ate tuna")

**Design implication:** Optimize for the common case (current ↔ next), not edge cases.

### Problems Identified

#### 1. Hidden "Jump to Current Week" Functionality

**Current state:**
- "Jump to Current Week" is triggered by tapping the Past/Current/Future label
- The label looks like **read-only status text**, not an interactive button
- Has tooltip "Tap to jump to current week" but requires explanation
- **"If you have to explain it, it's complicated from the beginning"** ✓

**User preference:**
- ✅ Keep the Past/Current/Future label (provides useful context)
- ✅ Make "Jump to Current Week" a separate, explicit button
- ✅ Use a return/home icon to make it discoverable
- ✅ Only show when timeContext = Past or Future (conditional visibility)

**Root cause:** Hidden functionality in disguised UI element (label that's secretly a button).

#### 2. Layout & Hierarchy Issues

**Current structure (WeekNavigationWidget):**
```
[←]  |  Week of 15/1/2026                    | [→]
     |  [📅 Current] • Next week 🎯           |
     |  "Tap to jump to current week"         |
```

**Identified problems:**

**a) Unclear visual hierarchy**
- "Week of [date]" = titleMedium (looks like primary info)
- Context badge ([📅 Current]) = smaller but visually heavy (bg color, border, icon)
- Relative time ("Next week") = bodySmall text
- No clear parent-child relationship between these elements

**b) Alignment chaos**
- Arrow buttons on outer edges (spaceBetween)
- Center content is Column with nested Rows
- Everything center-aligned but doesn't relate visually to arrows
- Arrows and content feel like separate components, not unified navigation bar

**c) Information overload**
Five pieces of information competing for attention:
1. Week of [date]
2. Context badge (icon + Past/Current/Future label)
3. Relative time text ("2 weeks ago", "next week")
4. Jump hint icon (🎯)
5. Jump hint text ("Tap to jump to current week")

**d) Visual weight imbalance**
- Context badge has background, border, icon, text → visually heavy
- But it's not the most important info (the week date is)
- Creates confusion about what to focus on

### Direction for Redesign

**Principles:**
- Simplify: reduce competing elements
- Clarify hierarchy: establish clear primary vs. supporting information
- Separate concerns: status indicators vs. action buttons
- Optimize for common case: make current ↔ next week navigation effortless
- Discoverability: don't hide functionality in disguised UI elements

**Deferred to Checkpoint 5 (Wireframe Design):** Specific layout solution

---

## Pending Discovery Questions

### Question 2: Mental Model ✓

**Answer:** Planning is **two-phase** (mix of creation + refinement)

**Phase 1: Creation ("Filling slots")**
- Starting with empty or partially-filled week
- Placing recipes into meal slots
- Initial composition of the week

**Phase 2: Refinement ("Tweaking the draft")**
- Reviewing what's been planned
- Making adjustments and changes
- Iterative process, not one-shot

**Two distinct recipe swapping scenarios:**

**Scenario A: During Planning (Reorganization)**
- User adds Recipe X to Monday
- Moments later realizes "this fits better on Wednesday"
- Wants to **move/shuffle** recipes between days
- Happens during active planning session
- **Future feature opportunity:** Drag-and-drop reorganization

**Scenario B: After Real-Life Changes (Replacement)**
- User planned Recipe X for Monday dinner
- Real life happened: plans changed, already cooked it elsewhere, etc.
- Wants to **replace** the planned recipe with something else
- Happens post-planning, as adjustment to reality

**Key insight:** These are different interactions:
- Scenario A = reorganizing the plan (shuffling within the week)
- Scenario B = updating the plan (replacing with different recipe)

**Summary Data During Planning:**
- **Current reality:** Summary is NOT particularly useful during active planning
- The planning view itself provides good enough "broad view" of the week
- Can see balance and variety visually from the calendar
- **Implication:** Reinforces that Summary should be a **supporting tool**, not peer tab competing for attention

### Question 3: Summary Usage Pattern ✓

**Answer:** Summary exists more as a placeholder than a truly valuable feature.

**Background:**
- Recently added functionality
- Built because it seemed like a good idea + was simple to implement
- Single user currently (limited usage data)

**Current value assessment:**
- **Planned Meals list:** Useful ✓
- **Other summary info** (protein rotation, variety metrics, etc.): Not particularly valuable

**Decision:** Keep Summary as-is (don't remove or redesign content), but **reduce its prominence** in the UI. It should be a supporting element, not a peer tab competing with Planning.

**Implication:** Confirms original instinct - Planning is primary, Summary should be accessible but not prominent.

### Question 4: Shopping List Generator ✓

**Context:** First week using shopping list feature - projecting typical use based on routine.

**User routine:**
- Plans meals on Thursdays
- Shops on Friday mornings

**Projected usage pattern:**
Three-stage workflow (but only Stage 3 currently exists):

**Stage 1: Preview/Projected Mode (during planning)**
- "What would I need to buy if I cooked these meals?"
- Helps inform planning decisions (avoid expensive ingredients? etc.)
- Lightweight, non-committal preview
- **Multiple views** during active planning session

**Stage 2: Refinement Mode (after planning, before shopping)**
- Review the projected list
- **Uncheck items** you don't need to buy (already have, substitutions, etc.)
- Curate what you actually need
- This is the real "generate for shopping" moment

**Stage 3: Shopping Mode (at the store)**
- Clean, focused list of **only items to buy**
- Check off items as you add to cart
- User-friendly shopping experience
- **Current implementation:** Only this stage exists

**Current limitation:** Shopping list is primitive - only supports Stage 3 (final list).

**Missing functionality:**
- Preview during planning (Stage 1)
- Refinement/curation before shopping (Stage 2)

**Design implication:**
- Shopping list should be integrated as a **tool within planning context** (for preview)
- Preview mode should be lightweight and accessible during planning
- "Generate for shopping" should trigger refinement flow (Stage 2 → Stage 3)
- Explains why FAB feels too prominent (it only handles final stage, not the full workflow)

---

## Design Artifacts

### Current State Assessment (Checkpoint 2)

**What exists:**
- TabBar with Planning and Summary as equal-weight tabs
- WeekNavigationWidget with complex information hierarchy
- FloatingActionButton.extended for shopping list generation
- WeeklyCalendarWidget (primary planning interface)
- WeeklySummaryWidget (summary view)

**What works** ✅:
- Week-at-a-glance calendar view (users like seeing full week)
- Tap-to-assign recipe interaction (familiar)
- Summary data is useful (protein rotation, variety metrics)
- Shopping list generation from meal plan

**What doesn't work** ❌:
- Planning/Summary tabs compete for attention (should be primary + tool)
- Shopping list FAB too prominent (takes screen real estate)
- Week navigation has hidden functionality + unclear hierarchy
- Summary is hidden behind tab (should be accessible while planning)

**Design patterns to maintain:**
- Friday-Thursday week structure (established convention)
- Meal slot interaction patterns (tap empty = add, tap filled = menu)
- Time context awareness (Past/Current/Future)
- Recommendation integration in recipe selection

**Approach:** Evolutionary improvement with architectural restructuring
- Keep proven patterns (calendar, interactions)
- Redesign information architecture (tabs → primary + tools)
- Simplify navigation (clear hierarchy, discoverable actions)

---

## User Flow Mapping (Checkpoint 3)

### Primary Flow: Planning a Week (Happy Path)

**Entry Point:** User navigates to Weekly Meal Plan screen

**Phase 1: Creation (Filling Empty Slots)**
1. User lands on Planning view (calendar visible)
2. User navigates to desired week (usually current or next)
   - Uses arrow buttons (← / →) for week-by-week movement
   - Sees time context indicator (Past/Current/Future)
3. User identifies empty meal slot
4. User taps empty slot (e.g., "Monday Dinner")
5. System shows RecipeSelectionDialog:
   - "Try This" tab (top 8 recommendations)
   - "All Recipes" tab (full catalog with scores)
6. User selects primary recipe + optional side dishes
7. System adds meal to slot, updates calendar
8. **Repeat steps 3-7** until satisfied

**Phase 2: Refinement (Adjusting the Plan)**
9. User reviews planned week (scrolls calendar)
10. User identifies meal to adjust
11. User taps filled slot
12. System shows meal options menu
13. User selects action (change/manage/remove/etc.)
14. System shows appropriate dialog
15. User makes changes, confirms
16. System updates slot, refreshes calendar
17. **Repeat steps 10-16** as needed

**Exit Point:** User leaves screen (auto-saved)

### Decision Points & Branches

**Week Navigation (Step 2):**
- If current week → No jump button needed
- If past/future → Jump button appears
  - Tap jump → Return to current week

**Slot Tap (Step 4):**
- If empty → RecipeSelectionDialog (add meal)
- If filled → Meal options menu
  - If not cooked → Options: View, Change, Manage, Mark as Cooked, Remove
  - If cooked → Options: View, Change, Manage, Edit Cooked, Manage Side Dishes, Remove

**Recipe Selection (Step 6):**
- If cancel → Return to calendar, no changes
- If select → Add meal to slot

**Meal Actions (Step 13):**
- "View recipe details" → RecipeDetailsScreen
- "Change recipe" → RecipeSelectionDialog
- "Manage recipes" → RecipeSelectionDialog (pre-selected)
- "Mark as cooked" → MealRecordingDialog
- "Remove from plan" → Delete meal, clear slot

### Secondary Flow: Shopping List Generation

**Current Implementation (Stage 3 only):**
1. User taps FloatingActionButton "Generate Shopping List"
2. Decision point:
   - No existing list → Generate new, navigate to ShoppingListScreen
   - Existing list → Show options: Cancel / View existing / Regenerate
3. User views/uses shopping list
4. User returns to weekly plan

**Desired Three-Stage Workflow (Future Enhancement):**

**Stage 1: Preview during Planning**
1. User actively planning meals
2. Wants to see "what would I need to buy?"
3. Accesses shopping list preview (tool)
4. System shows projected ingredients (read-only, lightweight)
5. User reviews, makes planning decisions
6. Returns to planning
7. **Repeat as needed** (multiple previews)

**Stage 2: Refinement before Shopping**
8. User finishes planning
9. Accesses "Generate Shopping List"
10. System shows refinement view (all projected ingredients)
11. User unchecks items not needed (already have, etc.)
12. User confirms final list
13. System generates shopping list

**Stage 3: Shopping Mode**
14. User at store with phone
15. Opens shopping list (clean, focused)
16. Checks off items as purchased
17. Completes shopping

### Error Paths

**No recipes available:**
- User taps empty slot → No recipes in DB
- Show SnackBar "No recipes available"
- Recovery: Navigate to Recipes section to add some

**Recipe not found:**
- Recipe ID in meal plan but not in DB (data inconsistency)
- Show error, allow removal of broken meal
- Recovery: Remove broken meal, add new one

**Database error:**
- Any operation fails
- Show SnackBar with error + retry option
- Recovery: User retries or refreshes

**Dialog cancellation:**
- User presses back/cancel in any dialog
- Close dialog, return to calendar, no changes
- Recovery: User can retry action

### Edge Cases

**Empty State:**
- No meal plan for week → All empty slots
- Show "+ Add Meal" placeholder on each slot

**Loading State:**
- While fetching meal plan → CircularProgressIndicator
- Usually <500ms

**Real-life Changes (Scenario B):**
- Planned meals but life happened
- User taps meal → Change/Remove
- System allows replacement/deletion

**Navigating Far from Current:**
- User goes 5+ weeks past/future (rare)
- "Jump to Current Week" becomes important
- Recovery: Tap jump button

**Partial Week Planning:**
- User only plans some meals (valid)
- System allows any filled/empty combination
- Shopping list includes only planned meals

**Multiple Side Dishes:**
- User adds many sides (supported)
- UI shows "+X more" badge
- Tap to manage all recipes

### Navigation

**Entry Points:**
- Bottom navigation bar
- Direct link from home (if implemented)
- Deep link from notification (future)

**Exit Points:**
- Bottom navigation to other sections
- Back button
- App background/close

**Within-Screen:**
- Week-to-week (arrows)
- Jump to current (conditional button)
- Calendar scroll (vertical days)
- Tap meal → Recipe details
- Generate shopping list → Shopping list screen

---

## Information Architecture (Checkpoint 4)

### Content Inventory

**Navigation elements:**
- Week navigation (arrows, week date, context indicator, optional jump button)
- Screen title ("Weekly Meal Plan")
- Refresh action

**Primary content:**
- Weekly calendar (7 days × 2 meals = 14 slots)
- Meal slot indicators (empty vs. filled, cooked status)
- Recipe names, difficulty, time estimates
- Today indicator

**Secondary tools:**
- Summary data access (Planned Meals list + metrics)
- Shopping list preview/generation

**Actions:**
- Add meal (tap empty slot)
- Manage meal (tap filled slot)
- Generate shopping list
- Access summary

### Hierarchy Design

**PRIMARY (Always Visible - Main Focus):**
- **Planning Calendar** - Occupies majority of screen, never hidden
- Users spend 90% of time here (creation + refinement)

**SECONDARY (Always Visible - Subtle):**
- **Week Navigation** - Present but not dominating, simplified hierarchy

**TERTIARY (Accessible - Not Prominent):**
- **Summary & Shopping List** - Available as tools, don't compete with planning

### Chosen Architecture: Bottom Sheet Tools ✓

**Layout Structure:**
```
┌─────────────────────────────────────┐
│  Weekly Meal Plan            [↻]    │  ← AppBar
├─────────────────────────────────────┤
│  [←]  Week of 15/1  [Current]  [→]  │  ← Simplified navigation
├─────────────────────────────────────┤
│                                     │
│  ┌─ Friday 15/1 ─────────────────┐ │
│  │  🌞 Lunch:   Recipe X         │ │
│  │  🌙 Dinner:  Recipe Y         │ │
│  └───────────────────────────────┘ │
│                                     │  ← PRIMARY: Planning Calendar
│  ┌─ Saturday 16/1 ───────────────┐ │     (fills most of screen)
│  │  🌞 Lunch:   + Add Meal       │ │
│  │  🌙 Dinner:  Recipe Z         │ │
│  └───────────────────────────────┘ │
│                                     │
│  [... more days ...]                │
│                                     │
└─────────────────────────────────────┘
│  📊 Summary  |  🛒 Shopping List    │  ← Persistent bottom bar
└─────────────────────────────────────┘
```

**How it works:**
- Planning calendar fills screen (primary focus, always visible)
- **Persistent bottom bar** with two tool buttons: "📊 Summary" and "🛒 Shopping List"
- Tap Summary → Bottom sheet slides up showing summary data (dismissible)
- Tap Shopping List → Bottom sheet with options: Preview / Generate / View existing
- Tools accessible but don't compete with planning
- No tabs - planning never hidden

**Rationale for this choice:**
1. **Planning stays primary** - Never hidden behind tabs, fills screen
2. **Tools accessible** - One tap access, persistent visibility
3. **Supports shopping preview workflow** - Bottom sheet perfect for quick preview during planning
4. **Modern pattern** - Bottom sheets are standard Material Design for auxiliary content
5. **Discoverable** - Persistent bottom bar makes tools visible and obvious
6. **Flexible** - Bottom sheet dismissible, doesn't permanently consume space
7. **Solves original problems:**
   - ✓ Planning/Summary no longer peer tabs
   - ✓ Shopping list not oversized FAB
   - ✓ Tools integrated into planning context

**Bottom bar composition:**
- Left button: "📊 Summary" → Opens summary bottom sheet
- Right button: "🛒 Shopping List" → Opens shopping options bottom sheet

---

## Wireframe & Interaction Design (Checkpoint 5)

### Detailed Layout Structure

**Default State (Planning View):**
See wireframe diagram in full UX document.

**Key measurements:**
- AppBar: 56px height
- Navigation bar: 48px collapsed, 80px with jump button
- Day cards: 12px vertical spacing, 12px internal padding
- Meal slots: 8px gap between lunch/dinner, 12px internal padding
- Bottom bar: 56px height
- Screen padding: 16px top/horizontal, 64px bottom (for bottom bar clearance)

### Simplified Navigation Bar Design

**Problem solved:** Current navigation has 5 competing elements with unclear hierarchy.

**Solution:** 2 rows, clear hierarchy

**Row 1 (Always visible - 48px):**
- [←] Arrow (48×48px) | "Week of 15/1/2026" (bodyLarge) | [Current] badge (subtle chip) | [→] Arrow (48×48px)

**Row 2 (Conditional - only when NOT current week - 32px):**
- "(Next week)" relative time (grey, 14px, centered-left) | [⌂] Jump button (32×32px, right)

**Context badge styling (simplified):**
- Past: Grey bg (25 alpha), no border, grey icon
- Current: Primary container (40 alpha), primary icon
- Future: Primary (20 alpha), primary icon

**Result:** 3 elements (not 5), scannable, clear hierarchy

### Persistent Bottom Bar

**Layout:**
```
┌──────────────────────┬──────────────────────┐
│   📊  Summary        │  🛒  Shopping List   │
└──────────────────────┴──────────────────────┘
```

**Specs:**
- Height: 56px (Material standard)
- Background: Surface color
- Elevation: 8
- Buttons: TextButton (icon + label), full half-width
- Tap target: Full width, 56px height ✓
- Active state: Icon/text change to primary when sheet open

### Bottom Sheet Interactions

**Summary Bottom Sheet:**
- Trigger: Tap "📊 Summary"
- Animation: Slide up (300ms, easeOut)
- Height: 60% of screen (scrollable)
- Content: WeeklySummaryWidget (no changes to existing content)
- Dismissal: Drag down, tap outside, or close button

**Shopping List Bottom Sheet:**
- Trigger: Tap "🛒 Shopping List"
- Animation: Slide up (300ms, easeOut)
- Initial view: Options (Preview / Generate / View Existing)
- Preview view: Slides to ingredient list (with back button)
- Actions: Preview (no commitment), Generate (full workflow), View (existing list)

### Component Specifications

**Day Card:**
- Card widget, elevation 2, 12px radius
- 16px horizontal margin, 12px vertical margin
- 12px internal padding

**Meal Slot:**
- Container + InkWell, 8px radius, 12px padding
- Min height: 56px (tap target ✓)
- Border: 1px solid (meal type color or context)
- Background: Contextual (empty/filled/cooked)

**Meal Type Indicator:**
- 16×16px icon (sun/moon) + bodySmall text
- 8px×4px padding, 4px radius
- Subtle background (40 alpha)

**Recipe Info:**
- Name: bodyLarge (16px) bold
- Metadata: bodySmall (12px) grey
- Icons: 12×12px (stars, timer)
- Badges: Chips for "+X more" and cooked status ✓

### Spacing & Rhythm (Generous Whitespace)

- Screen padding: 16px top/horizontal, 64px bottom
- Card gap: 12px vertical
- Meal gap: 8px vertical
- Navigation padding: 12px horizontal, 8px vertical
- Bottom sheet padding: 16px
- Action card gap: 12px

### Transitions & Animations

- Bottom sheet: 300ms slide up/down (easeOut/easeIn)
- Week change: 300ms fade (easeInOut) - existing
- Ripple: 200ms (Material default)
- Scrim: 200ms linear fade

### Feedback & State Indicators

- Button press: Ripple effect (primary 20% opacity)
- Bottom bar active: Icon/text → primary color when sheet open
- Success: SnackBar with ✓, green, 3s
- Error: SnackBar with ⚠️, red, 5s, optional Retry
- Loading: Centered CircularProgressIndicator

### State Variations

- Empty week: All slots show "➕ Add Meal"
- Loading: Centered spinner
- Error: SnackBar with retry
- Past week: Grey context badge, jump button visible
- Current week: Primary context badge, no jump button
- Future week: Primary context badge, jump button visible

**Design Problems Solved:**
✅ Planning always visible (not hidden by tabs)
✅ Navigation simplified (3 elements, clear hierarchy)
✅ Summary accessible as tool (bottom sheet)
✅ Shopping list integrated (preview during planning)
✅ Jump to current week discoverable (clear home icon)

---

## Checkpoint Progress

- [x] Checkpoint 1: Goal & Context Analysis
- [x] Checkpoint 2: Current State Assessment
- [x] Checkpoint 3: User Flow Mapping
- [x] Checkpoint 4: Information Architecture
- [x] Checkpoint 5: Wireframe & Interaction Design
- [ ] Checkpoint 6: Accessibility & Handoff

---

**Session Status:** Discovery in progress
**Last Updated:** 2026-01-31
**Contributors:** Rodrigo Machado, Claude Sonnet 4.5
