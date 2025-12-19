<!-- markdownlint-disable -->
# Sprint Planning: 0.1.2, 0.1.3 & 0.1.4

**Date:** December 1, 2025 (Updated: December 18, 2025)
**Participants:** Product Owner, Technical Leader
**Context:** Beta testing feedback session and milestone restructure

---

## Executive Summary

The original **0.1.1 - Stability & Polish** milestone was split into focused sprints to better manage scope and deliver value incrementally:

- **0.1.1** ✅ - Completed (9 issues: testing infrastructure, UI polish)
- **0.1.2** ✅ - Completed (11 issues: UX improvements, backup, parser quality)
- **0.1.3** 🎯 - User Features & Critical Foundation (8 issues: instructions, testing foundation)
- **0.1.4** 📋 - Model Changes & Architecture Polish (8 issues: DB migrations, consolidation)

### Why Split 0.1.3?

During 0.1.3 planning review (Dec 18, 2025), the milestone had grown from 8 to 16 issues due to:
1. New feature specifications (#172 Instructions, #238 Context menu)
2. Technical debt discovered during 0.1.2 testing (#234-237 refactoring chain)
3. Architecture improvements (#231 RecipesScreen extraction)
4. DevEx tooling (#230 coverage reporting)

**Decision:** Split into two focused milestones to maintain ~8-12 day sprint cadence.

---

## Milestone Restructure Rationale

### Original Split (0.1.1 → 0.1.2 + 0.1.3)

1. **Scope Management**: Original 0.1.1 backlog grew to 22 issues - too large for single sprint
2. **Focus Areas**: Testing vs Polish vs Features needed separate attention
3. **Beta Feedback**: Real-world usage revealed critical UX and data safety needs
4. **Risk Mitigation**: Backup feature needed before model changes in subsequent sprints

### Second Split (0.1.3 → 0.1.3 + 0.1.4)

1. **Scope Creep**: 0.1.3 grew from 8 to 16 issues
2. **Dependency Chain**: Architecture refactoring (#234→#235→#236→#237) emerged
3. **Risk Separation**: Model changes (#199, #196, #5) safer after testing foundation complete
4. **Focus**: User features vs technical consolidation need separate attention

---

## 0.1.2 - Polish & Data Safety ✅ COMPLETED

**Theme:** Make the app feel polished and protect user data
**Duration:** December 2-17, 2025
**Status:** ✅ Completed
**Total Issues:** 11

### Completed Goals

1. ✅ Protect user data with backup/restore capability (#223)
2. ✅ Fix critical UX issues - filter indicators (#228), sorting (#227)
3. ✅ Improve parser quality for bulk recipe updates (#226, #225)
4. ✅ Polish UI for better readability - fractions (#148)
5. ✅ Validate meal edit functionality with tests (#126, #125, #124, #76)
6. ✅ Tools tab organized and scalable (#224)

### Issues Completed

| # | Title | Type |
|---|-------|------|
| #223 | Complete Database Backup and Restore Functionality | Feature |
| #228 | UX: No clear indication when recipe filter is active | Bug |
| #224 | Reorganize Tools Tab for Better UX | UI/UX |
| #226 | Parser: Auto-extract parenthetical text to notes | Parser |
| #225 | Add 'maço' (bunch) measurement unit | Parser |
| #227 | Bug: Hyphenated ingredient/recipe names sort incorrectly | Bug |
| #148 | UI: Implement fraction display for ingredient quantities | UI |
| #126 | Test Complete End-to-End Meal Edit Workflow | Testing |
| #125 | Test UI Refresh After Meal Edit Operations | Testing |
| #124 | Test Feedback Messages for Meal Edit Operations | Testing |
| #76 | Create Database Tests for Meal Recording and History | Testing |

---

## 0.1.3 - User Features & Critical Foundation

**Theme:** Deliver high-impact user features + unblock testing infrastructure
**Duration:** ~8-10 days
**Status:** 🎯 Current Sprint
**Total Issues:** 8

### Goals

1. 🎯 Implement instructions viewing and editing (#172)
2. 🎯 Add context menu for meal history cards (#238)
3. 🎯 Refactor critical database access patterns (#234, #235)
4. 🎯 Complete widget test coverage for core screens (#77)
5. 🎯 Establish testing patterns for dialogs and edge cases (#38, #39)
6. 🎯 Organize test structure (#221)

### Issues by Category

#### **User-Facing Features (2 issues)**

**#172 - Add instructions viewing and editing to recipe management** (✓✓✓, UI/UX)
- **Effort:** Medium-High (2-3 days)
- **Priority:** Must-have
- **Why:** High user value, detailed spec ready, builds on #163
- **Implementation:** View screen, edit field, recipe card button
- **Risk:** Low - well-specified, follows existing patterns
- **Dependencies:** #163 (completed - instructions field exists)
- **Acceptance:** View instructions from card, edit in recipe screen

**#238 - Add context menu with edit and delete options to meal cards** (✓✓, UI)
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have
- **Why:** UX consistency with recipe cards, enables meal deletion
- **Implementation:** Replace IconButton with PopupMenuButton
- **Risk:** Low - follows existing RecipeCard pattern
- **Dependencies:** None
- **Acceptance:** Context menu with edit/delete, confirmation dialog

---

#### **Critical Architecture (2 issues)**

**#235 - Refactor WeeklyPlanScreen._handleMarkAsCooked() to use DatabaseHelper** (P1-High)
- **Effort:** Medium (1-2 days)
- **Priority:** Must-have
- **Why:** Blocks proper testing - raw DB access not mockable
- **Implementation:** Use DatabaseHelper/MealProvider abstraction
- **Risk:** Medium - core workflow, needs careful testing
- **Dependencies:** None
- **Acceptance:** No raw database access, tests can use MockDatabaseHelper

**#234 - Refactor WeeklyPlanScreen._updateMealRecord() to use DatabaseHelper**
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have
- **Why:** Same issue as #235, related methods
- **Implementation:** Use DatabaseHelper.updateMeal() abstraction
- **Risk:** Low - similar to #235
- **Dependencies:** None
- **Acceptance:** No raw database access in update methods

---

#### **Testing Foundation (4 issues)**

**#77 - Create Widget Tests for MealHistoryScreen** (✓✓, UI testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Complete widget test coverage for core screens
- **Implementation:** Test loading, empty state, meal rendering, actions
- **Risk:** Low
- **Dependencies:** None
- **Acceptance:** Comprehensive widget tests for MealHistoryScreen

**#38 - Implement Dialog and State Management Testing** (✓✓, UI testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Validate dialog interactions and temporary state
- **Implementation:** Test utilities for dialog simulation
- **Risk:** Low
- **Dependencies:** None
- **Acceptance:** Dialog return values and state management tested

**#39 - Develop Edge Case Test Suite** (✓✓, testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Catch edge cases, improve robustness
- **Implementation:** Tests for empty states, boundaries, error conditions
- **Risk:** Low
- **Dependencies:** None
- **Acceptance:** Edge case catalog with tests

**#221 - Organize integration tests into e2e/ and services/ directories**
- **Effort:** Low (0.5 day)
- **Priority:** Could-have
- **Why:** Better test organization and maintainability
- **Implementation:** Move files, update imports
- **Risk:** Very low - file reorganization only
- **Dependencies:** None
- **Acceptance:** Clear e2e/ and services/ directory structure

---

### Sprint Metrics

**Total Issues:** 8
**Estimated Effort:** 8-10 days

**Priority Breakdown:**
- P1-High: 1 issue (#235)
- ✓✓✓: 1 issue (#172)
- ✓✓: 5 issues (#238, #77, #38, #39, #234)
- Unlabeled: 1 issue (#221)

**Type Breakdown:**
- Features: 2 (#172, #238)
- Architecture: 2 (#234, #235)
- Testing: 4 (#77, #38, #39, #221)

---

### Success Criteria

1. ✅ Instructions viewable from recipe card and editable in edit screen (#172)
2. ✅ Meal cards have context menu with edit/delete options (#238)
3. ✅ WeeklyPlanScreen uses DatabaseHelper abstraction (#234, #235)
4. ✅ MealHistoryScreen has widget test coverage (#77)
5. ✅ Dialog testing patterns established (#38)
6. ✅ Edge case test suite in place (#39)
7. ✅ Integration tests organized (#221)
8. ✅ All issues pass `flutter analyze`
9. ✅ Foundation ready for model changes in 0.1.4

---

## 0.1.4 - Model Changes & Architecture Polish

**Theme:** Database migrations + service consolidation + remaining features
**Duration:** ~10-12 days
**Status:** 📋 Next Sprint
**Total Issues:** 8

### Goals

1. 📋 Implement Shopping List feature (#5)
2. 📋 Add Meal Type selection (#199)
3. 📋 Improve "To Taste" ingredient display (#196)
4. 📋 Complete architecture refactoring (#236, #237)
5. 📋 Extract RecipesScreen for better separation (#231)
6. 📋 Improve test infrastructure (#40, #230)

### Issues by Category

#### **Features with Model Changes (3 issues)**

**#5 - Add Shopping List Generation** (P1-High, ✓)
- **Deferred from:** 0.1.2, 0.1.3
- **Reason:** Needs design finalization before implementation
- **Effort:** Medium-High (2-3 days)
- **Priority:** High - valuable feature for users
- **Risk:** Medium - new model, algorithm, UI
- **Dependencies:** PO to finalize design
- **Note:** Major feature requiring careful planning

**#199 - Add Meal Type Selection When Recording Cooked Meals** (✓✓, UI)
- **Deferred from:** 0.1.2
- **Reason:** Model change safer after testing foundation in place
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Risk:** Low-Medium - database migration required
- **Dependencies:** #223 (backup - completed), testing foundation from 0.1.3

**#196 - Improve Display and Storage of "To Taste" Ingredients** (✓✓, model/UI)
- **Deferred from:** 0.1.2
- **Reason:** Model change safer after testing foundation in place
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Risk:** Low-Medium - may require database migration
- **Dependencies:** #223 (backup - completed), testing foundation from 0.1.3

---

#### **Architecture Completion (3 issues)**

**#236 - Refactor WeeklyPlanScreen._updateMealPlanItemRecipes() to use DatabaseHelper** (P2-Medium)
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have
- **Why:** Completes refactoring started in #234/#235
- **Dependencies:** #234, #235 (completed in 0.1.3)

**#237 - Consolidate meal editing logic into shared service** (P2-Medium)
- **Effort:** Medium (2-3 days)
- **Priority:** Should-have
- **Why:** Eliminates ~175 lines of duplicated code across screens
- **Dependencies:** #234, #235, #236 (all prerequisites)
- **Note:** Payoff issue - consolidates work from #234-236

**#231 - Extract RecipesScreen from HomePage** (P2-Medium, ✓✓)
- **Effort:** Medium (2-3 hours)
- **Priority:** Could-have
- **Why:** Better separation of concerns, testability
- **Dependencies:** None
- **Note:** Architecture improvement, not blocking

---

#### **Testing Infrastructure (2 issues)**

**#40 - Test Refactoring and Coverage Enhancement** (✓, technical-debt)
- **Effort:** Low-Medium (1 day)
- **Priority:** Could-have
- **Why:** Improve test quality and maintainability
- **Dependencies:** Testing work from 0.1.3

**#230 - Add test coverage reporting** (technical-debt)
- **Effort:** Low-Medium (1 day)
- **Priority:** Could-have
- **Why:** Visibility into test coverage metrics
- **Dependencies:** None
- **Note:** DevEx improvement

---

### Sprint Metrics

**Total Issues:** 8
**Estimated Effort:** 10-12 days

**Type Breakdown:**
- Features: 3 (#5, #199, #196)
- Architecture: 3 (#236, #237, #231)
- Testing: 2 (#40, #230)

---

### Success Criteria

1. ✅ Shopping list generation working (#5)
2. ✅ Meal type selection implemented (#199)
3. ✅ "To taste" ingredients handled properly (#196)
4. ✅ Meal editing logic consolidated into shared service (#237)
5. ✅ RecipesScreen extracted from HomePage (#231)
6. ✅ Test coverage reporting available (#230)
7. ✅ Test refactoring complete (#40)
8. ✅ All issues pass `flutter analyze`
9. ✅ Ready for 0.2.0 beta-ready phase

---

## Issues Moved to 0.2.0 - Beta-Ready Phase

**#9 - Add Cooking Instructions Management to Recipe Screens** (✓, enhancement)
- **Reason:** Superseded by #172 for text-based approach; structured steps deferred
- **Priority:** Low
- **Note:** Original vision for structured step-by-step instructions with reordering

**#193 - Add Recipe Usage View for Ingredients** (✓✓, UI)
- **Reason:** Nice-to-have feature, not critical for current polish phase
- **Priority:** Medium
- **Note:** Useful for understanding ingredient usage patterns

**#175 - Analyze feasibility of Type Safety pattern for entity IDs** (P3-Low, technical-debt)
- **Reason:** Research task, low priority
- **Priority:** Low
- **Note:** Can be explored during 0.2.0 architecture improvements

**#170 - Refactor ingredient parser to use localized measurement unit strings** (P3-Low, technical-debt, i18n)
- **Reason:** Technical debt, not user-facing
- **Priority:** Low
- **Note:** Can be addressed during 0.2.0 refactoring phase

---

## Dependencies

### 0.1.3 Dependencies

- **#235, #234 enable #236, #237**: Architecture refactoring in 0.1.3 enables consolidation in 0.1.4
- **#77, #38, #39 enable #199, #196**: Testing foundation makes model changes safer

### 0.1.4 Dependencies

- **#236 depends on #234, #235**: Must complete base refactoring first
- **#237 depends on #234, #235, #236**: Consolidation requires all refactoring complete
- **#5 depends on PO design**: Needs requirements finalization
- **#199, #196 depend on testing foundation**: Safer with #77, #38, #39 complete

### Cross-Milestone Dependencies

```
0.1.3                              0.1.4
─────                              ─────
#234 ─┬────────────────────────────→ #236 ─┐
#235 ─┘                                    ├─→ #237 (consolidation)
                                           │
#77, #38, #39 (testing) ───────────→ #199, #196 (model changes)
                                           │
                                     #5 (needs PO design)
```

---

## Risk Assessment

### 0.1.3 Risks

**Medium Risks:**
1. **#235, #234 (Refactoring)** - Core workflow changes
   - Mitigation: Thorough testing, E2E validation before merge

**Low Risks:**
2. **#172 (Instructions)** - Well-specified, follows existing patterns
3. Testing issues are isolated and low-risk

### 0.1.4 Risks

**Medium Risks:**
1. **#5 (Shopping List)** - Needs design clarity before implementation
   - Mitigation: PO to finalize requirements before sprint starts

2. **#199, #196 (Model Changes)** - Database migrations, data integrity
   - Mitigation: Backup feature (#223) complete, testing foundation from 0.1.3

3. **#237 (Consolidation)** - Touches multiple screens
   - Mitigation: Prerequisites (#234-236) completed first, comprehensive tests

**Low Risks:**
4. Architecture improvements (#231) are isolated
5. Testing infrastructure (#40, #230) is additive

---

## Next Steps

### Before 0.1.3

1. ✅ Split milestone scope (this document)
2. 🎯 Create 0.1.4 milestone in GitHub
3. 🎯 Move deferred issues to 0.1.4:
   - #5, #199, #196 → 0.1.4 (features with model changes)
   - #236, #237, #231 → 0.1.4 (architecture completion)
   - #40, #230 → 0.1.4 (testing infrastructure)
4. 🎯 Move #9 to 0.2.0 (structured instructions - deferred)

### Before 0.1.4

1. PO to finalize Shopping List (#5) requirements
2. Review 0.1.3 completion and lessons learned
3. Validate testing foundation is solid for model changes

---

## Document History

- **2025-12-01**: Initial sprint planning session (PO + Tech Lead)
- **2025-12-02**: Detailed estimation session and implementation sequencing
  - Estimated all 12 issues using fibonacci scale
  - Added #229 (Recipe import tool) during planning
  - Defined 5-phase implementation sequence with dependencies
  - Total: 45 story points
- **2025-12-17**: 0.1.2 completed, v0.1.2 released
- **2025-12-18**: 0.1.3 scope review and split decision
  - Milestone had grown from 8 to 16 issues
  - Split into 0.1.3 (8 issues) + 0.1.4 (8 issues)
  - 0.1.3: User features + critical foundation
  - 0.1.4: Model changes + architecture polish
  - Moved #9 (structured instructions) to 0.2.0
- **Status**: 0.1.3 plan approved, ready for execution

---

**Approved by:**
- Product Owner: ✅
- Technical Leader: ✅