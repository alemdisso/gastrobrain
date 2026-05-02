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

### 0.1.9 - Meal Planning UX Redesign

**Sprint Duration:** February 14-15, 2026
**Calendar Days:** 2
**Active Working Days:** 2 (longer-than-average hours + ~1hr emulator testing)
**Planned Issues:** 3 (18 points)
**Completed Issues:** 3 planned + 2 closed as byproducts (#277 absorbed, #288 won't do)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #279 | Color system for meal planning | UX redesign | 5 | 0.42 | 298 | 0.37x | ⚡ Faster |
| #271 | Meal slot component redesign | UX redesign | 5 | 0.10 | 227 | 0.09x | ⚡ Very fast |
| #280 | Shopping list flow redesign | UX redesign | 8 | 0.89 | 3,371 | 0.49x | ⚡ Faster |
| #277 | Full-screen dialogs | UX | (5) | 0 | — | — | Absorbed by #280 |
| #288 | Tabs testability/UX | UX/testing | (3) | 0 | — | — | Closed (won't do) |
| **TOTAL** | | | **18** | **1.41** | **3,896** | **0.34x** | ⚡ |

*#277 was absorbed into #280's scope (full-screen conversion was trivial in context of the redesign). #288 was closed as the tabs approach was scrapped entirely by #280.*

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| UX redesign (simplification) | #279, #271, #280 | 18 | 1.41 | 0.34x | ⚡ Fast — well-defined problems, net code deletion |

#### Variance Analysis

**Fastest: #271 (Meal slot redesign, 0.09x)** — Estimated: 5 points → Actual: 0.10 days
- Single file changed: 76 insertions, 151 deletions (net -75 lines)
- This was simplification, not creation — removing visual clutter, tightening hierarchy
- Color system (#279) established the visual language beforehand, reducing decisions
- Lesson: Simplification tasks that reduce code are faster than additive tasks at the same point estimate

**On profile: #279 (Color system, 0.37x)** — Estimated: 5 points → Actual: 0.42 days
- Design + implementation same day — clear vision, no iteration needed
- 5 files, 256 insertions, 42 deletions — clean replacement of old color approach
- Shared Feb 14 with 0.1.8 retro and WSL doc cleanup
- Lesson: When UX vision is clear pre-implementation, design+code same-day is viable

**Largest but still fast: #280 (Shopping list flow, 0.49x)** — Estimated: 8 points → Actual: 0.89 days
- Massive redesign: 17 files, +1104/-2055 (net -951 lines)
- Absorbed #277's full-screen conversion with minimal extra effort
- 4 UX bugs discovered during emulator testing and fixed same day
- Lesson: Redesigns that simplify architecture are faster than expected because deletion is faster than creation

**Byproducts: #277 and #288** — Zero separate effort
- #277 (5 pts separate) was trivial in context of #280's full redesign
- #288 (3 pts) became irrelevant — the entire tabs approach was eliminated
- Lesson: Linked issues estimated separately will overstate total effort; the redesign made both free

#### Working Pattern Observations

```
Feb 14: ████░░░░  #279 color system (0.42 days) + 0.1.8 retro + WSL cleanup
Feb 15: █░░░░░░░  #271 meal slot (0.10 days — quick simplification)
        ████████  #280 shopping list redesign + 4 bug fixes (0.89 days)
        ██░░░░░░  roadmap docs, version bump, release
```

**Patterns:**
- Foundational work first (#279 color system) → dependent work next day (#271, #280)
- #271 was so fast it was essentially a warm-up before the main #280 work
- Implementation → emulator testing → bug fixes in a single session for #280
- Longer-than-average hours on both days compressed calendar time

#### Lessons Learned

1. **Simplification sprints have their own velocity profile**
   - All 3 issues were redesigns that *removed* complexity (net -1,026 lines across the sprint)
   - Deletion is faster than creation: you're removing decisions, not making new ones
   - 0.34x ratio is consistent with design-system work (0.1.7b: 0.16x) but for different reasons
   - **Lesson: Estimate UX simplification/redesign at 0.3-0.5x of standard UX creation work**

2. **Well-defined UX vision eliminates discovery overhead**
   - Design and implementation happened same-day for all issues
   - No iteration cycles, no stakeholder feedback loops, no design exploration
   - The developer knew exactly what they wanted before writing code
   - **Lesson: Clear pre-implementation vision is the strongest velocity accelerator**

3. **Thematic coherence avoids context switching**
   - All 3 issues touched the meal planning screen ecosystem
   - Shared mental model, shared color system, shared design language
   - Sequencing was natural: color system (#279) → components (#271) → flow (#280)
   - **Lesson: Mono-theme sprints with natural sequencing execute faster than mixed sprints**

4. **Linked issues estimated separately overstate total work**
   - #277 (5 pts) + #280 (8 pts) were estimated as 13 points of separate work
   - In practice, #277 was absorbed into #280 at near-zero marginal cost
   - #288 (3 pts) became irrelevant when the approach was redesigned away
   - **Lesson: When issues overlap significantly, estimate the umbrella issue only; close sub-issues as absorbed**

5. **Net code deletion is a signal for simplification velocity**
   - Sprint deleted 1,026 more lines than it added
   - This is a leading indicator that work will be faster than estimated
   - Contrast with feature sprints where line counts grow
   - **Lesson: If a redesign is expected to reduce code, apply 0.3-0.5x multiplier to estimate**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| UX simplification executes at 0.3-0.5x | New calibration factor: "UX redesign (simplification)" |
| Clear UX vision eliminates discovery | Pre-design UX changes before sprint starts when possible |
| Mono-theme sprints are faster | Group related UX issues in same sprint for natural sequencing |
| Linked issues overstate total work | Estimate umbrella issue; don't sum overlapping sub-issues |
| Net code deletion signals fast execution | Use as planning heuristic: deletion-heavy = apply 0.3-0.5x |
| Velocity step-change confirmed | Cruising velocity revised upward to 30 pts/week (from 20) |

#### Notes

- Sprint delivered 18 points in 2 active days (~9 pts/day, ~36 pts/week effective velocity)
- Consistent with 0.1.7b (32 pts/week) and 0.1.8 (36 pts/week) — confirms velocity step-change, not outlier pattern
- Three consecutive sprints at 32-36 pts/week indicates sustained acceleration from codebase maturity, Claude Code, and accumulated infrastructure
- #277 and #288 were closed as byproducts, adding 0 overhead but cleaning up the backlog
- Emulator testing (~1 hr) caught 4 UX bugs fixed same-day — healthy implementation-test-fix cycle
- Feb 13 was spent on CI/flaky test infrastructure (not 0.1.9 work)

---

### 0.1.10 - Landing Page & Polish

**Sprint Duration:** February 16–18, 2026
**Calendar Days:** 3
**Active Working Days:** 2 (Feb 17–18; Feb 16 was planning + 0.1.9 retro)
**Planned Issues:** 4 (13 points; 19 additional points scoped but deferred)
**Completed Issues:** 4 planned

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|------------|
| #134 | Landing page MVP | New feature | 5 | 1.00 | 0.20x | ⚡ Faster |
| #149 | Unit pluralization | UI enhancement | 3 | 0.40 | 0.13x | ⚡ Faster |
| #293 | Shopping list unit conversions | Enhancement | 3 | 0.40 | 0.13x | ⚡ Faster |
| #294 | Category select/deselect | UX | 2 | 0.20 | 0.10x | ⚡ Faster |
| **TOTAL** | | | **13** | **2.00** | **0.15x** | ⚡ |

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| New feature | #134 | 5 | 1.00 | 0.20x | ⚡ Fast — clear MVP scope, well-defined requirements |
| UI/enhancement (batched) | #149, #293, #294 | 8 | 1.00 | 0.13x | ⚡ Fast — same-domain batch, established patterns |

#### Variance Analysis

**Fastest: #294 (Category select, 0.10x)** — Estimated: 2 points → Actual: ~0.20 days
- Small UX addition in the shopping list refinement screen
- Context already warm from adjacent #149 and #293 work
- Lesson: Last issue in a same-domain batch benefits from fully warmed context

**Consistent: #134 (Landing page, 0.20x)** — Estimated: 5 points → Actual: ~1.00 day
- Largest issue, given its own uninterrupted day (Feb 17)
- Well-defined MVP scope: dashboard with quick actions and recent activity
- No discovery overhead — clear acceptance criteria established on planning day
- Lesson: A single focused day for the anchor feature avoids context fragmentation

**Batch day: #149 + #293 + #294 (8 pts, 0.13x avg)** — all three completed Feb 18
- All touch the ingredient/shopping list display layer — shared mental model
- Sequential execution with no context switching
- Combined scope was clear from the planning day
- Lesson: Same-domain batching on one day multiplies efficiency

#### Working Pattern Observations

```
Feb 16: ░░░░░░░░  Planning day — 0.1.9 retro + 0.1.10 scope decisions (no commits)
Feb 17: ████████  #134 landing page (1.0 day)
Feb 18: ████████  #149 unit pluralization + #293 unit conversions + #294 category select (1.0 day)
```

**Patterns:**
- Planning day (Feb 16) structured the sprint so execution days were unambiguous
- Two clean execution days with no context switching or scope exploration
- 19 additional points (#292, #263, #268, #285) deliberately deferred — scope discipline enabled clean execution

#### Lessons Learned

1. **Pre-sprint scope decisions eliminate execution overhead**
   - Feb 16 was a dedicated planning day: zero commits, maximum value
   - All four issues had clear acceptance criteria and sequencing before day 1
   - No mid-sprint scope questions — full flow from the first commit
   - **Lesson: A planning day before execution pays for itself within the first hour of day 1**

2. **Scope discipline is a velocity multiplier**
   - Original milestone had 32 points; 13 were selected, 19 deliberately deferred
   - Delivering 13 well-chosen points in 2 days beats delivering 32 points in 10+ days
   - Deferred issues were technical/docs (#292, #263, #268, #285) — not user-facing
   - **Lesson: Scope discipline isn't underdelivering; it's optimizing for execution clarity**

3. **Anchor issue alone on Day 1 prevents fragmentation**
   - #134 (5 pts) occupied all of Feb 17 — no parallel issues, no context switches
   - Full-day focus enabled design → implementation → test in one session
   - **Lesson: Give the sprint's anchor feature its own uninterrupted day**

4. **Same-domain batch day compounds efficiency**
   - Three issues (#149, #293, #294) share the shopping list/ingredient display layer
   - Mental model stays fully warm; each issue builds directly on the previous
   - Combined 8 pts in ~1 day (0.13x average)
   - **Lesson: Group same-domain issues on the same day — 0.10-0.13x is achievable**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Planning day investment pays off in execution clarity | Reserve first day of sprint cycle for scope decisions, not code |
| Scope discipline (select 13 of 32 pts) enables 0.15x ratio | Prefer smaller well-chosen scope over comprehensive scope |
| Anchor issue benefits from solo day | Schedule sprint's largest issue on its own uninterrupted day |
| Same-domain batch day executes at 0.10-0.13x | Group thematically related issues for maximum batch efficiency |

#### Notes

- Sprint delivered 13 points in 2 active days (~6.5 pts/day, ~32 pts/week)
- Consistent with recent cruising velocity of ~30 pts/week
- 19 deferred points (#292, #263, #268, #285) moved to backlog — correctly scoped out as non-essential for user-facing sprint goal
- Feb 16 planning investment produced zero commits but was critical for Feb 17–18 execution clarity

---

### 0.1.11 - Shopping List Corrections

**Sprint Duration:** February 19–25, 2026
**Calendar Days:** 7
**Active Working Days:** 3 (Feb 21, 24, 25; Feb 19–20 were app usage + issue discovery days)
**Planned Issues:** 6 (14 points)
**Completed Issues:** 6 planned + ~4 unplanned (new categories, status bar fix, idempotent migrations, e2e stability)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|------------|
| #302 | Simplify filter chips | UX fix | 2 | 0.40 | 0.20x | ⚡ Faster |
| #297 | Remove toTaste alert icon | UX fix | 1 | 0.30 | 0.30x | ⚡ Faster |
| #299 | Hide past-week shopping FAB | UX fix | 1 | 0.30 | 0.30x | ⚡ Faster |
| #298 | Fix Android nav bar overlap | Bug fix | 2 | 0.20 | 0.10x | ⚡ Faster |
| #300 | Cooked meals in shopping list | Bug fix | 3 | 0.30 | 0.10x | ⚡ Faster |
| #301 | Stale banner on meal cook | Bug fix | 5 | 0.50 | 0.10x | ⚡ Faster |
| *Unplanned* | Categories, migrations, e2e, status bar | Various | — | ~0.50 | — | 📋 Unplanned |
| **TOTAL (planned)** | | | **14** | **2.50** | **0.18x** | ⚡ |

#### Accuracy by Type (Weighted)

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| UX fixes (small) | #302, #297, #299 | 4 | 1.00 | 0.25x | ⚡ Fast — small UI changes, established patterns |
| Bug fixes (post-usage) | #298, #300, #301 | 10 | 1.00 | 0.10x | ⚡ Very fast — root causes clear from usage testing |
| Unplanned | categories, migrations, e2e | ~6 | ~0.50 | — | 📋 Real-life QA overflow |

#### Variance Analysis

**Fastest class: #298, #300, #301 (logic/observer bugs, 0.10x each)** — combined 10 pts in ~1 day
- All three bugs discovered during Feb 19–20 intensive app usage
- Root cause was already known before opening the editor — no debugging phase
- Fix paths were direct: logic gate for cooked meals, observer notification for stale banner, edge padding for nav bar
- Lesson: Bugs caught by real usage have the clearest root causes — no reproduction guesswork

**Unplanned work absorbed cleanly** — ~0.5 days for ~6 pts of untracked work
- New categories (Herb, Pickles/Fermented): trivial enum + l10n additions
- Status bar overlap: single-line layout fix
- Idempotent migrations: correctness fix surfaced by e2e tests (#134 nav restructuring spillover)
- e2e stability: `tapSaveButton` scroll reliability + tab navigation tests updated for #134 nav
- All surfaced naturally from testing/usage — not scope creep

#### Working Pattern Observations

```
Feb 19–20: ░░░░░░░░  App usage + issue triage (no commits — discovery investment)
Feb 21:    ████████  #302 filter chips + #297 alert icon + #299 past-week FAB (1.0 day)
Feb 22–23: ░░░░░░░░  Weekend
Feb 24:    ████████  #298 nav bar + #300 cooked meals + #301 stale banner (1.0 day)
Feb 25:    ████░░░░  Idempotent migrations + e2e test stability + release (0.5 day)
```

**Patterns:**
- Discovery phase (Feb 19–20) front-loaded all issue identification — execution days had zero scope uncertainty
- Two clean batch days: UX fixes (Feb 21) and logic bugs (Feb 24), both at ~1 day each
- Feb 25 was a testing/stability cleanup day — unplanned but necessary before release
- The "use app → discover → batch fix" cycle executed efficiently and cleanly

#### Lessons Learned

1. **The "Real-life QA sprint" is a distinct and valuable sprint type**
   - Pattern: intensive personal app usage (2 days) → issue discovery → batch fix execution
   - Discovery phase looks like "wasted days" in commit data but produces the clearest issue specifications
   - When you discover a bug by hitting it yourself, root cause is already understood
   - **Lesson: Budget app usage days as productive sprint investment, not idle time**

2. **Real usage surfaces correctness bugs invisible to code review**
   - #300 (cooked meals in shopping list) and #301 (stale banner) required a complete meal planning → cooking → shopping workflow to discover
   - Both had immediate fix clarity because the usage context explained the exact failure mode
   - **Lesson: Scheduled "use the app" sessions are a form of integration testing — add to sprint planning**

3. **Post-usage bug fixes execute at 0.10x regardless of point estimate**
   - #300 (3 pts) + #301 (5 pts) + #298 (2 pts) = 10 pts in ~1 day
   - No exploratory debugging phase — straight to fix
   - The Fibonacci estimate reflects *potential* complexity, not *actual* complexity when root cause is known
   - **Lesson: Post-usage bugs → use 0.10x multiplier; batch them on a single day**

4. **Unplanned correctness work is a healthy post-release pattern**
   - ~6 pts of unplanned work absorbed with ~0.5 days overhead
   - Surfaced naturally from testing — not scope creep
   - Consistent with historical 20-30% unplanned budget
   - **Lesson: Always reserve 25-30% sprint capacity for post-release correctness overflow**

5. **Idempotent migrations belong in the definition of done**
   - e2e tests failing revealed non-idempotent migrations — a correctness issue, not a feature
   - Should have been caught before merging any migration
   - **Lesson: Migration idempotency is a baseline requirement; add to PR checklist**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Real-life QA sprint yields 0.15-0.25x ratio | Classify as "execution mode" sprint following a major UX/feature release |
| App usage days precede issue discovery | Schedule at least 1-2 usage days after each release before next sprint start |
| Post-usage bugs execute at 0.10x | Apply 0.10x multiplier to all bug sprint issues with known root cause |
| Unplanned correctness work ~30% | Maintain 25-30% buffer for post-release QA overflow |
| Idempotent migrations baseline | Add to migration definition of done; verify in e2e tests |

#### Notes

- Sprint delivered 14 planned + ~6 unplanned points in 3 active days (~6.3 pts/day, ~28 pts/week for planned work)
- Slightly below cruising velocity (30 pts/week) because Feb 25 was mixed: release + e2e debugging, not pure execution
- Feb 19–20 usage investment: zero commits but maximum issue clarity — essential setup for the fast execution days
- "Real-life QA sprint" pattern confirmed as a repeatable sprint type distinct from feature or refactor sprints
- Idempotent migrations spillover from #134 nav restructuring fully resolved; e2e suite now stable

---

### 0.1.12 - Servings & Quantity Tracking

**Sprint Duration:** February 27 – March 1, 2026
**Calendar Days:** 3 active + 1 hidden planning day (Feb 26)
**Effective Working Days:** 3.5d (2.65d implementation + 0.65d overhead)
**Planned Issues:** 7 (17 points)
**Completed Issues:** 7 planned (100%) + 1 unplanned commit (watchdog rules, trivial)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Lines | Weighted Actual | Ratio | Assessment |
|-------|-------|------|------------|-------|-----------------|-------|------------|
| #310 | Sort ingredient category dropdown | ui-micro | 1 | 24 | 0.05d | 0.05x | ⚡ Faster |
| #309 | Trim whitespace from search queries | ui-micro | 2 | 8 | 0.10d | 0.05x | ⚡ Faster |
| #304 | Add servings field to Recipe model | feat/model | 3 | 181 | 0.65d | 0.22x | ⚡ Faster |
| #308 | "To taste" toggle in AddIngredientDialog | feat | 2 | 551 | 0.40d | 0.20x | ⚡ Faster |
| #305 | Add planned servings to meal planning slot | feat | 3 | 390 | 0.60d | 0.20x | ⚡ ⚠️ |
| #306 | Scale ingredient quantities by planned servings | feat | 3 | 297 | 0.35d | 0.12x | ⚡ ⚠️ |
| #307 | Replace servings text field with stepper | ux | 3 | 1,386 | 0.50d | 0.17x | ⚡ Faster |
| *Overhead* | *Release, docs, watchdog rules* | — | — | — | 0.15d | — | 📋 |
| *Hidden* | *Feb 26 planning + device testing* | — | — | — | 0.50d | — | 📋 |
| **TOTAL (planned)** | | | **17** | | **2.65d** | **0.17x** | ⚡ |

⚠️ = Fast execution but device/UX validation deferred → follow-up issues #313, #314, #315

#### Accuracy by Type

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| feat/model — dependency chain | #304, #305, #306 | 9 | 1.60d | 0.18x | ⚡ Fast — but validation debt (see notes) |
| ux/feat — widget work | #307, #308 | 5 | 0.90d | 0.18x | ⚡ Fast — clean execution, no rework |
| ui-micro — one-liners | #309, #310 | 3 | 0.15d | 0.05x | ⚡ Very fast — one-liner territory regardless of estimate |

#### Variance Analysis

**The "fast but incomplete" problem (#304, #305, #306)**
- All three chain issues came in at 0.12-0.22x — but 3 follow-up issues (#313, #314, #315) emerged from deferred device testing and design thinking
- The ratio is partially artificial: some work was postponed, not eliminated
- Issues were well-specified for *code correctness* but under-specified for *real-world validation*
- Acceptance criteria covered implementation tasks, not device testing gates

**Clean execution (#307, #308)**
- #307 was the largest commit by lines (1,386) but a net simplification: 433 insertions, 797 deletions (−348 net)
- Replacing a TextFormField + controller with a reusable ServingsStepper widget reduced complexity
- e2e test break (`a1e110b`) was expected from the widget swap but wasn't pre-listed in the issue spec

**UI micro-issues at the 0.05x floor (#309, #310)**
- #309 (2pts): 8 lines total — `.trim()` calls across 4 files
- #310 (1pt): 24 lines — single sort call at build time
- Both took 15-30 minutes regardless of their Fibonacci estimates
- The 1pt floor is still too high; these should be bundled as a quick-wins block

#### Working Pattern Observations

```
Feb 26 │░░░░░░░░░░  Planning + device testing (0.5d hidden — no commits)
Feb 27 │▓▓▓▓▓▓▓░░░  #310 → #309 → #304  (afternoon burst, ~0.8d)
Feb 28 │▓▓▓▓▓▓▓▓░░  #308 → #305          (afternoon + evening, ~1.0d)
Mar 01 │▓▓▓▓▓▓▓▓▓▓  #306 → #307 → release (full day, ~1.0d)
```

Third sprint in a row following the "anchor + domain batch" structure:
- Day 0 (hidden): app testing + sprint planning — no commits but essential
- Day 1: trivial quick wins + foundation anchor (#310, #309, #304)
- Day 2: dependent UX features in domain order (#308, #305)
- Day 3: chain completion + release wrap-up (#306, #307, release)

#### Lessons Learned

1. **"100% completion" can mask validation debt**
   - All 17 points closed; 3 follow-up issues emerged from deferred device testing on the servings chain
   - Sprint completion rate ≠ feature completeness
   - Fast execution through a dependency chain is only a win if device validation is included

2. **Acceptance criteria need explicit device validation gates**
   - Issues with data-facing UX impact (quantity scaling, servings propagation) should require device testing as a non-optional AC item
   - If not listed in AC, device testing will be skipped under time pressure
   - **Add "✓ Tested on device" as required AC for any feature that changes data-facing behaviour**

3. **Predictable integration test breaks should be pre-listed in issue specs**
   - #307's widget swap was always going to break e2e tests referencing the old widget key (`meal_recording_servings_field`)
   - The `a1e110b` fix was expected but felt like unplanned work because it wasn't in the issue task list
   - **Pattern: for any UI widget replacement, add "update tests referencing `[old_key]`" as an explicit task**

4. **Diminishing complexity across dependency chains isn't modelled in estimates**
   - #304 at 3pts was correct: new model + DB migration + cascade to services and tests
   - #305 and #306 followed #304's established migration/model pattern; each was closer to 2pts in practice
   - **Future: when issues in a same-pattern chain, discount 2nd+ issues by 30–50% at estimation time**

5. **UI micro-issues cluster at ~0.05x regardless of estimate floor**
   - #309 (2pts, 8 lines) and #310 (1pt, 24 lines) both at 0.05x
   - Fibonacci scale can't express sub-30-minute work; individual estimation adds no precision
   - **Recommendation: bundle micro-issues as a "quick wins block" with a flat 0.5pt budget per set**

6. **Anchor + domain batch daily structure is a confirmed repeating pattern**
   - Day 0 (hidden) + Day 1 (anchor) + Day 2–3 (domain batch) has appeared in 0.1.10, 0.1.11, and 0.1.12
   - This is now the natural shape of a well-sequenced sprint — not accidental

7. **Pre-sprint planning/testing day is standard overhead**
   - Feb 26 (this sprint) and Feb 16 (0.1.10) were both zero-commit days used for app testing + planning
   - Should be budgeted as a standard 0.5d overhead, not treated as lost time or idle capacity

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Validation debt from servings chain | Add "✓ Tested on device" as required AC for data-facing features |
| Predictable test breaks from widget swaps | Pre-list old widget key test updates in issue task list |
| Diminishing complexity in dependency chains | Discount 2nd+ same-pattern chain issues by 30–50% at estimation time |
| UI micro-issues at 0.05x | Bundle as quick wins block, flat 0.5pt budget per set |
| Pre-sprint planning/testing day | Budget +0.5d standard overhead for planning + device validation |

#### Notes

- Sprint ran Feb 27 – Mar 1 (3 active commit days); Feb 26 was a zero-commit planning/testing day
- The servings chain (#304→#305→#306) is functionally complete but has known follow-up gaps: #313, #314, #315 capture the deferred device/UX validation work
- #307 (servings stepper) was the largest commit by lines (1,386) but a net simplification (−348 lines): replaced TextFormField + controller with a clean reusable `ServingsStepper` widget
- Cruising velocity (30 pts/week) confirmed for the 6th consecutive sprint (0.1.7b–0.1.12)

---

### 0.1.13 - Meal Planning & Shopping Enhancements

**Sprint Duration:** March 2–9, 2026
**Calendar Days:** 8
**Active Working Days:** ~4 (Mar 3, 6, 7, 8; Mar 2 = planning only; Mar 4–5 = rest; Mar 9 = release chores)
**Planned Issues:** 5 (21 points)
**Completed Issues:** 5 planned (100%)

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #314 | Display servings in recipe details | UI/display | 3 | 0.3d | 838 | 0.10x | ⚡ Faster |
| #313 | ServingsStepper in recipe forms | UI/enhancement | 5 | 0.7d | 855 | 0.14x | ⚡ Faster |
| #311 | Simple sides (ingredients as meal sides) | arch/feature | 8 | 1.0d | 1,902 | 0.13x | ⚡ Faster |
| #312 | Manual shopping list items | UI/enhancement | 3 | 0.1d | 581 | 0.03x | ⚡ Very fast |
| #315 | Extract UnitConverter + IngredientAggregator | refactor | 2 | 0.3d* | 623 | 0.15x | ⚡ Faster |
| *Overhead* | *Windows Defender friction + release chores* | — | — | ~0.3d | — | — | 📋 |
| **TOTAL (planned)** | | | **21** | **2.4d tracked / ~2.7d effective** | **4,799** | **0.11x** | ⚡ |

*\* #315 tracked commit time only; ~0.3d additional overhead from Windows Defender blocking Dart network access during release phase not reflected in commits.*

#### Accuracy by Type

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| UI display-only | #314 | 3 | 0.3d | 0.10x | ⚡ Fast — read-only addition; no interaction testing burden |
| UI/enhancement (cross-sprint pattern reuse) | #313 | 5 | 0.7d | 0.14x | ⚡ Fast — `ServingsStepper` from #307 applied to 4 locations |
| Architecture/feature (new DB tables) | #311 | 8 | 1.0d | 0.13x | ⚡ Fast — junction table pattern was clear; no discovery phase |
| UI/enhancement (within-sprint pattern reuse) | #312 | 3 | 0.1d | 0.03x | ⚡ Very fast — dialog pattern from #311 reused in same sprint |
| Refactor (mechanical extraction) | #315 | 2 | 0.3d | 0.15x | ⚡ Fast — fresh code context; extraction while code was warm |

**Overall:** Actual effort was 11% of estimated (0.11x ratio tracked; ~0.13x including hidden overhead). Sprint closed all 5 issues in ~4 focused sessions, delivering 21 points — completing the 0.1.12 validation debt (#313, #314) and shipping two new features (#311, #312) plus an opportunistic refactor (#315).

#### Variance Analysis

**Very fast: #312 (manual shopping list, 0.03x)** — Estimated: 3 pts → Actual: ~0.1d (single 45-minute session)
- All three #312 commits (feature: 23:42, category grouping: 23:54, widget tests: 00:27) span 45 minutes across Mar 7–8
- `AddSimpleSideDialog` from #311 (built same sprint, earlier that week) provided the structural template directly
- Category grouping emerged during testing in the same session — discovered and fixed in 12 minutes, never a separate day
- This is the strongest within-sprint pattern compounding observed to date

**Fast: #311 (simple sides, 0.13x)** — Estimated: 8 pts (L) → Actual: ~1.0d
- 18 files, 2 new DB tables, 2 new models, CRUD, UI in 2 screens, shopping list integration, l10n — all in one concentrated day (committed 22:37)
- No surprises: `MealPlanItemRecipe`/`MealRecipe` junction table pattern was a clear template; solution was known before opening the editor
- Developer expected more friction; it didn't materialise

**Fast: #313 (ServingsStepper in forms, 0.14x)** — Estimated: 5 pts → Actual: ~0.7d
- `ServingsStepper` widget fully established in #307 (0.1.12); applying it to 4 form locations was mechanical
- Landed same day as #314, afternoon session

**Fast: #314 (display servings, 0.10x)** — Estimated: 3 pts → Actual: ~0.3d
- Read-only display addition: no stepper, no interaction, no state management overhead
- Fast because inherently simpler than form-equivalent work — not primarily pattern reuse

**Hidden overhead: Windows Defender** — ~0.3d untracked
- During Mar 8–9 release phase, Windows Defender blocked Dart's network access
- Required diagnosing the failure mode and adding firewall exceptions for Dart/Flutter executables
- No commit trace; absorbed as release overhead
- Consistent category with adb/Android Studio friction from 0.1.5 and 0.1.8

#### Working Pattern Observations

```
Mar 02 (Sun) │ ░░░░░░░░  Planning only (~0.25d)
Mar 03 (Mon) │ ████████  #314 (morning) + #313 (afternoon) — committed 16:22
Mar 04 (Tue) │ ────────  Rest
Mar 05 (Wed) │ ────────  Rest
Mar 06 (Thu) │ ████████  #311 — single long session, committed 22:37
Mar 07 (Fri) │ ░░░░████  #312 feature + category grouping (late night: 23:42, 23:54)
Mar 08 (Sat) │ ░░░░████  #312 tests (00:27) + #315 (21:49) + Defender friction
Mar 09 (Sun) │ ░░░░░░██  Release chores only
```

**Patterns:**
- Sprint followed "thematic grouping" structure: servings completion on Day 1, new feature on Day 2, follow-on feature + refactor on Days 3–4
- Every issue was a single concentrated session — no context switching mid-issue
- Late-night sessions (21:00–00:30) for #311 and #312 reflect calmer environment and higher focus; these are genuine productivity windows, not anomalies
- Mar 4–5 were clean rest days; the sprint was efficient enough that rest didn't compromise delivery
- All 5 issues delivered without a single rework commit or regression fix

#### Lessons Learned

1. **Within-sprint pattern compounding can collapse a 3pt issue to 45 minutes**
   - #312 (3 pts) was completed in ~45 minutes because #311's `AddSimpleSideDialog` was built 3 days earlier in the same sprint
   - The dialog pattern transfer was direct: structural template, input handling, and validation logic reused with minimal adaptation
   - This is faster than cross-sprint reuse because the pattern is still fully loaded in working memory
   - **Lesson: When planning a sprint with two related dialogs/features, the second is near-free if it reuses the first's dialog. Sequence them deliberately back-to-back.**

2. **Display-only work needs its own calibration bucket**
   - #314 (display servings, 3 pts, 0.10x) was fast not because of pattern reuse but because it is inherently simpler: no user input, no state machine, no validation, minimal edge cases
   - Estimating display-only additions at the same point value as form additions overestimates by ~30–50%
   - **Lesson: Distinguish "display-only" from "form/interaction" at estimation time. Display-only → apply 0.10x; form-extension with established pattern → 0.14x.**

3. **L-size architecture issues execute reliably when the template pattern exists**
   - #311 (8 pts, L-size) — 2 new DB tables, 2 models, CRUD, UI in 2 screens, shopping list integration — completed in 1 day with no surprises
   - Key enabler: `MealPlanItemRecipe`/`MealRecipe` junction table structure was an exact template; implementation was translation, not design
   - **Lesson: Don't over-buffer L-size issues when the junction table/model pattern is already established. The L estimate accounts for discovery that doesn't materialise when the path is clear.**

4. **Cross-sprint pattern reuse is a reliable 0.14x for "apply to N locations" tasks**
   - #313 (5 pts) applied `ServingsStepper` (from #307, 0.1.12) to 4 form locations in ~0.7d
   - This matches the "cross-sprint pattern extension" profile consistently seen in 0.1.7b, 0.1.8, 0.1.12
   - **Lesson: "Apply existing widget/pattern to N locations (N ≤ ~5)" tasks → estimate 0.14x regardless of N.**

5. **Windows Defender is a Windows-specific release-phase tooling risk**
   - Dart's network access was silently blocked during the Mar 8–9 release phase, requiring firewall exception configuration
   - Similar category to adb/Android Studio friction (0.1.5, 0.1.8): Windows tooling overhead that leaves no commit trace
   - Risk is highest during release phases when `flutter pub get` and build steps need network access
   - **Lesson: Add Dart/Flutter firewall exception setup to new-machine checklist. If symptoms appear (Dart stops working), check Defender first before investigating app/tooling issues.**

6. **Validation debt properly scoped as follow-up issues is cleanly repaid**
   - #313 and #314 were explicit follow-ups from 0.1.12's deferred device testing on the servings chain
   - Both landed on Day 1 without rework — the debt was well-specified and bounded
   - **Lesson: Validation debt captured as explicit follow-up issues is low-risk to repay. The danger is untracked validation debt.**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Within-sprint dialog pattern reuse collapses 2nd issue to ~free | Sequence related dialog features back-to-back; estimate 2nd at 0.5–1 pt (not full story points) |
| Display-only work cheaper than form estimates suggest | Apply ~0.10x for display-only additions; 0.14x for form-extension with established pattern |
| L-size arch issues with clear template ≈ 0.13x | Don't buffer L issues for "complexity" when junction table pattern is established |
| Windows Defender tooling risk | Add to new-machine checklist; budget ~0.3d if encountered during release phase |
| Late-night concentrated sessions as productive as full days | Schedule single-issue sessions in preferred focus windows when possible |

#### Notes

- Sprint delivered 21 points in ~4 focused sessions (~2.4d tracked, ~2.7d effective) at ~8.75 pts/day tracked velocity
- Consistent with recent cruising velocity (30 pts/week); above it on active-session basis due to focused late-night work style
- Sprint completed the 0.1.12 validation debt story (#313, #314) plus shipped two new features (#311, #312) and opportunistic refactor (#315)
- #313 (−235 net lines) and #315 (−49 net lines) were net simplifications — the sprint both added features and reduced codebase complexity
- No rework commits, no regression fixes, no flaky tests
- Windows Defender incident documented; add Dart/Flutter firewall exceptions to new-machine setup checklist

---

### 0.1.14 - DB Housekeeping & Documentation

**Sprint Duration:** March 20–25, 2026
**Calendar Days:** 6
**Active Working Days:** ~4 (Mar 20, 21, 22, 25; weekends = rest)
**Planned Issues:** 5 (~21 estimated points*)
**Completed Issues:** 5 planned (100%)

*Retroactive entry — sprint was not tracked in real time. Point estimates derived from 0.1.10 milestone planning documents where these issues were originally scoped and deferred. Commit-level weighted analysis not available.*

#### Issue Summary

| Issue | Title | Type | Est Points | Closed | Notes |
|-------|-------|------|------------|--------|-------|
| #292 | Consolidate DB migrations into baseline | Refactor/Tech Debt | 8 | Mar 20 | Anchor issue — first completed |
| #268 | Update skills documentation structure | Tech Debt/Docs | 3 | Mar 21 | Batched with #263 |
| #263 | Create UI Component Library Documentation | Documentation | 5 | Mar 21 | Batched with #268 |
| #318 | Fix e2e test helpers (scroll before tap) | Testing | ~2 | Mar 22 | Emerged from test runs |
| #285 | Test suite governance + count updates | Documentation | 3 | Mar 25 | Intentionally last |
| **TOTAL** | | | **~21** | | |

#### Sprint Character

A deliberate **zero-features housekeeping sprint** — the cleanest possible way to close the 0.1.x series. Every issue was internal and invisible to users.

- **#292** was the heaviest: consolidating 12+ migration files into a clean baseline before any 0.2.x work. Changed the DB foundation without any user-visible behavior.
- **#268 + #263** were the documentation/skills pass: standardizing skill structure and documenting all UI components from 0.1.7–0.1.10. Batched on the same day for thematic efficiency.
- **#318** was a testing correctness fix discovered from e2e runs — e2e helpers weren't scrolling before tapping off-screen buttons. Not pre-planned; emerged as standard test-suite overhead.
- **#285** was intentionally sequenced last: test suite governance and count updates should capture all 0.1.x work, including the other four issues in this milestone.

#### Working Pattern Observations

```
Mar 20 (Fri) │ ████████  #292 migration consolidation (anchor, heaviest issue)
Mar 21 (Sat) │ ████████  #268 (skills) + #263 (UI docs) — documentation batch day
Mar 22 (Sun) │ ████░░░░  #318 e2e test fix (shorter session)
Mar 23–24    │ ──────────  Weekend
Mar 25 (Wed) │ ████░░░░  #285 test governance (intentionally last)
```

**Patterns:**
- Anchor issue first, on its own day — correct for the heaviest item
- Documentation batch day (Mar 21): two thematically linked issues done together
- Test fix (#318) isolated on a shorter day — consistent with emergent overhead pattern
- Governance close (#285) deliberately last to capture final 0.1.x state

#### Lessons Learned

1. **Zero-features sprints close cleanly when issues were pre-validated**
   - All 5 issues had clear acceptance criteria from 0.1.10 planning (where they were deferred)
   - No scope discovery, no emergent complexity — just execution of well-specified internal work
   - **Lesson: Deferred housekeeping issues are low-risk to execute when scope was already validated at deferral time**

2. **"Must be last" sequencing discipline produces correct documentation**
   - #285 (test governance) explicitly required capturing the final test count including the other 4 issues' work
   - Done earlier, counts would have been stale immediately
   - **Lesson: Establish explicit sequencing constraints for documentation issues that summarize other completed work**

3. **Migration baseline consolidation is high-leverage, permanent simplification**
   - #292 eliminated 12+ fragmented migration files — every future migration now has a clean baseline to build from
   - This is permanent technical debt reduction; every future developer and DB schema change benefits
   - **Lesson: Migration consolidation is high-leverage housekeeping — do it before adding more migrations, not after**

4. **Dedicated housekeeping sprints protect feature sprints from quality drift**
   - Batching documentation, skills governance, migrations, and test counts into one sprint prevents these from bleeding into 0.2.x feature work
   - Feature sprints that absorb housekeeping work lose focus; housekeeping-only sprints finish cleanly
   - **Lesson: One focused housekeeping sprint is more effective than spreading quality work across feature sprints at 10% each**

#### Notes

- Sprint closed the 0.1.x series with a clean internal state: consolidated DB baseline, documented UI components, updated skills infrastructure, and accurate test suite documentation
- #318 emerged from test runs rather than pre-planning — absorbed as standard overhead (~0.5 day)
- This milestone's completion was the prerequisite for clean 0.2.x work and the 0.2.1 data seeding milestone that followed

---

### 0.1.15 - Patch: Import Bug Fixes

**Sprint Duration:** ~April 2–5, 2026 (discovery to fix)
**Calendar Days:** ~4 (discovery phase + fix day)
**Active Working Days:** ~1 (fix day: April 5)
**Planned Issues:** 2 (both P0-Critical; emerged from 0.2.1 testing)
**Completed Issues:** 2 (100%)

*Retroactive entry — not a regular sprint. Both issues were P0 bugs discovered during 0.2.1 data seeding. Not pre-estimated; emergency patch.*

#### Issue Summary

| Issue | Title | Severity | Closed | Notes |
|-------|-------|----------|--------|-------|
| #330 | Recipe import does not restore instructions field | P0-Critical | Apr 5 | Silent data loss: imported recipes lost instructions |
| #332 | Recipe import cascades delete meal history and plan relationships | P0-Critical | Apr 5 | Data destructive: import wiped meal history |

#### Sprint Character

An **unplanned emergency patch milestone** — not a sprint in the planned sense. Both P0 bugs were discovered through active use of 0.2.1's seed recipe data, which exercised the import pathway more thoroughly than any prior testing had.

**#332 was the more dangerous bug:** recipe import was silently deleting meal history and meal plan relationships — real data loss for any user who imported recipes while having existing meal data.

**#330 was a silent field omission:** the `instructions` field was not included in the import mapping, so imported recipes would lose their cooking instructions without warning.

Both bugs shared the same root cause domain (the import service) and were fixed in a single focused session on Apr 5. The fact that two P0 bugs surfaced in the same subsystem simultaneously signals a structural coverage gap in import testing.

#### Why These Bugs Were Invisible Through 0.1.x

- The import feature existed since 0.1.2 (#229) but was rarely exercised during development
- Prior test fixtures used minimal data — few recipes, no meal history, no relational depth
- 0.2.1 introduced the first real seed dataset: recipes with full instructions, ingredients, categories, and associated meal history
- Import + restore with full relational data exposed the cascade behavior and missing field restoration
- **Pattern:** features exercised with synthetic/minimal fixtures can have silent production bugs that only surface with real relational data coverage

#### Working Pattern

```
0.2.1 testing → Bug discovery (#330, #332 filed) → Root cause diagnosis → Fix (Apr 5, single session, both closed same day)
```

Both were targeted fixes in the import service: #332 required explicit cascade protection or junction table reconstruction during import, #330 required adding the missing `instructions` field to the import field mapping.

#### Lessons Learned

1. **The import subsystem had structural coverage gaps**
   - Both P0 bugs existed through ~50 sprints of development without detection
   - Import tests used minimal fixture data that didn't exercise relationship preservation
   - **Lesson: Import/export integration tests must include full relational data: meals with history, plan relationships, instructions. This is mandatory before 0.2.8 extends the import system.**

2. **Real seed data is a distinct integration test category that synthetic fixtures miss**
   - 0.2.1's seed data (first real recipe content) exposed bugs that never surfaced in development
   - Synthetic fixtures tend to be minimal and single-entity; they don't stress relationship cascade behavior
   - **Lesson: "Real data smoke test" should be part of import/export feature validation — import a full-fidelity backup with all relationship types and verify integrity**

3. **Two P0 bugs in the same subsystem is a coverage signal, not bad luck**
   - If one area generates two P0s simultaneously, that area has structurally insufficient test coverage
   - Fixing one and shipping does not close the risk — the coverage gap remains
   - **Lesson: After fixing a P0 bug, audit the same subsystem for additional coverage gaps before shipping the patch**

4. **Emergency patches with known root cause execute at the 0.10x post-usage-bug rate**
   - Both bugs fixed in a single day — root causes were immediately clear from the import code
   - No exploratory debugging phase; traced the import path directly to the failure point
   - Consistent with 0.1.11's "post-usage bugs execute at 0.10x" pattern: known root cause → direct fix
   - **Lesson: Emergency patches are fast when the bug is reproducible and the code path is understood**

#### Notes

- This milestone closed Apr 5, 2026 — after 0.2.1 shipped (March 2026)
- Both bugs were P0-Critical with no safe workaround (users couldn't trust import)
- **Action item for 0.2.8 (Import & Remaining UX) planning:** Add import integration tests with full relational data (meals, history, plans, instructions) as a prerequisite before extending import features further

---

### 0.2.2 - Algorithm & Stability

**Sprint Duration:** April 12–15, 2026
**Calendar Days:** 4
**Active Working Days:** ~3.8 (Apr 12: planning only ~0.5d; Apr 13–15: 3 commit days + ~0.3d hidden Recraft design)
**Planned Issues:** 11 (29 pts original; adjusted to 10 issues / 26 pts after #232 won't fix at planning)
**Completed Issues:** 9 of 10 adjusted (90%); #341 committed but not validated on device

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #254 | Confidence dedup testing | Testing | 2 | ~0.50d* | 81 | 0.25x | ⚠️ Slowest in sprint |
| #331 | P0 crash + user warning | Bug P0 | 1 | ~0.15d† | 28 real | 0.15x | ✅ On target |
| #214 | Algorithm weight tuning | Algorithm | 3 | 0.20d | 170 | 0.07x | ⚡ Faster |
| #82 | Ingredient frequency factor | Algorithm | 3 | 0.60d | 510 | 0.20x | ✅ On target |
| #213 | Weekly variety constraint | Feature | 2 | 0.20d | 173 | 0.10x | ⚡ Faster |
| #347 | App icon redesign | UX Design | 2 | ~0.31d‡ | 2+design | 0.16x | ✅ On target |
| #342 | Parser bug (confidence) | Bug | 5 | 0.33d | 48 | 0.07x | ⚡ Faster (batched) |
| #344 | Parser bug (PT-BR) | Bug | 3 | 0.29d | 42 | 0.10x | ⚡ Faster (batched) |
| #343 | Parser bug (accented) | Bug | 3 | 0.28d | 41 | 0.09x | ⚡ Faster (batched) |
| #341 | Same-day meal ordering | Bug | 2 | ~0.10d | 13 | — | ⚠️ Incomplete fix |
| #232 | MealEditService consolidation | Refactor | 3 | — | 0 | — | Won't Fix |
| **TOTAL (confirmed complete)** | | | **24** | **~2.7d tracked / ~3.8d effective** | **1,168** | **~0.11x** | |

*#254 weighted actual slightly above raw script value after l10n correction to #331 redistributed Apr 13 proportional allocation.*
†#331 adjusted for l10n inflation: raw commit included ~60 lines of generated `app_localizations.dart`; real effort ~28 lines / ~0.15d.
‡#347: ~0.01d committed + ~0.30d hidden Recraft design iteration = ~0.31d adjusted.

#### Accuracy by Type

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Testing (new algorithm behavior) | #254 | 2 | ~0.50d | 0.25x | ⚠️ Slowest — dedup logic required analytical test design |
| P0 Bug | #331 | 1 | ~0.15d | 0.15x | ✅ On target — warning-only fix; l10n adjusted |
| Algorithm | #214, #82 | 6 | 0.80d | 0.13x | ✅ On target — established codebase; #82 heavier as expected |
| Feature | #213 | 2 | 0.20d | 0.10x | ⚡ Faster — familiar service layer, well-specified |
| UX Design | #347 | 2 | ~0.31d | 0.16x | ✅ On target (hidden Recraft work included) |
| Parser Bugs (batched cluster) | #342–#344 | 11 | ~0.90d | 0.08x | ⚡ Faster — same root cause; cluster execution |
| Incomplete | #341 | 2 | ~0.10d | — | ⚠️ Committed without device validation |
| Won't Fix | #232 | 3 | — | — | Excluded at planning |

**Overall:** 24 confirmed pts tracked at ~2.7d, ~0.11x — consistent with recent cruising range (0.10–0.17x). The parser bug cluster (#342–#344, 11 pts) compressed to ~0.90d through batch execution; the algorithm day (#214, #82, #213) delivered 8 pts cleanly in a single domain-focused session.

#### Variance Analysis

**Cluster execution: #342–#344 (parser bugs, 11 pts)**
- Three bugs sharing the same root cause domain (ingredient normalization/matching), batched on Apr 15
- First issue (#342) established the fix template; #343 and #344 were adaptations of the same approach
- Combined: 11 pts, ~0.90d, 0.08x avg — significantly faster than tackling independently across separate days
- The batch decision was correct and accounted for most of the sprint's apparent speed

**Heavier: #82 (ingredient frequency, 0.20x)**
- Largest single issue by lines (510) and weighted days (0.60d); highest-complexity algorithm issue
- 0.20x is above the sprint average but within normal cruising range — more surface area across the recommendation service
- Not a surprise; calibrated correctly as the heaviest algorithm item

**Slowest: #254 (confidence dedup testing, 0.25x)**
- Testing new dedup behavior required designing test cases from scratch, not following established fixtures
- Contrast with 0.07–0.10x range for the parser bugs (known patterns) — analytical test design takes longer
- Still fast in absolute terms; the sprint average of ~0.11x reflects the cluster batch skewing the baseline

**Design invisible in commits: #347 (app icon)**
- Two Recraft iterations (~0.30d) produced the icon assets; the committed change was only 2 lines (asset swap)
- Without the design time adjustment, #347 appears trivially fast; with it, 0.16x — on target for a branding iteration
- External design tooling leaves no commit trace by nature; must be accounted for explicitly in retrospective

**Incomplete fix: #341 (same-day meal ordering)**
- Two commits across Apr 13 and Apr 15 (CASE clause addition, `ffe7f7e`); 13 total lines
- Fix was logically consistent with the data model but never rebuilt as an APK and tested on device before shipping in 0.2.2
- Consequence: two downstream issues created post-sprint — #351 (query ordering hardening) and #352 (MealCookedDialog ignores plannedDate)
- Pattern: end-of-sprint compression caused a close-but-untested fix to ship as complete

**Won't Fix: #232 (MealEditService consolidation)**
- Evaluated and dropped at Apr 12 planning — consolidation had insufficient value vs sprint cost
- 0 implementation time spent; clean scope decision before the first commit

#### Working Pattern Observations

```
Apr 12 (Sun) │ ░░░░░░░░  Planning only (~0.5d) — sprint scope, #232 dropped
Apr 13 (Mon) │ ████████  #254 testing + #331 P0 warning + first #341 attempt
Apr 14 (Tue) │ ████████████  #214 + #82 + #213 — algorithm cluster day (8 pts)
Apr 15 (Wed) │ ████████████  #342 + #343 + #344 parser batch + #347 icon + #341 follow-up
             │ ░░░░        (~0.3d Recraft design untracked, embedded in #347 day)
```

**Patterns:**
- Apr 12 planning day produced clean Apr 13–15 execution — no scope uncertainty mid-sprint
- Algorithm cluster (Apr 14): 3 issues, same recommendation service domain, single day — delivered 8 pts without context switching
- Parser bug batch (Apr 15): same root cause → first fix set template, subsequent were mechanical
- Last-day compression: #341 and #347 both closed Apr 15, the final day — likely contributed to #341 shipping without device validation

#### Lessons Learned

1. **Parser/algorithm bugs with the same root cause execute at ~0.08–0.10x when batched**
   - #342 (5 pts), #343 (3 pts), #344 (3 pts) — all normalization/matching issues — delivered at 0.07–0.10x in a single day
   - First issue establishes the fix template; subsequent issues are adaptations, not independent investigations
   - This is faster than generic bug batching because the root cause is identical — no re-investigation per issue
   - **Lesson: When ≥2 parser or algorithm bugs share the same root cause, plan as a cluster day. Estimate the first at standard rate; discount 2nd+ issues 40–50% at estimation time.**

2. **End-of-sprint compression creates validation debt**
   - #341 was committed and closed across two days, but never rebuilt as an APK and tested on device
   - The CASE clause fix was logically sound but unverified in practice; issue shipped in 0.2.2 as "fixed"
   - Consequence: two downstream issues (#351, #352) emerged post-release during investigation
   - This is the same failure mode documented in 0.1.12 — fast execution through a bug without device validation generates deferred work, not completed work
   - **Lesson: Any bug fix touching query ordering, time-sensitive behavior, or display logic requires an explicit "tested on device" acceptance criterion. Committed ≠ validated.**

3. **Testing new algorithm behavior is analytically different from extending existing tests**
   - #254 (2 pts, 0.25x) was the slowest issue in the sprint — new dedup logic had no established test fixtures
   - Test design required understanding the dedup edge cases first, not following an established template
   - Contrast with the parser bug tests (0.07–0.10x) which reused the same normalization assertion pattern
   - **Lesson: Distinguish "test new algorithm behavior" from "extend existing test suite" at estimation time. Former is closer to "new test infrastructure" (0.20–0.30x); latter follows the established 0.07–0.10x pattern.**

4. **L10n-generated files inflate line counts in retrospective proportional allocation**
   - #331's raw line count was 88; ~60 of those were generated `app_localizations.dart` output from `flutter gen-l10n`
   - The script-calculated proportional day allocation gave #331 0.52d — more than 3× the actual effort
   - **Lesson: In retrospectives, check high-line commits on low-complexity issues for l10n generation artifacts. Adjust proportional allocation using "real effort" lines (exclude `app_localizations.dart` and `.g.dart` files) to avoid misrepresenting simple issues.**

5. **External design tooling work needs explicit tracking**
   - #347's Recraft iteration (~0.30d) was real creative effort that left zero commit trace
   - Without the developer interview, the sprint would appear shorter than it was
   - **Lesson: Note external design tool time (Recraft, Figma) during the sprint. Include as hidden overhead in the retrospective effective-day calculation — same treatment as adb friction or planning days.**

6. **Won't fix decisions at sprint planning are cleaner than mid-sprint abandonment**
   - #232 evaluated and dropped Apr 12; zero implementation time spent; sprint scope immediately clear
   - **Lesson: Sprint planning is the correct boundary for won't fix decisions. If a won't fix is recognized after the first commit, that commit is waste. Decide before opening the editor.**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Parser/algorithm bug cluster (~0.08x avg) when same root cause | Estimate first issue normally; apply 50% discount to 2nd+ issues sharing root cause domain |
| #341 shipped without device validation → 2 follow-up issues | Add "tested on device" as non-optional AC for bug fixes touching query ordering or display logic |
| Testing new algorithm behavior: 0.25x (vs 0.08–0.10x for pattern extension) | Separate estimation: "test new behavior" → 0.20–0.30x; "extend test suite" → 0.07–0.10x |
| L10n inflation distorts line-count proportional allocation | Exclude `app_localizations.dart` from line counts when computing proportional day attribution |
| Hidden design tooling (~0.30d for #347) invisible in commits | Note external design time in sprint log; include in effective-day calculation at retrospective |

#### Notes

- Sprint confirmed-complete: 24 pts / 3.8d effective → ~6.3 pts/day → **~31.5 pts/week** (cruising range)
- Milestone shipped: improved recommendation algorithm (ingredient frequency, weight tuning, variety constraint), P0 crash fix, parser normalization corrections (confidence, accented chars, PT-BR), refreshed app icon
- The incomplete #341 is the sprint's lasting cost: #351 (query ordering hardening) and #352 (MealCookedDialog date bug) are its direct successors; both require device-validated fixes in 0.2.3
- Parser bug cluster (11 pts in ~0.90d) created the perception of an unusually fast sprint, but the underlying velocity is normal cruising — the batch compressed one day's work, not the sprint's overall cadence

### 0.2.3 - UX Polish

**Sprint Duration:** April 16–18, 2026
**Calendar Days:** 3
**Active Working Days:** ~3.4 effective (3 commit days + ~0.4d hidden UX design/device testing overhead for #121)
**Planned Issues:** 11 (33 pts); #291 deliberately deferred at sprint start; #352 resolved by dead code removal rather than one-line patch
**Completed Issues:** 10 of 10 must-complete items (100%); #291 deferred; #353 unplanned refactor added

#### Estimation vs Actual

| Issue | Title | Type | Est Points | Weighted Actual | Lines | Ratio | Assessment |
|-------|-------|------|------------|-----------------|-------|-------|------------|
| #352 | MealCookedDialog `cooked_at` bug | Bug | 1 | ~0.10d* | ~50 | 0.10x | ✅ On target (resolved by dead code removal) |
| #351 | Same-day meal ordering | Bug | 2 | ~0.15d* | 6+157 | 0.08x | ✅ On target (device-validated) |
| #345 | Unit strings not localized | Bug | 2 | ~0.05d* | 5 | 0.03x | ⚡ Faster (trivial l10n pattern) |
| #339 | Add button unlabelled grey box | Bug | 2 | ~0.05d* | 2 | 0.03x | ⚡ Faster (2-line fix) |
| #340 | Dialog layout breaks with suggestions | Bug | 3 | ~0.30d* | 137 | 0.10x | ✅ On target |
| #296 | Reduce whitespace in ingredient cards | Polish | 2 | ~0.35d* | 255 | 0.18x | ✅ On target |
| #295 | Plan Today scrolls to today's slot | Feature | 3 | ~0.25d | 73+187 | 0.08x | ⚡ Faster (pre-diagnosed failure → no discovery phase) |
| #193 | Ingredient detail screen — Used In tab | Feature | 3 | ~0.50d | 546 | 0.17x | ✅ On target |
| #329 | Ingredient usage frequency — meal history | Feature | 2 | ~0.35d | 475 | 0.18x | ✅ On target |
| #121 | Multi-recipe UX discoverability | P1 Feature | 8 | ~0.75d tracked / ~0.95d eff.† | 289+3 | 0.12x | ✅ On target |
| #353 | Remove dead RecipeIngredientsScreen | Refactor | N/A | ~0.10d | 362 del | — | 📋 Unplanned (sprint-opportunistic) |
| **TOTAL (confirmed complete)** | | | **33** | **~3.0d tracked / ~3.4d effective** | **~2,300** | **~0.10x** | |

*\* Apr 16 issues proportional to insertions; l10n-generated output excluded from line counts per 0.2.2 methodology note.*
†#121 tracked commits: 292 lines; ~0.20d hidden overhead for device testing, UX design decision (Option A vs B), and AddSideDishDialog flow iteration.

#### Accuracy by Type

| Type | Issues | Est Total | Weighted Actual | Avg Ratio | Verdict |
|------|--------|-----------|-----------------|-----------|---------|
| Bug fixes (prior-sprint validation debt) | #351, #352 | 3 | ~0.25d | 0.08x | ⚡ Faster — root cause pre-diagnosed in 0.2.2 |
| Bug fixes (known patterns, batched Apr 16) | #345, #339, #340 | 7 | ~0.40d | 0.06x | ⚡ Faster — all known patterns, no debugging phase |
| UX Polish | #296 | 2 | ~0.35d | 0.18x | ✅ On target |
| Feature (medium-risk, pre-diagnosed) | #295 | 3 | ~0.25d | 0.08x | ⚡ Faster — prior failure mode known; no discovery |
| Feature (new screen + second tab) | #193, #329 | 5 | ~0.85d | 0.17x | ✅ On target |
| P1 Feature (discovery-adjacent) | #121 | 8 | ~0.95d effective | 0.12x | ✅ On target |

**Overall:** 33 confirmed pts at ~3.4d effective → ~0.10x — consistent with recent cruising range (0.10–0.17x). The bug batch (Apr 16) and UX feature pair (#193+#329) executed as expected; #121 required UX iteration overhead but landed within cruising range.

#### Variance Analysis

**Validation debt repaid as expected: #351, #352 (0.08x)**
- Root cause was fully diagnosed during 0.2.2 post-release investigation; no debugging phase in 0.2.3
- #352 resolved by deletion rather than patching: MealCookedDialog was unreachable dead code — safer outcome than the planned one-line fix, and zero commit overhead for #351's integration test suite
- Device-validated same-day: ordering queries pass on device, confirming `date(cooked_at)` fix is correct
- Confirms the "prior-sprint debt executes at post-usage rates" pattern — the investigation phase already happened; execution is mechanical

**Trivial bug batch at ~0.03-0.10x: #345, #339, #340**
- #345 (5 insertions) and #339 (2 insertions) are at the extreme low end — applying known l10n and widget state patterns
- #340 (137 insertions, 0.10x) was the only one requiring non-trivial layout constraint reasoning, but still batched on same day as the others
- All three closed Apr 16 alongside #351/#352/#296 — 12 pts in a single day confirms execution-mode batch velocity

**Medium-risk issue resolved cleanly when pre-diagnosed: #295 (0.08x)**
- Sprint planning noted "prior attempt failed" and diagnosed root cause: `maxScrollExtent` returned 0 while ListView wasn't rendered. Prescribed fix: GlobalKey + `scrollToToday()` + post-frame callback.
- Actual execution matched the prescription directly — no re-investigation. Tests added same day.
- A "previously failed + sound diagnosis" is not a risk amplifier — it constrains the solution space and eliminates alternatives. The failure made the next attempt more reliable, not less.

**UX iteration overhead on P1 feature: #121 (~0.20d hidden)**
- Device testing after initial implementation revealed a flow problem: "Voltar" in `AddSideDishDialog` discarded side-dish selections; "Salvar Refeição" bypassed `RecipeSelectionDialog` entirely — no path existed to review the full meal before saving.
- Design decision required: single save point in `RecipeSelectionDialog` (Option B) won over keeping the save button inside `AddSideDishDialog` (Option A). Pure-picker pattern applied.
- Result also improved: bottom sheet replaced `SimpleDialog` for meal actions (better affordance, grouped sections).
- ~0.20d overhead is comparable to 0.2.2's Recraft design work for #347. Device-testing-driven UX iteration on P1 features should be budgeted as standard overhead, not an overrun.

**Integration test coupling to l10n keys: #121 follow-up fix**
- Changing `l10n.save` → `l10n.saveMeal` in `_buildMenu()` silently broke 2 integration tests. Tests compiled without error (label text changed, not key reference) but failed at runtime.
- Caught by running the full integration test suite post-release. Fast fix once identified (replace_all in both test files).
- The issue is structural: integration tests asserting on translated button text couple test correctness to l10n key choices. Any button rename triggers a test hunt.

**#291 deliberate deferral validated**
- 5 pts: DB migration + model + full UI + history display + l10n. Disproportionate effort relative to the "UX Polish" theme value.
- Milestone shipped cleanly without it. No user-facing gap. Correct scope decision.

**Emergent refactor #353: free delivery**
- `RecipeIngredientsScreen` was dead code (replaced by `recipe_details_ingredients_tab.dart` in a prior sprint). Removal cost ~0.10d and reduced codebase surface area. Opportunistic clean-up during an active sprint is consistently low-cost.

#### Working Pattern Observations

```
Apr 16 (Wed) │ ████████████  #351+#352 validation debt + #345 + #339 + #340 + #296 — 12 pts, bug+polish batch
Apr 17 (Thu) │ ████████      #295 (Plan Today) + #193 (ingredient detail) + #353 unplanned
Apr 18 (Fri) │ ████████      #329 (meal history tab) + #121 (multi-recipe UX) + release + integration test fixes
             │ ░░░░          (~0.20d hidden: #121 device testing, UX design decision, AddSideDishDialog iteration)
```

**Patterns:**
- Bug batch compressed Days 1+2 of the sprint plan into one actual day (Apr 16 — 12 pts)
- UX feature pair (#193+#329, same screen) executed across Apr 17–18 as planned; tab-extension pattern confirmed fast
- P1 feature (#121) required mid-day UX iteration; release same day confirms high commit-to-ship confidence
- Sprint plan was 5 working days; delivered in 3 — confirms execution-mode sprints (well-specified, no discovery) outperform velocity estimates

#### Lessons Learned

1. **0.2.2 validation debt repaid at expected post-usage rate (0.08x)**
   - #341's incomplete fix created #351 and #352 as successors. Both executed at ~0.08x — the "debugging already happened" principle holds even across sprint boundaries.
   - The cost of deferred validation is not re-investigation time; it's the issue management overhead and the risk of it blocking subsequent features. In this sprint it didn't block anything, but it consumed one of the three available days.
   - **Prior lesson confirmed: "tested on device" is a non-optional AC for any data-facing fix.**

2. **Dead code resolution beats patching when it applies**
   - #352 was planned as a one-line patch to `MealCookedDialog.initState`. Inspection found the dialog was never called — dead code. Removal was safer (zero runtime path) and needed no device validation.
   - **Lesson: Before implementing a bug fix, verify the buggy code path is reachable. If it isn't, deletion is the correct fix.**

3. **"Previously failed + sound diagnosis" is lower risk than "new implementation"**
   - #295 had a Medium risk rating due to the prior failed attempt. In practice it was the fastest feature in the sprint (0.08x). The prior failure left a correct diagnosis that eliminated all alternatives.
   - **Lesson: Revise risk ratings downward when a failure mode has been documented and a prescribed fix exists. The failure made the next attempt more predictable, not less.**

4. **Device-testing-driven UX iteration on P1 features is standard overhead (~0.20d)**
   - #121 required one round of design iteration triggered by device testing (AddSideDishDialog flow problem). This is comparable to 0.2.2's external design tool time (#347, ~0.30d) — real creative work that leaves no commit trace.
   - **Lesson: Budget ~0.20-0.30d hidden overhead for any P1 UX feature that requires real-device validation. It's not an overrun; it's the spec phase for interaction details that aren't visible until you hold the device.**

5. **Integration tests asserting on translated button labels couple test correctness to l10n key names**
   - Changing `l10n.save` → `l10n.saveMeal` broke 2 integration tests that found the button by its translated text ("Salvar"). Tests compiled and passed static analysis but failed at runtime.
   - **Lesson: When changing a button's l10n key, immediately search integration tests for the old translated text. Better practice: integration tests should use semantic keys (`Key('save_meal_button')`) rather than translated labels for tap targets. Using translated text for assertions (not taps) is acceptable and desirable.**

6. **#193 → #329 tab extension pattern executes at expected 0.17-0.18x**
   - Ingredient detail screen (#193) built the scaffold; meal history tab (#329) extended it. Both landed at ~0.17-0.18x — consistent with the "follow-on tab in established scaffold" category.
   - The dependency (#193 before #329) was the main sequencing constraint; executing on consecutive days was correct.

7. **Post-release real-device testing surfaces platform issues that simulator can't catch (#354)**
   - Backup/restore broken on Android 10+ (scoped storage): `/sdcard/Download/` path access blocked, text-field path input also blocked. Discovered on wife's physical device post-release.
   - Issue #354 created and scoped (2 pts: `share_plus` for backup, `file_picker` for restore, `restoreDatabaseFromString()` overload).
   - **Lesson: Sprint completion and test suite passing is not a substitute for post-release physical device testing. The gap between emulator behavior and scoped-storage enforcement on production Android is real.**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Prior-sprint validation debt executes at post-usage rate (0.08x) | No change — this is expected; the cost is issue management, not re-investigation |
| Dead code check before patching | Add "verify code path is reachable" to bug fix checklist; deletion is safer than patching when applicable |
| "Previously failed + diagnosis" = lower risk | Revise risk downward when a prescribed fix exists from prior failed attempt |
| P1 UX features: ~0.20d hidden device/iteration overhead | Build into planning; do not count as overrun |
| Integration test coupling to translated labels | Use `Key()` for tappable elements in integration tests; search old label text when l10n keys change |
| Post-release physical device testing required | Create a post-release device checklist: backup/restore, scoped paths, platform-specific permissions |

#### Notes

- Sprint confirmed-complete: 33 pts / 3.4d effective → ~9.7 pts/day → **~48 pts/week** (execution mode, above cruising baseline)
- Milestone shipped: 0.2.2 validation debt closed (#351, #352), 3 UX bug fixes (#345, #339, #340), ingredient card whitespace (#296), Plan Today scroll (#295), ingredient detail screen with Used In + Meal History tabs (#193, #329), multi-recipe UX discoverability (#121)
- 1793 tests passing at release; all integration tests green post-release fix
- #291 deliberately deferred to 0.2.4+; does not affect milestone theme
- Post-release: backup/restore scoped storage issue discovered (#354, 2 pts, 0.2.x road)
- The 0.2.2 and 0.2.3 sprints together delivered the full UX Polish milestone in ~7.2 effective days (3.8d + 3.4d)

### 0.2.4 - Recipe Enhancement

**Sprint Duration:** April 20–25, 2026
**Calendar Days:** 6
**Active Working Days:** 4 (Apr 20, 22, 24, 25); Apr 21 and Apr 23 were public holidays (rest days); Apr 25 (Saturday) used for final push and release
**Planned Issues:** 10 core must-complete + 3 deferrable/stretch (#291 stretch-only, #170/#150/#151 deferrable)
**Completed Issues:** 12 (10 core + #170 deferrable + #291 stretch + 4 unplanned #360–#363); #150 and #151 deferred

> **Methodology note:** From this entry onward, ratio = actual days ÷ estimated days, where estimated days = estimated points ÷ 6.5 (cruising velocity). Prior entries used 1pt = 1 day as the baseline and are not directly comparable.

#### Estimation vs Actual

| Issue | Title | Type | Est Pts | Est Days | Weighted Actual | Ratio | Assessment |
|-------|-------|------|---------|----------|-----------------|-------|------------|
| #354 | Backup/restore broken on Android 10+ | Bug (platform) | 2 | 0.31d | ~0.70d* | 2.27x | 🔴 Over (SAF + new packages; plan narrative hedged correctly) |
| #198 | Ingredient aliases | Feature (model+UI) | 5 | 0.77d | 0.39d | 0.51x | ⚡ Faster (well-specified; code samples in issue) |
| #320 | Duplicate ingredient prevention | Feature (UI) | 3 | 0.46d | 0.37d | 0.80x | ✅ On target (used #198 alias infra directly) |
| #348 | Marinating time field | Feature (model) | 2 | 0.31d | 0.23d | 0.74x | ✅ On target (servings pattern) |
| #321 | Markdown rendering for instructions | Feature (UI) | 3 | 0.46d | 0.49d | 1.06x | ✅ On target |
| #326 | Recipe story/narrative field | Feature (model+UI) | 2 | 0.31d | ~0.15d† | 0.49x | ⚡ Faster (near-free after #321 — shared widget, model, editor) |
| #291 | Per-recipe notes in multi-dish meals *(stretch)* | Feature (model+UI) | 5 | 0.77d | 0.54d | 0.70x | ✅ On target (leveraged existing multi-dish meal infra) |
| #170 | Parser refactor to localized units *(deferrable)* | Refactor | 2 | 0.31d | 0.24d | 0.78x | ✅ On target |
| #362 | Unit in ingredient usage list | Bug (UX) | 2 | 0.31d | 0.11d | 0.36x | ⚡ Faster |
| #360 | Disambiguate difficulty/rating stars | Bug (UX) | 2 | 0.31d | 0.09d | 0.29x | ⚡ Faster |
| #361 | Localize "Qty:" label | Bug (i18n) | 1 | 0.15d | 0.01d | 0.07x | ⚡ Faster |
| #363 | Remove category chip | UX | 1 | 0.15d | 0.01d | 0.07x | ⚡ Faster |
| Untagged | CI timing fix, to-taste bugfix, release prep | Overhead | — | — | ~0.3d | — | 📋 Overhead |
| **TOTAL** | | | **30** | **4.62d** | **~4.0d** | **~0.87x** | ✅ |

*\* Adjusted for sprint planning overhead (untagged 476-line commit on same day; full 1.0d weighted-day overstates fix effort)*
*† Adjusted for same-day line-proportion weighting artifact; developer confirmed near-free after #321*

#### Accuracy by Type

| Type | Issues | Est Pts | Est Days (÷6.5) | Weighted Actual | Avg Ratio | Verdict |
|------|--------|---------|-----------------|-----------------|-----------|---------|
| Bug (platform, new packages) | #354 | 2 | 0.31d | ~0.70d | 2.27x | 🔴 Over — SAF complexity + new packages underpriced at current velocity |
| Bug (UX display, batched cluster) | #360–#363 | 6‡ | 0.92d | ~0.22d | 0.24x | ⚡ Faster — trivial display fixes; est. inflated by individual ticketing |
| Feature (model+UI, dependency chain) | #198, #326, #291 | 12 | 1.85d | ~1.08d | 0.58x | ⚡ Faster — code samples + dependency compounding across all three |
| Feature (UI, dependency chain) | #320, #321 | 6 | 0.92d | ~0.86d | 0.93x | ✅ On target |
| Feature (model, established pattern) | #348 | 2 | 0.31d | ~0.23d | 0.74x | ✅ On target |
| Refactor (mechanical) | #170 | 2 | 0.31d | ~0.24d | 0.78x | ✅ On target |

*‡ As a single "fix ingredient usage list" cluster: ~3 pts → ~0.46d est. → ratio ~0.48x — individual ticketing inflated the total without inflating effort*

**Overall:** 30 pts / ~4.0d effective → **~0.87x** — slightly faster than cruising. A well-executed sprint with three dependency chains driving the efficiency edge. #354 was the only genuine overrun, driven by platform complexity, not a planning failure.

#### Variance Analysis

**#354: the only genuine overrun (2.27x)**
- SAF content URI handling on Android 10+ required two new packages (`share_plus`, `file_picker`), a new `restoreDatabaseFromString()` service overload, and virtual device testing. Plan noted "full-day focus is correct even at 2 pts" — a correct hedge in the narrative. At 6.5 pts/day, 2 pts implies 0.31d; actual was ~0.70d.
- Story points reflect relative complexity; the 2pt weight was coherent. The calendar mismatch was real and pre-acknowledged. Going forward, platform/permission bugs requiring new packages should be estimated at 3–5 pts to match actual calendar cost at current velocity.

**Three independent dependency chains confirming the compounding pattern:**

**#198→#320 (alias infra → duplicate prevention, 0.51x/0.80x)**
- #198 built the alias-aware matching service; #320 consumed it directly on the same day. Code samples in the #198 spec eliminated design discovery overhead. Combined 8 pts in ~0.76d on Apr 22 alongside #348.

**#321→#326 (MarkdownBody → story field, 1.06x/0.49x)**
- #321 integrated `flutter_markdown` and built the preview toggle. #326 reused `MarkdownBody`, the same recipe model, and the same editor section. Plan described #326 as "near-free" — 0.49x confirms it. The 1.06x on #321 shows the first integration cost was fully absorbed there.

**Existing infra→#291 (multi-dish architecture → per-recipe notes, 0.70x)**
- Labeled stretch-only. Landed Apr 25 after core work complete. Multi-dish junction tables and dialog patterns already existed; #291 added a notes field without new architecture. 0.70x is solidly on target — the "easy" feel came from having no infrastructure work to do.

**Unplanned UX cluster #360–#363 (0.24x average)**
- Discovered while working in the ingredient usage list / Used In tab. Four individually-estimated issues (6 pts → 0.92d expected) that as a bundle would have been ~3 pts → ~0.46d. Actual: ~0.22d. Compensated by deferring #150+#151 (5 pts), keeping net scope change to +1 pt. In-context discovery while code is warm is consistently efficient.

**Deferred #150 and #151: correct scope decisions**
- #150 (range formatting): schema implications for min/max quantities proved deeper than estimated.
- #151 (smart rounding): value questioned during sprint. Both were pre-labeled deferrable; no course correction needed.

#### Working Pattern Observations

```
Apr 20 (Mon) │ ████████  #354 (platform bug) ░░░░ sprint planning (~0.3d hidden)
Apr 21 (Tue) │ ────────  Holiday (rest)
Apr 22 (Wed) │ ████████████  #198 + #320 + #348 — ingredient cluster (stretched day; holidays on both sides)
Apr 23 (Thu) │ ────────  Holiday (rest)
Apr 24 (Fri) │ ████████  #321 + #326 ░░ CI timing fix (~1h overhead)
Apr 25 (Sat) │ ████████████  #291 + #170 + #360–#363 cluster + to-taste bugfix + release
             │ ░░░░  (~0.3d hidden: virtual device testing across sprint, release prep)
```

**Patterns:**
- Holiday sandwich (Tue+Thu) concentrated work into Mon+Wed+Fri with Saturday for final push
- Wed Apr 22 was the heaviest day (10 pts across three issues), motivated partly by knowing rest days bracketed it
- Dependency chains drove sequencing naturally: #198→#320 on Apr 22, #321→#326 on Apr 24, multi-dish infra→#291 on Apr 25
- Final day (Apr 25) delivered stretch goal + deferrable + unplanned cluster + release — high throughput from code familiarity

#### Lessons Learned

1. **Dependency chain compounding is a planning tool, not an accident**
   - Three chains generated three "free rides" in one sprint. All were deliberately sequenced in the sprint plan, not discovered mid-execution.
   - **Lesson: When planning, actively identify "free ride" issues and schedule them immediately after their enablers. The compounding is reliable when the sequence is enforced.**

2. **Platform/permission bugs with new packages are underpriced at 2 pts given current velocity**
   - At 6.5 pts/day, 2 pts implies 0.31d. #354 cost ~0.70d (SAF, new packages, platform testing). Story points are now the primary planning unit and must reflect actual calendar cost at current velocity.
   - **Lesson: Platform/permission bugs requiring new packages should be estimated at 3–5 pts. The relative complexity weight must match the calendar reality at 6.5 pts/day.**

3. **Fine-grained UX cluster ticketing inflates point totals without inflating effort**
   - #360–#363 (6 pts individually, ~0.22d actual). As a bundle: ~3 pts → ~0.46d expected → ratio ~0.48x.
   - **Lesson: Bundle related small fixes as one ticket when discovered together. Flag granularity in the retro; don't adjust individual estimates upward.**

4. **Stretch/deferrable labeling functions as a capacity absorption mechanism**
   - #291 and #170 filled Apr 25's remaining capacity after core work was done. #150 and #151 were correctly deferred.
   - **Lesson: Continue pre-tagging flex issues. The tier prevents scope creep while providing ready options when capacity opens.**

5. **Holiday-interrupted weeks don't disrupt well-sequenced sprints**
   - Mon+Wed+Fri+Sat schedule with two mid-week holidays. Each day started with an unambiguous next issue — the dependency-ordered backlog removed decision overhead entirely.
   - **Lesson: Sprint sequencing is load-bearing in irregular calendars. A clear ordered backlog eliminates the daily "what do I work on?" cost.**

6. **CI/tooling failures are cheap when CI is maintained as a passing baseline**
   - Timing test failure cost ~1h on Apr 24: caught immediately by GitHub Actions, diagnosed quickly, fixed in one commit. No sprint impact.
   - **Lesson: A consistently-green CI baseline converts tooling failures from blockers into 1h diagnostics.**

7. **In-context UX discovery is high-efficiency cleanup**
   - #360–#363 surfaced while already in the ingredient usage list code. Fixed while the code was warm. Same pattern as 0.2.3's #353 dead code removal and 0.1.11's real-life QA sprint.
   - **Lesson: Budget 10–15% for in-context discovery cleanup. Adjacent trivial wins have near-zero context-switching cost when you're already in the area.**

#### Recommendations for Future Sprints

| Finding | Adjustment |
|---------|------------|
| Dependency chains reliably compound velocity | Explicitly sequence "free ride" issues immediately after their enablers |
| Platform/permission bugs: 2 pts underprices at 6.5 pts/day | Estimate at 3–5 pts when new packages or SAF/permissions involved |
| UX cluster ticketing inflates individual point totals | Bundle related small fixes as one ticket; note granularity inflation in retro |
| Stretch/deferrable tier functioning as designed | Continue pre-tagging flex work |
| Irregular calendars: no impact when sprint is sequenced | Dependency ordering removes daily decision overhead automatically |
| CI baseline green → tooling failures = 1h diagnostic | Maintain passing CI as standard discipline |

#### Notes

- Sprint confirmed-complete: 30 pts / 4.0d effective → ~7.5 pts/day → **~37.5 pts/week** (execution mode)
- Milestone shipped: backup/restore fixed for Android 10+ (#354), ingredient aliases (#198), duplicate prevention (#320), marinating time (#348), Markdown instructions (#321), recipe story field (#326), per-recipe meal notes (#291), parser l10n refactor (#170), ingredient usage list polish (#360–#363)
- 1857 tests passing at release
- #150 deferred (range quantity formatting — deeper schema complexity than estimated); #151 deferred (smart rounding — value questioned)
- Unplanned: #360–#363 ingredient usage list cluster (in-context discovery); to-taste bugfix (found during cluster testing)
- Apr 25 used as final sprint day (Saturday); compensated for 2 mid-week public holidays

---

## Cumulative Metrics

### Estimation Accuracy Trend

| Sprint | Planned Points | Weighted Actual | Ratio | Points/Day | Trend |
|--------|----------------|-----------------|-------|------------|-------|
| 0.1.2 | 12.2 | ~11 | 0.90x | 1.11 | Baseline (slightly conservative, mixed work) |
| 0.1.3 | 26 | 10.0 | 0.38x | 2.60 | VERY conservative (pattern reuse) |
| 0.1.4 | 12 | 2.0 | 0.17x | 6.00 | Well-prepared work, early sign of acceleration |
| 0.1.5 | 14 | 6.88 | 1.98x | 2.03 | OVERRAN - Discovery work + MASSIVE hidden overhead |
| 0.1.6 | 18 | 6.0 | 0.33x | 3.00 | Well-specified features |
| 0.1.7a | 21 | ~0.5* | ~0.02x | ~42* | **UNRELIABLE** - Shared day with 0.1.7b, methodology breaks down |
| 0.1.7b | 43 | 6.69 | 0.16x | 6.43 | Design system application + efficient batching |
| 0.1.8 | 25 | 3.35 | 0.13x | 7.14 | Small UX fixes + pattern-extension testing |
| 0.1.9 | 18 | 1.41 | 0.34x | 9.0 | UX simplification, mono-theme, extended hours |
| 0.1.10 | 13 | 2.00 | 0.15x | 6.5 | Pre-sprint scope clarity, anchor feature day, same-domain batch |
| 0.1.11 | 14 | 2.50 | 0.18x | 5.6 | Real-life QA sprint: usage discovery → batch fix |
| 0.1.12 | 17 | 3.30 | 0.17x | 5.7 | Servings chain + UX polish; validation debt deferred to #313-#315 |
| 0.1.13 | 21 | 2.4 (tracked) / ~2.7 (effective) | 0.11x | ~8.75 | Within-sprint pattern compounding; L-size arch smooth; validation debt repaid |
| 0.1.14 | ~21 | ~4.0d | ~0.19x† | ~5.25 | Zero-features housekeeping: migration consolidation + docs + test governance (retroactive) |
| 0.1.15 | n/a‡ | ~1.0d | n/a | n/a | Emergency P0 patch: 2 import data loss bugs discovered via 0.2.1 (retroactive; not a regular sprint) |
| 0.2.2 | 24 | ~2.7d | 0.11x | 6.3 | Algorithm + parser batch cluster; validation debt on #341 (→ #351, #352) |
| 0.2.3 | 33 | ~3.0d tracked / ~3.4d effective | 0.10x | 9.7 | Execution-mode sprint: 6 bugs + 4 UX features + P1 feature; validation debt repaid; #354 discovered post-release |
| 0.2.4 | 30 | ~4.0d | ~0.87x§ | 7.5 | Execution mode: dependency chains, holiday-interrupted week, stretch goal delivered; #354 only overrun (platform complexity) |

*\* 0.1.7a weighted-days methodology underrepresents actual effort due to shared day with 0.1.7b. Developer estimates ~0.5 days actual effort. Excluded from velocity calculations.*
*† 0.1.14 ratio is a retroactive estimate; no commit-level weighted analysis available. Calculated as active days / expected days at cruising velocity.*
*‡ 0.1.15 issues were not pre-estimated (P0 emergency patch); ratio not applicable.*
*§ From 0.2.4 onward, ratio = actual days ÷ (estimated pts ÷ 6.5). Prior entries used 1pt = 1 day baseline — not directly comparable.*

**Critical Insights:**
- **Cruising velocity: 30 points/week** — validated across 0.1.7b–0.2.4 (10 consecutive sprints at 26-48 pts/week); execution-mode sprints (pure bugs + well-specified features, no discovery) can spike above 40 pts/week
- **Velocity step-change confirmed** — early sprints (0.1.2-0.1.6) averaged 1.1-3.0 pts/day; recent sprints (0.1.7b-0.1.11) sustain 5.6-9.0 pts/day. Genuine acceleration from codebase maturity, Claude Code, accumulated infrastructure, and developer proficiency
- **Sprint ratio depends heavily on work type** — Can't use one sprint to predict another
- **Velocity modes**: "Discovery mode" (~20 pts/week) vs "Cruising mode" (~30 pts/week) vs "Execution mode" (~36 pts/week)
- **Hidden overhead is CRITICAL** — Tooling/environment issues added 29% to 0.1.5 (2 full days)
- **Well-specified features are fast** — 0.1.6 showed 0.33x ratio with detailed specs
- **First-screen polish vs follow-up is 8x difference** — The first screen investment creates patterns that compound
- **Healthy UX feedback loops add ~25-30% emergent work** — budget for this, it's a feature not a bug
- **Small UX fixes inflate velocity partially** — 0.1.8's 0.13x ratio partly driven by 1-point floor, but also reflects genuine speed gains
- **Scope discipline (0.1.10) is as powerful as execution skill** — selecting 13 of 32 available points enabled 0.15x execution; the deferred 19 points would have diluted focus without user-facing benefit
- **"Real-life QA sprint" is a distinct sprint type (0.1.11)** — intensive app usage → issue discovery → batch fix; expect 0.15-0.25x ratio, ~28 pts/week; app usage days are not wasted, they're the specification phase
- **Post-usage bugs execute at 0.10x** — root cause is known before the editor opens; no debugging phase needed
- **"Committed ≠ validated" is a recurring failure mode** — confirmed in 0.1.12 (#313–#315, servings chain) and 0.2.2 (#341, meal ordering); fast execution through a bug without device testing generates deferred work, not completed work; "tested on device" must be a non-optional AC item for any data-facing or display-ordering fix
- **"100% completion" can mask validation debt (0.1.12)** — all 17 pts closed but 3 follow-up issues (#313-#315) emerged from skipped device testing on the servings chain; completion rate ≠ feature completeness
- **Dependency chains have diminishing complexity (0.1.12)** — #304 (anchor, 3pts, 0.22x) established the pattern; #305 and #306 followed it at ~0.16x; discount 2nd+ chain issues by 30-50%
- **UI micro-issues are uncalibrateable at 1pt floor (0.1.12)** — bundle as "quick wins block" with 0.5pt flat budget; individual Fibonacci estimation adds no precision for <30-line changes
- **Pre-sprint planning/testing day is standard overhead** — confirmed in 0.1.10 (Feb 16) and 0.1.12 (Feb 26); budget +0.5d per sprint as standard investment

### Type-Based Calibration Factors

Use these multipliers when estimating future work:

> **Methodology note:** Entries up to 0.2.3 use ratio = actual days ÷ estimated points (1pt = 1day baseline). Entries marked **0.2.4 methodology** use ratio = actual days ÷ (estimated pts ÷ 6.5). Rows marked `*` use the new formula and are not directly comparable to prior rows.

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
| UX redesign (simplification) | 3 issues | 0.34x | 0.3-0.5x | **NEW**: Net code deletion, clear vision, no discovery (0.1.9: #279, #271, #280) |
| Bug fixes (post-usage, known root cause) | 3 issues | 0.10x | 0.1x | **NEW**: Root cause known from usage; no debugging phase; batch on one day (0.1.11: #298, #300, #301) |
| Dependency chain — anchor issue | 1 issue | 0.22x | 0.2-0.3x | **NEW**: First issue in chain sets the pattern; includes migration + cascade (0.1.12: #304) |
| Dependency chain — follow-on issues | 2 issues | 0.16x | 0.1-0.2x | **NEW**: Follow issues reuse anchor pattern; discount 30-50% vs anchor estimate (0.1.12: #305, #306) |
| UI micro-issues (< 30 lines, one-liner) | 2 issues | 0.05x | bundle | **NEW**: Bundle as "quick wins block", flat 0.5pt budget per set; Fibonacci scale too coarse (0.1.12: #309, #310) |
| UI display-only (read-only additions) | 1 issue | 0.10x | 0.10x | **NEW**: No interaction, no state machine, no validation; calibrate separately from form-equivalent work (0.1.13: #314) |
| UI/enhancement (cross-sprint pattern reuse, N locations) | 1 issue | 0.14x | 0.14x | **NEW**: "Apply existing widget to N locations (N ≤ 5)" — reliable 0.14x regardless of N (0.1.13: #313) |
| UI/enhancement (within-sprint dialog reuse) | 1 issue | 0.03x | ~0.03-0.05x | **NEW**: Dialog pattern built earlier same sprint; fully loaded in working memory; estimate 2nd dialog at 0.5–1 pt (0.1.13: #312) |
| Architecture/feature (junction table, established template) | 1 issue | 0.13x | 0.13x | **NEW**: L-size issues with clear junction table template execute without discovery overhead; don't over-buffer (0.1.13: #311) |
| Zero-features housekeeping sprint (migration + docs + governance) | 1 sprint | ~0.19x | 0.15-0.25x | **NEW**: Deferred housekeeping issues execute reliably when scope pre-validated; docs fast, migration consolidation moderate (0.1.14) |
| Emergency P0 patch (known root cause, post-release) | 2 issues | ~0.10x | 0.10x | **NEW**: Same 0.10x rate as post-usage bugs — root cause clear from bug report, no debugging phase; import bugs (0.1.15: #330, #332) |
| Parser/algorithm bugs (batched cluster, same root cause) | 3 issues | 0.08x | 0.08-0.10x | **NEW**: Same root cause → template set by first fix; discount 2nd+ issues 40-50% vs first; batch on single day (0.2.2: #342, #343, #344) |
| Testing new algorithm behavior (no established fixtures) | 1 issue | 0.25x | 0.20-0.30x | **NEW**: Distinct from "extend test suite" (0.07-0.10x); dedup/scoring logic requires analytical test design before fixtures can be written (0.2.2: #254) |
| Feature (medium-risk, prior failure + diagnosis documented) | 1 issue | 0.08x | 0.08-0.10x | **NEW**: "Previously failed + sound diagnosis" lowers risk — failure constrained solution space; no re-investigation phase; treat like post-usage bug (0.2.3: #295) |
| P1 Feature (discovery-adjacent, device-test iteration) | 1 issue | 0.12x | 0.10-0.15x | **NEW**: UX design decisions + one round of device-triggered flow iteration; budget ~0.20d hidden overhead beyond commit estimate; analogous to external design tool time (0.2.3: #121) |
| Bug (platform/permission, new packages required) | 1 issue | 2.27x* | 2.0-2.5x* | **NEW (0.2.4 methodology)**: SAF + new packages + platform testing; estimate at 3–5 pts at current velocity (6.5 pts/day); 2 pts implies 0.31d but actual ~0.70d (0.2.4: #354) |
| Feature (model+UI, within-sprint dependency — same-session follow-on) | 1 issue | 0.49x* | ~0.5x* | **NEW (0.2.4 methodology)**: Enabler ships same day → full working memory load; estimate follow-on at 1 pt; MarkdownBody fully loaded → story field nearly free (0.2.4: #326 after #321) |
| UX bug cluster (individually ticketed, discovered in-context) | 4 issues | 0.24x* | 0.2-0.3x* | **NEW (0.2.4 methodology)**: In-context discovery while code is warm; individual ticketing inflates pts (6pts actual ≈ 3pt bundle); batch on one session (0.2.4: #360–#363) |

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

**Key Insights from 0.1.9:**
- **UX simplification/redesign has distinct velocity** — 0.34x ratio when pre-designed, thematically coherent, and deletion-heavy
- **Net code deletion signals fast execution** — sprint deleted 1,026 more lines than it added; simplification is faster than creation
- **Mono-theme sprints with natural sequencing are faster** — all 3 issues shared the meal planning area; color system → components → flow
- **Linked issues estimated separately overstate work** — #277 (5 pts) absorbed by #280 at zero marginal cost; #288 (3 pts) made irrelevant
- **Velocity step-change is real** — 3 consecutive sprints (0.1.7b-0.1.9) at 32-36 pts/week; driven by codebase maturity, Claude Code, and accumulated infrastructure

**Key Insights from 0.1.10:**
- **Pre-sprint scope discipline is as powerful as execution skill** — selecting 13 of 32 available points enabled clean 2-day execution; the deferred 19 points (#292, #263, #268, #285) would have diluted focus without user-facing benefit
- **Planning day investment (no commits) pays for itself in execution clarity** — Feb 16 produced no code but eliminated all scope questions for Feb 17–18
- **Anchor feature needs its own uninterrupted day** — #134 solo on Feb 17 completed design → implementation → test in one flow session
- **Same-domain batch day reliably executes at 0.10-0.13x** — three issues sharing the ingredient/shopping layer completed together at 0.13x average

**Key Insights from 0.1.11:**
- **"Real-life QA sprint" is a repeatable sprint type** — intensive personal app usage (2 days) → clear issue discovery → batch fix execution; expect 0.15-0.25x, ~28 pts/week
- **Post-usage bugs execute at 0.10x regardless of point estimate** — root cause is known before the editor opens; #300 (3 pts) + #301 (5 pts) + #298 (2 pts) all at 0.10x
- **App usage days are a specification phase, not idle time** — Feb 19–20 with zero commits produced the clearest possible issue specs for Feb 21 and 24 execution
- **Idempotent migrations are a non-negotiable baseline** — add to migration definition of done; e2e tests are the safety net that catches violations

**Key Insights from 0.1.13:**
- **Within-sprint pattern compounding is the fastest reuse mode** — #312 (3 pts) completed in 45 minutes because #311's dialog pattern was built 3 days earlier in the same sprint; the pattern was fully loaded in working memory; sequence related dialog features back-to-back deliberately
- **Display-only work needs its own calibration bucket** — #314 (0.10x) was fast not from pattern reuse but from inherent simplicity: no input, no state machine, no validation; estimating display-only at the same level as form work overestimates by 30–50%
- **L-size issues with a clear template execute at ~0.13x** — #311 (8 pts, 2 new DB tables, 2 models, CRUD, 2 screens, shopping list) delivered in 1 day; don't over-buffer L issues when the junction table/model pattern is already established
- **Windows Defender is a Windows-specific release-phase risk** — Dart network access silently blocked during release; same category as adb/AS friction in 0.1.5 and 0.1.8; add firewall exceptions to new-machine checklist

**Key Insights from 0.1.12:**
- **Validation debt is a distinct failure mode from scope creep** — sprint closed 100% of points but generated 3 follow-up issues (#313-#315); fast execution through a chain without device testing creates deferred work, not completed work
- **Device validation gates belong in acceptance criteria** — if "tested on device" isn't an explicit AC item, it will be skipped under time pressure; add it as a non-optional gate for any data-facing feature
- **Dependency chains have diminishing complexity** — anchor issue (#304, 0.22x) sets the pattern; follow-on issues (#305, #306) execute at ~0.16x by reusing it; discount 2nd+ chain issues 30-50% at estimation time
- **UI micro-issues are uncalibrateable at 1pt floor** — #309 and #310 both at 0.05x regardless of 2pt/1pt estimates; bundle one-liner tasks as a flat "quick wins block" (0.5pt per set)
- **Pre-sprint planning/testing day is standard overhead** — confirmed in 0.1.10 (Feb 16) and 0.1.12 (Feb 26); budget +0.5d as a planned investment, not lost time

**Key Insights from 0.1.14:**
- **Zero-features housekeeping sprints close cleanly when scope was pre-validated** — all 5 issues were deferred from 0.1.10 with clear acceptance criteria; no discovery, no emergent complexity, straight execution
- **"Must be last" sequencing constraint is correct for governance issues** — #285 (test governance) captured test counts from all other issues in the milestone; done earlier, it would have been stale immediately
- **Migration consolidation is permanent, high-leverage simplification** — eliminating 12+ fragmented migration files gives every future migration a clean baseline; do it before adding more migrations, not after
- **One focused housekeeping sprint outperforms spreading quality work across feature sprints** — dedicated sprint finishes all internal obligations cleanly; interleaved housekeeping dilutes feature sprint focus

**Key Insights from 0.2.2:**
- **Parser/algorithm bug clusters have their own velocity profile** — when ≥2 bugs share the same root cause domain, the first fix establishes a template; subsequent are adaptations; batch on same day and discount 40–50% for 2nd+ at estimation time
- **"Committed ≠ validated" confirmed again** — 0.1.12 (servings chain) and 0.2.2 (#341) both show the same failure: fast execution → shipped without device testing → downstream issues; device validation is a non-optional gate for any ordering or display-logic fix
- **L10n-generated files are a known retrospective analysis distortion** — `app_localizations.dart` inflation can make a simple 1pt fix appear 3× slower than it was; exclude generated files from line counts before attributing high ratios to simple issues
- **External design tool time (Recraft, Figma) leaves no commit trace** — account explicitly in effective-day calculation during retrospective; treat same as adb friction or planning-only days

**Key Insights from 0.1.15:**
- **Real seed data is a distinct integration test category** — 0.2.1's first real recipe dataset exposed two P0 import bugs that existed undetected through 50+ sprints; synthetic fixtures don't stress relationship cascade behavior the same way
- **Two P0 bugs in the same subsystem signals structural coverage gaps, not bad luck** — if one area generates multiple P0s simultaneously, the test coverage for that area is architecturally insufficient; fix + audit, don't just fix
- **Import/export subsystems need full relational data in tests** — meals with history, plan relationships, instructions; any test that only exercises single-entity import misses the failure modes that matter
- **Emergency P0 patches execute at the 0.10x post-usage-bug rate** — root cause was clear from the import code path; no debugging phase, direct fix; consistent with 0.1.11's post-usage bug pattern

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
| 0.1.4 | 12 | 2 | 6.00 | 30.0 | Well-prepared work, early sign of acceleration |
| 0.1.5 | 14 | 6.88 | 2.03 | 10.2 | Discovery + iteration + MASSIVE overhead (29%) |
| 0.1.6 | 18 | 6 | 3.00 | 15.0 | Well-specified features |
| 0.1.7a | 21 | ~0.5* | ~42* | —* | **UNRELIABLE** (shared day, methodology breaks down) |
| 0.1.7b | 43 | 6.69 | 6.43 | 32.1 | Design system application + efficient batching |
| 0.1.8 | 25 | 3.5 | 7.14 | 35.7 | Small UX fixes + pattern-extension testing |
| 0.1.9 | 18 | 2 | 9.00 | 36.0 | UX simplification, mono-theme, extended hours |
| 0.1.10 | 13 | 2 | 6.50 | 32.5 | Pre-sprint scope clarity, anchor feature day, same-domain batch |
| 0.1.11 | 14 | 2.5 | 5.60 | 28.0 | Real-life QA sprint: usage discovery + batch fix |
| 0.1.12 | 17 | 3.3 | 5.15 | 28.3 | Servings chain + UX polish; validation debt to #313-#315 |
| 0.1.13 | 21 | ~2.7 | ~7.8 | ~30.0 | Within-sprint pattern compounding; L-size arch with clear template; validation debt repaid |
| 0.1.14 | ~21 | ~4.0 | ~5.25 | ~26.3 | Zero-features housekeeping sprint (retroactive; no commit-level data) |
| 0.1.15 | — | ~1.0 | — | — | Emergency P0 patch (not a regular sprint; excluded from velocity calculations) |
| 0.2.2 | 24 | ~3.8 | ~6.3 | ~31.5 | Algorithm tuning + parser bug batch; #341 incomplete (validation debt) |
| 0.2.3 | 33 | ~3.4 | ~9.7 | ~48.5 | Execution-mode sprint: bug batch + UX features + P1 feature; 3 working days |
| 0.2.4 | 30 | ~4.0 | ~7.5 | ~37.5 | Dependency chains, holiday-interrupted week (4 days); stretch goal delivered |

*\* 0.1.7a excluded from velocity calculations — shared day with 0.1.7b makes weighted-days unreliable.*
*0.1.15 excluded from velocity calculations — emergency patch, not a regular sprint.*

**Cruising Velocity: 30 points/week** — validated across 0.1.7b–0.2.4 (10 consecutive sprints at 26-48 pts/week).

**Velocity Modes:**
- **Discovery mode:** ~20 pts/week (new patterns, complex features, tooling overhead)
- **Cruising mode:** ~30 pts/week (mixed work, sustainable pace)
- **Execution mode:** ~36 pts/week (small fixes, pattern reuse, deep focus)

### Milestone Sizing Recommendations

**Primary metric: 30 points/week cruising velocity**

| Sprint Length | Conservative | Cruising | Aggressive |
|---------------|:-----------:|:--------:|:----------:|
| 1 week (5 days) | 20 pts | 30 pts | 36 pts |
| 2 weeks (10 days) | 40 pts | 60 pts | 72 pts |

### Adjustment Factors

**Use Aggressive (~36 pts/week) if:**
- All work is well-prepared with prerequisites completed
- Issues are similar and can be batched
- Extending existing patterns (not creating new ones)
- Sprint dominated by small fixes or mechanical work

**Use Conservative (~20 pts/week) if:**
- Work involves discovery or research
- New infrastructure or patterns needed
- UI polish requiring iteration and feedback
- External service integrations
- Mobile/UI work with potential tooling issues

**Critical Rules:**
1. **Use 30 pts/week as default** for milestone sizing
2. **Adjust by sprint profile** — discovery (20), cruising (30), execution (36)
3. **Add 25-35% overhead buffer** for mobile/UI sprints with testing phases
4. **Budget 20-30% for emergent work** — healthy UX feedback and TODO cleanup
5. **Review velocity after each sprint** — validate the 30 pts/week target
6. **0.1.5 remains the only overrun** — discovery + hidden overhead; budget extra for discovery-heavy sprints

### Examples

**Standard Milestone (1 week, 30 points):**
- 2x M-sized features (5 points each) = 10 points
- 2x S-sized features (3 points each) = 6 points
- 2x L-sized features (5 points each) = 10 points
- 2x bug fixes (2 points each) = 4 points
- At cruising velocity: 30 pts / 1 week ✅

**Discovery-Heavy Milestone (1 week, 20 points):**
- 1x L-sized feature with discovery (8 points)
- 1x M-sized testing infra (5 points)
- 1x M-sized feature (5 points)
- 1x S-sized bug fix (2 points)
- At conservative velocity: 20 pts / 1 week ✅

**Execution Sprint (1 week, 36 points):**
- 10x small UX fixes (1-2 points each) = 15 points
- 3x testing extensions (5 points each) = 15 points
- 1x refactor (3 points) + 1x bug fix (3 points) = 6 points
- At aggressive velocity: 36 pts / 1 week ✅ (only if pure execution)

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
- **2026-02-16**: Added 0.1.9 retrospective analysis
  - Sprint completed: 3 planned issues (18 points) in 2 active days (1.41 weighted days, 0.34x ratio)
  - #277 absorbed by #280, #288 closed as won't do — zero separate effort for both
  - All UX simplification work — net deletion of 1,026 lines
  - New calibration factor: UX redesign/simplification (0.34x, recommend 0.3-0.5x)
  - **KEY: Velocity step-change confirmed** — 3 consecutive sprints (0.1.7b-0.1.9) at 32-36 pts/week; not outliers but sustained acceleration
  - **Cruising velocity revised upward to 30 pts/week** (from 20), with discovery at 20 and execution at 36
  - Drivers: codebase maturity, Claude Code acceleration, accumulated infrastructure, developer proficiency
  - Removed "outlier" labels from 0.1.4, 0.1.7b, 0.1.8 — reframed as part of acceleration trend
  - 0.1.7a remains flagged as unreliable data (shared day methodology issue)
  - Updated all milestone sizing guidelines and velocity reference data
  - Fixed `scripts/gh-project-issue.sh` limit from 200 to 500 (project now has 266+ items)
- **2026-02-25**: Added 0.1.10 and 0.1.11 retrospective analyses (combined — 0.1.10 review was missed at release time)
  - 0.1.10 completed: 4 issues (13 points) in 2 active days (2.00 weighted days, 0.15x ratio)
  - Scope discipline: selected 13 of 32 available points; deferred #292, #263, #268, #285 intentionally
  - Planning day (Feb 16, no commits) structured clean 2-day execution
  - New pattern: anchor feature solo day + same-domain batch day = most efficient feature sprint structure
  - 0.1.11 completed: 6 planned issues (14 points) + ~4 unplanned in 3 active days (2.50 weighted days, 0.18x ratio)
  - **NEW SPRINT TYPE: "Real-life QA sprint"** — intensive app usage (Feb 19-20) → issue discovery → batch fix execution
  - Post-usage bugs executed at 0.10x across all three bug issues (#298, #300, #301)
  - New calibration factor: post-usage bug fixes (0.10x, flat rate regardless of estimate)
  - Idempotent migrations identified as non-negotiable baseline; added to definition of done recommendation
- **2026-03-03**: Added 0.1.12 retrospective analysis
  - Sprint completed: 7 planned issues (17 points) + 1 unplanned commit in 3.5 effective days
  - Actual ratio: 0.17x (execution-mode sprint, consistent with 0.1.11)
  - Cruising velocity (30 pts/week) confirmed for 6th consecutive sprint (0.1.7b–0.1.12)
  - **NEW PATTERN: "Validation debt"** — fast execution through dependency chain (#304→#305→#306) deferred device testing, generating follow-up issues #313, #314, #315; completion rate ≠ feature completeness
  - **NEW RULE: Device validation gates in AC** — "✓ Tested on device" must be explicit AC for data-facing features
  - New calibration: dependency chain diminishing complexity (anchor at 0.22x, follow-on at 0.16x; discount 2nd+ issues 30-50%)
  - New calibration: UI micro-issues < 30 lines → bundle as flat 0.5pt quick wins block; expect 0.05x
  - Pre-sprint planning/testing day confirmed as standard 0.5d overhead (0.1.10 + 0.1.12)
  - Cruising velocity (30 pts/week) validated across 5 consecutive sprints (0.1.7b–0.1.11)
- **2026-04-09**: Added 0.1.14 and 0.1.15 retrospective entries (post-hoc captures; no real-time tracking for either milestone)
  - 0.1.14 completed: 5 issues (~21 pts) in ~4 active days (Mar 20–25); zero-features housekeeping sprint: migration consolidation (#292), skills/docs (#268, #263), e2e test fix (#318), test governance (#285)
  - 0.1.15 completed: 2 P0-Critical import bugs (#330, #332) in ~1 day (Apr 5); emergency patch discovered via 0.2.1 seed data
  - **NEW PATTERN: "Zero-features housekeeping sprint"** — all internal obligations batched into one sprint; deferred issues execute cleanly when pre-validated; ~0.19x ratio
  - **NEW INSIGHT: "Real seed data as integration test category"** — import bugs invisible through 50+ sprints of synthetic-fixture testing; surfaced only with full relational data from 0.2.1 seed content
  - **NEW RULE: Import integration tests must include full relational data** — meals, history, plans, instructions; prerequisite for 0.2.8 (Import & Remaining UX)
  - New calibration factors: zero-features housekeeping sprint (~0.19x), emergency P0 patch (~0.10x)
  - Updated velocity reference table (added 0.1.13, 0.1.14; excluded 0.1.15 as non-regular sprint)
  - Cruising velocity extended: validated across 0.1.7b–0.1.14 (7 consecutive sprints at 26-36 pts/week)
- **2026-04-16**: 0.2.3 sprint started; pre-sprint investigation session
  - Sprint plan created: `docs/planning/sprints/sprint-planning-0.2.3.md` (33 pts, 11 issues, ~6 days at cruising velocity)
  - **Investigation finding: `MealCookedDialog` was dead code** — never called anywhere; deleted widget + 7 tests
  - **#352 closed as misidentified** — `MealRecordingDialog` already handles `cooked_at = plannedDate` correctly
  - **New test file: `test/database/meal_ordering_test.dart`** — 6 real-SQLite integration tests covering weekly plan path (slot midnight) and cook_meal_screen path (recording timestamp); confirms current query correct for primary flow
  - **#351 applied** — `date(cooked_at)` fix in 3 queries; confirmed necessary only for `cook_meal_screen` path but applied as defensive hardening
  - **#345 applied** — unit strings localized at 3 sites; confirmed all 20 `MeasurementUnit` values translated in `app_pt.arb`
  - **NEW INSIGHT: Mock ordering is vacuous** — `MockDatabaseHelper.getRecentMeals` sorts by `cookedAt` only, no CASE clause; real SQLite integration tests are the only reliable check for ordering correctness
  - **NEW RULE: Always create feature branch before coding** — two commits went directly to develop before the rule was flagged; enforced from #351 onwards
  - **#339 applied** — added `textOnDisabled` (white) token; `disabledForegroundColor` in `ElevatedButtonThemeData` was identical to `disabledBackgroundColor` (#A8A29E), causing zero contrast; fix is app-wide
  - **#340 applied** — wrapped `AddSimpleSideDialog` content column in `SingleChildScrollView`; suggestions list overflow was displacing the actions area; added 7 widget tests covering layout, button states, and return values
  - **Root-cause pattern**: #339 and #340 were in the same dialog (same file, same branch) — batched correctly; 2 pts each, executed at ~0.10x combined
- **2026-04-15**: Added 0.2.2 retrospective analysis
  - Sprint completed: 9 of 10 adjusted issues (24 confirmed pts); #341 committed but unvalidated on device
  - Effective ratio: ~0.11x (~2.7d tracked / ~3.8d effective); ~31.5 pts/week — cruising range
  - Key finding: parser bug cluster (#342–#344, 11 pts, 0.08x avg) confirms root-cause-batch pattern; #341 shipped as validation debt (→ #351, #352)
  - New calibration factors: parser/algorithm same-root-cause cluster (0.08–0.10x); testing new algorithm behavior (0.20–0.30x)
  - Retrospective methodology note: l10n-generated files (`app_localizations.dart`) inflate line-count proportional allocation; exclude from real-effort line counts
  - Critical insight reinforced: "Committed ≠ validated" — same failure mode as 0.1.12; device validation is a non-optional AC gate for ordering/display fixes
  - Cruising velocity extended: validated across 0.1.7b–0.2.2 (8 consecutive sprints at 26-36 pts/week)
