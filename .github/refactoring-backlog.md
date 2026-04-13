# Refactoring Backlog

Auto-flagged by the Code Quality Watchdog. Review during Sprint Planning as part of the 20% quality allocation.

---

- [ ] 🔴 `lib/core/services/shopping_list_service.dart` — file length 457 lines (threshold: 350) — flagged during: #306 servings scaling implementation — 2026-03-01
- [ ] 🔴 `lib/screens/recipe_editor_screen.dart` — file length 2291 lines (threshold: 400) — flagged during: issue creation for servings stepper consistency — 2026-03-02 — **will be addressed in #283 (Extract IngredientParserService as reusable ingredient entry method); do not refactor in isolation**
- [x] ✅ `lib/screens/add_recipe_screen.dart` — resolved in #313 — refactored to 397 lines (extracted `_buildFormFields`, `_buildIngredientsCard`) — 2026-03-03
- [x] ✅ `lib/screens/edit_recipe_screen.dart` — resolved in #313 — refactored to 298 lines (extracted `_buildFormFields`) — 2026-03-03
- [ ] 🔴 `lib/widgets/recipe_selection_dialog.dart` — file length ~410 lines (threshold: 250) — flagged during: issue creation for servings stepper consistency — 2026-03-02 — **opportunistic refactoring attempted in #313 but reverted (no genuine structural extraction without splitting the two dialog modes into separate widgets — requires dedicated effort)**
- [ ] 🔴 `lib/screens/recipe_details_screen.dart` — file length 828 lines (threshold: 400) — flagged during: issue creation for servings in recipe details — 2026-03-02
- [ ] 🔴 `lib/core/migration/migration_runner.dart` — file length 330 lines (threshold: 300) — flagged during: #311 Phase 1 analysis — 2026-03-04
- [ ] 🔴 `lib/widgets/add_side_dish_dialog.dart` — file length 349 lines (threshold: 250) — flagged during: #311 Phase 1 analysis — 2026-03-04
- [ ] 🔴 `lib/screens/weekly_plan_screen.dart` — file length 1019 lines (threshold: 400) — flagged during: #311 Phase 1 analysis — 2026-03-04
- [ ] 🔴 `lib/screens/shopping_list_screen.dart` — file length 517 lines — flagged during: #312 manual shopping items implementation — 2026-03-07
- [ ] 🔴 `lib/database/database_helper.dart` — file length 2242 lines (threshold: 500) — flagged during: #292 Phase 1 analysis — 2026-03-20
- [ ] 🔴 `lib/screens/tools_screen.dart` — file length 869 lines — flagged during: issue #331 analysis — 2026-04-13
