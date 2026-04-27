# Sprint Plan: 0.2.5 — Tagging & Filtering

**Sprint Period**: ~6 days (starting 2026-04-27, milestone due 2026-05-02)
**Milestone**: 0.2.5 - Tagging & Filtering
**Total Story Points**: 33 pts (31 planned + 2 unplanned P1 bug fix)
**Target Velocity**: 6.5 pts/day (cruising)

---

## Sprint Goal

Introduce a flexible typed tagging system as the primary organization and discovery layer for recipes, and upgrade filtering to range-based criteria and tag-aware search. The category field migration (#334, #335) is the logical completion of this sprint but is explicitly deferrable — the milestone's core value is delivered by #324 and #111 alone.

Key deliverables:
- Typed tag system with predefined and open vocabularies (cuisines, dietary, occasions, techniques) — **must** (#324)
- Enhanced recipe filtering: range-based criteria + tag filtering — **must** (#111)
- meal_role and food_type tag types for category migration prep — **should** (#333)
- Meal type-specific recommendation profiles (lunch vs dinner) — **should** (#127)
- Category → meal_role/food_type tag migration — **stretch** (#334)
- Category field deprecation and removal — **stretch** (#335)

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Sprint days | ~5 working days (Mon Apr 28 – Fri May 2; optional Sun Apr 27 start) |
| Cruising velocity | 6.5 pts/day |
| Base capacity | 32.5 pts |
| Sprint total | 31 pts (4.77d estimated) |
| Buffer | ~0.23d (~5%) — effectively at capacity |

**Capacity warning**: Two 8-pt L-size issues (#324 and #334) occupy 16 of 31 pts and are sequential (can't start #334 without #324 + #333 + #127 complete). If #324 runs over its estimated 1.23d, the entire downstream chain slides. #334 and #335 are the designated pressure valve — they defer cleanly to 0.2.6 without breaking milestone theme.

**New architecture risk adjustment for #324**: First-time implementation (3 new DB tables + new UI patterns). Historical calibration for "Feature (model+UI, well-specified)" = 0.51x at current methodology. Estimate of 1.23d × 1/0.51 ≈ 2.4d realistic without dependency acceleration. **Budget 2 days for #324 and sequence accordingly.**

---

## Issues by Theme

### Unplanned P1 Bug Fix — Must Complete (2 pts)

#### #372 — Recipe save crash: `story` column missing from DB
- **Story Points**: 2 (S) — **P1-High**
- **Est Days**: 0.31d — well-scoped, all affected files identified during investigation
- **Type**: Bug fix (migration system + one screen)
- **Dependencies**: None — isolated to migration infrastructure
- **Risk**: **Low** — root cause fully diagnosed; fix is structural and non-destructive
- **Root Cause**: Migration 004 (`004_add_recipe_story.dart`) silently failed on some Android SQLite builds because its validation query ran inside the same sqflite transaction as the `ALTER TABLE` — schema changes are not visible to `PRAGMA` queries within the same transaction. The transaction rolled back, the column was never added, and the failure was swallowed. Repeats on every launch.
- **Scope**:
  - [ ] `lib/core/migration/migration_runner.dart` — move `validate()` call to after transaction commit (post-commit, schema changes guaranteed visible)
  - [ ] `lib/core/migration/migrations/002_add_ingredient_aliases.dart` — idempotent `up()` (check before ALTER); fix `validate()` to use `PRAGMA table_info(table)` direct form
  - [ ] `lib/core/migration/migrations/003_add_marinating_time.dart` — same as 002
  - [ ] `lib/core/migration/migrations/004_add_recipe_story.dart` — same as 002
  - [ ] `lib/screens/edit_recipe_screen.dart` — replace `DatabaseHelper()` at line 158 with `ServiceProvider.database.helper`
- **On-device recovery**: No action needed — on the next app launch after the fix, migration 004 retries automatically (it's still pending in `schema_migrations`) and succeeds.

---

### Theme 1: Tagging Foundation — Must Complete (8 pts)

#### #324 — Recipe tagging system — flexible typed tags
- **Story Points**: 8 (L) — **P1**
- **Est Days**: 1.23d base; **realistic 1.5–2.0d** (new architecture)
- **Type**: Feature (model + DB + UI) — new patterns throughout
- **Dependencies**: None — this is the sprint anchor
- **Risk**: **High** — 3 new DB tables, new UI pattern (closed picker vs open picker+create), seed data, recommendation engine awareness
- **Design decisions already made in issue body** (reduces discovery risk significantly):
  - Schema: `tag_types`, `tags`, `recipe_tags` tables; `is_hard` + `is_open` flags on `TagType`
  - Hard vs soft: type-level, not per-tag; enforced in recommendation engine as business rule
  - Open types (occasion, technique): deduplication via prefix-match suggestions (same as #320)
  - Category field: untouched by this issue
- **Scope**:
  - [ ] DB migration: `tag_types`, `tags`, `recipe_tags` tables
  - [ ] Seed predefined types: cuisine, dietary (closed); occasion, technique (open)
  - [ ] Seed initial vocabulary (cuisines, dietary restrictions)
  - [ ] Recipe editor: closed type = picker; open type = picker + create inline
  - [ ] Recipe detail screen: display tags by type
  - [ ] Recipe list/search: filter by tag (feeds #111)
  - [ ] l10n: all tag UI strings in EN + PT-BR

---

### Theme 2: Enhanced Filtering — Must Complete (5 pts)

#### #111 — Enhanced recipe filtering — range-based + tag filtering
- **Story Points**: 5 (M) — **P1**
- **Est Days**: 0.77d
- **Type**: Feature (UI + backend) — extends existing filter panel
- **Dependencies**: #324 for tag filtering; range-based filtering (difficulty/frequency/rating) has **no dependency**
- **Risk**: **Medium** — UI work with iteration potential; filter panel complexity
- **Scope**:
  - [ ] Range toggles for difficulty ("Easy or easier", "Medium or easier")
  - [ ] Range toggles for frequency ("At least this frequent")
  - [ ] Range toggles for rating ("At least X stars")
  - [ ] Tag picker per tag type in filter panel (closed types: multi-select; open types: search+select)
  - [ ] Hard tag types (dietary): exclusive filter; soft types (cuisine, occasion): inclusive
  - [ ] Clear indication of active filters and their behavior
  - [ ] l10n: all filter UI strings

---

### Theme 3: Tag System Expansion + Recommendation Profiles — Should Complete (8 pts)

#### #333 — Expand tag system: meal_role + food_type tag types
- **Story Points**: 3 (M) — **P2**
- **Est Days**: 0.46d — **free ride** after #324 (same infrastructure, new vocabulary)
- **Type**: Feature (model extension)
- **Dependencies**: #324 must be complete
- **Risk**: **Low** — follows #324 pattern directly; closed types only, no open-type complexity
- **Scope**:
  - [ ] Add `meal_role` closed type (main dish, side dish, complete meal, appetizer, accompaniment, dessert, snack)
  - [ ] Add `food_type` closed type (soup, stew, salad, stock, sandwich, pasta, rice, grilled, baked, raw, ...)
  - [ ] Update recipe editor to support tagging with these types
  - [ ] No category migration yet — existing recipes keep category in parallel

#### #127 — Meal type-specific recommendation profiles
- **Story Points**: 5 (M) — **P2**
- **Est Days**: 0.77d — algorithm work, no UI
- **Type**: Feature (algorithm/backend)
- **Dependencies**: Soft dependency on #333 (uses meal_role tags eventually; initial implementation uses existing category field as proxy — can proceed without #333 if needed)
- **Risk**: **Medium** — touches recommendation engine; configurable architecture required
- **Note**: Ships category-based rules as initial heuristics; tag-based heuristics deferred until #334 migrates data. Configurable backend (rule tables, named constants) required — no user settings UI in scope
- **Scope**:
  - [ ] Extend existing weekday/weekend profile mechanism with meal type dimensions (lunch, dinner)
  - [ ] Configurable profile architecture: rule tables and weights as named constants / config objects
  - [ ] Hardcoded default profile (no settings UI — deferred to #24)
  - [ ] Category-based heuristic rule table as initial signal
  - [ ] Unit tests for meal type scoring adjustments
  - [ ] Document default rules as assumptions, not universals

---

### Theme 4: Category Migration — Stretch / Deferrable to 0.2.6 (10 pts)

#### #334 — Migrate recipe category field to meal_role + food_type tags
- **Story Points**: 8 (L) — **P2**
- **Est Days**: 1.23d base; likely **1.5–2.0d** (data migration + multi-system touch)
- **Type**: Architecture (data migration + model + recommendation + UI)
- **Dependencies**: #333 (tag types must exist) + #127 (recommendation must be tag-ready) — hard sequential
- **Risk**: **High** — touches recommendation engine, filters, and UI simultaneously; data migration for all existing recipes
- **Deferral condition**: If #324 + #333 + #127 consume more than 3.5 days, defer #334 and #335 to 0.2.6. The migration is a correctness improvement, not a user-facing blocker.
- **Scope**:
  - [ ] Map all existing category values to equivalent meal_role and/or food_type tags for all recipes
  - [ ] Update recommendation engine to read tags instead of category
  - [ ] Update filters to read tags instead of category
  - [ ] Update UI display to use tags instead of category
  - [ ] Keep category field intact (removal in #335)

#### #335 — Deprecate and remove recipe category field
- **Story Points**: 2 (S) — **P2**
- **Est Days**: 0.31d
- **Type**: Chore (model cleanup)
- **Dependencies**: #334 (hard — category must be fully migrated before removal)
- **Risk**: **Low-Medium** — touches many files (editor, detail screen, model, DB), but purely subtractive
- **Scope**:
  - [ ] Remove `category` column from recipes table (DB migration)
  - [ ] Remove `RecipeCategory` enum and all references
  - [ ] Remove category from recipe editor, detail screen, remaining UI
  - [ ] Verify no orphaned references

---

### Flex / Research (0 pts)

#### #303 — Research: servings data as recommendation factor
- **Story Points**: 0 (XS) — P2
- **Type**: Research/exploration
- **No implementation** — reading, thinking, notes only
- Can happen during any idle moment throughout sprint

---

## Day-by-Day Breakdown

### Day 1 (Apr 27 Sun or Apr 28 Mon): Bug Fix + Tagging Foundation — DB + Backend

**Goal**: Clear the P1 bug first thing, then get the tagging DB schema and seed data landed so all downstream work unblocks.

**Issues**:
- **#372** — P1 bug fix: recipe save crash (story column missing)
  - Why first: P1 blocks basic recipe functionality; fix is fast and fully scoped
  - Deliverable: Migration runner validates post-commit; migrations 002–004 idempotent; edit_recipe_screen uses ServiceProvider
- **#324** — DB migration (tag_types, tags, recipe_tags) + seed predefined types + initial vocabulary
  - Why first: Everything in the sprint depends on this. DB work must come first within the issue — never leave migration to mid-sprint.
  - Deliverable: Migration runs cleanly on both empty and seeded DB; tag types and initial vocabulary seeded; model layer updated

**Testing**: #372: `flutter analyze` + migration consolidation test; #324: Migration idempotency test; unit tests for Tag/TagType models

**Risks**: Migration design decisions surface here — if schema needs adjustment, better now than after UI is built

---

### Day 2 (Apr 28/29): Tagging Foundation — UI Complete

**Goal**: Complete #324 (recipe editor + detail display); start #111 range filtering.

**Issues**:
- **#324** (cont.) — recipe editor tag selection UI + recipe detail display + l10n
  - Deliverable: Tags fully functional end-to-end; recipe can be tagged and tags display correctly
- **#303** — Research: servings as recommendation factor (0 pts, reading during natural breaks)
- **#111** (start, range-only) — range-based filtering for difficulty, frequency, rating (no #324 dep)
  - Why now: Range filtering part has no dependency on #324; don't let it sit idle
  - Deliverable: Range toggles functional in filter panel; tag section placeholder ready for Day 3

**Testing**: Widget tests for tag selection UI; localization tests both languages

**Risks**: Open-type picker (occasion, technique) has deduplication logic — may need iteration

---

### Day 3 (Apr 29/30): Filtering Complete + Tag Expansion

**Goal**: Ship #111; start #333 using established #324 patterns.

**Issues**:
- **#111** (complete) — tag filtering UI + hard/soft filter behavior
  - Dependencies met: #324 complete; tags exist on recipes
  - Deliverable: Full filter panel functional (range + tag); both filter behaviors correct
- **#333** — meal_role + food_type tag types
  - Why now: Immediate free ride off #324 — infrastructure fully loaded in working memory
  - Deliverable: meal_role and food_type types seeded; recipe editor supports tagging with them

**Testing**: Widget tests for enhanced filter panel; unit tests for filter logic (range, hard filter, soft filter)

**Risks**: #111 filter panel UI may need iteration — keep #333 as the natural recovery buffer for this day

---

### Day 4 (Apr 30 / May 1): Recommendation Profiles

**Goal**: Ship #127; confirm #333 is fully tested and solid before #334 begins.

**Issues**:
- **#127** — Meal type-specific recommendation profiles
  - Dependencies met: #333 complete (meal_role types exist as future signal); uses category for now
  - Deliverable: Lunch/dinner profiles active; unit tests for scoring; configurable architecture in place; rules documented as defaults
- **#333** (tests + polish if needed)

**Testing**: Unit tests for meal type scoring; document scoring rules and weights explicitly

**Risks**: Recommendation engine is sensitive — ensure existing tests still pass before #334

---

### Day 5 (May 1/2): Category Migration — Stretch

**Goal**: Ship #334 if Days 1–4 completed on schedule. If not, document deferred state and release.

**Issues**:
- **#334** — Category → meal_role/food_type migration (full day if on schedule)
  - Dependencies met: #333 types exist; #127 recommendation engine is tag-aware
  - Deliverable: All recipes migrated; recommendation engine, filters, and UI read tags not category; category field still present

**Stretch Goals** (if #334 completes):
- **#335** — Remove category field (0.31d — quick cleanup)

**Testing**: Migration validation (all recipes have tags; no orphaned category reads); regression test existing recommendation behavior

**Risks**: This is the highest-risk day — data migration + multi-system changes. If any issue from Days 1–4 ran over, skip this day and release with #324+#111+#333+#127 as the milestone deliverable.

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #324 runs 2+ days (new architecture, first implementation) | Downstream chain slides; #334/#335 miss milestone | Medium | Budget 2 days for #324; #334/#335 are explicitly deferrable |
| #334 data migration surfaces edge cases (category values without tag equivalents) | Migration incomplete or incorrect | Medium | Validate category → tag mapping before writing migration; test on seeded data set |
| Open-type tag deduplication in #324 requires more iteration than expected | Day 2 spills; #111 delayed | Low-Medium | Use #320's duplicate-prevention pattern directly; scope: prefix-match suggestions only |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #111 filter panel UI requires iteration | Day 3 delayed | Medium | Range filtering has no dep — can ship partial; tag filtering is the new part |
| #127 recommendation engine changes break existing test suite | Blocked on Day 4 | Low | Run full test suite before committing #127; unit tests for new profiles in isolation first |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #335 removal misses a category reference | Compile error post-removal | Low | Search codebase for `RecipeCategory` and `category` column references before migration |

### Risk Mitigation Summary
- **Scope flexibility**: #334 + #335 (10 pts) are the designated deferral buffer — milestone value is complete without them
- **Dependency management**: DB migration (#324) on Day 1 — never mid-sprint
- **Recovery point**: End of Day 4 — if on schedule, proceed to #334; if not, prepare release
- **Pressure valve**: #303 is 0 pts and truly optional

---

## Dependency Chain

```
#324 (anchor)
  ├── #111 (tag filtering part — range filtering starts immediately)
  └── #333 (meal_role + food_type types)
        └── #127 (recommendation profiles — can use category as proxy if #333 delays)
              └── #334 (category migration — needs both #333 + #127)
                    └── #335 (deprecation — needs #334)

#303 (independent, 0 pts — research only)
```

| Blocker | Unblocks | Status |
|---------|----------|--------|
| #324 | #111 (tag part), #333 | Must complete Day 1–2 |
| #333 | #334 | Must complete Day 3 |
| #127 | #334 | Must complete Day 4 |
| #334 | #335 | Stretch — Day 5 |

---

## Testing Strategy

- **#324**: DB migration idempotency test; Tag/TagType model unit tests; widget tests for tag picker (closed + open types); l10n for both languages
- **#111**: Filter logic unit tests (range semantics, hard/soft behavior); widget tests for filter panel; empty state (no tags yet); both languages
- **#333**: Seed data validation; editor widget tests for new tag types
- **#127**: Unit tests for meal type scoring adjustments; regression: existing recommendations unaffected; scoring rules documented as named constants
- **#334**: Migration validation (all recipes have tags); regression: recommendation, filter, and UI output unchanged after migration
- **#335**: Compile-time verification (no orphaned references); DB migration test (column removed cleanly)

All new UI → l10n required in both ARB files + `flutter gen-l10n`.

---

## Database Migration Plan

| Migration | Issue | Type | Tables | Risk |
|-----------|-------|------|--------|------|
| Create tag_types, tags, recipe_tags; seed vocabulary | #324 | New tables | 3 new | Medium (schema decisions locked) |
| Seed meal_role + food_type tag types + vocabulary | #333 | Data insert | tags, tag_types | Low |
| Data migration: map category → tags for all recipes | #334 | Data transform | recipe_tags, recipes | High |
| Remove category column from recipes | #335 | Column removal | recipes | Low-Medium |

All migrations must run on Day 1 (#324) or immediately when their issue starts. Never leave a migration to the end of the sprint.

---

## Success Criteria

### Primary — Must Complete
- [ ] Recipe save crash resolved: `story` column added on next app launch (#372)
- [ ] Tag system fully functional: create, display, filter by tags (#324)
- [ ] Range-based filtering operational: difficulty, frequency, rating (#111)
- [ ] Tag-based filtering operational: hard (dietary) and soft (cuisine, occasion) (#111)
- [ ] All tests pass (`flutter test`)
- [ ] Zero analysis issues (`flutter analyze`)
- [ ] Both EN and PT-BR tested visually

### Secondary — Should Complete
- [ ] meal_role + food_type tag types seeded and available in editor (#333)
- [ ] Meal type recommendation profiles active: lunch vs dinner differentiation (#127)
- [ ] Recommendation scoring rules documented as named constants

### Stretch — If Schedule Allows
- [ ] All existing recipes migrated from category to meal_role/food_type tags (#334)
- [ ] RecipeCategory enum and category column removed (#335)

### Quality Gates
- [ ] DB migrations idempotent (run twice without error)
- [ ] No regression in existing recommendation behavior
- [ ] Tag deduplication working for open tag types
- [ ] Localization complete for all new strings (EN + PT-BR)

---

## Notes & Assumptions

- **#334 and #335 are explicitly deferrable.** If Days 1–4 deliver #324 + #111 + #333 + #127, the milestone theme ("Tagging & Filtering") is complete. The category migration is a correctness improvement that can ship in 0.2.6 without user-facing regression.
- **#127 has a soft dependency on #333.** Initial implementation uses the existing `category` field as a proxy for meal_role. This is documented in the issue as intentional — tag-based heuristics replace it once #334 migrates the data.
- **#303 is research only.** 0 pts, no implementation. Can be absorbed into any idle moment.
- **open-type tag creation pattern (#324)** should reuse the deduplication logic from #320 (ingredient duplicate prevention) directly — same prefix-match + case normalization approach.
- The recommendation engine integration for `is_hard` tag filtering is **out of scope** for this sprint — tags will be available on recipes but the engine wiring requires user preference infrastructure that doesn't exist yet.

---

**Plan Created**: 2026-04-26
**Last Updated**: 2026-04-27 — added unplanned P1 bug fix #372 (recipe save crash, 2 pts)
