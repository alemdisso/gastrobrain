<!-- markdownlint-disable -->
# Sprint Estimation Diary

**Purpose:** Track estimation accuracy across sprints to improve planning and identify patterns.

**Methodology:** Commit-based analysis using weighted working days. When multiple issues share a day, effort is distributed proportionally by lines of code changed.

---

## How to Run a Sprint Retrospective

### 1. Generate Commit Analysis

Use the analysis script to extract commit data:

```bash
# Basic usage - analyze commits from start date to now
python3 scripts/analyze_sprint_commits.py --since YYYY-MM-DD --branch develop

# With end date (for completed sprints)
python3 scripts/analyze_sprint_commits.py --since 2025-12-02 --until 2025-12-17 --branch develop

# Focus on specific issues only
python3 scripts/analyze_sprint_commits.py --since 2025-12-02 --issues "223,228,124"
```

**Note:** Use `python3` command (not `python`) in WSL/Linux environments.

### 2. Review Output

The script outputs:
- **Commits by Issue** - Active days and commit counts per issue
- **Untagged Commits** - Commits without issue numbers that need attribution
- **Working Days Summary** - Utilization and date range
- **Daily Activity** - Visual timeline of work

### 3. Attribute Untagged Commits

Review untagged commits and mentally assign them to issues based on commit message content. Common patterns:
- Test commits without `#number` often belong to nearby tagged test issues
- Merge commits can be ignored
- Doc/style commits may be general maintenance

### 4. Compare with Estimates

Cross-reference actual days with estimates from sprint planning doc to calculate ratios.

### 5. Document in This File

Add a new section under "Sprint Reviews" following the 0.1.2 template.

---

## Sprint Reviews

### 0.1.2 - Polish & Data Safety

**Sprint Duration:** December 2-17, 2025
**Calendar Days:** 15
**Active Working Days:** 9 (60% utilization)
**Planned Issues:** 11
**Completed Issues:** 12 (including #229 added mid-sprint)

#### Estimation vs Actual

| Issue | Title | Type | Est Days | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|----------|-----------------|-------|-------|------------|
| #225 | Add 'maço' unit | Parser | 0.5 | 0.08* | 61 | 0.16x | ⚡ Faster |
| #226 | Parenthetical to notes | Parser | 0.5-1 | 0.18* | 135 | 0.24x | ⚡ Faster |
| #227 | Hyphenated sorting | Bug | 1 | 0.74* | 553 | 0.74x | ⚡ Faster |
| #223 | Backup/Restore | Feature | 2-3 | 3 | 2000+ | 1.20x | ✅ On target |
| #228 | Filter indicator | Bug | 1 | 0.5* | ~200 | 0.50x | ⚡ Faster |
| #148 | Fraction display | UI | 1 | 0.3* | ~150 | 0.30x | ⚡ Faster |
| #229 | Recipe import | Feature | N/A | 0.4* | ~300 | - | 📋 Unplanned |
| #76 | DB meal tests | Testing | 1-2 | 0.3* | ~200 | 0.20x | ⚡ Faster |
| #224 | Tools tab reorganize | UI/UX | 1 | 0.5* | ~250 | 0.50x | ⚡ Faster |
| #125 | UI refresh tests | Testing | 0.5-1 | 0.5* | ~300 | 0.67x | ⚡ Faster |
| #124 | Feedback msg tests | Testing | 0.5-1 | 3 | 800+ | 4.00x | 🔴 Over |
| #126 | E2E meal edit test | Testing | 1-2 | 1.5 | 500+ | 1.00x | ✅ On target |
| **TOTAL** | | | **12.2** | **~11** | | **0.90x** | |

*\* Weighted by lines changed when sharing day with other issues*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Bug | #227, #228 | 2 | 1.24 | 0.62x | ⚡ Faster than expected |
| UI/Feature | #223, #148, #224 | 4.5 | 3.8 | 0.84x | ✅ Good |
| Parser | #225, #226 | 1.25 | 0.26 | 0.21x | ⚡ Very efficient |
| Testing | #76, #124, #125, #126 | 4.5 | 5.3 | 1.18x | ⚠️ Slightly over |

**Note:** Testing ratio improved significantly when accounting for shared days. Only #124 was a true overrun due to infrastructure work.

#### Variance Analysis

**Major Overrun: #124 (Feedback message tests)**
- Estimated: 0.5-1 day → Actual: 3 days (4x over)
- Root cause: Built shared test infrastructure
  - Created `MockDatabaseHelper` error simulation
  - Developed snackbar test utilities
  - Documented `createTestableWidget()` pattern
- Lesson: Test infrastructure work compounds but enables future velocity

**On Target: #223 (Backup/Restore)**
- Estimated: 2-3 days → Actual: 3 days
- 15 commits indicate high iteration despite accurate estimate
- Android/iOS file permission issues required multiple fixes
- Lesson: High commit count can signal hidden complexity even when estimate is met

**Unplanned: #229 (Recipe Import)**
- Added mid-sprint when backup infrastructure was ready
- Reused backup/restore JSON format
- Added 1 day to sprint
- Lesson: Plan for emergent opportunities (~10% buffer)

#### Working Pattern Observations

```
Dec 3:  ███ #225, #226, #227 (parallel quick wins)
Dec 4:  ██████ #223 (backup start)
Dec 5:  ████ #223 (backup cont.)
Dec 6:  ████████ #223, #228 (backup finish + filter)
Dec 7:  - (no commits)
Dec 8:  ██████ #148, #229, #76 (parallel work)
Dec 9:  ██ #224, #125
Dec 10: ████ #124 (test infra)
Dec 11: ████ #124 (test infra)
Dec 12: ████ #124, #126 (tests)
Dec 13-16: - (no commits)
Dec 17: ██ #126 (E2E finalization)
```

**Patterns:**
- Quick wins batched effectively (Dec 3)
- Feature work (#223) dominated early sprint
- Testing clustered at end (Dec 9-12)
- Natural breaks (Dec 7, Dec 13-16)

#### Lessons Learned

1. **Test infrastructure work is the main estimation risk**
   - #124 was the only true overrun (4x) due to building shared test utilities
   - Future: Add explicit "infra setup" task when new test patterns needed
   - Infra investment pays off - #125 and #126 benefited from #124's work

2. **Small estimates work well when batched**
   - Dec 3: Three 0.5-1 day issues completed efficiently in one day
   - Batching related quick wins reduces context switching
   - Half-day estimates are valid when work is focused

3. **High commit count = complexity signal**
   - #223 had 15 commits (5x average)
   - Even when estimate is accurate, watch for iteration patterns

4. **Unplanned work happens (~10%)**
   - #229 added because opportunity arose
   - Build buffer into sprint capacity

5. **Most estimates were conservative**
   - Overall ratio 0.90x means we slightly overestimated
   - Only #124 (test infra) was significantly underestimated

#### Recommendations Applied to 0.1.3

| Finding | Adjustment |
|---------|------------|
| Test infrastructure underestimated | Add explicit "infra" task when new patterns needed |
| Small tasks efficient when batched | Group related quick wins on same day |
| Most estimates conservative | Trust estimates, but watch for infra work |
| Unplanned work ~10% | Build buffer into sprint capacity |

### 0.1.3 - User Features & Critical Foundation

**Sprint Duration:** December 18-30, 2025
**Calendar Days:** 12
**Active Working Days:** 10 (83% utilization)
**Planned Issues:** 8
**Completed Issues:** 9 (including #236 added mid-sprint)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #221 | Organize integration tests | Testing | 1 | 1.0 | 688 | 1.00x | ✅ On target |
| #238 | Context menu for meal cards | UI | 2 | 1.0 | 3787 | 0.50x | ⚡ Faster |
| #234 | Refactor _updateMealRecord | Architecture | 2 | 0.33* | 867 | 0.17x | ⚡ Very fast |
| #235 | Refactor _handleMarkAsCooked | Architecture | 3 | 1.33* | 1221 | 0.44x | ⚡ Faster |
| #236 | Refactor _updateMealPlanItem | Architecture | N/A | 0.33* | 867 | - | 📋 Unplanned |
| #172 | Instructions viewing/editing | Feature | 3 | 1.0 | 737 | 0.33x | ⚡ Very fast |
| #77 | MealHistoryScreen widget tests | Testing | 2 | 1.0 | 8307 | 0.50x | ⚡ Faster |
| #38 | Dialog testing infrastructure | Testing | 5 | 3.25* | 30252 | 0.65x | ⚡ Faster |
| #39 | Edge case test suite | Testing | 8 | 0.75* | 22970 | 0.09x | ⚡ Very fast |
| **TOTAL** | | | **26** | **10.0** | **69696** | **0.38x** | |

*\* Weighted by lines changed when sharing day with other issues*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Testing | #221, #77, #38, #39 | 16 | 6.0 | 0.38x | ⚡ Much faster than expected |
| Architecture | #234, #235, #236 | 5 | 2.0 | 0.40x | ⚡ Very efficient |
| Features/UI | #238, #172 | 5 | 2.0 | 0.40x | ⚡ Very efficient |

**Overall:** Estimates were very conservative - actual effort was 38% of estimated (0.38x ratio)

#### Variance Analysis

**Major Underruns:**

**#39 (Edge case test suite)** - Estimated: 8 points → Actual: 0.75 days (0.09x)
- Root cause: Shared work with #38, efficient test pattern reuse
- Most work done on same days as #38 (Dec 27, 30)
- Edge case tests built on foundation from #38
- Lesson: Related testing tasks have high synergy when done together

**#234, #235, #236 (Architecture refactoring)** - Estimated: 5 points → Actual: 2.0 days (0.40x)
- All three done in parallel on Dec 23
- Similar patterns across all refactorings
- Once pattern established, very fast to replicate
- Lesson: Similar refactoring tasks are much faster when batched

**#172 (Instructions feature)** - Estimated: 3 points → Actual: 1.0 day (0.33x)
- Well-specified feature with existing patterns
- Clean implementation in single day
- Lesson: Well-specified features with clear patterns are faster than estimated

**On Target:**

**#221 (Organize tests)** - Estimated: 1 point → Actual: 1.0 day
- Perfect estimate for file reorganization task
- Lesson: Simple, well-defined tasks estimate accurately

**Fastest:**

**#38 (Dialog testing)** - Estimated: 5 points → Actual: 3.25 days (0.65x)
- Still faster than estimate despite being largest task
- Created comprehensive testing infrastructure
- Enabled fast execution of #39
- Lesson: Infrastructure tasks still faster than conservative estimates

#### Working Pattern Observations

```
Dec 19:  ███ #221 (688)
Dec 20:  ████████ #238 (3787)
Dec 22:  ██ #235 (354)
Dec 23:  ████████████ #234, #235, #236 (2601 total)
Dec 25:  ███ #172 (737)
Dec 26:  ████████ #77 (8307)
Dec 27:  ████████████ #38, #39 (7914 total)
Dec 28:  ████ #38 (2395)
Dec 29:  ██ #38 (963)
Dec 30:  ████████████████ #38, #39 (41950 total)
```

**Patterns:**
- Quick wins batched at start (Dec 19-20)
- Architecture refactoring done in parallel (Dec 23)
- Feature work isolated (Dec 25)
- Testing clustered at end (Dec 26-30)
- Final push with massive documentation/test additions (Dec 30)

#### Lessons Learned

1. **Estimates were VERY conservative (0.38x ratio overall)**
   - Testing estimates particularly conservative (0.38x)
   - Architecture estimates very conservative (0.40x)
   - Features/UI also very conservative (0.40x)
   - Lesson: Can be more aggressive with estimates, especially for well-understood work

2. **Batching similar tasks is extremely efficient**
   - #234, #235, #236 all done in one day despite 5 point estimate
   - Similar patterns enable fast replication
   - Context switching avoided
   - Lesson: When possible, batch similar refactorings together

3. **Related testing tasks have high synergy**
   - #38 and #39 shared days, #39 reused #38 patterns
   - Edge cases built on dialog testing foundation
   - Total: 13 points estimated → 4.0 days actual (0.31x)
   - Lesson: Related testing work should be done together for efficiency

4. **Well-specified features are fast**
   - #172 (instructions) done in 1 day vs. 3 point estimate
   - Clear requirements + existing patterns = fast execution
   - Lesson: Good specifications dramatically improve velocity

5. **Documentation and test writing dominated effort**
   - 69,696 lines changed (mostly test code and documentation)
   - #38 alone: 30,252 lines
   - #39: 22,970 lines
   - #77: 8,307 lines
   - Lesson: Testing sprints generate massive documentation but estimate conservatively

#### Recommendations for 0.1.4

| Finding | Adjustment |
|---------|------------|
| Overall very conservative (0.38x) | Can reduce estimates by ~30-40% for similar work |
| Batching similar tasks extremely efficient | Group related refactorings/tests together |
| Related testing tasks have synergy | Don't estimate testing tasks independently |
| Well-specified features fast | Trust specifications, reduce feature estimates |

#### Notes

- #236 was added mid-sprint (originally planned for 0.1.4)
- Sprint included comprehensive documentation creation
- Major testing infrastructure built (#38) enables future work
- Edge case catalog created (#39) - valuable reference
- All 8 planned issues + 1 bonus issue completed

### 0.1.4 - Architecture & Critical Bug Fixes

**Sprint Duration:** January 2-3, 2026
**Calendar Days:** 2
**Active Working Days:** 2 (100% utilization)
**Planned Issues:** 4
**Completed Issues:** 4

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #250 | Save Changes button obscured by Android navigation bar | Bug | 2 | 0.16* | 446 | 0.08x | ⚡ Very fast |
| #252 | Recipe card chevron inaccessible behind FAB | Bug | 2 | 0.0* | 12 | 0.00x | ⚡ Trivial |
| #244 | Add error simulation to MockDatabaseHelper | Testing | 3 | 0.56* | 1523 | 0.19x | ⚡ Very fast |
| #237 | Consolidate meal editing logic into shared service | Architecture | 5 | 1.27 | 1560 | 0.25x | ⚡ Very fast |
| **TOTAL** | | | **12** | **2.0** | **3541** | **0.17x** | |

*\* Weighted by lines changed when sharing day with other issues*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Bug fixes | #250, #252 | 4 | 0.16 | 0.04x | ⚡ Extremely fast (trivial fixes) |
| Testing | #244 | 3 | 0.56 | 0.19x | ⚡ Very fast (extending patterns) |
| Architecture | #237 | 5 | 1.27 | 0.25x | ⚡ Very fast (well-prepared) |

**Overall:** Estimates were EXTREMELY conservative - actual effort was 17% of estimated (0.17x ratio)

#### Variance Analysis

**All Issues Significantly Faster Than Estimated:**

**#252 (Recipe chevron fix)** - Estimated: 2 points → Actual: 0.0 days (0.00x)
- Root cause: Trivial fix - already solved in #250 pattern
- Only 12 lines changed
- Essentially zero effort once #250 pattern was understood
- Lesson: Related UI fixes have near-zero marginal cost

**#250 (Save button fix)** - Estimated: 2 points → Actual: 0.16 days (0.08x)
- Standard SafeArea pattern application
- 446 lines changed but straightforward implementation
- Lesson: Well-understood UI patterns are much faster than estimated

**#244 (MockDatabaseHelper error simulation)** - Estimated: 3 points → Actual: 0.56 days (0.19x)
- Extending existing test patterns (not new infrastructure)
- 1523 lines but mostly repetitive copy-paste work
- Lesson: Extending existing patterns is very efficient

**#237 (Meal editing service)** - Estimated: 5 points → Actual: 1.27 days (0.25x)
- Well-prepared with prerequisites (#234, #235, #236) completed
- Clear roadmap and implementation plan
- 1560 lines changed across 5 files
- Lesson: Thorough planning and prerequisites dramatically improve velocity

#### Working Pattern Observations

```
Jan 2:  ████████████████████ #244 (1523), #237 (726), #250 (446), #252 (12)
Jan 3:  ████████ #237 (834)
```

**Patterns:**
- All issues started on same day (Jan 2)
- Three small issues (#250, #252, #244) completed in parallel on day 1
- #237 (largest) continued to day 2
- Highly efficient batching and parallel work
- Clean 2-day sprint execution

#### Lessons Learned

1. **Estimates EXTREMELY conservative (0.17x ratio overall)**
   - Bug fixes: 0.04x (near-instant when using known patterns)
   - Testing: 0.19x (extending patterns is very efficient)
   - Architecture: 0.25x (thorough preparation pays off massively)
   - Lesson: When work is well-prepared and patterns are established, execution is 5-6x faster than estimated

2. **Related bug fixes have near-zero marginal cost**
   - #252 was essentially free after #250 (0.00x ratio)
   - Similar UI issues should be batched and estimated together
   - Lesson: Don't estimate similar fixes independently

3. **Prerequisites and planning eliminate uncertainty**
   - #237 had prerequisites #234, #235, #236 completed in 0.1.3
   - Detailed roadmap created before implementation
   - Result: 0.25x ratio (4x faster than estimated)
   - Lesson: Investment in planning and prerequisites dramatically improves velocity

4. **Extending patterns vs creating patterns**
   - #244 extended existing MockDatabaseHelper patterns (0.19x)
   - No new infrastructure needed
   - Mostly copy-paste work
   - Lesson: Distinguish "extend pattern" from "create pattern" when estimating

5. **Ultra-short sprints are viable**
   - 2-day sprint completed all 4 issues
   - 100% utilization
   - Clear scope and execution
   - Lesson: Well-defined work can be executed in very short sprints

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Overall extremely conservative (0.17x) | Reduce estimates by 70-80% for well-prepared work |
| Related bug fixes nearly free | Estimate as single unit when using same pattern |
| Prerequisites eliminate risk | Trust aggressive estimates when work is well-prepared |
| Pattern extension very fast | Use 0.2x multiplier for "extend existing pattern" tasks |
| Ultra-short sprints viable | Don't artificially extend sprints - ship when ready |

#### Notes

- Sprint benefited enormously from 0.1.3 preparation (#234, #235, #236)
- All issues had clear scope and known solutions
- No unknowns or discoveries during implementation
- Perfect example of how preparation reduces execution time
- Fastest sprint ratio to date (0.17x)

### 0.1.5 - Test Coverage & Polish

**Sprint Duration:** January 5-9, 2026
**Calendar Days:** 5
**Active Working Days:** 5 (100% utilization)
**Planned Issues:** 7
**Completed Issues:** 8 (including #254 added mid-sprint)

#### Estimation vs Actual

| Issue | Title | Type | Est Days | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|----------|-----------------|-------|-------|------------|
| #230 | Test coverage reporting | Infrastructure | 0.5 | 1.0 | 28 | 2.00x | 🔴 Over |
| #247 | AddIngredientDialog coverage (75.6% → 89%) | Testing | 0.5 | 0.82* | 457 | 1.64x | 🔴 Over |
| #248 | EditMealRecordingDialog coverage (89.6%) | Testing | 0.5 | 0.18* | 98 | 0.36x | ⚡ Faster |
| #249 | MealRecordingDialog coverage (79.8% → 96.7%) | Testing | 0.5 | 0.93* | 715 | 1.86x | 🔴 Over |
| #245 | Deferred error handling tests | Testing | 0.16 | 0.07* | 50 | 0.44x | ⚡ Faster |
| #251 | AddSideDishDialog visual hierarchy | UI/Polish | 0.44 | 1.61† | 391 | 3.66x | 🔴 Major overrun |
| #199 | Meal type selection feature | Feature | 0.88 | 2.27‡ | 508 | 2.58x | 🔴 Over |
| #254 | Update TODO comment | Docs | N/A | ~0 | 2 | - | 📋 Trivial |
| **TOTAL** | | | **3.48** | **6.88§** | **2249*** | **1.98x** | |

*\* Weighted by lines changed when sharing day with other issues*
*\*\* Total excludes roadmap deletions (2187 lines of cleanup work on Jan 9)*
*† #251: 1.01 days visible work + 0.6 days hidden adb/Android Studio overhead (30% of total)*
*‡ #199: 0.87 days visible work + 1.4 days hidden adb/Android Studio overhead (70% of total)*
*§ Total includes 2.0 days of sprint-wide hidden tooling overhead*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Infrastructure | #230 | 0.5 | 1.0 | 2.00x | 🔴 Overran (Codecov setup) |
| Testing (coverage) | #247, #248, #249 | 1.5 | 1.93 | 1.29x | 🔴 Overran (new discovery) |
| Testing (simple) | #245 | 0.16 | 0.07 | 0.44x | ⚡ Faster than expected |
| UI/Polish | #251 | 0.44 | 1.61 | 3.66x | 🔴 Major overrun (iteration + tooling) |
| Feature | #199 | 0.88 | 2.27 | 2.58x | 🔴 Overran (sprint-wide tooling issues) |

**Overall:** First sprint to overrun estimates - actual effort was 198% of estimated (1.98x ratio including 2.0 days of hidden tooling overhead)

#### Variance Analysis

**Major Overruns:**

**#199 (Meal type selection)** - Estimated: 0.88 days → Actual: 2.27 days (2.58x)
- Root cause: Sprint-wide adb/Android Studio tooling issues during testing phase
- Visible work (0.87 days): Database migration, models, screens, widgets, tests
- Hidden work (1.4 days / 70% of total overhead): adb/Android Studio debugging during final testing
- Feature implementation itself was fast (~0.5 days for visible work)
- **Critical lesson: Testing phase can have massive hidden overhead not visible in commits**
- Previously thought to be "perfect estimate" until tooling overhead was properly attributed

**#251 (AddSideDishDialog UI)** - Estimated: 0.44 days → Actual: 1.61 days (3.66x)
- Root cause: UI polish required multiple iterations PLUS hidden tooling overhead
- Visible work (1.01 days): (1) visual hierarchy, (2) scrolling improvements, (3) overflow fix
- Hidden work (0.6 days / 30% of total overhead): adb/Android Studio debugging
- User feedback drove additional improvements mid-implementation
- Overflow issue discovered during testing (RenderFlex 144px error)
- **Critical lesson: Mobile/UI work has invisible tooling overhead not tracked in commits**

**#230 (Coverage infrastructure)** - Estimated: 0.5 days → Actual: 1.0 days (2.00x)
- Codecov setup and documentation took full day
- Integration, badge configuration, and documentation more involved than expected
- Lesson: External service integrations take longer than expected even with good docs

**#249 (MealRecordingDialog)** - Estimated: 0.5 days → Actual: 0.93 days (1.86x)
- Comprehensive coverage improvement (79.8% → 96.7%)
- Required understanding existing patterns and writing new tests
- Lesson: Coverage improvements without existing patterns are slower

**#247 (AddIngredientDialog)** - Estimated: 0.5 days → Actual: 0.82 days (1.64x)
- Coverage improvement (75.6% → 89%) PLUS hidden work
- Required MockDatabaseHelper enhancements (error simulation, new methods)
- Additional infrastructure work not explicitly estimated
- Lesson: Test coverage tasks may reveal infrastructure gaps - estimate conservatively

**Faster than Expected:**

**#248 (EditMealRecordingDialog)** - Estimated: 0.5 days → Actual: 0.18 days (0.36x)
- Already at 89.6% coverage - analysis only, no code changes needed
- Pragmatic decision: 89.6% with strong workflow tests > 90% with low-value tests
- Lesson: Coverage targets should be pragmatic, not absolute

**#245 (Deferred error tests)** - Estimated: 0.16 days → Actual: 0.07 days (0.44x)
- Small, well-defined task with clear scope
- Two specific tests to implement
- Lesson: Small, focused tasks estimate well

#### Working Pattern Observations

```
Jan 5:  ██ #230 (28)
Jan 6:  █████ #247 (457), #248 (98)
Jan 7:  ███████ #249 (715), #245 (50)
Jan 8:  ███ #251 (391)
Jan 9:  █████████ #199 (508), #251 (6), plus cleanup (2187 lines of roadmap deletions)
```

**Patterns:**
- Infrastructure first (Jan 5: #230 Codecov setup)
- Coverage improvements batched (Jan 6-7: #247, #248, #249, #245)
- UI polish mid-sprint (Jan 8: #251 main work)
- Feature work at end (Jan 9: #199)
- Large cleanup day (Jan 9: roadmap deletions after issues completed)
- 100% utilization - every day had active work

#### Lessons Learned

1. **First sprint to overrun estimates (1.98x ratio including hidden overhead)**
   - Previous sprints: 0.90x, 0.38x, 0.17x (all under estimate)
   - Those sprints benefited from well-prepared work and pattern reuse
   - This sprint had discovery, iteration, new infrastructure, AND massive sprint-wide tooling overhead
   - **CRITICAL: Can't use previous sprint ratios to predict all future work types**

2. **Hidden tooling/environment overhead is MASSIVE and sprint-wide**
   - Total: 2.0 full days lost to adb/Android Studio debugging (29% of actual time!)
   - #199: 1.4 days (70%) - testing phase tooling issues
   - #251: 0.6 days (30%) - UI iteration tooling issues
   - Zero trace in commit history but doubled the sprint ratio (1.98x vs hypothetical 0.99x)
   - **CRITICAL: Add 25-35% buffer for mobile/UI sprints with testing phases**

3. **Don't use outlier sprints for future estimates**
   - 0.1.4 was exceptional (0.17x, 6.00 points/day) - well-prepared work, simpler than expected
   - 0.1.5 estimates were based on 0.1.4's velocity - huge mistake
   - Normal velocity: 1.1-2.8 points/day (0.1.2, 0.1.3, 0.1.5)
   - **Lesson: Use median/normal velocity, not best-case outliers**

4. **Coverage improvement tasks need conservative estimates**
   - #247, #249 took 1.64x-1.86x longer than estimated
   - Prior testing data (0.38x, 0.19x) was for extending existing patterns
   - Raw coverage improvement requires understanding, writing new tests, infrastructure
   - Lesson: Distinguish "extend patterns" (fast) from "improve coverage" (slower)

5. **UI polish requires massive iteration buffer**
   - #251 took 3.66x when including hidden overhead
   - Three visible commits (1.01 days) + 0.6 days of invisible tooling
   - User feedback and discovered issues compound
   - **Lesson: UI polish estimates should include 3-4x buffer (iteration + tooling)**

6. **External service integrations underestimated**
   - #230 (Codecov) took 2.0x longer than estimated
   - Even with good documentation, integrations have hidden complexity
   - Lesson: Double estimates for external service integrations

7. **Hidden infrastructure work in coverage tasks**
   - #247 required MockDatabaseHelper enhancements not explicitly estimated
   - Test infrastructure dependencies should be identified upfront
   - Lesson: Coverage improvement tasks should explicitly estimate infrastructure work

8. **Pragmatic coverage targets work well**
   - #248 completed at 89.6% with analysis only (no code changes)
   - Strong workflow coverage more valuable than hitting arbitrary 90% threshold
   - Lesson: Coverage targets should be pragmatic, not absolute

9. **Feature implementation CAN be fast despite testing overhead**
   - #199 visible work: 0.87 days (near-perfect for feature complexity)
   - Total with tooling: 2.27 days (2.58x overrun due to testing phase overhead)
   - Feature estimates were accurate - testing phase overhead was not
   - **Lesson: Separate "implementation estimate" from "testing/validation overhead estimate"**

#### Recommendations for 0.1.6

| Finding | Adjustment |
|---------|------------|
| **CRITICAL: Sprint-wide tooling overhead (2.0 days = 29%)** | Add 25-35% buffer for mobile/UI sprints with testing phases |
| Hidden overhead distributed across issues | Expect ~70% of tooling overhead in testing/validation, ~30% in UI iteration |
| UI polish requires massive iteration (3.66x) | Add 3-4x buffer for UI tasks (iteration + tooling + feedback) |
| Feature testing phase massively underestimated (2.58x) | Explicitly estimate testing/validation overhead separate from implementation |
| Don't use outlier velocity (0.1.4 was 6.0x faster) | Use median velocity (2.0-2.8 points/day) for milestone sizing |
| Coverage improvement tasks overran (1.64x-1.86x) | Use 1.5-2.0x multiplier for coverage improvement vs pattern extension |
| External integrations underestimated (2.0x) | Double estimates for external service integrations |
| Hidden infrastructure work | Explicitly estimate test infrastructure enhancements |
| Pragmatic coverage targets | Accept <90% if coverage is pragmatic and valuable |
| **Milestone sizing** | Target 8-12 points per 5-day sprint (reduced from 10-15 due to overhead discovery) |

#### Notes

- #254 was added mid-sprint (trivial TODO update)
- All 7 planned issues completed successfully
- Sprint included comprehensive cleanup (2187 lines of roadmap deletions on Jan 9)
- Coverage infrastructure (#230) enables future quality tracking
- Three dialogs now have >89% coverage with pragmatic test suites
- First sprint to overrun estimates - important data point for calibration
- Jan 9 had exceptionally high line count due to roadmap deletions (not implementation)
- **Revised analysis:** Initial estimate was 1.69x (1 day overhead), corrected to 1.98x (2 days overhead: 70% on #199 testing, 30% on #251 UI)

---

## Cumulative Metrics

### Estimation Accuracy Trend

| Sprint | Planned Points | Weighted Actual | Ratio | Points/Day | Trend |
|--------|----------------|-----------------|-------|------------|-------|
| 0.1.2 | 12.2 | ~11 | 0.90x | 1.11 | Baseline (slightly conservative, mixed work) |
| 0.1.3 | 26 | 10.0 | 0.38x | 2.60 | VERY conservative (pattern reuse) |
| 0.1.4 | 12 | 2.0 | 0.17x | 6.00 | **OUTLIER** - Extremely well-prepared work |
| 0.1.5 | 14 | 6.88 | 1.98x | 2.03 | OVERRAN - Discovery work + MASSIVE hidden overhead |

**Critical Insights:**
- **Sprint ratio depends heavily on work type** - Can't use one sprint to predict another
- **0.1.4 was an outlier** (6.00 points/day) - Don't use for future estimates
- **Normal velocity: 1.1-2.8 points/day** (0.1.2, 0.1.3, 0.1.5)
- **Median velocity: ~2.5 points/day** - Use this for milestone sizing
- **Hidden overhead is CRITICAL** - Tooling/environment issues added 29% to 0.1.5 (2 full days)

### Type-Based Calibration Factors

Use these multipliers when estimating future work:

| Type | Sample Size | Avg Ratio | Recommended Multiplier | Notes |
|------|-------------|-----------|------------------------|-------|
| Bug fixes (new patterns) | 2 issues | 0.62x | 0.5-1.0x | Conservative (0.1.2) |
| Bug fixes (known patterns) | 2 issues | 0.04x | 0.1-0.2x | **NEW**: Trivial when pattern established (0.1.4) |
| Bug fixes (related/batched) | - | 0.00x | 0.0x | **NEW**: Near-zero marginal cost for similar fixes (0.1.4: #252) |
| UI/Features | 5 issues | 0.56x | 0.6-0.7x | Very conservative (0.1.2: 0.84x, 0.1.3: 0.40x) |
| Parser/Algorithm | 2 issues | 0.21x | 0.5x | Very efficient (0.1.2) |
| Architecture (unprepared) | 5 issues | 0.40x | 0.5x | Very efficient when batched (0.1.3) |
| Architecture (well-prepared) | 1 issue | 0.25x | 0.2-0.3x | **NEW**: Extremely fast with prerequisites (0.1.4: #237) |
| Testing (existing patterns) | 3 issues | 0.62x | 1.0x | Conservative (0.1.2) |
| Testing (extend patterns) | 1 issue | 0.19x | 0.2x | **NEW**: Very fast copy-paste work (0.1.4: #244) |
| Testing (new infra) | 5 issues | 1.27x | 1.0-1.5x | **REVISED**: 0.1.2 was outlier (4.00x), 0.1.3 averaged 0.51x |
| Testing (related tasks) | 2 issues | 0.31x | 0.3-0.5x | Extremely efficient when done together (0.1.3: #38+#39) |

**Key Insights from 0.1.4:**
- **Well-prepared work is 5-6x faster** than estimated (0.17x average)
- **Prerequisites eliminate uncertainty** - #237 was 0.25x after #234, #235, #236
- **Pattern reuse is nearly free** - #252 was 0.00x after #250 established pattern
- **Extending vs creating patterns** - Distinguish when estimating (0.19x vs 1.27x)

---

## Estimation Guidelines

### Before Estimating

1. **Identify infrastructure work explicitly**
   - New test patterns needed? → Add separate "infra" task
   - New utilities or helpers? → Don't hide in feature estimate
   - This is the main source of estimation errors

2. **Consider batching small tasks**
   - Group related 0.5-day tasks on same day
   - Reduces context switching overhead
   - Small estimates are valid when focused

3. **Check commit history for similar past work**
   - High commit count in similar issues = add buffer

### Estimate Sizes

- **XS (0.5 day):** Valid for focused work, batch with similar tasks
- **S (1 day):** Most bugs, small features
- **M (2 days):** Standard features, complex bugs
- **L (3 days):** Features with multiple components
- **XL (5+ days):** Consider breaking down

### Red Flags During Sprint

- Issue exceeds 10 commits → likely underestimated
- Multiple "fix:" commits → unexpected complexity
- Work spanning 3+ days on "1 day" estimate → stop and reassess
- Building new test utilities → flag as infrastructure work

---

## Milestone Sizing Guidelines

Use historical velocity data to size future milestones and prevent overcommitment.

### Velocity Reference Data

| Sprint | Points | Days | Points/Day | Work Type |
|--------|--------|------|------------|-----------|
| 0.1.2 | 12.2 | 11 | 1.11 | Mixed (features, bugs, testing) |
| 0.1.3 | 26 | 10 | 2.60 | Well-prepared (pattern reuse) |
| 0.1.4 | 12 | 2 | 6.00 | **OUTLIER** (extremely well-prepared) |
| 0.1.5 | 14 | 6.88 | 2.03 | Discovery + iteration + MASSIVE overhead (29%) |

**Normal Velocity Range:** 1.1 - 2.8 points/day
**Median Velocity:** ~2.5 points/day
**Outlier (ignore):** 6.0 points/day (0.1.4)

### Milestone Sizing Recommendations

**For 5-Day Sprints:**
- **Conservative (recommended):** 10-12 points (~2.0-2.4 points/day)
- **Normal:** 12-15 points (~2.4-3.0 points/day)
- **Aggressive (risky):** 15+ points (>3.0 points/day)

**For 10-Day Sprints:**
- **Conservative (recommended):** 20-25 points (~2.0-2.5 points/day)
- **Normal:** 25-30 points (~2.5-3.0 points/day)
- **Aggressive (risky):** 30+ points (>3.0 points/day)

### Adjustment Factors

**Increase capacity (+20-30%) if:**
- All work is well-prepared with prerequisites completed
- Issues are similar and can be batched
- Extending existing patterns (not creating new ones)

**Decrease capacity (-30-50%) if:**
- Work involves discovery or research
- New infrastructure or patterns needed
- UI polish requiring iteration and feedback
- External service integrations
- Mobile/UI work with potential tooling issues

**Critical Rules:**
1. **Never use outlier velocity** (0.1.4's 6.0 points/day) for planning
2. **Use median velocity** (2.5 points/day) as baseline
3. **Add 25-35% overhead buffer** for mobile/UI sprints with testing phases
4. **Limit milestones to 8-12 points per 5 days** for mobile/UI work (revised down from 10-15)
5. **Review velocity after each sprint** - don't assume it's constant

### Examples

**Good Milestone (5 days, 12 points):**
- 3x S-sized features (2 points each) = 6 points
- 2x M-sized features (3 points each) = 6 points
- Expected velocity: 12 points / 5 days = 2.4 points/day ✅

**Risky Milestone (5 days, 20 points):**
- Assumes 4.0 points/day velocity
- Higher than normal range (1.1-2.8 points/day)
- Likely to overrun unless work is extremely well-prepared ❌

**Well-Balanced Milestone (10 days, 25 points):**
- Mix of features, testing, and polish
- Expected velocity: 25 points / 10 days = 2.5 points/day ✅
- Includes 10% buffer for overhead

---

## Document History

- **2025-12-18**: Created with 0.1.2 retrospective analysis
- **2025-12-18**: Added `scripts/analyze_sprint_commits.py` for automated commit analysis
- **2025-12-18**: Corrected methodology to use weighted days (lines changed) for shared days
  - Previous "active days" method overcounted when multiple issues shared a day
  - Revised overall ratio from 1.31x to 0.90x (estimates were slightly conservative)
  - Key insight: Small estimates work well when batched; test infra is main risk
- **2025-12-31**: Added 0.1.3 retrospective analysis
  - Sprint completed: 8 planned + 1 unplanned issues (9 total)
  - Actual ratio: 0.38x (VERY conservative estimates)
  - Revised testing infrastructure estimates: 0.1.2's 4.00x was outlier, 0.1.3 averaged 0.51x
  - Key insights: Batching similar tasks is extremely efficient; related testing tasks have high synergy; well-specified features are faster than estimated
  - Updated calibration factors based on combined 0.1.2 and 0.1.3 data
- **2026-01-03**: Added 0.1.4 retrospective analysis
  - Sprint completed: 4 issues in 2 days (100% utilization)
  - Actual ratio: 0.17x (EXTREMELY conservative - fastest sprint to date)
  - Key insight: Well-prepared work with prerequisites is 5-6x faster than estimated
  - New calibration factors: Bug fixes with known patterns (0.04x), architecture with prerequisites (0.25x), extending patterns (0.19x)
  - Critical finding: Related bug fixes have near-zero marginal cost when using same pattern
- **2026-01-10**: Added 0.1.5 retrospective analysis (REVISED with accurate overhead distribution)
  - Sprint completed: 7 planned + 1 trivial issue (8 total) in 5 days (100% utilization)
  - Actual ratio: 1.98x (FIRST sprint to overrun estimates)
  - **CRITICAL discovery: Massive sprint-wide hidden tooling overhead** (2.0 full days = 29% of actual time)
  - Overhead distribution: #199 (70% / 1.4 days testing phase), #251 (30% / 0.6 days UI iteration)
  - Zero trace in commit history but doubled the sprint ratio from hypothetical 0.99x to actual 1.98x
  - Identified 0.1.4 as outlier (6.00 points/day) - should not be used for future estimates
  - Established normal velocity range: 1.1-2.8 points/day, median: ~2.5 points/day
  - **NEW: Milestone Sizing Guidelines** section added with velocity-based capacity planning
  - Key findings: UI polish requires 3-4x buffer, feature testing phase massively underestimated (2.58x), sprint-wide tooling overhead = 25-35% buffer needed
  - Recommendations: Target 8-12 points per 5-day sprint (reduced from 10-15), add 25-35% buffer for mobile/UI sprints with testing phases, separate implementation estimates from testing/validation overhead
