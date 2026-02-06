# Gastrobrain Senior Developer Implementation Skill

Quick reference for the Phase 2 implementation skill that acts as an experienced Flutter/Dart developer.

## Quick Start

### Trigger Phrases

```
"Implement Phase 2 for #XXX"
"Start implementing #XXX"
"Execute the implementation for issue #XXX"
```

### What Happens

1. Detects branch: `feature/XXX-description`
2. Loads roadmap: `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md`
3. Parses Phase 2 requirements
4. Detects needed patterns (model, service, widget, provider)
5. Generates checkpoint plan
6. Executes checkpoints with user verification

## Core Philosophy

**Pattern-First → Checkpoint → Verify → Next Checkpoint**

- Every implementation follows detected patterns from the codebase
- User confirms each checkpoint before proceeding
- Quality gates ensure code meets standards
- Specialized work delegated to appropriate skills

## Checkpoint Categories

### Simple UI Fix (3-4 checkpoints)
```
CP1: Analyze and prepare
CP2: Implement UI changes
CP3: Verify responsive behavior
CP4: Update localization (if needed)
```

### Service Logic (4-5 checkpoints)
```
CP1: Create/update service structure
CP2: Implement core logic
CP3: Add error handling
CP4: Integrate with ServiceProvider
CP5: Update callers
```

### Feature with Database (6-8 checkpoints)
```
CP1: [DELEGATE] Database migration
CP2: Model class updates
CP3: Service layer implementation
CP4: UI components
CP5: Wire up with providers
CP6: Localization strings
CP7: Error handling polish
CP8: Integration verification
```

### Widget/Screen (5-6 checkpoints)
```
CP1: Widget structure and state
CP2: Core UI implementation
CP3: User interactions
CP4: Data binding and state management
CP5: Localization
CP6: Responsive design verification
```

## Pattern Detection

Before each checkpoint, the skill:

1. Identifies what needs to be created/modified
2. Searches codebase for similar patterns
3. Extracts pattern structure
4. Presents context in checkpoint

**Pattern Reference Files:**

| Pattern | Reference |
|---------|-----------|
| Enum | `lib/models/meal_type.dart` |
| Model | `lib/models/recipe.dart` |
| Service | `lib/core/services/recommendation_cache_service.dart` |
| Widget | `lib/screens/weekly_plan_screen.dart` |
| Provider | `lib/core/providers/recipe_provider.dart` |

## Quality Gates

Every checkpoint must pass:

1. **Static Analysis**: `flutter analyze [files]` - no errors
2. **File Length**: Each file < 400 lines
3. **SOLID Principles**: Maintained throughout
4. **Pattern Compliance**: Matches codebase conventions
5. **Test Readiness**: DI in place, testable signatures

## Skill Delegation

### Database Changes → `gastrobrain-database-migration`
When schema changes are needed, the skill delegates to the database migration specialist which:
- Creates versioned migration file
- Implements up() and down() methods
- Verifies rollback works
- Updates model classes

### Testing → `gastrobrain-testing-implementation`
After Phase 2 completes, hands off to testing specialist which:
- Creates test file structure
- Implements tests one at a time
- Verifies each test passes
- Covers edge cases per Issue #39

### Localization
Handled inline (not delegated):
- Adds strings to `app_en.arb` and `app_pt.arb`
- Runs `flutter gen-l10n`
- Verifies both locales work

## Example Workflow

```
Phase 2 Implementation for Issue #123
═══════════════════════════════════════

Branch: feature/123-add-recipe-filtering
Roadmap: docs/planning/0.1.5/ISSUE-123-ROADMAP.md

Implementation Categories Detected:
├─ Database: No
├─ Models: FilterOptions
├─ Services: RecipeFilterService
├─ Widgets: FilterDropdown
└─ Localization: 4 strings

Checkpoint Plan:
1. Create FilterOptions model
2. Implement RecipeFilterService
3. Create FilterDropdown widget
4. Integrate with RecipeListScreen
5. Add localization strings

Total: 5 checkpoints

Ready to start Checkpoint 1/5? (y/n)
```

## Checkpoint Format

```
═══════════════════════════════════════
CHECKPOINT 2/5: Implement RecipeFilterService
Goal: Create service with filtering logic

Pattern Context:
- Similar: lib/core/services/recommendation_cache_service.dart
- Key patterns:
  • Constructor DI with DatabaseHelper
  • Private helper methods with _ prefix
  • GastrobrainException error handling

Progress:
✓ Checkpoint 1: FilterOptions model [COMPLETE]
⧗ Checkpoint 2: RecipeFilterService [CURRENT]
○ Checkpoint 3: FilterDropdown widget
○ Checkpoint 4: Integration
○ Checkpoint 5: Localization

Tasks:
- [ ] Create service class with DI
- [ ] Implement filtering methods
- [ ] Add error handling

[Implementation code here]

Verification:
1. flutter analyze lib/core/services/recipe_filter_service.dart
2. Verify service follows pattern

Ready to proceed? (y/n)
═══════════════════════════════════════
```

## Related Skills

| Skill | Purpose |
|-------|---------|
| `gastrobrain-issue-roadmap` | Creates Phase 1-4 roadmaps |
| `gastrobrain-database-migration` | Database schema changes |
| `gastrobrain-testing-implementation` | Phase 3 testing |
| `gastrobrain-refactoring` | Code extraction when needed |

## Success Criteria

- [ ] Pattern-First: Follows detected codebase patterns
- [ ] Checkpoint-Driven: User confirms each step
- [ ] Quality Gates: All checkpoints pass `flutter analyze`
- [ ] Proper Delegation: DB/Testing delegated to specialists
- [ ] Roadmap Sync: Checkboxes updated as work completes
- [ ] Test-Ready: All code has DI and is testable
- [ ] Localized: All UI strings in both ARB files

---

**Full documentation**: See `SKILL.md` for complete details, patterns, and examples.
