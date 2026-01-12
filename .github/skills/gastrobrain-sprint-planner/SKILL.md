---
name: "Gastrobrain Sprint Planner"
description: "Data-driven sprint planning for Gastrobrain using GitHub Project #3 issues, historical velocity patterns, and sprint estimation diary insights. Generates realistic sprint plans with capacity analysis, sequencing strategy, and risk assessment for solo Flutter development with comprehensive testing requirements."
version: "1.0.0"
author: "Gastrobrain Development Team"
---

# Gastrobrain Sprint Planner

A specialized skill for planning development sprints for the Gastrobrain Flutter application using historical velocity data, GitHub Projects issue tracking, and lessons learned from the Sprint Estimation Diary.

## When to Use This Skill

Use this skill when:
- Planning a new sprint or release cycle
- Evaluating sprint capacity and feasibility
- Sequencing issues for optimal implementation flow
- Assessing risks in upcoming work
- Calibrating estimates based on historical performance
- Creating a day-by-day sprint breakdown
- Aligning sprint goals with milestone themes

**Do NOT use this skill for:**
- Individual issue estimation (use your judgment based on patterns)
- Post-sprint retrospectives (use sprint diary analysis instead)
- Long-term roadmap planning (use milestone planning instead)

## Project Context

### Development Environment
- **Project**: Gastrobrain - Flutter meal planning & recipe management app
- **Database**: SQLite with comprehensive data models
- **Localization**: Bilingual (English, Portuguese-BR) - all features require l10n
- **Testing**: 600+ tests (unit, widget, integration, E2E) - non-negotiable requirement
- **Issue Tracking**: GitHub Projects (Project #3) with story points estimation
- **Workflow**: Git Flow (develop → release/X.X.X → master with tags)
- **Team**: Solo developer (no coordination overhead, but no parallel work)

### Story Point Scale
Fibonacci-like scale: **1, 2, 3, 5, 8, 13**
- **1 point**: Trivial fix, <1 hour, well-understood pattern
- **2 points**: Simple feature, ~2-3 hours, minor testing
- **3 points**: Standard feature, ~4-6 hours, widget tests required
- **5 points**: Complex feature, ~1 day, full testing suite
- **8 points**: Major feature, ~2 days, architecture changes
- **13 points**: Epic-level work, ~3+ days, significant complexity

### Size Labels (GitHub)
- **XS**: 1-2 points
- **S**: 3 points
- **M**: 5 points
- **L**: 8 points
- **XL**: 13+ points

## Sprint Planning Process

Follow this systematic approach:

### 1. Gather Issue Data
```bash
# Use gh CLI to fetch issues from Project #3
gh issue list --project 3 --state open --json number,title,labels,milestone
```

For each issue, extract:
- Issue number and title
- Story point estimate (from labels or title)
- Size label (XS/S/M/L/XL)
- Type (feature, bug, refactor, testing, UI/UX)
- Milestone assignment
- Dependencies (mentioned in issue body)
- Prerequisites (is prerequisite work complete?)

### 2. Analyze Sprint History Context
Review recent sprints from `docs/workflows/Sprint-Estimation-Diary.md`:

**Sprint 0.1.2** (12.2 points → ~11 days, 0.90x ratio):
- Mixed work (architecture, testing, UI)
- Database model changes added overhead
- Discovery work increased effort

**Sprint 0.1.3** (26 points → 10 days, 0.38x ratio):
- Pattern reuse accelerated delivery
- Batched similar work (all testing infrastructure)
- Well-prepared with clear requirements

**Sprint 0.1.4** (12 points → 2 days, 0.17x ratio):
- **OUTLIER**: Prerequisites complete, pure execution
- Well-prepared work, established patterns
- **Do NOT use as baseline** - atypical conditions

**Sprint 0.1.5** (14 points → 6.88 days, 1.98x ratio):
- Hidden overhead from mobile tooling (adb, Android Studio)
- Discovery work (UI iteration, user feedback)
- Database migration complexity underestimated

### 3. Apply Velocity Calibration
**Normal Velocity Range**: 1.1 - 2.8 points/day
- **Conservative estimate**: 2.0 points/day
- **Median estimate**: 2.5 points/day
- **Optimistic estimate**: 2.8 points/day (only if well-prepared)

**DO NOT use Sprint 0.1.4's 6.0 points/day** - it was an outlier with ideal conditions.

### 4. Group and Sequence Issues
Group by:
- **Type**: Feature, bug, refactor, testing, UI/UX, docs
- **Theme**: Related functionality (e.g., all meal planning features)
- **Dependencies**: What blocks what
- **Similarity**: Batch similar work for efficiency

### 5. Calculate Sprint Capacity
**For a 5-day sprint:**
- **Conservative**: 10-12 points (recommended for new features, UI work)
- **Normal**: 12-15 points (established patterns, backend work)
- **Aggressive**: 15-18 points (only if purely extending patterns, no discovery)

**Adjust for work type** (see Velocity Calibration section below)

### 6. Perform Risk Assessment
Flag issues with:
- Incomplete prerequisites
- Hidden overhead potential (UI iteration, mobile tooling)
- Discovery work (new patterns, unclear requirements)
- Database migrations or model changes
- External dependencies (APIs, third-party libraries)
- Testing infrastructure work (vs extending patterns)

### 7. Generate Sprint Plan
Use the template at `templates/sprint_plan_template.md` to create:
- Sprint header (number, theme, dates, capacity)
- Sprint goal (2-3 sentences)
- Issues grouped by theme
- Day-by-day breakdown
- Risk assessment
- Testing strategy
- Success criteria

## Sprint History Insights

Key lessons from `docs/workflows/Sprint-Estimation-Diary.md`:

### Pattern Reuse Acceleration
**Effect**: 2.5-5x faster than original estimate when reusing patterns
**Indicators**: "Extend existing test infrastructure", "Follow pattern from X"
**Example**: Sprint 0.1.3 testing work (0.38x ratio)
**Action**: Reduce estimates by 60-80% if purely extending patterns

### Hidden Mobile/UI Overhead
**Effect**: 25-35% additional time for tooling, iteration, feedback
**Indicators**: UI polish, mobile-specific features, user-facing screens
**Example**: Sprint 0.1.5 UI iteration (1.98x ratio)
**Action**: Add 1.3-1.5x buffer to UI/mobile estimates

### Well-Prepared vs Discovery Work
**Well-prepared** (0.2-0.3x ratio):
- Prerequisites complete
- Clear requirements
- Established patterns
- Known implementation path

**Discovery work** (1.5-2.0x ratio):
- Unclear requirements
- New patterns needed
- Architecture decisions required
- External dependencies

**Action**: Distinguish implementation effort from discovery overhead

### Bug Fix Patterns
**Known pattern bugs** (0.1-0.2x ratio):
- Clear reproduction steps
- Known root cause
- Familiar code area

**Exploratory bugs** (1.0-1.5x ratio):
- Unclear reproduction
- Unknown root cause
- Multiple potential causes

### Testing Work Categorization
**Extend patterns** (0.2-0.4x ratio):
- Use existing test helpers
- Follow established structure
- Similar to existing tests

**New infrastructure** (1.0-1.5x ratio):
- Create new test patterns
- Build new helpers/fixtures
- Establish new conventions

### Database Migration Complexity
**Simple migrations** (no overhead):
- Add columns with defaults
- Add new tables (no foreign keys)

**Complex migrations** (1.5-2.0x buffer):
- Schema restructuring
- Data migration logic
- Foreign key changes
- Junction table modifications

### Batching Benefits
**Effect**: 20-30% efficiency gain when batching similar work
**Examples**:
- All testing work together
- All UI screens together
- All database changes together
**Action**: Sequence related tasks consecutively

## Velocity Calibration

### Type-Specific Multipliers

Apply these multipliers to story point estimates to get realistic effort:

#### Bug Fixes
- **Known pattern bugs**: 0.1-0.2x (quick fixes with clear path)
- **Exploratory bugs**: 1.0-1.5x (investigation required)
- **Regression bugs**: 0.5-0.8x (code area is familiar)

#### UI/UX Work
- **Backend logic only**: 1.0x (use estimate as-is)
- **UI with existing patterns**: 1.2-1.5x (widget building + testing)
- **UI polish/iteration**: 3.0-4.0x (feedback loops, mobile tooling overhead)
- **New UI patterns**: 2.0-3.0x (design + implementation + testing)

#### Testing Work
- **Extend existing patterns**: 0.2-0.4x (fast, well-understood)
- **New test infrastructure**: 1.0-1.5x (pattern creation overhead)
- **Edge case coverage**: 0.5-0.8x (systematic but tedious)
- **E2E/integration tests**: 1.5-2.0x (setup complexity, flakiness)

#### Architecture/Refactoring
- **Well-prepared refactor**: 0.2-0.3x (clear plan, prerequisites done)
- **Exploratory refactor**: 1.5-2.0x (requires analysis and design)
- **Pattern extraction**: 0.8-1.2x (mechanical but careful)

#### Feature Implementation
- **Established patterns**: 0.8-1.0x (straightforward implementation)
- **New patterns**: 1.2-1.8x (design decisions required)
- **With discovery**: 1.5-2.5x (unclear requirements, iteration)

#### Database Work
- **Simple migrations**: 1.0x (use estimate)
- **Complex migrations**: 1.5-2.0x (data migration, schema changes)
- **Model changes**: 1.2-1.5x (cascade to services, tests)

### Overhead Adjustments

**Add these to base estimate:**

#### Mobile Tooling Overhead
- **Backend-only sprint**: 0% overhead
- **Widget tests only**: 5-10% overhead (basic Flutter test tooling)
- **UI iteration sprint**: 25-35% overhead (adb, device testing, Android Studio)
- **Mobile-specific features**: 20-30% overhead (platform channels, permissions)

#### Localization Overhead
- **Backend work**: 0% (no user-facing strings)
- **New UI screens**: 10-15% (ARB file updates, translation)
- **Error messages**: 5-10% (localization testing)

#### Testing Overhead
- **Unit tests only**: 20-30% of implementation estimate
- **Widget tests**: 40-60% of implementation estimate
- **Integration tests**: 60-80% of implementation estimate
- **E2E tests**: 80-100% of implementation estimate
- **Edge case coverage**: 30-50% additional (per Issue #39 standards)

#### Documentation Overhead
- **Code comments**: 5% of implementation estimate
- **Architecture docs**: 15-20% of implementation estimate
- **API documentation**: 10-15% of implementation estimate

### Sprint Capacity Adjustment Formula

```
Base Capacity = Available Days × Median Velocity (2.5 points/day)

Adjusted Capacity = Base Capacity × (1 - Overhead %) × Work Type Multiplier

Example (5-day sprint, UI-heavy):
Base = 5 × 2.5 = 12.5 points
Overhead = 30% (mobile tooling)
Multiplier = 1.3 (UI iteration average)

Adjusted = 12.5 × 0.7 × 1.3 ≈ 11.4 points

Conservative Target: 10-11 points
```

## Sprint Capacity Guidelines

### Conservative Planning (Recommended)
**10-12 points per 5-day sprint**
- Use when: New patterns, UI work, discovery required
- Risk: Low (high confidence of completion)
- Buffer: 20-30% slack for unknowns
- Best for: Feature sprints, UI polish, new architecture

### Normal Planning
**12-15 points per 5-day sprint**
- Use when: Established patterns, backend work, clear requirements
- Risk: Medium (likely completion with focus)
- Buffer: 10-15% slack
- Best for: Bug fix sprints, pattern extension, refactoring

### Aggressive Planning (Use Sparingly)
**15-18 points per 5-day sprint**
- Use when: Pure execution, prerequisites complete, simple patterns
- Risk: High (requires ideal conditions)
- Buffer: <10% slack
- Best for: Well-prepared work only (rare)
- **Warning**: Only 1 historical sprint achieved this (0.1.4 outlier)

### Capacity Red Flags

**Overcommitment Warning** if:
- Total points > 18 for 5-day sprint (unrealistic)
- >50% of points in UI/discovery work without buffer
- Multiple database migrations in one sprint
- New testing infrastructure + feature work combined
- >3 unrelated themes (context switching overhead)

**Undercommitment Warning** if:
- Total points < 8 for 5-day sprint (may lose momentum)
- All bug fixes with known patterns (consider adding features)
- Missing testing work (did you forget to account for it?)

## Implementation Sequencing Strategy

### Optimal Sequencing Pattern

**Day 1-2: Quick Wins & Prerequisites**
- Start with 1-2 point bugs (build momentum)
- Complete blocking/prerequisite work
- Set up test infrastructure if needed
- Database migrations (get them done early)

**Day 2-3: Main Features**
- Tackle highest-value features when context is fresh
- Batch similar work together (all UI, all backend, all testing)
- Use momentum from quick wins

**Day 4: Integration & Testing**
- Widget tests for features built earlier
- Integration tests across components
- Edge case coverage

**Day 5: Polish & Flex**
- UI polish and iteration
- Documentation updates
- Stretch goals (optional work that can be cut)
- Open-ended work like edge case coverage (Issue #39)

### Sequencing Principles

#### 1. Dependencies First
- Complete blocking work before dependent work
- Database migrations before features using new schema
- Test infrastructure before tests using it
- Service layer before UI using it

#### 2. Batch Similar Work
**Efficiency gain: 20-30%**
- Group all testing work together (shared context)
- Group all UI work together (design decisions consistent)
- Group all database work together (migration planning)
- Group all refactoring together (architectural mindset)

#### 3. Risk Management
- High-risk items in Days 2-3 (time to recover if problems)
- Low-risk items in Days 1 or 5 (flexible timing)
- Discovery work early (inform later decisions)
- Polish work late (can be deferred if needed)

#### 4. Context Preservation
- Keep related features consecutive (avoid context switching)
- Finish one theme before starting another
- Complete feature + tests together (not separated)

#### 5. Energy Management
- Hardest problems when fresh (Days 2-3)
- Mechanical work when tired (Day 5 polish)
- Testing work mid-sprint (requires focus but not creativity)

### Anti-Patterns to Avoid

**Don't:**
- Scatter related work across the sprint (context switching)
- Put discovery work at end (no time to recover)
- Mix database migrations throughout (migration hell)
- Alternate between UI and backend daily (inefficient)
- Save all testing for Day 5 (rush job, poor quality)
- Start with hardest problem (risk momentum loss)

### Example Sequencing

**Bad Sequencing:**
```
Day 1: Feature A (backend)
Day 2: Feature B (UI), Bug C (backend)
Day 3: Tests for Feature A, Feature D (UI)
Day 4: Tests for Feature B, Bug E (database)
Day 5: Tests for Feature D, Database migration
```
*Issues: Constant context switching, migration too late, testing scattered*

**Good Sequencing:**
```
Day 1: Bug C (backend, 2pts), Bug E (database, 1pt), DB migration (1pt)
Day 2: Feature A (backend, 5pts)
Day 3: Feature A tests (3pts), Feature D (UI, 3pts)
Day 4: Feature B (UI, 5pts), Feature B tests (3pts)
Day 5: Feature D tests (2pts), UI polish (flex)
```
*Benefits: Bugs first (momentum), migration early, batched testing, related UI together*

## Risk Assessment Framework

### Risk Categories

#### High Risk
**Indicators:**
- Unclear requirements or acceptance criteria
- No similar prior work (new patterns)
- External dependencies (APIs, libraries, third-party services)
- Database schema restructuring (not just additions)
- Multiple teams/systems involved (rare for Gastrobrain)
- Significant architecture changes

**Mitigation:**
- Add 50-100% time buffer
- Schedule discovery spike before implementation
- Break into smaller, iterative deliverables
- Plan for multiple iteration cycles
- Consider descoping to reduce risk

#### Medium Risk
**Indicators:**
- Some prior work but variations needed
- UI work with iteration expected
- Integration between existing components
- Testing infrastructure for new patterns
- Mobile-specific features (tooling overhead)
- Localization for complex UI

**Mitigation:**
- Add 25-50% time buffer
- Schedule in middle of sprint (time to recover)
- Plan for one iteration cycle
- Allocate time for tooling issues

#### Low Risk
**Indicators:**
- Established patterns (done similar work recently)
- Clear requirements and acceptance criteria
- No external dependencies
- Purely extending existing code
- Backend logic only (no UI)
- Known bug patterns

**Mitigation:**
- Minimal buffer (10-15%)
- Can schedule at sprint start or end
- Good for quick wins

### Risk Identification Checklist

For each issue, ask:

**Requirements Clarity:**
- [ ] Are acceptance criteria clear and specific?
- [ ] Are edge cases documented?
- [ ] Are design decisions already made?
- [ ] Is the "definition of done" explicit?

**Technical Clarity:**
- [ ] Is the implementation approach known?
- [ ] Have we done similar work before?
- [ ] Are all dependencies identified?
- [ ] Are there known technical challenges?

**Dependency Assessment:**
- [ ] Are prerequisites complete?
- [ ] Are external dependencies available?
- [ ] Are blocking issues resolved?
- [ ] Is the codebase in a stable state?

**Overhead Identification:**
- [ ] Does this involve mobile tooling? (25-35% overhead)
- [ ] Does this require UI iteration? (3-4x buffer)
- [ ] Does this need database migration? (1.5-2.0x buffer)
- [ ] Does this need new test infrastructure? (1.0-1.5x buffer)
- [ ] Does this require localization? (10-15% overhead)

**Complexity Signals:**
- [ ] Multiple files modified (>5 files)?
- [ ] Multiple systems integrated?
- [ ] Data model changes with cascading effects?
- [ ] New architectural patterns introduced?

### Risk Mitigation Strategies

**For High-Risk Items:**
1. **Descope**: Can we deliver a simpler version first?
2. **Spike**: Should we do a time-boxed investigation first?
3. **Buffer**: Double the estimate to be safe
4. **Defer**: Should this wait until prerequisites are clearer?
5. **Iterate**: Plan for multiple cycles of feedback

**For Medium-Risk Items:**
1. **Buffer**: Add 25-50% to estimate
2. **Schedule wisely**: Days 2-3 for recovery time
3. **Monitor closely**: Daily check-ins on progress
4. **Plan fallback**: What's the MVP if this takes longer?

**For Low-Risk Items:**
1. **Use for quick wins**: Build momentum early
2. **Fill gaps**: Good for end-of-sprint flex time
3. **Batch together**: Efficiency gains from grouping

## Flutter/Testing Specific Considerations

### Flutter Development Overhead

#### Widget Testing Requirements
**Mandatory for all UI features:**
- Widget tree rendering tests
- User interaction tests (taps, scrolls, forms)
- State management tests
- Localization tests (both EN and PT-BR)
- Responsive layout tests (different screen sizes)
- Edge case UI tests (Issue #39 standards)

**Overhead**: 40-60% of implementation estimate
- Simple widgets: 40%
- Complex forms/dialogs: 60%
- Stateful interactions: 50%

#### E2E Testing Requirements
**Required for major features:**
- Full user workflows (recipe creation → meal planning → cooking)
- Database integration tests
- Navigation flows
- Error handling paths

**Overhead**: 80-100% of implementation estimate
- Basic flows: 80%
- Complex multi-screen flows: 100%

#### Edge Case Coverage (Issue #39)
**Required for all new features:**
- Empty states (no data scenarios)
- Boundary conditions (min/max values, zero, negative)
- Error scenarios (database failures, validation errors)
- Interaction patterns (unusual user behaviors)
- Data integrity (consistency across operations)

**Overhead**: 30-50% additional
- Use templates from `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- Reference catalog at `docs/testing/EDGE_CASE_CATALOG.md`

### Database Migration Planning

#### Simple Migrations (Minimal Overhead)
- Add columns with default values
- Add new tables (no relationships)
- Add indexes
- Non-destructive changes

**Buffer**: 0-10%

#### Complex Migrations (Significant Overhead)
- Schema restructuring (rename, reorder)
- Data migration logic (transform existing data)
- Foreign key changes (relationship modifications)
- Junction table changes (many-to-many updates)

**Buffer**: 50-100%
**Action**: Plan migration script, test on copy of production data

### Localization Impact

#### Bilingual Requirements
**All user-facing features must support EN and PT-BR:**
- Update `lib/l10n/app_en.arb`
- Update `lib/l10n/app_pt.arb`
- Run `flutter gen-l10n` after changes
- Test both languages

**Overhead by component:**
- Simple labels: 5% (just ARB updates)
- Error messages: 10% (context-dependent translations)
- Complex UI: 15% (multiple strings, layout testing)

#### Localization Validation
- [ ] No hardcoded strings in code
- [ ] All strings in both ARB files
- [ ] Placeholder formatting correct (`{count}`, etc.)
- [ ] Context provided for translators
- [ ] Both languages tested in UI

### Mobile Tooling Overhead

#### Tooling Issues (From Sprint 0.1.5)
**Hidden overhead: 25-35% for UI-heavy sprints**

**Common issues:**
- ADB connection problems (device not detected)
- Android Studio build failures (Gradle sync issues)
- Emulator startup time (slow on WSL)
- Hot reload inconsistencies (requires full rebuild)
- Flutter doctor issues (SDK path problems)

**Mitigation:**
- Add 30% buffer for UI-heavy sprints
- Plan for tooling troubleshooting time
- Use `flutter analyze` and `flutter test` in WSL (reliable)
- Reserve device testing for validation phases

#### WSL Limitations
**Cannot run in local WSL environment:**
- `flutter build apk`
- `flutter build ios`
- `flutter run`

**Workaround:**
- Use GitHub Actions CI/CD for builds (works reliably)
- Local validation: `flutter analyze` && `flutter test`
- Physical device testing: Done outside WSL

### Testing Organization

#### Test Suite Structure (600+ tests)
```
test/
├── unit/                    # Business logic, models, services
├── widget/                  # UI components, screens
├── integration/             # Multi-component workflows
├── e2e/                     # End-to-end user journeys
├── edge_cases/              # Issue #39 coverage
│   ├── empty_states/
│   ├── boundary_conditions/
│   ├── error_scenarios/
│   ├── interaction_patterns/
│   └── data_integrity/
└── regression/              # Bug regression tests
```

#### Test Coverage Requirements
- **Unit tests**: All business logic, models, services (>80% coverage)
- **Widget tests**: All UI screens and components (>70% coverage)
- **Integration tests**: Major workflows and data flows (key paths)
- **E2E tests**: Critical user journeys (happy path + error path)
- **Edge case tests**: All new features (Issue #39 standards)
- **Regression tests**: All fixed bugs (prevent reoccurrence)

#### Testing Strategy per Sprint Type

**Feature Sprint:**
- Unit tests: 20-30% overhead
- Widget tests: 40-60% overhead
- Edge cases: 30-50% overhead
- **Total testing overhead**: ~100% of implementation

**Bug Fix Sprint:**
- Regression tests: 50-80% overhead (prevent reoccurrence)
- Related test updates: 20-30% overhead
- **Total testing overhead**: ~60-80% of implementation

**Refactoring Sprint:**
- Test updates: 40-60% overhead (maintain coverage)
- New test patterns: If introducing new architecture
- **Total testing overhead**: ~50-70% of implementation

**Testing Infrastructure Sprint:**
- If extending patterns: Use 0.2-0.4x multiplier (fast)
- If new infrastructure: Use 1.0-1.5x multiplier (slower)
- Plan for documentation overhead (15-20%)

## Output Format

Generate sprint plans using the template at `templates/sprint_plan_template.md`.

### Key Sections to Include

1. **Sprint Header**: Number, theme, dates, total story points
2. **Sprint Goal**: 2-3 sentence summary aligned with milestone
3. **Capacity Analysis**: Points, expected days, work type adjustments
4. **Issues by Theme**: Group related work together
5. **Day-by-Day Breakdown**: Detailed sequencing with rationale
6. **Risk Assessment**: Identify and mitigate risks
7. **Testing Strategy**: Required test types and coverage
8. **Success Criteria**: Checklist of deliverables

### Sprint Plan Validation

Before finalizing, verify:
- [ ] Total points within capacity guidelines (10-15 for 5 days)
- [ ] Work type buffers applied (UI: +30%, testing: varies, etc.)
- [ ] Dependencies resolved (prerequisites complete)
- [ ] Testing work explicitly included (not forgotten)
- [ ] Risks identified with mitigations
- [ ] Sequencing follows principles (quick wins first, etc.)
- [ ] Sprint goal aligns with milestone theme
- [ ] Success criteria are measurable and specific

## Examples

### Example 1: Mixed Sprint (Features + Testing + Bugs)

**Scenario**: Sprint 0.1.6, 5 days available, mix of feature work and testing

**Issues**:
- Issue #200: Add recipe difficulty filter (5 points, feature)
- Issue #201: Fix meal plan date picker bug (2 points, bug)
- Issue #202: Edge case tests for ingredient management (3 points, testing)
- Issue #203: Improve recipe search performance (3 points, refactor)
- Issue #204: Add serving size adjustment (5 points, feature)

**Total**: 18 points (too high for conservative planning)

**Analysis**:
- Issue #200: New UI feature → 1.5x multiplier → 7.5 adjusted points
- Issue #201: Known bug → 0.2x multiplier → 0.4 adjusted points
- Issue #202: Extend patterns → 0.3x multiplier → 0.9 adjusted points
- Issue #203: Backend refactor → 1.0x multiplier → 3.0 adjusted points
- Issue #204: Complex UI → 1.5x multiplier → 7.5 adjusted points

**Adjusted Total**: ~19.3 points (still too high)

**Recommendation**: Defer Issue #204 (lowest priority) → 12.8 adjusted points ✓

**Sequencing**:
```
Day 1: Issue #201 (bug fix, 0.4 pts) + Issue #203 (refactor, 3 pts)
       → Quick win + backend optimization

Day 2: Issue #200 (filter feature, 7.5 pts)
       → Main feature when fresh

Day 3: Issue #200 tests (widget + edge cases, ~3 pts)
       → Complete feature fully

Day 4: Issue #202 (edge case tests, 0.9 pts) + Buffer
       → Extend patterns, flex time

Day 5: Polish, documentation, stretch goal (Issue #204 if time allows)
```

**Capacity**: 12.8 adjusted points over 5 days = ~2.5 points/day ✓ (matches median velocity)

**Risks**: Medium
- Issue #200 requires UI iteration (mobile tooling overhead)
- Issue #203 performance work may reveal unexpected issues

**Mitigations**:
- 50% buffer on Issue #203 (performance testing time)
- Issue #204 deferred (can pull in if time allows)

### Example 2: UI-Heavy Sprint with Overhead Buffer

**Scenario**: Sprint focused on mobile UI polish, need to account for tooling overhead

**Issues**:
- Issue #210: Redesign meal planning calendar UI (8 points, UI)
- Issue #211: Add recipe image carousel (5 points, UI)
- Issue #212: Improve loading states across app (3 points, UI)

**Total**: 16 points (UI-heavy)

**Analysis**:
- All UI work → Mobile tooling overhead: +30%
- UI iteration expected → 1.5x multiplier on estimates
- Issue #210: 8 × 1.5 = 12 adjusted points
- Issue #211: 5 × 1.5 = 7.5 adjusted points
- Issue #212: 3 × 1.5 = 4.5 adjusted points
- **Subtotal**: 24 adjusted points
- **With overhead**: 24 × 1.3 = 31.2 adjusted points (WAY too high)

**Recommendation**: Do ONE major UI feature per sprint
- Keep Issue #210 only (primary goal)
- Defer #211 and #212 to next sprint

**Revised Plan**:
- Issue #210: Meal calendar redesign (12 adjusted points)
- Add quick wins to fill capacity:
  - Issue #213: Fix calendar date picker bug (1 point, known pattern → 0.2 adjusted)
  - Issue #214: Update calendar localization (2 points, ARB updates → 2 adjusted)

**Total**: 14.2 adjusted points ✓

**Sequencing**:
```
Day 1: Issue #213 (bug fix) + Design review for Issue #210
       → Quick win + planning

Day 2-3: Issue #210 implementation (calendar UI redesign)
         → Main feature, expect iteration

Day 4: Issue #210 testing (widget tests, both languages)
       → Comprehensive testing

Day 5: Issue #214 (localization) + UI polish iteration
       → Cleanup + respond to testing findings
```

**Risks**: High
- UI iteration unpredictable (user feedback, design changes)
- Mobile tooling overhead (adb issues, emulator problems)
- Calendar component is complex (date handling, state management)

**Mitigations**:
- 30% tooling overhead buffer already applied
- Defer #211 and #212 (scope flexibility)
- Plan for multiple iteration cycles
- Use GitHub Actions for reliable builds (WSL limitations)

**Success Criteria**:
- [ ] Calendar UI matches design mockups
- [ ] All date interactions work correctly
- [ ] Both EN and PT-BR tested
- [ ] Widget tests cover calendar component
- [ ] Edge cases tested (empty meals, future dates)
- [ ] No performance regressions

### Example 3: Optimal Sequencing Demonstration

**Scenario**: Sprint with diverse work types, show optimal sequencing

**Issues**:
- Issue #220: Database migration for recipe tags (2 points, database)
- Issue #221: Add tag filtering to recipe list (5 points, feature)
- Issue #222: Tag management UI (5 points, UI)
- Issue #223: Fix recipe deletion bug (1 point, bug)
- Issue #224: Edge case tests for tags (3 points, testing)

**Total**: 16 points

**Analysis**:
- Issue #220: Database migration → Do first (prerequisite for #221, #222)
- Issue #221: Backend feature → Depends on #220
- Issue #222: UI feature → Depends on #221 (needs tag filtering)
- Issue #223: Known bug → Quick win
- Issue #224: Extend test patterns → Low complexity

**Adjusted estimates**:
- Issue #220: 2 × 1.0 (simple migration) = 2 points
- Issue #221: 5 × 0.8 (backend pattern) = 4 points
- Issue #222: 5 × 1.5 (UI work) = 7.5 points
- Issue #223: 1 × 0.2 (known bug) = 0.2 points
- Issue #224: 3 × 0.3 (extend patterns) = 0.9 points

**Total**: 14.6 adjusted points ✓

**Optimal Sequencing** (by dependency + type batching):
```
Day 1: Issue #223 (bug, 0.2 pts) + Issue #220 (DB migration, 2 pts)
       → Quick win + prerequisite work
       → Rationale: Bug first for momentum, migration early (risky if late)

Day 2: Issue #221 (tag filtering backend, 4 pts)
       → Feature implementation (depends on Day 1 migration)
       → Rationale: Backend work when fresh

Day 3: Issue #221 tests + Issue #222 start (UI, ~3.5 pts)
       → Complete backend feature, start UI
       → Rationale: Finish before moving on, batch UI work

Day 4: Issue #222 continue (UI, ~4 pts)
       → Complete tag management UI
       → Rationale: Keep UI work together (design context)

Day 5: Issue #224 (tag edge case tests, 0.9 pts) + Polish
       → Testing work at end (can cut if needed)
       → Rationale: Open-ended work as flex time
```

**Why This Sequencing Works**:
1. **Dependencies respected**: Migration → Backend → UI (logical flow)
2. **Type batching**: Backend Day 2, UI Days 3-4, Testing Day 5
3. **Risk management**: Migration early (time to fix if issues)
4. **Quick win first**: Bug fix builds momentum
5. **Flex at end**: Testing can be cut/deferred if schedule slips

**Alternative (Bad) Sequencing**:
```
Day 1: Issue #222 (UI) - FAILS, needs backend from #221
Day 2: Issue #221 (backend) - FAILS, needs migration from #220
Day 3: Issue #220 (migration) - Too late if issues found
Day 4: Issue #223 (bug) + Issue #224 (tests) - Context switch
Day 5: Rework Days 1-2 - Sprint failure
```

**Why Alternative Fails**:
- Dependencies backwards (UI before backend before migration)
- Risky work too late (migration on Day 3)
- No momentum building (no quick wins)
- Constant context switching (bug and tests together)

## Usage Instructions

### Step 1: Invoke the Skill
```
User: "Plan sprint 0.1.6 with issues from Project #3"
```

### Step 2: Gather Issue Data
Use `gh` CLI to fetch issues, or user will provide list.

### Step 3: Analyze and Plan
Apply all frameworks from this skill:
- Velocity calibration
- Type-specific multipliers
- Overhead adjustments
- Sequencing principles
- Risk assessment

### Step 4: Generate Sprint Plan
Use `templates/sprint_plan_template.md` to create structured output.

### Step 5: Validate Plan
Check against capacity guidelines, risks, and success criteria.

### Step 6: Present to User
Provide sprint plan with:
- Clear capacity justification
- Risk assessment with mitigations
- Day-by-day breakdown with rationale
- Testing strategy
- Success criteria

## Continuous Improvement

After each sprint:
1. **Update Sprint Estimation Diary** with actual vs estimated
2. **Calculate effort ratio** for sprint
3. **Identify new patterns** in velocity data
4. **Refine multipliers** based on learnings
5. **Update this skill** with new insights

**The skill should evolve** as more sprint data becomes available. Treat it as a living document.

---

## Version History

- **1.0.0** (2026-01-11): Initial skill creation with Sprint 0.1.2-0.1.5 data
