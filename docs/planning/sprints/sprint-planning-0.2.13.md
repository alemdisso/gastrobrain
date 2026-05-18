# Sprint Plan: 0.2.13 — Recipe Redesign

**Sprint Period**: After 0.2.12 lands — est. ~6 working days
**Milestone**: 0.2.13 — Recipe Redesign
**Total Story Points**: 26 raw (37.7 adjusted)
**Target Velocity**: 6.5 points/day (cruising); expect discovery-mode friction (~5 pts/day)

> **Prerequisite**: 0.2.12 must be fully merged. `IngredientParserService` (#283)
> must be standalone and `RecipeEditorScreen` (#336) must be split before these
> redesigns begin — they build on the clean foundation established in 0.2.12.
>
> **Sprint character**: Both issues explicitly require a UX design phase before
> implementation. This sprint is discovery-heavy. Budget more time than the raw
> point total suggests. Day 1 is a mandatory design day — no code.

---

## Sprint Goal

Redesign the two core recipe entry surfaces — creation and ingredient parsing —
as first-class, guided experiences that reduce cognitive load and surface the
app's most powerful features (structured phases, natural language parsing) at
the right moment.

Key deliverables:
- Recipe creation broken into progressive phases (stub → timing → tags → ingredients → notes);
  each phase independently completable; user can save at any point
- Ingredient parser surfaced as a prominent, first-class entry method rather than
  a hidden feature; redesigned UX makes natural language input the default path

---

## Capacity Analysis

### Base Calculation
- **Available days**: 6 days (UX-heavy sprint; one design day + implementation + iteration)
- **Cruising velocity**: 6.5 pts/day (30 pts/week)
- **Base capacity**: 6 × 6.5 = 39 pts raw

### Work Type Adjustments

| Issue | Raw pts | Multiplier | Reason | Adjusted |
|-------|---------|------------|--------|----------|
| #370 Recipe creation phased flow | 13 | 1.5x | New UX pattern; requires design phase; multi-screen architecture; UX iteration expected | 19.5 |
| #371 Ingredient parser UX redesign | 13 | 1.4x | New UX pattern; parser service ready from 0.2.12; still requires design + iteration | 18.2 |

**Total adjusted**: 37.7 pts
**Days at cruising**: 37.7 ÷ 6.5 = 5.8 days → plan for 6 days
**Discovery-mode caveat**: If UX decisions take longer than estimated (unclear flows,
multiple design iterations), this sprint may run 7 days. The design day on Day 1
is the primary risk mitigation — resolving UX questions before touching code.

### Capacity Decision
- **Target**: 26 raw / 37.7 adjusted
- **Confidence**: Low-Medium — this is the most uncertain sprint in the three-sprint
  sequence; both issues have "requires dedicated UX design phase" in their bodies
- **Flex levers**:
  - #371: Minimum viable — parser accessible as primary entry method with improved
    affordance. Full visual polish is deferrable.
  - #370: Minimum viable — phases 1 (Stub) and 4 (Ingredients) must ship. Phases 2,
    3, 5 can be deferred to a follow-up if design complexity exceeds time.
- **If both run long**: Scope to MVP phases only; create follow-up issues for the
  remaining phases rather than shipping incomplete UX

---

## Issues Breakdown

### Theme: Recipe Entry Redesign (2 issues, 26 pts)

#### #371 — Redesign ingredient parser UX as first-class entry method
- **Story Points**: 13 (18.2 adjusted)
- **Type**: UX redesign / Enhancement
- **Priority**: P2-Medium
- **Multiplier**: 1.4x — new UX pattern; `IngredientParserService` is ready (0.2.12);
  implementation is mostly UI layer on top of existing parser logic
- **Dependencies**: `IngredientParserService` (#283 from 0.2.12) must be standalone
- **Risk**: Medium — design decisions (where does the parser entry live, how does it
  coexist with manual entry) need to be made on Day 1
- **Why before #370**: Smaller surface area, more constrained scope; completing it
  first builds momentum and reveals patterns usable in #370's ingredients phase
- **Acceptance Criteria**:
  - [ ] Natural language parser is the prominent, default entry method for ingredients
  - [ ] Manual entry still accessible (explicit opt-in, not buried)
  - [ ] Parse preview shown before committing
  - [ ] Failed parse handled gracefully with fallback to manual
  - [ ] Localized in EN and PT-BR
  - [ ] Widget tests for: parse success, parse failure, manual fallback, cancellation

#### #370 — Redesign recipe creation as phased progressive disclosure flow
- **Story Points**: 13 (19.5 adjusted)
- **Type**: UX redesign / Enhancement
- **Priority**: P2-Medium
- **Multiplier**: 1.5x — significant UX redesign; multi-phase architecture; expect
  one full design-then-iterate cycle
- **Dependencies**: `RecipeEditorScreen` (#336 from 0.2.12) split; #371 done (ingredients
  phase reuses the redesigned parser UX)
- **Risk**: High — largest design surface in the three-sprint sequence; "requires
  dedicated UX design phase" per issue body; stepper vs bottom-sheet vs separate
  screens is an open architecture decision
- **Minimum viable scope**:
  - Phase 1 (Stub): name + meal type → saveable immediately
  - Phase 4 (Ingredients): ingredient list with parser UX from #371
  - Phases 2, 3, 5 (Timing, Tags, Notes): can ship as "edit in details screen"
    with a follow-up issue to add as creation phases
- **Acceptance Criteria**:
  - [ ] Recipe creation entry point feels lighter than current single-form approach
  - [ ] Phase 1 (Stub) produces a valid, saveable recipe
  - [ ] Phase 4 (Ingredients) uses the redesigned parser UX from #371
  - [ ] User can save at any phase and return to add more detail
  - [ ] Existing recipe creation path still functional during transition
  - [ ] Localized in EN and PT-BR
  - [ ] Widget tests for: phase navigation, save at each phase, back navigation

---

## Day-by-Day Breakdown

### Day 1: UX Design Session (No Code)

**Goal**: Resolve all open UX decisions for both #371 and #370 before writing a
single line of implementation code. A half-day of design prevents a full day of
rework.

**Design deliverables for #371**:
- Where does the parser entry live? (FAB, bottom sheet, tab, inline)
- How does manual entry coexist? (toggle, separate button, fallback)
- What does the parse preview look like?
- What happens on parse failure?

**Design deliverables for #370**:
- Architecture decision: stepper, bottom-sheet sequence, or separate screens?
- Phase ordering and scope (confirm or cut phases 2, 3, 5 for MVP)
- How does phase 4 reuse #371's redesigned UX?
- What does "save at any phase" look like in the navigation stack?

**Output**: A short written design note (even 20 lines in a scratch file) capturing
each decision. This becomes the spec that Day 2–6 implement from.

**Risk**: If Day 1 doesn't resolve the architecture decision for #370 (stepper vs
screens), do NOT start implementation — invest another half-day. Implementing the
wrong architecture wastes more time than the extra design time costs.

---

### Days 2–3: Implement #371 — Ingredient Parser UX Redesign

**Goal**: Parser UX shipped, tested, localized. Reusable foundation for #370 Phase 4.

**Day 2**: New entry point + parse preview UI + IngredientParserService wiring
**Day 3**: Manual fallback path + failure handling + L10N + widget tests

**Testing**: Widget tests after implementation (not separated to Day 5)
- Parse success flow
- Parse failure + manual fallback
- Cancellation
- Both EN and PT-BR

**Risk**: Medium — if Day 1 design decision is wrong for the entry point location,
Day 2 may need to restart. This is the core reason Day 1 is non-negotiable.

---

### Days 4–5: Implement #370 — Recipe Creation Phased Flow

**Goal**: Phase 1 (Stub) and Phase 4 (Ingredients, reusing #371 UX) shipped.
Phases 2, 3, 5 deferred to follow-up if time runs short.

**Day 4**: Phase 1 (Stub — name + meal type → saveable); phase navigation skeleton;
routing from existing "New Recipe" entry point
**Day 5**: Phase 4 (Ingredients — integrate #371 UX); save-at-any-phase behavior;
existing path still functional

**Testing**: Widget tests after each phase
- Phase 1: save immediately produces valid recipe
- Phase navigation: forward, back, skip
- Phase 4: parser UX works within creation flow

**Risk**: High — scope creep into phases 2, 3, 5 is the primary risk. If Day 5 ends
and only phases 1 and 4 are done, that is a successful MVP. Resist adding phases 2/3/5
in the same sprint.

---

### Day 6: Polish, Testing, and Release Prep

**Goal**: Both issues fully tested, localized, and release-ready. Create follow-up
issues for any deferred phases.

**Tasks**:
- Device testing for both #371 and #370 (critical — this is UX work, must feel right)
- Edge case tests: empty state, failed parse, back navigation, orientation change
- Verify both EN and PT-BR render correctly with new UI
- Create follow-up issues for any deferred phases (2, 3, 5 of #370)
- `flutter test && flutter analyze`

**Stretch Goals** (if all above complete):
- Phase 2 (Timing: prep time, cook time, difficulty) — most self-contained of the
  deferred phases; good candidate if Day 6 has capacity

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #370 architecture decision (stepper vs screens) not resolved on Day 1 | Sprint slips 1-2 days | Medium | Day 1 is mandatory design day; do not start #370 implementation without a written decision |
| #370 phases 2/3/5 scope creep | Sprint extends past 6 days | Medium | Explicit MVP scope (phases 1+4 only); create follow-up issues for the rest |
| UX iteration on #371 requires redesign after Day 2 | +1-2 days | Low-Medium | Prototype on paper/sketch before coding; validate entry point location on Day 1 |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #370 reuse of #371 UX tighter-coupled than expected | +4-8 hrs | Low-Medium | Do #371 before #370; extract reusable components explicitly |
| Device UX testing reveals flow issues on Day 6 | +1 day | Medium | Test on device during implementation (Day 3, Day 5), not only at the end |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Localization string count higher than expected | +2-4 hrs | Low | Budget half a day for L10N across both issues |

### Risk Mitigation Summary
- **Day 1 is non-negotiable**: No implementation without resolved design decisions
- **MVP scope is explicit**: Phases 1+4 for #370; full #371. Everything else is a follow-up issue.
- **Device testing mid-sprint**: Not just at the end
- **Flex day**: Day 6 absorbs overrun from Days 4-5

---

## Testing Strategy

### Both issues require widget tests during implementation (not deferred to Day 6)

### #371 — Widget tests (Day 3)
- Parse success: input text → preview → confirm → ingredient added
- Parse failure: input text → fallback to manual entry offered
- Cancellation: no side effects
- Both EN and PT-BR render correctly

### #370 — Widget tests (Days 4-5, one phase at a time)
- Phase 1: save immediately produces valid recipe with correct fields
- Phase navigation: forward, back, save-at-phase
- Phase 4: ingredient parser integrated and functional within creation flow
- Existing "New Recipe" entry point still routes correctly

### Edge Cases (Day 6)
- Empty recipe name in Phase 1 (validation)
- Parser input with unparseable text (graceful fallback)
- Back navigation from Phase 4 preserves Phase 1 data
- App backgrounded and resumed mid-creation (state preserved)

### Localization Testing
- **Issues with new strings**: #371 (parser entry labels, failure messages),
  #370 (phase labels, save CTAs, back navigation)
- Test both languages on device — new UX surfaces often expose layout issues with PT-BR text

---

## Dependencies & Prerequisites

### Blocking
- #371 blocked on: `IngredientParserService` (#283 from 0.2.12) must be standalone
- #370 blocked on: `RecipeEditorScreen` (#336 from 0.2.12) must be split; #371 must be done

### Design decisions that must be made on Day 1 (no code without these)
- #371: Entry point location; manual fallback mechanism
- #370: Phase architecture (stepper / bottom-sheet / screens); MVP scope confirmation

---

## Follow-Up Issues to Create After Sprint

When #370 ships phases 1+4 only, immediately create:
- "enhancement: recipe creation phase 2 — timing (prep time, cook time, difficulty)"
- "enhancement: recipe creation phase 3 — tags & quality"
- "enhancement: recipe creation phase 5 — notes & history"

These are not failures — they are intentionally deferred scope with a clear home.

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] #371 merged — parser is first-class entry method with preview + fallback
- [ ] #370 Phase 1 merged — Stub phase produces valid saveable recipe
- [ ] #370 Phase 4 merged — Ingredients phase uses #371 redesigned UX
- [ ] Device-tested (not just emulator)
- [ ] `flutter test && flutter analyze` pass
- [ ] Both EN and PT-BR tested visually

### Secondary Goals
- [ ] #370 Phase 2 (Timing) shipped
- [ ] Deferred phases (3, 5) created as follow-up issues

### Stretch Goals
- [ ] All 5 phases of #370 complete

### Definition of Done for This Sprint
A user can create a new recipe from scratch using natural language to add
ingredients, save immediately after naming it, and return later to add timing
and tags. The ingredient parser is the obvious, prominent path — not a hidden feature.

---

**Plan Created**: 2026-05-16
**Plan Author**: Claude Code
