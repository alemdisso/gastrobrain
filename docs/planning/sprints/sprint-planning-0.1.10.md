# Sprint Plan: 0.1.10 — Landing Page & Final Polish

**Sprint Period**: Feb 17-21, 2026 (5 working days)
**Milestone**: 0.1.10 - Landing Page & Documentation
**Total Story Points**: 32 raw
**Target Velocity**: 6 pts/day (30 pts/week cruising)

---

## Sprint Goal

Complete the 0.1.x series: deliver the landing page MVP for feature discoverability, polish ingredient display with pluralization and smarter aggregation, add category-level selection to shopping lists, and cap with comprehensive documentation of all patterns established since 0.1.7.

Key deliverables:
- Landing page MVP with quick actions (#134)
- Ingredient unit pluralization in EN/PT (#149)
- Smarter shopping list aggregation (#293) + category selection (#294)
- DB migration consolidation for clean 0.2.0 baseline (#292)
- Final documentation pass (#268, #263, #285)

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Available days | 5 |
| Cruising velocity | 6.0 pts/day |
| Base capacity | 30 pts |
| Sprint total | 32 pts |
| Fit | Comfortable — docs issues (#268, #263, #285) are Claude Code-heavy and historically execute at 0.1-0.3x |

**Sprint profile**: Mixed (1 feature, 3 UX enhancements, 1 refactor, 3 docs). No pure discovery work. All issues have clear requirements. Docs batch will likely compress significantly.

---

## Issues by Theme

### Theme 1: User-Facing Feature (5 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #134 | Landing page MVP | 5 | Medium | New screen, UX design decisions needed, l10n |

### Theme 2: Shopping List & Ingredient Polish (8 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #149 | Unit pluralization | 3 | Low | Mechanical — ARB plurals + thread quantity through 22 call sites |
| #293 | Expand unit conversions/aggregation | 3 | Low-Med | Some investigation (garlic cloves/heads), extend `convertToCommonUnit()` |
| #294 | Select/deselect by category | 2 | Low | Reuse existing `_toggleAll()` pattern at category level |

### Theme 3: Technical (8 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #292 | Consolidate DB migrations + seed data | 8 | Medium | Mechanical but needs careful testing; no schema change, just consolidation |

### Theme 4: Documentation (11 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #268 | Update skills docs structure | 3 | Low | Claude Code-heavy, mechanical |
| #263 | UI Component Library docs | 5 | Low | Claude Code-heavy, should capture all 0.1.7-0.1.10 patterns |
| #285 | Test suite governance + counts | 3 | Low | Must be LAST — reflects final 0.1.x state |

---

## Day-by-Day Breakdown

### Day 1 (Feb 17): Quick Win + Main Feature

**Goal**: Build momentum, deliver the sprint's primary user-facing feature

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #294 | 2 | Quick win — reuse existing toggle pattern, builds momentum |
| #134 | 5 | Main deliverable; tackle when fresh, UX decisions need energy |

- **#294 first**: 30-60 min, reuse `_toggleAll()` at category level, done before lunch
- **#134 rest of day**: Landing page design + implementation, l10n strings
- **Testing**: Widget tests for #294 tristate behavior; #134 basic rendering tests
- **Risk**: #134 may need UX iteration — schedule emulator validation end of day

### Day 2 (Feb 18): Ingredient Polish (batched)

**Goal**: Complete all shopping list/ingredient UX enhancements in one focused session

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #149 | 3 | Pluralization — shared context with #293 (both touch ingredient display) |
| #293 | 3 | Aggregation — extend `convertToCommonUnit()`, investigate garlic/tsp/tbsp conversions |

- **#149 morning**: Add plural ICU strings to ARBs (14 units x 2 languages), update `getLocalizedDisplayName()` signature, update call sites
- **#293 afternoon**: Extend conversion table, add smart thresholds, test aggregation logic
- **Batching benefit**: Both issues touch `shopping_list_service.dart` and ingredient display — shared mental model
- **Testing**: Unit tests for plural forms, unit tests for new conversions
- **Risk**: Portuguese plural rules may have edge cases; garlic clove-to-head ratio needs research

### Day 3 (Feb 19): DB Migration Consolidation

**Goal**: Clean up migration history into a baseline for 0.2.0

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #292 | 8 | Full focused day — mechanical but needs careful testing |

- **Why Day 3**: Mid-sprint gives recovery time if issues found; all user-facing work done first
- **Approach**: Consolidate incremental migrations into single baseline, update seed data
- **Testing**: Test on empty DB (fresh install), test on existing DB (upgrade path), verify data integrity
- **Risk**: Medium — consolidation is mechanical but any migration bug could cause data loss

### Day 4 (Feb 20): Documentation (batched)

**Goal**: Capture all 0.1.x patterns in documentation

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #268 | 3 | Skills docs structure — prerequisite for #263 |
| #263 | 5 | UI Component Library docs — comprehensive, captures 0.1.7-0.1.10 |

- **#268 morning**: Update skill files to enforce consistent doc structure
- **#263 rest of day**: Document all visual patterns, design tokens, components
- **Batching benefit**: Both are documentation with Claude Code doing heavy lifting; same mindset
- **Risk**: Low — docs work historically executes at 0.1-0.3x

### Day 5 (Feb 21): Final Governance + Release

**Goal**: Final documentation pass, release prep

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #285 | 3 | Test suite governance — MUST be last (reflects final 0.1.x state) |

- **#285 morning**: Update test counts, establish governance process
- **Afternoon**: Emulator validation of all changes, release prep (version bump, release branch)
- **Buffer**: If any Day 1-4 work spilled, flex time here to finish
- **Stretch**: Any polish items discovered during emulator testing

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #292 migration breaks existing data | High | Low | Test on copy of real data first; consolidation only, no schema changes |
| #134 landing page needs UX iteration | Medium | Medium | Clear MVP scope; defer polish to 0.2.x if needed |
| #293 garlic/unit conversions are ambiguous | Low | Medium | Time-box investigation at 1 hour; implement clear cases only |
| Portuguese plural edge cases in #149 | Low | Low | ICU handles most cases; test all 14 units explicitly |

**Scope flexibility**: If anything overruns, #268 and #263 (docs) can be deferred — they're important but not blocking. #285 must stay last regardless.

---

## Testing Strategy

| Issue | Test Types | l10n |
|-------|-----------|------|
| #134 | Widget tests (new screen), edge cases (empty states) | Yes — new strings |
| #149 | Unit tests (all 14 units x singular/plural x EN/PT) | Yes — 28 ARB entries |
| #293 | Unit tests (conversion table, aggregation logic) | Minimal |
| #294 | Widget tests (tristate behavior, category toggle interaction with global toggle) | Yes — accessibility labels |
| #292 | Integration tests (fresh install + upgrade path) | No |

---

## Success Criteria

### Must Complete
- [ ] Landing page screen live with quick actions (#134)
- [ ] Ingredients display proper plurals in recipes + shopping lists (#149)
- [ ] Shopping list aggregates garlic, tsp/tbsp intelligently (#293)
- [ ] Shopping list categories can be toggled as a group (#294)
- [ ] DB migrations consolidated into baseline (#292)
- [ ] All tests pass, no analysis warnings

### Should Complete
- [ ] Skills enforce standardized doc structure (#268)
- [ ] UI Component Library documented (#263)
- [ ] Test suite governance established (#285)
- [ ] Both EN and PT-BR tested on emulator

### Sprint Completion
- [ ] Release 0.1.10 created
- [ ] 0.1.x series complete — ready for 0.2.0

---

**Plan Created**: 2026-02-16
**Plan Author**: Claude Code (sprint planner skill)
