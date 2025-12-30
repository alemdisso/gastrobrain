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

---

## Cumulative Metrics

### Estimation Accuracy Trend

| Sprint | Planned Days | Weighted Actual | Ratio | Trend |
|--------|--------------|-----------------|-------|-------|
| 0.1.2 | 12.2 | ~11 | 0.90x | Baseline (slightly conservative) |
| 0.1.3 | TBD | TBD | TBD | - |
| 0.1.4 | TBD | TBD | TBD | - |

### Type-Based Calibration Factors

Use these multipliers when estimating future work:

| Type | Sample Size | Avg Ratio | Recommended Multiplier |
|------|-------------|-----------|------------------------|
| Bug fixes | 2 issues | 0.62x | 1.0x (estimates are conservative) |
| UI/Features | 3 issues | 0.84x | 1.0x (estimates are good) |
| Parser/Algorithm | 2 issues | 0.21x | 0.5x (very efficient, can reduce) |
| Testing (existing patterns) | 3 issues | 0.62x | 1.0x (estimates are conservative) |
| Testing (new infra) | 1 issue | 4.00x | 2.0-3.0x (main risk area) |

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
