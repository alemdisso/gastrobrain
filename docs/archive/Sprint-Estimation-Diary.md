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

**Note:** Use `python3` command (not `python`) in Linux environments. On Windows, use `python`.

### 2. Review Output

The script outputs:
- **Commits by Issue** - Active days and commit counts per issue
- **Untagged Commits** - Commits without issue numbers that need attribution
- **Working Days Summary** - Utilization and date range
- **Daily Activity** - Visual timeline of work

### 3. Interview the Developer (CRITICAL)

Before interpreting data, **ask the developer** about aspects commits don't capture:
- **Sprint boundaries:** Confirm actual start/end dates (commits are a proxy, not the truth)
- **Hidden work:** Device testing, design thinking, planning, debugging that left no commit trace
- **Rest days vs no-commit work days:** A day without commits may have been research, testing, or rest
- **Milestone transitions:** How did sprints overlap? Was there a deliberate handoff or continuous flow?
- **Unplanned work context:** Why did emergent issues appear? UX feedback loop? Bug discovery? Scope evolution?
- **Efficiency drivers:** What went well? New skills applied? Pattern reuse? Better tooling?
- **Blockers or friction:** Anything that slowed down but doesn't show in data?

This step prevents the analyst from guessing at context and attributing fast execution solely to overestimation when genuine efficiency may be a factor.

### 4. Attribute Untagged Commits

Review untagged commits and mentally assign them to issues based on commit message content. Common patterns:
- Test commits without `#number` often belong to nearby tagged test issues
- Merge commits can be ignored
- Doc/style commits may be general maintenance

### 5. Compare with Estimates

Cross-reference actual days with estimates from sprint planning doc or GitHub Project fields (Size/Estimate columns) to calculate ratios.

### 6. Document in This File

Add a new section under "Sprint Reviews" following the 0.1.2 template. When writing the analysis:
- **Balance overestimation vs efficiency** — fast execution can be both; acknowledge genuine skill gains
- **Distinguish work types** — design system, features, testing, and polish have different velocity profiles
- **Frame emergent work contextually** — UX feedback is a healthy product cycle, not just "unplanned work"

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

### 0.1.6 - Shopping List & Polish

**Sprint Duration:** January 22-28, 2026
**Calendar Days:** 7
**Active Working Days:** 6 (86% utilization)
**Planned Issues:** 6 (20 points)
**Completed Issues:** 6 (5 planned + 1 unplanned; #242 Resolved by SDK Update)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #231 | Extract RecipesScreen refactor | Architecture | 1 | 0.96* | 1230 | 0.96x | ✅ On target |
| #196 | "To Taste" ingredients display | Polish | 1 | 0.04* | 54 | 0.04x | ⚡ Very fast |
| #33 | Recipe navigation from meal plan | UX Fix | 3 | 0.57* | 844 | 0.19x | ⚡ Very fast |
| #264 | RecipeCard UI improvements | Refactor | N/A | 1.43* | 759 | - | 📋 Unplanned |
| #32 | Meal summary section | Feature | 5 | 1.0 | 2544 | 0.20x | ⚡ Very fast |
| #5 | Shopping List Generation | Feature | 8 | 2.0 | 4812 | 0.25x | ⚡ Very fast |
| #242 | Fix RegExp deprecation warnings | Tech Debt | 2 | - | - | - | Not needed |
| **TOTAL** | | | **18*** | **6.0** | **10243** | **0.33x** | |

*\* Weighted by lines changed when sharing day with other issues*
*\*\* Total excludes #242 (Resolved by SDK Update)*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Architecture | #231 | 1 | 0.96 | 0.96x | ✅ Perfect estimate |
| Polish | #196 | 1 | 0.04 | 0.04x | ⚡ Extremely fast (trivial) |
| UX/Features | #33, #32 | 8 | 1.57 | 0.20x | ⚡ Much faster than expected |
| Major Feature | #5 | 8 | 2.0 | 0.25x | ⚡ Very fast (well-specified) |

**Overall:** Estimates were very conservative - actual effort was 33% of estimated (0.33x ratio)

#### Variance Analysis

**Major Underruns:**

**#5 (Shopping List Generation)** - Estimated: 8 points → Actual: 2.0 days (0.25x)
- Root cause: Well-specified feature with comprehensive planning document
- 26 commits show thorough implementation but faster than expected
- Clear roadmap and incremental approach enabled fast execution
- Complete test coverage (unit, widget, integration, edge cases)
- Lesson: Detailed feature specifications dramatically improve velocity

**#32 (Meal summary section)** - Estimated: 5 points → Actual: 1.0 day (0.20x)
- "Keep simple" approach worked perfectly
- No external libraries, basic widgets
- Foundation laid for future enhancements
- Lesson: Simple MVP scope estimates should be more aggressive

**#33 (Recipe navigation)** - Estimated: 3 points → Actual: 0.57 days (0.19x)
- MVP scope clearly defined in issue
- Straightforward implementation once scope limited
- Lesson: Clear MVP boundaries enable accurate (aggressive) estimates

**#196 (To Taste ingredients)** - Estimated: 1 point → Actual: 0.04 days (0.04x)
- Extremely small change (54 lines)
- Batched with #231 on same day


**On Target:**

**#231 (Extract RecipesScreen)** - Estimated: 1 point → Actual: 0.96 days (0.96x)
- Nearly perfect estimate for refactoring task
- 1230 lines changed but straightforward extraction
- Lesson: Simple refactorings estimate accurately

**Unplanned Work:**

**#264 (RecipeCard improvements)** - Unplanned → Actual: 1.43 days
- Related to #33 but expanded scope
- Improved recipe card UI and navigation
- Added tap navigation to RecipeDetailsScreen
- 4 commits, 759 lines
- Lesson: Related improvements discovered during implementation add ~25% to sprint

**Deferred:**

**#242 (RegExp warnings)** - Estimated: 2 points → Deferred
- Not critical for milestone completion
- Prioritized features over tech debt
- Lesson: Flexible prioritization enables focus on value

#### Working Pattern Observations

```
Jan 22:  ████████ #231 (1230), #196 (54)
Jan 23:  ████████ #33 (844), #264 (647)
Jan 24:  ████ #32 (2544)
Jan 25:  - (untagged: skills/docs - 2664 lines)
Jan 26:  ████ #5 (start)
Jan 27:  ████████ #5 (continue)
Jan 28:  ████ #264 (finalize), #5 (tests)
```

**Patterns:**
- Quick wins first (Jan 22: #231, #196)
- UX fixes next (Jan 23: #33, #264)
- Features in sequence (Jan 24: #32, Jan 26-28: #5)
- Major feature (#5) spanned 3 days with 26 commits
- Parallel work on Jan 23 and Jan 28 (multiple issues)
- High utilization (86%) with focused days

#### Lessons Learned

1. **Estimates very conservative again (0.33x ratio overall)**
   - Similar to 0.1.3 (0.38x) and 0.1.4 (0.17x)
   - Well-prepared work continues to be 3-4x faster than estimated
   - Lesson: Continue using aggressive estimates for well-specified work

2. **Detailed feature specifications are game-changers**
   - #5 had comprehensive spec document
   - Clear requirements, data models, algorithms documented
   - Result: 8-point feature done in 2 days (0.25x)
   - Lesson: Invest time in specifications - pays off 3-4x in execution

3. **MVP scope clarity enables fast execution**
   - #32, #33 both had explicit "keep simple" / "MVP scope" guidance
   - No scope creep, no over-engineering
   - Result: 0.19x-0.20x ratios
   - Lesson: "Keep simple" must be explicit in estimates and execution

4. **Unplanned work is consistent (~10-25%)**
   - #264 added 1.43 days (~24% of total)
   - Similar pattern in previous sprints
   - Lesson: Build 20-25% buffer for emergent work

5. **Small tasks have inherent 1-point floor**
   - #196 was 1 point but took 0.04 days (trivial work)
   - 1 point represents minimum overhead: read issue, branch, commit, document, push
   - Better to have "fat to burn" on small tasks than introduce decimal complexity
   - Lesson: Keep 1 point as minimum; scale UP larger estimates instead

6. **Flexible prioritization works well**
   - #242 deferred without impact
   - Focus on value delivery over completionism
   - Lesson: Not all planned work must complete if priorities shift

7. **Architecture refactoring estimates accurate**
   - #231 was nearly perfect (0.96x)
   - Second sprint in a row with good architecture estimates
   - Lesson: Refactoring velocity is now well-calibrated

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Overall very conservative (0.33x) | Scale UP larger estimates to match velocity (e.g., 8pt → 12-15pt) |
| Detailed specs enable fast execution | Invest in feature specs before estimating |
| MVP scope prevents over-engineering | Explicitly mark "keep simple" tasks with lower estimates |
| Unplanned work ~25% | Build 20-25% buffer into sprint capacity |
| Small tasks have 1-point floor | Keep 1pt minimum for task overhead; scale larger tasks instead |
| Architecture estimates calibrated | Trust 1:1 ratio for simple refactorings |

#### Notes

- Sprint successfully delivered 90% of planned work (18/20 points)
- #242 deferred (non-critical tech debt)
- #264 added mid-sprint (related to #33)
- Major feature (#5) completed with comprehensive testing
- All features have full localization (EN/PT)
- Shopping list workflow completes core meal planning functionality
- 0.1.7 milestone continues the 0.1.x series

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

### 0.1.7a - Visual Foundation

**Sprint Duration:** January 30, 2026
**Calendar Days:** 1
**Active Working Days:** 1 (shared with start of 0.1.7b work)
**Planned Issues:** 3
**Completed Issues:** 3

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #255 | Define visual identity & design principles | Design | 5 | 0.07* | 565 | 0.01x | ⚡ Very fast |
| #256 | Create design tokens system | Design | 8 | 0.07* | 565 | 0.01x | ⚡ Very fast |
| #257 | Implement ThemeData configuration | Implementation | 8 | 0.17* | 1379 | 0.02x | ⚡ Very fast |
| **TOTAL** | | | **21** | **0.31** | **2509** | **0.01x** | |

*\* Heavily weighted down because Jan 30 was shared with #258 (0.1.7b) which dominated line count (69% of day)*

**Note on methodology:** The weighted-days method significantly underrepresents 0.1.7a effort because #258 prep work (refactoring extractions, skill creation, analysis docs — 5489 lines) started on the same day. Realistically, the 3 foundation issues took approximately half a day of focused effort, with #255 and #256 completed in a single commit.

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Design/Docs | #255, #256 | 13 | 0.14 | 0.01x | ⚡ Extremely fast (single commit) |
| Implementation | #257 | 8 | 0.17 | 0.02x | ⚡ Very fast (well-prepared) |

**Overall:** Foundation milestone completed in a single day. The low ratio reflects both conservative estimates for a new work type AND genuine efficiency — the visual identity was well-conceptualized, enabling a clean design → tokens → ThemeData flow with no iteration or rework.

#### Variance Analysis

**All Issues Extremely Fast:**

**#255 + #256 (Visual identity + design tokens)** — Estimated: 13 points → Actual: same commit
- Root cause: These were conceptually a single task — defining the visual identity naturally produces the design tokens
- Single commit `5a8f0c2` covered both issues
- Lesson: Conceptually linked design tasks should be estimated as a unit, not separately

**#257 (ThemeData configuration)** — Estimated: 8 points → Actual: ~0.17 weighted days
- Straightforward implementation once tokens were defined
- Flutter's ThemeData API maps directly to design tokens
- Lesson: ThemeData implementation is mechanical once design tokens exist — estimate as 1-2 points, not 8

#### Working Pattern Observations

```
Jan 30:  ████ #255+#256 (565), #257 (1379) → then immediately started #258 prep
```

**Patterns:**
- All 3 foundation issues completed before noon
- #258 (0.1.7b) prep work started same day — no gap between milestones
- Design → tokens → ThemeData was a natural sequential flow
- Single-day milestone enabled immediate transition to screen polish

#### Lessons Learned

1. **Design foundation estimates need calibration for this project**
   - 21 points across 3 issues for what was ~0.5 days of focused work
   - Part overestimation (new work type, no prior data), part genuine efficiency (clear vision, no iteration)
   - The visual identity was well-conceptualized before sitting down to implement
   - Lesson: Estimate design foundation as a single 3-5 point unit; recognize that clear creative vision enables fast execution

2. **Linked design tasks should be estimated together**
   - #255 and #256 were literally one commit
   - Separate 5pt + 8pt estimates for what was a single deliverable
   - Lesson: When issues share the same deliverable, estimate as one

3. **Clean design → implementation pipeline is highly efficient**
   - Once design tokens were defined, ThemeData was direct translation
   - No back-and-forth between design and code — the pipeline flowed naturally
   - Lesson: Distinguish "creative design" from "mechanical translation"; invest in clear design upfront

4. **Zero gap between milestones is efficient**
   - Transitioning immediately from 0.1.7a to 0.1.7b avoided context loss
   - Foundation work + immediate application is highly productive
   - Lesson: Sequential milestones with natural flow don't need buffer days

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Design foundation massively overestimated (0.01x) | Estimate linked design tasks as single 3-5 point unit |
| Linked issues = single commit | Don't separate tightly-coupled design tasks |
| ThemeData is mechanical translation | Estimate at 1-2 points when tokens already defined |
| Zero-gap milestone transition works well | Plan sequential milestones with natural flow |

#### Notes

- Milestone effectively completed in half a day
- All 3 issues were tightly coupled and could have been a single issue
- #258 (0.1.7b) prep work began immediately on same day
- Design tokens and ThemeData became the foundation for all subsequent 0.1.7b work
- No unplanned work — scope was perfectly contained

### 0.1.7b - Screen & Component Polish

**Sprint Duration:** January 30 - February 6, 2026
**Calendar Days:** 8
**Active Working Days:** 7 (Jan 30, 31, Feb 1, 2, 3, 5, 6; 88% utilization)
**Planned Issues:** 5 (31 points)
**Completed Issues:** 8 (5 planned + 3 unplanned)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #258 | Polish weekly meal planning screen | UI/UX | 8 | 3.27* | 18717 | 0.41x | ⚡ Faster |
| #259 | Polish recipe list screen | UI/UX | 5 | 0.42* | 510 | 0.08x | ⚡ Very fast |
| #260 | Standardize button styles | UI | 5 | 0.29* | 632 | 0.06x | ⚡ Very fast |
| #261 | Standardize form input styles | UI | 8 | 0.31* | 677 | 0.04x | ⚡ Very fast |
| #262 | Standardize navigation styles | UI | 5 | 1.0 | 1579 | 0.20x | ⚡ Faster |
| #266 | Shopping list preview (Stage 1) | Feature | 5 | 0.93* | 1704 | 0.19x | 📋 Unplanned |
| #267 | Shopping list refinement (Stage 2) | Feature | 5 | 0.40* | 856 | 0.08x | 📋 Unplanned |
| #269 | Shopping list overflow fix | Bug | 2 | 0.07* | 134 | 0.04x | 📋 Unplanned |
| **TOTAL** | | | **43** | **6.69** | **24809** | **0.16x** | |

*\* Weighted by lines changed when sharing day with other issues*

**Note:** #258 work started on Jan 30 (shared with 0.1.7a). Its 3.27 weighted days span Jan 30-Feb 2 (2.69 days Jan 30-Feb 1 + 0.58 days Feb 2). Issues #266, #267, #269 were unplanned additions that emerged during implementation.

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Screen Polish | #258, #259 | 13 | 3.69 | 0.28x | ⚡ Faster (but #258 was massive effort) |
| Component Standardization | #260, #261, #262 | 18 | 1.60 | 0.09x | ⚡ Extremely fast |
| Unplanned Features | #266, #267 | 10 | 1.33 | 0.13x | ⚡ Very fast (built on existing patterns) |
| Unplanned Bug Fix | #269 | 2 | 0.07 | 0.04x | ⚡ Trivial fix |

**Overall:** Actual effort was 16% of estimated (0.16x ratio). This reflects both conservative estimates for a new work type (design system application) AND genuine workflow efficiency — the design tokens foundation from 0.1.7a enabled fast, mechanical application across screens and components, and batching similar work minimized context switching.

#### Variance Analysis

**Major Issue: #258 (Polish weekly planning screen)** — Estimated: 8 points → Actual: 3.27 weighted days (0.41x)
- Largest issue in the sprint with 17 commits and 18717 lines changed
- Included major refactoring: extracted MealPlanService, MealActionService, MealPlanSummaryService, RecommendationCacheService, WeekNavigationWidget, RecipeSelectionDialog
- UX redesign with bottom sheet tools pattern (Phase 2A)
- Visual polish with design tokens (Phase 2B)
- Created issue analysis skill and senior dev implementation skill during this work
- While 0.41x ratio looks fast, the absolute effort (3.27 days) was substantial
- Lesson: Complex screen polish with refactoring is accurately estimated at ~3 days, even if points suggest more

**Very Fast: Component Standardization (#260, #261, #262)** — Estimated: 18 points → Actual: 1.60 days (0.09x)
- All three followed the same pattern: audit current styles → apply theme tokens → verify
- #260 (buttons) and #261 (forms) done on same day alongside #267
- #262 (navigation) got a full day but included comprehensive tests (1078 lines of tests)
- Lesson: Component standardization is mechanical once design tokens exist — estimate at 1-2 points each, not 5-8

**Very Fast: #259 (Recipe list polish)** — Estimated: 5 points → Actual: 0.42 days (0.08x)
- Pattern already established by #258
- Applying design tokens to a second screen is much faster than the first
- Lesson: Second-screen polish is ~80% faster than first screen

**Unplanned: #266, #267 (Shopping list enhancements)** — Unplanned (12 points total) → Actual: 1.33 days
- Emerged during sprint when shopping list improvements were identified
- #266 (preview mode) was more substantial (0.93 days, including comprehensive tests)
- #267 (refinement mode) built directly on #266 patterns (0.40 days)
- Lesson: Unplanned work added 28% to sprint (consistent with historical ~20-25% pattern)

**Trivial: #269 (Overflow fix)** — Estimated: 2 points → Actual: 0.07 days (0.04x)
- Simple padding/layout fix
- Lesson: Known-pattern bug fixes continue to be near-instant

#### Working Pattern Observations

```
Jan 30:  ████████████████████ #258 prep (refactoring extractions, skills, analysis)
Jan 31:  ████████████████ #258 (services, UX redesign analysis, more skills)
Feb 1:   ████████████████ #258 (Phase 2A UX redesign, Phase 2B visual polish)
Feb 2:   ████████████ #258 (finalize), #259 (recipe list polish)
Feb 3:   ██████████████████ #266 (shopping preview), #269 (overflow fix)
Feb 5:   ████████████████████ #267 (shopping refinement), #261 (forms), #260 (buttons)
Feb 6:   ███████████████ #262 (navigation + tests), release prep
```

**Patterns:**
- #258 dominated the first 4 days (Jan 30-Feb 2) — justified by its scope (refactoring + redesign + polish)
- Once #258 pattern established, subsequent screens/components were very fast
- Feb 3 and Feb 5 were highly productive batching days (3 issues each)
- Feb 4 was a rest day (no commits)
- Unplanned work (#266, #267, #269) interleaved naturally without disrupting planned work
- Release prep on final day (Feb 6)

#### Lessons Learned

1. **First-screen polish creates patterns; subsequent screens harvest them**
   - #258 (first screen): 3.27 days, 18717 lines, 17 commits — included refactoring 6 services/widgets + creating polish patterns
   - #259 (second screen): 0.42 days, 510 lines, 1 commit — applied established patterns
   - The 8x difference is not just estimation error — it reflects genuine compound returns from investing in the first screen properly
   - **Lesson: Budget 3-5x more for first-screen polish vs follow-up screens; the investment compounds**

2. **Component standardization benefits from design token foundation**
   - Three standardization issues (18 points estimated) done in 1.60 days
   - This speed was earned: 0.1.7a's token system made application mechanical
   - Batching #260 + #261 + #267 on a single day avoided context switching
   - Lesson: Estimate component standardization at 1-2 points per component type when tokens already exist

3. **Refactoring during polish pays compound dividends**
   - #258 extracted 6 services/widgets during polish work
   - This refactoring simplified the screen AND made subsequent work (#259, component standardization) easier
   - Lesson: Refactoring during polish is valuable — don't separate as distinct task

4. **UX feedback loop drives healthy emergent work**
   - #266 and #267 (shopping list preview/refinement) emerged as needed UX adjustments during the sprint
   - #269 (overflow fix) was discovered during #266 implementation
   - This isn't scope creep — it's a healthy product feedback cycle where using the app reveals needed improvements
   - Sprint absorbed 12 extra points without overrunning, showing capacity flexibility
   - Lesson: Budget 20-30% for emergent work; distinguish healthy UX feedback from scope creep

5. **Design system application is a distinct work type with its own velocity**
   - Combined 0.1.7a+0.1.7b: 64 points estimated, 7.0 weighted days actual (0.11x ratio)
   - The ratio reflects both conservative estimates (new work type, no prior data) AND genuine efficiency:
     - Clear design vision eliminated iteration
     - Design tokens made application mechanical
     - Batching similar work minimized context switching
     - Zero-gap milestone transition preserved momentum
   - **Lesson: Design system sprints need their own estimation calibration — use 0.2-0.3x multiplier**

6. **Workflow skill creation during sprints is compound investment**
   - Issue analysis and senior dev implementation skills created during #258
   - Not captured as separate issues but improved workflow for all subsequent work
   - Lesson: Tool/skill creation is investment, not waste — track but don't over-estimate

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| First screen creates patterns, subsequent harvest | Budget 3-5 points for first screen, 1-2 for subsequent |
| Component standardization fast with tokens | Estimate 1-2 points per component type when tokens exist |
| Design system application has own velocity | Use 0.2-0.3x multiplier for design token application work |
| UX feedback loop adds ~25-30% | Budget 20-30% for healthy emergent improvements |
| Refactoring during polish compounds | Don't separate refactoring from polish — estimate together |
| Combined milestone velocity 9.1 pts/day | Outlier — reflects both overestimation AND genuine efficiency from compound patterns |

#### Notes

- Combined 0.1.7a+0.1.7b delivered 64 points in 7 active days (9.14 points/day)
- This velocity is an outlier for general planning but reflects genuine efficiency: clear design vision, compound pattern reuse, effective batching, and zero-gap milestone transition
- #258 was the sprint's anchor issue — 3.27 days, 17 commits, massive refactoring + polish
- 3 unplanned shopping list issues (#266, #267, #269) added mid-sprint
- Major infrastructure created: 2 new skills, 6 extracted services/widgets
- Sprint ended with clean release (v0.1.7) on Feb 6
- All component standardization benefits from design tokens established in 0.1.7a
- No hidden tooling overhead reported (contrast with 0.1.5's 29% overhead)

---

### 0.1.8 - UX Quick Fixes & Bug Fixes

**Sprint Duration:** February 9-12, 2026
**Calendar Days:** 4
**Active Working Days:** 3.5 (Feb 9-11 coding + Feb 12 release; Feb 11 partial rest)
**Planned Issues:** 10 (21 points)
**Completed Issues:** 12 (10 planned + 2 emergent flaky test fixes)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #274 | bug: units not localized | bug/i18n | 1 | 0.40 | 670 | 0.40x | ⚡ Faster |
| #282 | testing: modal bottom sheet infra | testing | 5 | 0.60 | 670 | 0.12x | ⚡ Very fast |
| #272 | ux: rename + fix title overflow | UX/i18n | 1 | 0.25 | 607 | 0.25x | ⚡ Faster |
| #273 | ux: edit recipe to popup menu | UX | 1 | 0.05 | 27 | 0.05x | ⚡ Very fast |
| #275 | ux: reduce ingredient card spacing | UX | 1 | 0.02 | 2 | 0.02x | ⚡ Trivial |
| #276 | ux: select/deselect toggle | UX | 2 | 0.10 | 65 | 0.05x | ⚡ Very fast |
| #278 | ux: simplify overview styling | UX | 1 | 0.03 | 14 | 0.03x | ⚡ Very fast |
| #284 | refactor: move ShoppingListService | arch | 1 | 0.35 | 1592 | 0.35x | ⚡ Faster |
| #270 | ux: week navigation overlap | UX | 3 | 0.20 | 204 | 0.07x | ⚡ Very fast |
| #286 | testing: meal history edit tests | testing | 5 | 0.35 | 846 | 0.07x | ⚡ Very fast |
| #289 | testing: flaky meal editing | testing | 2 | 0.50* | — | 0.25x | 📋 Emergent |
| #290 | testing: flaky recipe name | testing | 2 | 0.50* | — | 0.25x | 📋 Emergent |
| **TOTAL** | | | **25** | **3.35** | **4027** | **0.13x** | |

*\* #289/#290 include time building flaky test detection tooling (~0.5 day combined) that didn't yield actionable insights*

**Note:** #282, #284, #286 emerged from reviewing code-embedded TODOs. #289, #290 emerged from flaky test discovery during testing. Original plan was 21 points across 10 issues.

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| UX fixes | #270, #272, #273, #275, #276, #278 | 9 | 0.65 | 0.07x | ⚡ Extremely fast (small, focused tweaks) |
| Bug fix | #274 | 1 | 0.40 | 0.40x | ⚡ Faster (localization investigation) |
| Testing (infra) | #282 | 5 | 0.60 | 0.12x | ⚡ Very fast (extending patterns) |
| Testing (extend) | #286 | 5 | 0.35 | 0.07x | ⚡ Very fast (existing helpers) |
| Testing (flaky) | #289, #290 | 4 | 1.00 | 0.25x | ⚡ Faster (but tooling overhead) |
| Architecture | #284 | 1 | 0.35 | 0.35x | ⚡ Faster (mechanical move) |

**Overall:** Actual effort was 13% of estimated (0.13x ratio). This reflects a sprint dominated by small, well-understood UX tweaks where the 1-point floor on the Fibonacci scale still overestimates 5-minute fixes, combined with testing work that extended established patterns.

#### Variance Analysis

**Extremely Fast: UX Fixes (#270, #272, #273, #275, #276, #278)** — Estimated: 9 points → Actual: 0.65 days (0.07x)
- Six issues completed in a single focused session on Feb 10
- Most were CSS-level tweaks: #275 was 2 lines, #278 was 14 lines, #273 was 27 lines
- Batching effect + deep focus time drove exceptional throughput
- The 1-point floor problem: scale can't distinguish a 5-minute tweak from a 2-hour fix
- Lesson: Small UX fix sprints will always show inflated velocity in story points

**Very Fast: Testing (#282, #286)** — Estimated: 10 points → Actual: 0.95 days (0.10x)
- #282 (modal bottom sheet infra, 5 pts): Testing patterns from previous sprints made this fast
- #286 (meal history edit tests, 5 pts): Extending existing test helpers was mechanical
- Lesson: Testing work extending patterns continues to be 0.07-0.12x — consistent with 0.1.3, 0.1.4

**Overhead Without Payoff: Flaky Tests (#289, #290)** — Estimated: 4 points → Actual: ~1.0 days (0.25x)
- Built multi-cycle integration test runner tool
- Invested ~0.5 days in tooling that didn't produce actionable insights
- Root cause appears to be adb instability, not app/test issues
- Lesson: Time-box diagnostic tooling; if no signal after 2 hours, document and move on

**Mechanical: #284 (Move ShoppingListService)** — Estimated: 1 point → Actual: 0.35 days (0.35x)
- 1592 lines but mostly file moves and import updates
- Ratio looks high for a 1-point issue but absolute effort was still under half a day
- Lesson: Large refactors measured in lines don't correlate with effort when mechanical

#### Working Pattern Observations

```
Feb 7-8:  ░░░░░░░░░░  Planning, issue review, TODO audit
Feb 9:    ████████░░  #274 (bug), #282 (test infra), chores
Feb 10:   ██████████  #272, #273, #275, #276, #278, #284 — 6 issues (deep focus)
Feb 11:   ████░░░░░░  #270, #286 (partial rest day)
Feb 12:   ██████░░░░  #289, #290, flaky test tooling, release, AS debugging
```

**Patterns:**
- Feb 10 was the sprint's peak — 6 issues in one focused session, all simple UX fixes + 1 mechanical refactor
- Batching similar UX work on a single day eliminated context switching
- Feb 11 partial rest still delivered 2 issues (sustainable pace)
- Feb 12 mixed release work with diagnostic tooling investigation
- Android Studio config debugging consumed time without resolution — switched to VS Code

#### Untracked Overhead
- **Android Studio debugging**: ~0.25 days investigating Dart/Flutter debug config losing module references. No fix — switched to VS Code.
- **Flaky test detection tooling**: ~0.3 days beyond issue fixes. Created test runner tool but adb instability was root cause.
- **Planning/TODO review**: ~0.25 days (Feb 7-8). Surfaced #282, #284, #286.

#### Lessons Learned

1. **Small UX fix sprints inflate story point velocity**
   - 6 UX issues (9 points) completed in ~0.65 days (0.07x ratio)
   - The Fibonacci 1-point floor can't distinguish 5-minute tweaks from 2-hour fixes
   - For planning: a sprint of 10+ small fixes will always look like extreme velocity
   - **Lesson: Don't recalibrate velocity based on UX-fix-heavy sprints**

2. **Batching small issues + deep focus = exceptional throughput**
   - Feb 10: 6 issues closed in one session with no context switching
   - All issues were similar type (UX layer), similar scope (small), same codebase area
   - Replicable when: issues are pre-triaged, similar type, developer has uninterrupted time
   - **Lesson: Group similar small issues for batch days; protect focus time**

3. **TODO audit as sprint planning input is valuable**
   - Reviewing code-embedded TODOs surfaced 3 useful issues (#282, #284, #286)
   - These were genuine quality improvements, not busywork
   - **Lesson: Periodic TODO audits are a healthy source of tech debt/testing issues**

4. **Time-box diagnostic tooling investment**
   - Flaky test detection tool consumed ~0.5 days without actionable insights
   - Root cause (adb instability) was outside app/test scope
   - The tooling may pay off later, but for this sprint it was overhead
   - **Lesson: Set 2-hour time-box for diagnostic investigations; if no signal, document and defer**

5. **Testing pattern reuse continues to compound**
   - #282 (5 pts, 0.12x) and #286 (5 pts, 0.07x) — both leveraged existing test helpers
   - Consistent with 0.1.3 (0.38x), 0.1.4 (0.19x) testing velocity
   - The testing infrastructure investments from earlier sprints keep paying dividends
   - **Lesson: Testing extending patterns remains at 0.07-0.12x — estimate accordingly**

6. **Android Studio friction is a recurring theme**
   - Config issues wasted ~0.25 days this sprint (similar to 0.1.5's tooling overhead)
   - VS Code as fallback worked, but debug experience differs
   - **Lesson: Accept VS Code as primary debug tool; don't invest more time in AS config**

7. **Week navigation (#270) validated as highest-value UX delivery**
   - Developer/stakeholder identified this as the sprint's user-facing highlight
   - 3 points, 3 commits, 204 lines — moderate effort, high perceived value
   - **Lesson: Small UX improvements can have outsized user impact; prioritize accordingly**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Small UX fixes are sub-1-point actual effort | Keep 1-pt floor but expect inflated velocity for UX-fix sprints |
| Batching similar issues on focus days | Deliberately group similar small issues for batch sessions |
| TODO audits surface quality issues | Include periodic TODO audit in sprint planning |
| Diagnostic tooling needs time-boxing | Set 2-hour cap on investigations without signal |
| Testing pattern reuse at 0.07-0.12x | Estimate testing-extension work at 0.1-0.2x |
| Android Studio friction recurring | Default to VS Code for debug; track AS issues separately |
| Cruising velocity established at 20 pts/week | Use as primary planning metric going forward |

#### Notes

- Sprint delivered 25 points in 3.5 effective working days (~36 pts/week velocity)
- Above cruising velocity (20 pts/week) due to sprint profile: dominated by small UX fixes and pattern-extension testing
- 5 of 12 issues (40%) were unplanned — absorbed easily due to sprint profile
- Flaky test detection infrastructure created on Feb 12 — may prove valuable for future test stability work
- Week navigation fix (#270) was highest user-perceived-value delivery
- **Cruising velocity established: 20 points/week** — based on analysis of sprints 0.1.3 through 0.1.8
- Android Studio config remains unresolved — VS Code is effective workaround

---

## Cumulative Metrics

### Estimation Accuracy Trend

| Sprint | Planned Points | Weighted Actual | Ratio | Points/Day | Trend |
|--------|----------------|-----------------|-------|------------|-------|
| 0.1.2 | 12.2 | ~11 | 0.90x | 1.11 | Baseline (slightly conservative, mixed work) |
| 0.1.3 | 26 | 10.0 | 0.38x | 2.60 | VERY conservative (pattern reuse) |
| 0.1.4 | 12 | 2.0 | 0.17x | 6.00 | **OUTLIER** - Extremely well-prepared work |
| 0.1.5 | 14 | 6.88 | 1.98x | 2.03 | OVERRAN - Discovery work + MASSIVE hidden overhead |
| 0.1.6 | 18 | 6.0 | 0.33x | 3.00 | VERY conservative (well-specified features) |
| 0.1.7a | 21 | 0.31 | 0.01x | 67.7* | **OUTLIER** - Foundation work, single day, overlapped with 0.1.7b |
| 0.1.7b | 43 | 6.69 | 0.16x | 6.43* | **OUTLIER** - Design system application + efficient batching |
| 0.1.8 | 25 | 3.35 | 0.13x | 7.14* | **UX-fix-heavy** - Small issues inflate velocity |

*\* 0.1.7a/b and 0.1.8 velocity reflects sprint profiles that inflate points/day (design system, small UX fixes). Not representative of general-purpose velocity.*

**Critical Insights:**
- **Cruising velocity: 20 points/week** — established from analysis of sprints 0.1.3 through 0.1.8, accounting for both discovery and execution modes
- **Sprint ratio depends heavily on work type** - Can't use one sprint to predict another
- **Bimodal velocity pattern**: "Discovery mode" (~14 pts/week) vs "Execution mode" (~32 pts/week); cruising velocity (20 pts/week) is the sustainable midpoint
- **0.1.4, 0.1.7a, 0.1.7b, 0.1.8 are velocity outliers** — each for different reasons (well-prepared, design system, small UX fixes)
- **Hidden overhead is CRITICAL** - Tooling/environment issues added 29% to 0.1.5 (2 full days)
- **Well-specified features are fast** - 0.1.6 showed 0.33x ratio with detailed specs
- **First-screen polish vs follow-up is 8x difference** - The first screen investment creates patterns that compound
- **Healthy UX feedback loops add ~25-30% emergent work** — budget for this, it's a feature not a bug
- **Small UX fixes inflate velocity** — 0.1.8's 0.13x ratio driven by 1-point floor problem; don't recalibrate based on these sprints

### Type-Based Calibration Factors

Use these multipliers when estimating future work:

| Type | Sample Size | Avg Ratio | Recommended Multiplier | Notes |
|------|-------------|-----------|------------------------|-------|
| Bug fixes (new patterns) | 2 issues | 0.62x | 0.5-1.0x | Conservative (0.1.2) |
| Bug fixes (known patterns) | 3 issues | 0.04x | 0.1-0.2x | Trivial when pattern established (0.1.4, 0.1.7b) |
| Bug fixes (related/batched) | - | 0.00x | 0.0x | Near-zero marginal cost for similar fixes (0.1.4: #252) |
| UI/Features | 5 issues | 0.56x | 0.6-0.7x | Very conservative (0.1.2: 0.84x, 0.1.3: 0.40x) |
| Parser/Algorithm | 2 issues | 0.21x | 0.5x | Very efficient (0.1.2) |
| Architecture (unprepared) | 5 issues | 0.40x | 0.5x | Very efficient when batched (0.1.3) |
| Architecture (well-prepared) | 1 issue | 0.25x | 0.2-0.3x | Extremely fast with prerequisites (0.1.4: #237) |
| Testing (existing patterns) | 3 issues | 0.62x | 1.0x | Conservative (0.1.2) |
| Testing (extend patterns) | 1 issue | 0.19x | 0.2x | Very fast copy-paste work (0.1.4: #244) |
| Testing (new infra) | 5 issues | 1.27x | 1.0-1.5x | **REVISED**: 0.1.2 was outlier (4.00x), 0.1.3 averaged 0.51x |
| Testing (related tasks) | 2 issues | 0.31x | 0.3-0.5x | Extremely efficient when done together (0.1.3: #38+#39) |
| Design foundation | 3 issues | 0.01x | 0.1-0.2x | **NEW**: Linked design tasks complete as single unit (0.1.7a) |
| Screen polish (first) | 1 issue | 0.41x | 0.4-0.5x | **NEW**: Includes refactoring + pattern creation (0.1.7b: #258) |
| Screen polish (subsequent) | 1 issue | 0.08x | 0.1-0.2x | **NEW**: Applying established patterns is 5-8x faster (0.1.7b: #259) |
| Component standardization | 3 issues | 0.09x | 0.1-0.2x | **NEW**: Mechanical once design tokens exist (0.1.7b: #260-#262) |
| Small UX fixes (batched) | 6 issues | 0.07x | 0.05-0.1x | **NEW**: 1-point floor inflates; batch for efficiency (0.1.8: #272-#278) |
| Flaky test investigation | 2 issues | 0.25x | 0.2-0.3x | **NEW**: Time-box at 2 hours; root cause often external (0.1.8: #289-#290) |

**Key Insights from 0.1.7a/b:**
- **Design system work has its own velocity profile** — 64 points in 7 days (0.11x) reflects both new-type overestimation AND genuine efficiency from clear vision, compound patterns, and effective batching
- **First-screen polish creates compound returns** — #258 (0.41x) invested in patterns that #259 (0.08x) harvested; the 8x difference is earned velocity
- **Component standardization is fast when tokens exist** — 18 points in 1.60 days; the speed was earned by 0.1.7a's foundation
- **Linked design tasks should be estimated as one** — #255+#256 were literally one commit
- **UX feedback loop is healthy and predictable** — 3 emergent issues (#266, #267, #269) added 12 points (~28%); budget 20-30% for this

**Key Insights from 0.1.8:**
- **Small UX fixes at Fibonacci floor inflate velocity** — 9 points in 0.65 days (0.07x); the scale can't distinguish 5-min tweaks from 2-hour fixes
- **Batching + deep focus is multiplicative** — 6 issues in one session on Feb 10; pre-triage similar issues for batch days
- **Testing pattern reuse keeps compounding** — #282 (0.12x) and #286 (0.07x) consistent with historical 0.07-0.19x range
- **TODO audits are healthy sprint planning input** — surfaced 3 quality issues (#282, #284, #286)
- **Time-box diagnostic tooling** — flaky test runner consumed 0.5 days without signal; adb instability was root cause

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

| Sprint | Points | Days | Points/Day | Pts/Week | Work Type |
|--------|--------|------|------------|----------|-----------|
| 0.1.2 | 12.2 | 11 | 1.11 | 5.5 | Mixed (features, bugs, testing) |
| 0.1.3 | 26 | 10 | 2.60 | 13.0 | Well-prepared (pattern reuse) |
| 0.1.4 | 12 | 2 | 6.00 | 30.0* | **OUTLIER** (extremely well-prepared) |
| 0.1.5 | 14 | 6.88 | 2.03 | 10.2 | Discovery + iteration + MASSIVE overhead (29%) |
| 0.1.6 | 18 | 6 | 3.00 | 15.0 | Well-specified features |
| 0.1.7a | 21 | 0.31 | 67.7* | —* | **OUTLIER** (design foundation, shared day) |
| 0.1.7b | 43 | 6.69 | 6.43* | 32.1* | **OUTLIER** (design system application) |
| 0.1.8 | 25 | 3.5 | 7.14* | 35.7* | **UX-fix-heavy** (small issues inflate velocity) |

*\* Outlier sprints — velocity inflated by sprint profile (well-prepared, design system, small UX fixes). Not representative of general-purpose velocity.*

**Cruising Velocity: 20 points/week** — established from analysis of sprints 0.1.3 through 0.1.8, validated by developer as sustainable midpoint between discovery and execution modes.

**Velocity Modes:**
- **Discovery mode:** ~14 pts/week (new patterns, complex features, tooling overhead)
- **Cruising mode:** ~20 pts/week (mixed work, sustainable pace)
- **Execution mode:** ~32 pts/week (small fixes, pattern reuse, deep focus)

### Milestone Sizing Recommendations

**Primary metric: 20 points/week cruising velocity**

| Sprint Length | Conservative | Cruising | Aggressive |
|---------------|:-----------:|:--------:|:----------:|
| 1 week (5 days) | 15 pts | 20 pts | 30 pts |
| 2 weeks (10 days) | 30 pts | 40 pts | 55 pts |

### Adjustment Factors

**Use Aggressive (~30 pts/week) if:**
- All work is well-prepared with prerequisites completed
- Issues are similar and can be batched
- Extending existing patterns (not creating new ones)
- Sprint dominated by small fixes or mechanical work

**Use Conservative (~15 pts/week) if:**
- Work involves discovery or research
- New infrastructure or patterns needed
- UI polish requiring iteration and feedback
- External service integrations
- Mobile/UI work with potential tooling issues

**Critical Rules:**
1. **Use 20 pts/week as default** for milestone sizing
2. **Adjust by sprint profile** — discovery (15), cruising (20), execution (30)
3. **Add 25-35% overhead buffer** for mobile/UI sprints with testing phases
4. **Budget 20-30% for emergent work** — healthy UX feedback and TODO cleanup
5. **Review velocity after each sprint** - don't assume it's constant
6. **Don't recalibrate based on UX-fix-heavy sprints** — 1-point floor inflates velocity

### Examples

**Standard Milestone (1 week, 20 points):**
- 2x M-sized features (5 points each) = 10 points
- 2x S-sized features (3 points each) = 6 points
- 2x bug fixes (2 points each) = 4 points
- At cruising velocity: 20 pts / 1 week ✅

**Discovery-Heavy Milestone (1 week, 15 points):**
- 1x L-sized feature with discovery (8 points)
- 1x M-sized testing infra (5 points)
- 1x S-sized bug fix (2 points)
- At conservative velocity: 15 pts / 1 week ✅

**Execution Sprint (1 week, 30 points):**
- 10x small UX fixes (1-2 points each) = 15 points
- 3x testing extensions (5 points each) = 15 points
- At aggressive velocity: 30 pts / 1 week ✅ (only if pure execution)

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
- **2026-01-29**: Added 0.1.6 retrospective analysis
  - Sprint completed: 5 planned + 1 unplanned issue (6 total) in 7 calendar days (6 active, 86% utilization)
  - Actual ratio: 0.33x (VERY conservative - back to fast execution pattern)
  - Completed: 18 out of 20 planned points (90% completion, #242 deferred)
  - Velocity: 3.00 points/day (highest sustainable velocity to date)
  - Key insight: Detailed feature specifications enable fast execution (0.25x for 8-point feature)
  - Major feature (#5 Shopping List) completed in 2 days with comprehensive testing (26 commits)
  - MVP scope clarity prevented over-engineering (#32, #33: 0.19x-0.20x ratios)
  - Unplanned work (#264) added ~24% to sprint, consistent with previous sprints
  - Lesson: Well-specified features with clear MVP boundaries execute 3-4x faster than estimated
  - Updated normal velocity range to 1.1-3.0 points/day (adding 0.1.6 data)
  - Estimation philosophy: Keep 1-point minimum for task overhead; scale UP larger estimates rather than introducing sub-point complexity
- **2026-02-08**: Added 0.1.7a and 0.1.7b retrospective analyses
  - 0.1.7a completed: 3 issues in 1 day (21 points estimated, 0.31 weighted days actual, 0.01x ratio)
  - Foundation issues were massively overestimated — #255+#256 completed in single commit
  - 0.1.7b completed: 5 planned + 3 unplanned issues (43 points) in 7 active days (6.69 weighted days, 0.16x ratio)
  - #258 was the anchor issue (3.27 days, 17 commits, major refactoring + polish)
  - 3 unplanned shopping list issues (#266, #267, #269) added 12 points (~28% unplanned work)
  - **KEY: Design system work has its own velocity profile** — combined 64 pts in 7 days (0.11x), driven by both overestimation AND genuine efficiency
  - New calibration factors: design foundation (0.01x), first-screen polish (0.41x), subsequent-screen polish (0.08x), component standardization (0.09x)
  - First-screen polish is 8x more expensive than follow-up screens
  - Both sprints classified as outliers for velocity purposes — don't use for future estimates
  - Updated velocity reference data and type-based calibration factors
- **2026-02-13**: Added 0.1.8 retrospective analysis
  - Sprint completed: 10 planned + 2 emergent issues (12 total) in 3.5 effective days
  - Actual ratio: 0.13x (UX-fix-heavy sprint inflates velocity)
  - 25 points delivered at ~36 pts/week (above cruising due to sprint profile)
  - **KEY: Cruising velocity established at 20 points/week** — based on full sprint history analysis (0.1.3-0.1.8)
  - Bimodal velocity: discovery mode (~14 pts/week) vs execution mode (~32 pts/week)
  - New calibration factors: small UX fixes batched (0.07x), flaky test investigation (0.25x)
  - Lessons: 1-point floor inflates velocity for UX-fix sprints; batch similar issues for focus days; TODO audits are valuable planning input; time-box diagnostic tooling at 2 hours
  - Revised Milestone Sizing Guidelines to use 20 pts/week as primary planning metric
  - Updated velocity reference data with pts/week column
