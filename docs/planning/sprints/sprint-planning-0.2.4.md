# Sprint Plan: 0.2.4 — Recipe Enhancement

**Sprint Period**: ~5 working days (starting 2026-04-21)
**Milestone**: 0.2.4 - Recipe Enhancement
**Total Story Points**: 29 pts
**Target Velocity**: 6 pts/day (30 pts/week cruising)

---

## Sprint Goal

Fix the P1 backup/restore regression on Android 10+ first, then deliver a rich set of recipe and ingredient enhancements: ingredient aliases with duplicate prevention, Markdown rendering for instructions, a recipe story field, and marinating time. Cap with quantity intelligence (range formatting, smart rounding, parser refactor) and per-recipe meal notes as stretch. The three P3 quantity issues (#150, #151, #170) and the stretch goal (#291) are explicitly deferrable; the core milestone value is in #354, #198, #320, #321, #326, and #348.

Key deliverables:
- Backup/restore functional on Android 10+ without storage permissions — **P1, must-complete** (#354)
- Ingredients searchable and parseable by alternative names (aliases) (#198)
- Duplicate ingredients prevented at creation time — alias-aware (#320)
- Recipe instructions rendered as Markdown with a preview toggle (#321)
- Recipe story/narrative field for personal and cultural context (#326)
- Marinating time visible alongside prep and cook time (#348)
- Ingredient quantities displayable as ranges (e.g. `2-3 cloves`) (#150) — deferrable
- Smart rounding for metric conversions (`237ml → ~250ml`) (#151) — deferrable
- Ingredient parser uses localized unit strings from l10n files (#170) — deferrable
- Per-recipe notes in multi-dish meal recording (#291) — **stretch only**

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Available days | ~5 |
| Cruising velocity | 6.0 pts/day |
| Base capacity | 30 pts |
| Sprint total | 29 pts |
| Fit | At capacity — 1 pt buffer; P3 items and #291 explicitly deferrable |

**Sprint profile**: Platform bug (day 1) → ingredient model cluster (day 2) → recipe content cluster (day 3) → quantity intelligence batch (day 4) → stretch + testing (day 5).

- **Day 1 — P1 platform fix**: #354 is labeled 2 pts but involves new packages, SAF content URI handling, and a new service overload. Full-day focus is correct even at 2 pts.
- **Day 2 — Ingredient model cluster**: #198 (5 pts) builds alias-aware matching; #320 (3 pts) immediately uses that matching infrastructure for duplicate prevention. Same code domain — natural same-day batch. Combined 8 pts; #320 can spill to Day 3 morning if #198 runs long.
- **Day 3 — Recipe content cluster**: #348 (2 pts) warm-up, #321 (3 pts) Markdown main feature, #326 (2 pts) story field. #326 is near-free after #321 — same recipe model, same editor, same `MarkdownBody` widget already integrated. Combined 7 pts.
- **Day 4 — Quantity intelligence**: #170 (2 pts) + #151 (2 pts) + #150 (3 pts). All quantity/parser domain. Do #151 before #150 (soft dependency). #150 has schema risk — deferrable if design phase > 1 hour.
- **Day 5 — Stretch + testing**: #291 (5 pts) if everything is clean. Otherwise: edge case tests, device validation for #354, release prep.

---

## Issues by Theme

### Theme 1: P1 Platform Bug Fix (2 pts)

| # | Title | Est | Priority | Risk | Notes |
|---|-------|-----|----------|------|-------|
| #354 | bug: backup/restore broken on Android 10+ | 2 | P1 | **High-Medium** | Prescribed fix: `share_plus` for backup share sheet, `file_picker` for SAF-compliant restore. New `restoreDatabaseFromString()` overload needed. SAF may return `bytes` instead of a `path` — must handle both. After this, `file_picker` is available in the project for future use (#216). |

### Theme 2: Ingredient Data Model + Duplicate Prevention (5 + 3 = 8 pts)

| # | Title | Est | Priority | Risk | Notes |
|---|-------|-----|----------|------|-------|
| #198 | Add Aliases Field to Ingredients for Alternative Names | 5 | P2 | Medium | DB migration (simple ALTER TABLE), model update (JSON array), new alias matching stage at 0.95 confidence, UI in edit screen (comma-separated field) + detail view (chips). Well-specified with code samples. |
| #320 | ux: prevent duplicate ingredients — show similar matches while typing | 3 | **P1** | Low-Medium | Live prefix-match suggestions in Add Ingredient dialog. Hard-block save on exact match (case-insensitive, post-normalization). Non-blocking suggestion on prefix/near match. Alias-aware from the start (uses #198's matching service). Must be done after #198 in same sprint. |

### Theme 3: Recipe Content Enhancement (2 + 3 + 2 = 7 pts)

| # | Title | Est | Priority | Risk | Notes |
|---|-------|-----|----------|------|-------|
| #348 | feat: add marinating time as a separate recipe field | 2 | P3 | Low | Optional field. Same pattern as servings (#304, 0.22x). DB migration + model + display alongside prep/cook time. Total time calculation adjustment. |
| #321 | ux: add markdown rendering support for recipe instructions | 3 | P2 | Medium | `flutter_markdown` package (first-party Flutter). `MarkdownBody` in recipe detail; `TextField` + preview toggle in `recipe_editor_screen.dart` (large file). `shrinkWrap` may need tuning in scrollable form. No data migration needed. |
| #326 | ux: add recipe story/narrative field | 2 | P3 | Low | New optional `story` TEXT field in recipes. Same DB migration + model pattern as #348. Displayed at top of recipe detail with warm visual treatment, hidden when absent. Markdown-rendered via same `MarkdownBody` built in #321. Near-free after #321 — same editor, same model, same widget. |

### Theme 4: Quantity Intelligence (2 + 2 + 3 = 7 pts) — Deferrable if needed

| # | Title | Est | Priority | Risk | Notes |
|---|-------|-----|----------|------|-------|
| #170 | Refactor ingredient parser to use localized measurement unit strings | 2 | P3 | Low | Mechanical refactor: `_parseUnit()` in `BulkRecipeUpdateScreen` (~line 453). Replace hardcoded map with `AppLocalizations.of(context)!` dynamic map. Keep common abbreviations as fallbacks. |
| #151 | UI: Implement smart metric conversion with intelligent rounding | 2 | P3 | Low | Logic/utility work. Round to practical cooking increments (25ml, 50ml, 100ml intervals). Preserve precision for small quantities. Show `~` when rounding is significant. Extends existing conversion utilities. |
| #150 | UI: Implement range formatting for approximate ingredient quantities | 3 | P3 | Medium | Extends `RecipeIngredient` model for min/max quantities. Likely needs schema update. Do after #151 (soft dependency). Display: `{min}-{max} {unit}`. Backward-compatible with existing single values. |

### Theme 5: Stretch — Deferrable to 0.2.8 (5 pts)

| # | Title | Est | Priority | Risk | Notes |
|---|-------|-----|----------|------|-------|
| #291 | Per-recipe notes in multi-dish meals | 5 | P2 | Medium | `ALTER TABLE meal_recipes ADD COLUMN notes TEXT` migration, `MealRecipe` model update, per-recipe note fields in `MealRecordingDialog`, history display in recipe details. **Known limitation**: `MealRecordingDialog` lacks DI (#237) — widget test coverage for dialog is reduced. Complete only if Days 1–4 are clean and Day 5 has capacity. |

---

## Day-by-Day Breakdown

### Day 1: P1 Platform Bug — Backup/Restore Android 10+

**Goal**: Ship #354. Restore full backup/restore functionality on Android 10+ without storage permissions.

| Issue | Pts | Notes |
|-------|-----|-------|
| #354 | 2 | Full-day focus. |

**Implementation sequence:**
1. Add `share_plus` and `file_picker` to `pubspec.yaml` → `flutter pub get`
2. `DatabaseBackupService`: replace `_writeBackupToFile()` (direct `/sdcard/` write) with write to `getApplicationDocumentsDirectory()` then `Share.shareXFiles()`
3. `DatabaseBackupService`: add `restoreDatabaseFromString(String jsonContent)` overload for SAF bytes case
4. `tools_screen.dart`: replace text-field restore dialog with `FilePicker.platform.pickFiles()` call; handle both `path` (available) and `bytes` (SAF content URI) cases
5. Tests: unit tests for `restoreDatabaseFromString()`; verify backup JSON format unchanged
6. Emulator validation: any available emulator (all are API 33+, confirmed above API 29 threshold)

**Note**: After this, `file_picker` is in the project — no re-setup cost for #216 in 0.2.8.

---

### Day 2: Ingredient Model Cluster — Aliases + Duplicate Prevention

**Goal**: Ship #198 then #320. Build the alias foundation in the morning, immediately use it for duplicate prevention in the afternoon.

| Issue | Pts | Notes |
|-------|-----|-------|
| #198 | 5 | Morning/early afternoon — model anchor. |
| #320 | 3 | Afternoon — uses #198's matching service directly. Can spill to Day 3 morning. |

**#198 implementation sequence:**
1. DB migration: `ALTER TABLE ingredients ADD COLUMN aliases TEXT` (JSON array, nullable, idempotent)
2. `Ingredient` model: add `aliases` field, update `toMap()`/`fromMap()` (null → empty list), add `MatchType.alias` to `ingredient_match.dart`
3. `IngredientMatchingService`: add alias matching stage — normalize to lowercase, confidence 0.95; handle ambiguous aliases (multiple ingredients → return all)
4. `EditIngredientScreen`: comma-separated text field for aliases; parse to `List<String>` on save
5. Ingredient detail view: display aliases as chips/tags
6. l10n: label strings to both ARB files; `flutter gen-l10n`
7. Tests: DB storage/retrieval (empty, populated); alias matching (case-insensitive, ambiguous, priority over fuzzy); import/export includes aliases

**#320 implementation sequence** (while `IngredientMatchingService` is loaded):
1. `AddIngredientDialog`: add live prefix-match query on name field change (case-insensitive, against existing ingredient names AND aliases from #198)
2. Display suggestion list while typing (non-blocking — allows legitimate new ingredients)
3. Hard-block save on exact match (case-insensitive, post-trim normalization): show inline error, disable save button
4. Normalize case to lowercase on save
5. Edit flow: renaming in `EditIngredientScreen` also triggers exact-match duplicate check (same guard)
6. Tests: no suggestions for unique name; suggestions for prefix match; save blocked on exact match; alias match detected; rename duplicate blocked

---

### Day 3: Recipe Content Cluster — Marinating Time + Markdown + Story

**Goal**: Ship #348, #321, and #326. Three recipe content enhancements in thematic sequence.

| Issue | Pts | Notes |
|-------|-----|-------|
| #348 | 2 | Morning warm-up. Known DB + model pattern. |
| #321 | 3 | Mid-day main feature. New package — reserve full focus. |
| #326 | 2 | Afternoon — near-free after #321 (same model, same editor, same `MarkdownBody`). |

**#348 implementation** (follow servings pattern from #304):
1. DB migration: `ALTER TABLE recipes ADD COLUMN marinating_time INTEGER` (minutes, nullable, idempotent)
2. `Recipe` model: add `marinatingTime` field; update `toMap()`/`fromMap()`
3. Display: show alongside prep/cook time in recipe details (hidden when null)
4. Total time: include marinating time in total when non-null
5. Edit form: optional stepper or integer field
6. l10n: `marinatingTime` label to both ARB files

**#321 implementation**:
1. `pubspec.yaml`: add `flutter_markdown` → `flutter pub get`
2. Recipe detail view: replace `Text(recipe.instructions)` with `MarkdownBody(data: recipe.instructions)` — verify scroll behavior
3. `recipe_editor_screen.dart`: add `bool _showPreview` state; preview toggle button; show `MarkdownBody` when preview on, `TextField` when off
4. Layout: if `MarkdownBody` overflows in scrollable form, apply `shrinkWrap: true` or wrap in inner `SingleChildScrollView`
5. Tests: headers/lists/bold render; preview toggles; plain text passthrough; no overflow on small screens
6. **Scope fallback**: if layout debugging exceeds 2 hours, ship display-only Markdown (no editor preview) as MVP

**#326 implementation** (while recipe model and editor are warm from #348 + #321):
1. DB migration: `ALTER TABLE recipes ADD COLUMN story TEXT` (nullable, idempotent) — same pattern as #348
2. `Recipe` model: add `story` field; update `toMap()`/`fromMap()`
3. Recipe detail: display `MarkdownBody(data: recipe.story)` at top of screen, visually distinct from culinary content (e.g. italic style, subtle background); hidden when null
4. `recipe_editor_screen.dart`: add `story` `TextField` (same pattern as other text fields already in editor)
5. l10n: `recipeStory` label to both ARB files
6. Tests: displayed when non-null, hidden when null, Markdown renders

---

### Day 4: Quantity Intelligence Batch

**Goal**: Ship #170, #151, and #150 in the quantity/parser domain.

| Issue | Pts | Notes |
|-------|-----|-------|
| #170 | 2 | First: mechanical refactor — warm-up. |
| #151 | 2 | Second: logic/utility. |
| #150 | 3 | Third: model change. Deferrable if design phase > 1 hour. |

**#170 implementation** (`BulkRecipeUpdateScreen` parser refactor):
1. `_parseUnit()` at ~line 453 of `bulk_recipe_update_screen.dart`
2. Build dynamic map from `AppLocalizations.of(context)!` for each `MeasurementUnit` enum value
3. Keep common abbreviations and accent-stripped variants as fallbacks
4. Remove hardcoded static map; verify same parsing behavior in EN + PT-BR

**#151 implementation** (smart metric conversion):
1. Locate existing conversion utility in `lib/` — verify #141 (decimal formatting) is already implemented
2. Implement rounding: 25ml/50ml/100ml intervals for volume; 25g/50g/100g for weight; preserve precision for < 15ml/15g
3. Show `~` prefix when rounded differs from exact by > 5%
4. Tests: `237ml → ~250ml`, `15ml → 15ml`, `473ml → ~500ml`, `28g → ~30g`

**#150 implementation** (range quantities):
1. Schema: simplest backward-compatible option — store as `quantity_range TEXT` JSON alongside existing `quantity` column; or add `min_quantity`/`max_quantity` REAL columns if cleaner
2. `RecipeIngredient` model: optional `minQuantity`/`maxQuantity`; existing `quantity` unchanged
3. Display: `{min}-{max} {unit}`; edit UI: toggle to reveal range fields
4. Tests: display format, backward-compat single values, DB round-trip

**Day 4 scope guard**: If #150 schema design takes > 1 hour, defer to 0.2.8. Ship 26 pts.

---

### Day 5: Stretch (#291) + Buffer + Release

**Goal**: Attempt #291 if Days 1–4 are fully clean. Otherwise: edge case tests, device validation, release.

| Focus | Notes |
|-------|-------|
| #291 (stretch) | `ALTER TABLE meal_recipes ADD COLUMN notes TEXT` (idempotent); `MealRecipe` model update; per-recipe note inputs in `MealRecordingDialog`; history display in recipe detail screen; l10n. **DI limitation applies** — unit-test DB + model layers; accept reduced dialog widget test coverage per CLAUDE.md guidance. |
| Device validation | Emulator (any available — all API 33+): backup → share sheet appears, restore → file picker opens, round-trip intact |
| Edge case tests | Alias edge cases (#198/#320): alias = other ingredient's name, duplicate aliases across ingredients; Markdown edge cases (#321/#326): empty string, very long content, plain text passthrough |
| Release prep | `flutter analyze` clean, full test suite, version bump, merge to develop → release/0.2.4 |

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **#354 SAF bytes path** — `file_picker` returns `bytes` instead of `path` on some devices | High | Medium | Implement `restoreDatabaseFromString()` as mandatory scope. Test both code paths explicitly. |
| **#320 alias-aware duplicate check ordering** — #320 must use #198's alias matching; if #198 runs long, #320 spills to Day 3 morning | Medium | Low | Explicit dependency noted. #320 can start Day 3 if #198 finishes late Day 2. |
| **#321 layout overflow** — `MarkdownBody` in scrollable form causes `RenderFlex` overflow | Medium | Medium | Budget 1 extra hour. Fallback: display-only Markdown, no editor preview. |
| **#321 preview toggle state** — `recipe_editor_screen.dart` is large; state collision risk | Medium | Low | Isolate as single `bool _showPreview`. No surrounding refactoring. |
| **#150 schema complexity** — min/max quantities require more than a simple column add | Medium | Medium | Time-box design to 1 hour. Use `TEXT` JSON column as simplest path. Defer if over time-box. |
| **#291 MealRecordingDialog DI gap** — known limitation from CLAUDE.md (#237) reduces widget test coverage | Low | Certain | Unit-test model + DB. Accept dialog widget test gap. This is a known limitation, not a new risk. |
| **Day 3 overload** — 7 pts across 3 issues; #321 layout issues could crowd out #326 | Low | Low | #326 is the natural last item. If #321 layout debugging runs long, #326 spills to Day 4 morning — still fine. |

---

## Testing Strategy

| Issue | Test Types | l10n | Device Validation |
|-------|-----------|------|------------------|
| #354 | Unit (`restoreDatabaseFromString()`), Manual (backup → share, restore → file picker) | No | **Required** (any emulator — all API 33+) |
| #198 | Unit (DB alias round-trip, alias matching confidence + case-insensitive + ambiguous), Widget (edit field, detail chips) | Yes | Optional |
| #320 | Widget (suggestions appear on prefix, save blocked on exact match, alias detected, rename blocked), Unit (normalization) | No | Optional |
| #348 | Unit (model serialization, total time), Widget (display null/non-null, edit field) | Yes | Optional |
| #321 | Widget (Markdown renders headers/lists/bold, preview toggles, plain text passthrough, no overflow) | No | Recommended |
| #326 | Widget (displayed when non-null, hidden when null, Markdown renders, visually distinct) | Yes | Optional |
| #170 | Unit (parse same results EN + PT-BR), Widget (BulkRecipeUpdateScreen unchanged behavior) | No | No |
| #151 | Unit (rounding values, small quantity precision, `~` prefix threshold) | No | No |
| #150 | Unit (DB round-trip, backward-compat), Widget (range display format, edit toggle) | No | Optional |
| #291 | Unit (model + DB CRUD), Widget (recipe detail history notes display) | Yes | Optional |

---

## Dependencies Map

```
#354    → independent (Day 1)
#198    → independent (Day 2, morning)
#320    → requires #198 in same sprint; alias-aware matching needed (Day 2, afternoon)
#348    → independent (Day 3, warm-up)
#321    → independent (Day 3, main)
#326    → after #321 (same sprint); reuses MarkdownBody and recipe model (Day 3, close)
#170    → independent (Day 4)
#151    → verify #141 done (Day 4)
#150    → soft dependency on #151; schema design first (Day 4)
#291    → independent, stretch (Day 5)
```

---

## Priority Order (if sprint overruns)

| Priority | Issues | Points | Justification |
|----------|--------|--------|---------------|
| Must-complete | #354, #198, #320, #321 | 13 | P1 bug + two ingredient issues (model + UX, directly linked) + P2 Markdown |
| Should-complete | #348, #326, #170 | 6 | Quick issues; high value/effort ratio; all < 0.3 effective days each |
| Could-complete | #151, #150 | 5 | P3; #150 has schema risk; no user-facing impact if deferred to 0.2.8 |
| Stretch | #291 | 5 | Per-recipe notes; DI limitation; Day 5 only if Days 1–4 are clean |

---

## Success Criteria

### Must Complete
- [ ] Backup writes to app-private dir and triggers share sheet — no `/sdcard/` path (#354)
- [ ] Restore uses file picker — no text-field path input (#354)
- [ ] Both work on Android 10+ without `MANAGE_EXTERNAL_STORAGE` (#354)
- [ ] `restoreDatabaseFromString()` overload implemented and tested (#354)
- [ ] `aliases` column in `ingredients` table via idempotent migration (#198)
- [ ] `Ingredient` serialization round-trips aliases correctly (#198)
- [ ] `IngredientMatchingService` matches by alias at 0.95 confidence, below exact (#198)
- [ ] Edit ingredient screen has aliases input; ingredient detail shows aliases (#198)
- [ ] Add Ingredient dialog shows prefix-match suggestions while typing (#320)
- [ ] Save hard-blocked on exact name match (case-insensitive) (#320)
- [ ] Ingredient names normalized to lowercase on save (#320)
- [ ] Recipe detail renders Markdown in instructions field (#321)
- [ ] Recipe editor has working preview toggle (#321)

### Should Complete
- [ ] Marinating time displayed alongside prep/cook time when non-null (#348)
- [ ] Recipe story field displayed at top of recipe detail, Markdown-rendered (#326)
- [ ] `_parseUnit()` uses l10n strings + abbreviation fallbacks (#170)

### Could Complete (Deferrable to 0.2.8)
- [ ] Metric conversions show rounded value with `~` prefix when ≥5% rounding (#151)
- [ ] `RecipeIngredient` supports optional min/max range; displayed as `{min}-{max} {unit}` (#150)

### Stretch (Day 5 only)
- [ ] `meal_recipes.notes` column added via idempotent migration (#291)
- [ ] Per-recipe notes visible in meal history per recipe (#291)

### Sprint Completion
- [ ] `flutter analyze` clean
- [ ] Full test suite passes (including integration tests)
- [ ] Release 0.2.4 created and merged to main
- [ ] 0.2.4 milestone closed

---

## Pre-Sprint Checklist

- [x] **Android 10+ emulator confirmed available** — all installed emulators (API 33, 35, 36) are above the API 29 scoped storage threshold. No new AVD needed for #354 validation.
- [ ] Confirm `share_plus` and `file_picker` latest stable versions; check for conflicts in `pubspec.yaml`
- [ ] Confirm `flutter_markdown` latest stable version compatible with current Flutter SDK
- [ ] Verify #141 (smart decimal formatting) is already in codebase before starting #151 — search `lib/` for existing conversion/formatting utilities
- [ ] Confirm DB migration numbering: check current highest migration version in `database_helper.dart` before writing migrations for #198, #348, #326, and #291

---

**Plan Created**: 2026-04-20
**Plan Updated**: 2026-04-20 (added #320, #326, #291; confirmed AVD prerequisites)
**Plan Author**: Claude Code (sprint planner skill)
