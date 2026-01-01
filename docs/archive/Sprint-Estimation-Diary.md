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
python scripts/analyze_sprint_commits.py --since YYYY-MM-DD --branch develop

# With end date (for completed sprints)
python scripts/analyze_sprint_commits.py --since 2025-12-02 --until 2025-12-17 --branch develop

# Focus on specific issues only
python scripts/analyze_sprint_commits.py --since 2025-12-02 --issues "223,228,124"
```

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

---

## Cumulative Metrics

### Estimation Accuracy Trend

| Sprint | Planned Points | Weighted Actual | Ratio | Trend |
|--------|----------------|-----------------|-------|-------|
| 0.1.2 | 12.2 | ~11 | 0.90x | Baseline (slightly conservative) |
| 0.1.3 | 26 | 10.0 | 0.38x | VERY conservative (major underestimate of velocity) |
| 0.1.4 | 12 | TBD | TBD | - |

### Type-Based Calibration Factors

Use these multipliers when estimating future work:

| Type | Sample Size | Avg Ratio | Recommended Multiplier | Notes |
|------|-------------|-----------|------------------------|-------|
| Bug fixes | 2 issues | 0.62x | 1.0x | Conservative (0.1.2) |
| UI/Features | 5 issues | 0.56x | 0.6-0.7x | Very conservative (0.1.2: 0.84x, 0.1.3: 0.40x) |
| Parser/Algorithm | 2 issues | 0.21x | 0.5x | Very efficient (0.1.2) |
| Architecture | 5 issues | 0.40x | 0.5x | Very efficient when batched (0.1.3) |
| Testing (existing patterns) | 3 issues | 0.62x | 1.0x | Conservative (0.1.2) |
| Testing (new infra) | 5 issues | 1.27x | 1.0-1.5x | **REVISED**: 0.1.2 was outlier (4.00x), 0.1.3 averaged 0.51x |
| Testing (related tasks) | 2 issues | 0.31x | 0.3-0.5x | Extremely efficient when done together (0.1.3: #38+#39) |

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
