# Sprint Planning: 0.1.2 & 0.1.3

**Date:** December 1, 2025
**Participants:** Product Owner, Technical Leader
**Context:** Beta testing feedback session and milestone restructure

---

## Executive Summary

The original **0.1.1 - Stability & Polish** milestone was split into three focused sprints to better manage scope and deliver value incrementally:

- **0.1.1** ✅ - Completed (9 issues: testing infrastructure, UI polish)
- **0.1.2** 🎯 - Polish & Data Safety (11 issues: UX improvements, backup, parser quality)
- **0.1.3** 📋 - Testing & Features (8 issues: testing completion, deferred features)

---

## Milestone Restructure Rationale

### Why Split 0.1.1?

1. **Scope Management**: Original 0.1.1 backlog grew to 22 issues - too large for single sprint
2. **Focus Areas**: Testing vs Polish vs Features needed separate attention
3. **Beta Feedback**: Real-world usage revealed critical UX and data safety needs
4. **Risk Mitigation**: Backup feature needed before model changes in subsequent sprints

### Strategic Approach

- **0.1.2**: Focus on **user-facing polish** and **data safety** (critical for beta confidence)
- **0.1.3**: Focus on **testing completion** and **deferred features** (foundation for 0.2.0)
- **0.2.0**: Advanced features for beta-ready phase

---

## 0.1.2 - Polish & Data Safety

**Theme:** Make the app feel polished and protect user data
**Duration:** ~10-14 days
**Status:** Current Sprint
**Total Issues:** 11

### Goals

1. ✅ Protect user data with backup/restore capability
2. ✅ Fix critical UX issues (filter indicators, sorting)
3. ✅ Improve parser quality for bulk recipe updates
4. ✅ Polish UI for better readability (fractions)
5. ✅ Validate meal edit functionality with tests

### Issues by Category

#### **Critical Data Safety & UX (3 issues)**

**#223 - Complete Database Backup and Restore Functionality** (P0-Critical)
- **Effort:** Medium-High (2-3 days)
- **Priority:** Must-have
- **Why:** Data loss destroys user trust; critical for beta testers
- **Implementation:** SQLite file export/import with warning dialogs
- **Risk:** Medium - file picker integration, restore edge cases
- **Dependencies:** None
- **Acceptance:** One-click backup, one-click restore with data replacement

**#228 - UX: No clear indication when recipe filter is active** (P1-High, bug)
- **Effort:** Low-Medium (1 day)
- **Priority:** Must-have
- **Why:** Major UX confusion - users think recipes are missing
- **Implementation:** Filter banner, count indicator, clear button
- **Risk:** Low - mostly UI work
- **Dependencies:** None
- **Acceptance:** Visual indicators when filter active, easy clear action

**#224 - Reorganize Tools Tab for Better UX** (UI/UX, ✓✓)
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have (supports #223)
- **Why:** Needed for clean backup/restore integration
- **Implementation:** Section-based layout (Data Management, Recipe Management)
- **Risk:** Low - layout refactoring
- **Dependencies:** #223 (provides new tools to organize)
- **Acceptance:** Clear sections, scalable structure

---

#### **Parser Quality & Data (3 issues)**

**#226 - Parser: Auto-extract parenthetical text to notes** (P2-Medium)
- **Effort:** Low (0.5-1 day)
- **Priority:** Should-have
- **Why:** Improves bulk parser quality, better ingredient matching
- **Implementation:** Regex preprocessing to extract `(...)` to notes field
- **Risk:** Low - preprocessing step
- **Dependencies:** None
- **Acceptance:** "150 ml azeite (mais um pouco)" → notes: "mais um pouco"
- **Beta Impact:** Reported by beta tester during repopulation experience

**#225 - Add 'maço' (bunch) measurement unit** (P2-Medium, i18n)
- **Effort:** Low (0.5 day)
- **Priority:** Should-have
- **Why:** Common Portuguese pattern, quick win
- **Implementation:** Add to MeasurementUnit enum, localization, parser map
- **Risk:** Very low - similar to #197 (completed in 0.1.0)
- **Dependencies:** None
- **Acceptance:** "2 maços de coentro" parses correctly as bunch unit
- **Beta Impact:** Reported by beta tester during bulk recipe entry

**#227 - Bug: Hyphenated ingredient/recipe names sort incorrectly** (P2-Medium, bug)
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have
- **Why:** UX polish - affects all alphabetical lists
- **Implementation:** Normalized sort key (replace hyphens, lowercase, accent handling)
- **Risk:** Medium - ensure locale-aware sorting doesn't break existing behavior
- **Dependencies:** None
- **Acceptance:** "pimenta-do-reino" before "pimenta jalapeño"
- **Beta Impact:** Reported by beta tester - affects discoverability

---

#### **UI Polish (1 issue)**

**#148 - UI: Implement fraction display for ingredient quantities** (P2-Medium)
- **Effort:** Low-Medium (1 day)
- **Priority:** Should-have
- **Why:** Much better readability for daily cooking use
- **Implementation:** Convert decimals to fractions (½, ¼, ¾, ⅓, ⅔)
- **Risk:** Low - builds on existing formatting (#141)
- **Dependencies:** #141 (smart decimal formatting - completed)
- **Acceptance:** "0.5 xícara" displays as "½ xícara"
- **Beta Impact:** Moved from 0.2.0 based on beta tester feedback

---

#### **Testing - Meal Edit Validation (4 issues)**

**#126 - Test Complete End-to-End Meal Edit Workflow** (✓✓, integration)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Validate meal edit functionality works end-to-end
- **Implementation:** Integration test covering full edit workflow
- **Risk:** Low
- **Dependencies:** Existing meal edit functionality
- **Acceptance:** E2E test passes for meal edit scenarios

**#125 - Test UI Refresh After Meal Edit Operations** (✓✓, UI testing)
- **Effort:** Low-Medium (0.5-1 day)
- **Priority:** Should-have
- **Why:** Ensure UI updates correctly after edits
- **Implementation:** Widget tests for UI refresh behavior
- **Risk:** Low
- **Dependencies:** #126
- **Acceptance:** Tests verify UI reflects changes immediately

**#124 - Test Feedback Messages for Meal Edit Operations** (✓✓, UI testing)
- **Effort:** Low-Medium (0.5-1 day)
- **Priority:** Should-have
- **Why:** Validate user feedback is clear and correct
- **Implementation:** Widget tests for success/error messages
- **Risk:** Low
- **Dependencies:** #126
- **Acceptance:** Tests verify appropriate feedback messages

**#76 - Create Database Tests for Meal Recording and History** (✓✓, testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Validate database layer for meal operations
- **Implementation:** Unit tests for meal CRUD operations
- **Risk:** Low
- **Dependencies:** None
- **Acceptance:** Comprehensive database test coverage for meals

---

### Sprint Metrics

**Total Issues:** 11
**Estimated Effort:** 10-14 days
**Priority Breakdown:**
- P0-Critical: 1 issue (#223)
- P1-High: 1 issue (#228)
- P2-Medium: 4 issues (#226, #225, #227, #148)
- No priority: 5 issues (testing - #126, #125, #124, #76, #224)

**Type Breakdown:**
- Features: 2 (#223, #224)
- Bugs: 2 (#228, #227)
- Parser/Algorithm: 2 (#226, #225)
- UI Polish: 1 (#148)
- Testing: 4 (#126, #125, #124, #76)

**Complexity Breakdown:**
- High (✓✓✓): 0
- Medium (✓✓): 5 (#224, #126, #125, #124, #76)
- Low (✓): 0
- Not estimated: 6 (need quick estimation during sprint)

---

### Success Criteria

1. ✅ Backup/restore feature working and tested (#223)
2. ✅ No more "where are my recipes?" confusion (#228)
3. ✅ Portuguese ingredient/recipe names sort naturally (#227)
4. ✅ Bulk parser handles common patterns correctly (#226, #225)
5. ✅ Ingredient quantities display as fractions (#148)
6. ✅ Meal edit functionality validated with tests (#126, #125, #124, #76)
7. ✅ Tools tab organized and scalable (#224)
8. ✅ All issues pass `flutter analyze`
9. ✅ Beta tester validates fixes

---

## 0.1.3 - Testing & Deferred Features

**Theme:** Testing completion and feature development
**Duration:** TBD
**Status:** Next Sprint
**Total Issues:** 8

### Goals

1. ✅ Complete testing foundation from 0.1.1
2. ✅ Implement deferred features (Shopping List, Meal Type, To Taste)
3. ✅ Prepare for 0.2.0 beta-ready phase

### Issues by Category

#### **Deferred Features (3 issues)**

**#5 - Add Shopping List Generation** (P1-High, ✓)
- **Deferred from:** 0.1.2
- **Reason:** Needs more design/planning before implementation
- **Effort:** Medium (2-3 days estimated)
- **Priority:** High - valuable feature for users
- **Note:** PO to finalize design and requirements before sprint

**#199 - Add Meal Type Selection When Recording Cooked Meals** (✓✓, UI)
- **Deferred from:** 0.1.2
- **Reason:** Scope reduction; model changes safer after backup feature
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Dependencies:** #223 (backup provides safety net)

**#196 - Improve Display and Storage of "To Taste" Ingredients** (✓✓, model/UI)
- **Deferred from:** 0.1.2
- **Reason:** Scope reduction; model changes safer after backup feature
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Dependencies:** #223 (backup provides safety net)
- **Note:** May require database migration

---

#### **Testing Completion (5 issues)**

**#77 - Create Widget Tests for MealHistoryScreen** (✓✓, UI testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Complete widget test coverage for core screens

**#40 - Test Refactoring and Coverage Enhancement** (✓, technical-debt)
- **Effort:** Low-Medium (1 day)
- **Priority:** Could-have
- **Why:** Improve test quality and maintainability

**#39 - Develop Edge Case Test Suite** (✓✓, testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Catch edge cases and improve robustness

**#38 - Implement Dialog and State Management Testing** (✓✓, UI testing)
- **Effort:** Medium (1-2 days)
- **Priority:** Should-have
- **Why:** Validate dialog interactions and state management

**#221 - Organize integration tests into e2e/ and services/ directories** (technical-debt)
- **Effort:** Low (0.5 day)
- **Priority:** Could-have
- **Why:** Better test organization and maintainability

---

### Sprint Metrics

**Total Issues:** 8
**Estimated Effort:** 8-12 days
**Type Breakdown:**
- Features: 3 (#5, #199, #196)
- Testing: 5 (#77, #40, #39, #38, #221)

**Complexity Breakdown:**
- Medium (✓✓): 4 (#199, #196, #77, #39, #38)
- Low (✓): 2 (#5, #40)
- Not estimated: 2 (#221)

---

### Success Criteria

1. ✅ Shopping list generation working (#5)
2. ✅ Meal type selection implemented (#199)
3. ✅ "To taste" ingredients handled properly (#196)
4. ✅ Widget test coverage for MealHistoryScreen (#77)
5. ✅ Edge case test suite in place (#39)
6. ✅ Dialog and state management tested (#38)
7. ✅ Integration tests organized (#221)
8. ✅ Test refactoring complete (#40)
9. ✅ All issues pass `flutter analyze`
10. ✅ Ready for 0.2.0 beta-ready phase

---

## Issues Moved to 0.2.0 - Beta-Ready Phase

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

## Risk Assessment

### 0.1.2 Risks

**Medium Risks:**
1. **#223 (Backup/Restore)** - File picker integration, platform differences, restore edge cases
   - Mitigation: Start early, thorough testing, clear user warnings

2. **#227 (Sorting)** - Locale-aware sorting could break existing behavior
   - Mitigation: Comprehensive tests, manual verification across lists

**Low Risks:**
3. All other issues are low complexity with clear implementations

### 0.1.3 Risks

**Medium Risks:**
1. **#5 (Shopping List)** - Needs design clarity before implementation
   - Mitigation: PO to finalize requirements before sprint starts

2. **#199, #196 (Model Changes)** - Database migrations, data integrity
   - Mitigation: Backup feature (#223) in place, thorough testing

**Low Risks:**
3. Testing issues are isolated and low-risk

---

## Dependencies

### 0.1.2 Dependencies
- **#224 depends on #223**: Tools tab reorganization benefits from backup/restore buttons
- **#125, #124 depend on #126**: UI tests build on E2E workflow tests
- **#148 depends on #141**: Fraction display builds on smart decimal formatting (completed)

### 0.1.3 Dependencies
- **#199, #196 depend on #223**: Model changes safer with backup feature in place
- **#5 depends on PO design**: Needs requirements finalization

### Cross-Milestone Dependencies
- **0.1.3 depends on 0.1.2**: Backup feature must be complete before model changes
- **0.2.0 depends on 0.1.3**: Testing foundation must be complete

---

## Beta Testing Impact

All issues in 0.1.2 were informed by **real-world beta testing feedback**:

- **#223**: Tester lost data during deployment, highlighted critical need
- **#228**: Tester confused by hidden filter state
- **#227**: Tester noticed incorrect sorting of Portuguese ingredients
- **#226**: Tester encountered parenthetical text during bulk recipe entry
- **#225**: Tester found missing "maço" unit during bulk recipe entry
- **#148**: Tester requested better readability (moved from 0.2.0)

This validates our approach of **real-world usage driving priorities**.

---

## Next Steps

### Immediate Actions (Tech Lead)
1. ✅ Create 0.1.3 milestone in GitHub
2. ✅ Move issues to correct milestones:
   - #196, #199, #5, #77, #40, #39, #38, #221 → 0.1.3
   - #193, #175, #170 → 0.2.0
3. ✅ Update roadmap document with new milestone structure
4. ✅ Estimate remaining issues without complexity labels

### Sprint Planning Actions (PO + Tech Lead)
1. Review and approve final 0.1.2 scope
2. Identify sprint start date
3. Assign issues or determine workflow
4. Establish sprint cadence and check-ins

### Before 0.1.3
1. PO to finalize Shopping List (#5) requirements
2. Review 0.1.2 completion and lessons learned
3. Adjust 0.1.3 scope based on 0.1.2 outcomes

---

## Document History

- **2025-12-01**: Initial sprint planning session (PO + Tech Lead)
- **Status**: Plan approved, ready for execution

---

**Approved by:**
- Product Owner: ✅
- Technical Leader: ✅
