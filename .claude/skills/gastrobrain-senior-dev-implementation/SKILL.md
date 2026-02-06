---
name: gastrobrain-senior-dev-implementation
description: Phase 2 implementation with checkpoint-driven development
version: 1.0.0
---

# Gastrobrain Senior Developer Implementation Skill

## Purpose

Acts as an experienced Flutter/Dart developer implementing Phase 2 (Implementation) of issue roadmaps using checkpoint-driven development with pattern detection, quality verification, and skill delegation.

**Core Philosophy**: Pattern-First → Checkpoint → Verify → Next Checkpoint

## When to Use This Skill

### Trigger Patterns

Use this skill when:
- "Implement Phase 2 for #XXX"
- "Start implementing #XXX"
- "Execute the implementation for issue #XXX"
- "Begin Phase 2 work on #XXX"
- Ready to implement after completing Phase 1 analysis

### Automatic Actions

When triggered:
1. **Detect context** from current branch
2. **Load roadmap** from docs/planning/
3. **Parse Phase 2** implementation requirements
4. **Detect patterns** needed (model, service, widget, provider)
5. **Generate checkpoint plan** with appropriate count
6. **Execute checkpoints** with verification gates

### Do NOT Use This Skill

- For Phase 1 analysis (use `gastrobrain-issue-roadmap` instead)
- For Phase 3 testing (delegate to `gastrobrain-testing-implementation`)
- For database migrations specifically (delegate to `gastrobrain-database-migration`)
- For exploration or research tasks

## Context Detection

### Automatic Analysis Flow

```
1. Detect current branch: feature/XXX-description
2. Extract issue number: XXX
3. Locate roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
4. Parse Phase 2 (Implementation) section
5. Identify implementation categories:
   - Database changes → Delegate to database-migration skill
   - Model changes → Apply model pattern
   - Service changes → Apply service pattern
   - Widget changes → Apply widget pattern
   - Provider changes → Apply provider pattern
   - Localization → Handle inline with ARB updates
```

### Initial Context Output

```
Phase 2 Implementation for Issue #XXX
═══════════════════════════════════════

Branch: feature/XXX-description
Roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md

Phase 2 Requirements Summary:
[Parsed from roadmap]

Implementation Categories Detected:
├─ Database: [Yes/No] → [if yes: "Delegate to gastrobrain-database-migration"]
├─ Models: [List of models to modify/create]
├─ Services: [List of services to modify/create]
├─ Widgets: [List of widgets to modify/create]
├─ Providers: [List of providers to modify/create]
└─ Localization: [Number of strings to add]

Pattern References Found:
- [Similar implementation 1]: lib/path/to/similar.dart
- [Similar implementation 2]: lib/path/to/another.dart

Checkpoint Plan:
1. [Checkpoint name] - [Brief description]
2. [Checkpoint name] - [Brief description]
...
N. [Checkpoint name] - [Brief description]

Total: N checkpoints

Ready to start Checkpoint 1/N? (y/n)
```

## Pattern Detection Mechanism

### How Patterns Are Detected

Before each checkpoint, scan the codebase for similar implementations:

```
1. Identify what needs to be created/modified
2. Search for similar patterns in codebase:
   - Enums → Look in lib/models/ for similar enums
   - Models → Look in lib/models/ or lib/core/models/
   - Services → Look in lib/core/services/
   - Widgets → Look in lib/widgets/ or lib/screens/
   - Providers → Look in lib/core/providers/
3. Extract the pattern structure
4. Present in checkpoint context
```

### Pattern Context in Checkpoints

Each checkpoint includes:

```
Pattern Context:
- Similar implementation: lib/models/meal_type.dart
- Key patterns to follow:
  • [Pattern element 1]
  • [Pattern element 2]
  • [Pattern element 3]
```

## Checkpoint Structure

### Standard Checkpoint Format

```
═══════════════════════════════════════
CHECKPOINT X/Y: [Checkpoint Name]
Goal: [One sentence describing what this accomplishes]

Pattern Context:
- Similar implementation: [path/to/similar/file.dart]
- Key patterns:
  • [Pattern 1 to follow]
  • [Pattern 2 to follow]

Progress:
✓ Checkpoint 1: [Name] [COMPLETE]
✓ Checkpoint 2: [Name] [COMPLETE]
⧗ Checkpoint X: [Name] [CURRENT]
○ Checkpoint X+1: [Name]
...

Tasks:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

[Generate complete implementation code]

Files Modified:
- [file path]: [what changed]

Verification Steps:
1. flutter analyze [specific file]
2. [Specific verification step]
3. [Specific verification step]

Ready to proceed to Checkpoint [X+1]/Y? (y/n)

[STOP - WAIT for user response]
═══════════════════════════════════════
```

### Response Handling

**If user responds "y" (checkpoint verified):**

```
✅ CHECKPOINT X/Y complete

Progress: X/Y checkpoints ████░░ XX%

[If X < Y:]
Ready for CHECKPOINT (X+1)/Y? (y/n)

[If X == Y:]
🎉 Phase 2 Implementation Complete!

[Show summary]
```

**If user responds "n" (checkpoint failed):**

```
❌ CHECKPOINT X/Y verification failed

Let's debug before proceeding. What issue are you seeing?

Common issues for [checkpoint type]:
1. [Common issue 1]
2. [Common issue 2]
3. [Common issue 3]

[WAIT for user input, then diagnose and fix]
```

## Implementation Categories

### Category 1: Simple UI Fix (3-4 checkpoints)

**Typical for**: Layout bugs, SafeArea issues, overflow fixes

```
Checkpoint 1: Analyze and prepare
Checkpoint 2: Implement UI changes
Checkpoint 3: Verify responsive behavior
Checkpoint 4: Update localization (if needed)
```

### Category 2: Service Logic (4-5 checkpoints)

**Typical for**: New business logic, service extraction, algorithm changes

```
Checkpoint 1: Create/update service structure
Checkpoint 2: Implement core logic
Checkpoint 3: Add error handling
Checkpoint 4: Integrate with ServiceProvider
Checkpoint 5: Update callers (if needed)
```

### Category 3: Feature with Database (6-8 checkpoints)

**Typical for**: New features requiring schema changes

```
Checkpoint 1: [DELEGATE] Database migration → gastrobrain-database-migration
Checkpoint 2: Model class updates
Checkpoint 3: Service layer implementation
Checkpoint 4: UI components
Checkpoint 5: Wire up with providers
Checkpoint 6: Localization strings
Checkpoint 7: Error handling polish
Checkpoint 8: Integration verification
```

### Category 4: Widget/Screen (5-6 checkpoints)

**Typical for**: New screens, complex widgets, UI components

```
Checkpoint 1: Widget structure and state
Checkpoint 2: Core UI implementation
Checkpoint 3: User interactions
Checkpoint 4: Data binding and state management
Checkpoint 5: Localization
Checkpoint 6: Responsive design verification
```

## Skill Delegation

### When to Delegate

**Database Migration** → `gastrobrain-database-migration`
```
═══════════════════════════════════════
CHECKPOINT X/Y: Database Schema Changes
Goal: Implement required database migration

⚠️ DELEGATION REQUIRED

This checkpoint requires database migration work. Delegating to:
→ gastrobrain-database-migration skill

The database migration skill will:
1. Create migration file with proper versioning
2. Implement up() and down() methods
3. Verify rollback works
4. Update model classes

After database migration completes, return here for Checkpoint (X+1)/Y.

Hand off to database migration skill? (y/n)
═══════════════════════════════════════
```

**Testing Phase** → `gastrobrain-testing-implementation`
```
═══════════════════════════════════════
PHASE 2 COMPLETE - TESTING HANDOFF

All implementation checkpoints completed successfully.
Phase 3 (Testing) should be handled by:
→ gastrobrain-testing-implementation skill

The testing skill will:
1. Create test file structure
2. Implement tests one at a time
3. Verify each test before proceeding
4. Cover edge cases per Issue #39

Ready to hand off to testing implementation? (y/n)
═══════════════════════════════════════
```

### Localization (Inline Handling)

Localization is handled within implementation checkpoints, not delegated:

```
═══════════════════════════════════════
CHECKPOINT X/Y: Localization
Goal: Add all user-facing strings to ARB files

Files to modify:
- lib/l10n/app_en.arb
- lib/l10n/app_pt.arb

Strings to add:
1. [key1]: "[English]" / "[Portuguese]"
2. [key2]: "[English]" / "[Portuguese]"
...

After adding strings:
Run: flutter gen-l10n

Verification:
1. flutter analyze lib/l10n/
2. Verify AppLocalizations.of(context)!.[key] compiles
3. Test both locales visually (if applicable)
═══════════════════════════════════════
```

## Quality Gates

### Every Checkpoint Verification

1. **Static Analysis**
   ```bash
   flutter analyze [modified files]
   # Must pass with no errors, warnings acceptable
   ```

2. **File Length Check**
   ```
   Each file should be < 400 lines
   If exceeding, consider extraction in next checkpoint
   ```

3. **SOLID Principles**
   - Single Responsibility: Each class/function has one purpose
   - Open/Closed: Extended via new code, not modification
   - Liskov Substitution: Subtypes work in parent contexts
   - Interface Segregation: Small, focused interfaces
   - Dependency Inversion: Depend on abstractions

4. **Pattern Compliance**
   - Follows detected pattern from codebase
   - Consistent with existing code style
   - Uses Gastrobrain conventions (ServiceProvider, exceptions, etc.)

5. **Test Readiness**
   - Dependency injection in place
   - Testable method signatures
   - No hard-coded dependencies that block testing

## Roadmap Synchronization

### Marking Progress

After each checkpoint, update the roadmap checkbox:

```
Before:
- [ ] Update model class with new field

After:
- [x] Update model class with new field
```

### Completion Summary

When Phase 2 completes:

```
═══════════════════════════════════════
PHASE 2 IMPLEMENTATION SUMMARY
═══════════════════════════════════════

Issue: #XXX
Branch: feature/XXX-description

Checkpoints Completed:
✓ Checkpoint 1: [Name]
✓ Checkpoint 2: [Name]
...
✓ Checkpoint N: [Name]

Files Modified:
- lib/models/[model].dart [MODIFIED]
- lib/core/services/[service].dart [NEW]
- lib/widgets/[widget].dart [MODIFIED]
- lib/l10n/app_en.arb [MODIFIED]
- lib/l10n/app_pt.arb [MODIFIED]

Quality Verification:
✓ flutter analyze passes
✓ All files < 400 lines
✓ Patterns followed correctly
✓ DI in place for testing

Roadmap Updated:
- docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
  └─ Phase 2 checkboxes marked complete

Next Steps:
1. ○ Hand off to gastrobrain-testing-implementation for Phase 3
2. ○ After testing, proceed to Phase 4 (Documentation & Cleanup)

═══════════════════════════════════════
```

## Common Gastrobrain Patterns

### Dependency Injection Pattern

```dart
// In widget/screen
class MyScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  const MyScreen({super.key, this.databaseHelper});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
  }
}
```

### Service Pattern

```dart
class MyService {
  final DatabaseHelper _dbHelper;

  MyService(this._dbHelper);

  Future<Result> doSomething(String param) async {
    try {
      // Implementation
      return Result.success(data);
    } on NotFoundException {
      // Handle not found
      rethrow;
    } on ValidationException {
      // Handle validation errors
      rethrow;
    } catch (e) {
      throw GastrobrainException('Operation failed: $e');
    }
  }
}
```

### Enum Pattern

```dart
import '../l10n/app_localizations.dart';

enum MyType {
  option1('option1'),
  option2('option2');

  final String value;
  const MyType(this.value);

  static MyType? fromString(String? value) {
    if (value == null) return null;
    return MyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MyType.option1,
    );
  }

  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case MyType.option1:
        return l10n.myTypeOption1;
      case MyType.option2:
        return l10n.myTypeOption2;
    }
  }
}
```

### Widget State Management Pattern

```dart
class _MyWidgetState extends State<MyWidget> {
  late MyService _service;
  bool _isLoading = true;
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _service = MyService(widget.databaseHelper ?? ServiceProvider.database.dbHelper);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getItems();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError(context, 'Error loading data');
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers, subscriptions, etc.
    super.dispose();
  }
}
```

### Model Pattern

```dart
class MyModel {
  final String id;
  final String name;
  final MyType? type;

  MyModel({
    required this.id,
    required this.name,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type?.value,
    };
  }

  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: MyType.fromString(map['type'] as String?),
    );
  }

  MyModel copyWith({
    String? id,
    String? name,
    MyType? type,
  }) {
    return MyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### Provider Pattern

```dart
import 'package:flutter/foundation.dart';
import '../errors/gastrobrain_exceptions.dart';

class MyProvider extends ChangeNotifier {
  final MyRepository _repository;

  List<Item> _items = [];
  bool _isLoading = false;
  GastrobrainException? _error;

  // Getters
  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  GastrobrainException? get error => _error;

  MyProvider(this._repository);

  Future<void> loadItems() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.getAll();
    } on GastrobrainException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(Item item) async {
    try {
      await _repository.create(item);
      _items.add(item);
      notifyListeners();
      return true;
    } on GastrobrainException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
```

## Error Handling and Debugging

### Common Checkpoint Issues

**Checkpoint 1 (Setup/Structure):**
- Compilation errors → Check imports and types
- Pattern mismatch → Review reference file more carefully
- Missing dependency → Add to ServiceProvider

**Checkpoint 2-N (Implementation):**
- Logic errors → Review similar patterns in codebase
- Type mismatches → Check model definitions
- Null safety issues → Verify nullable types

**Localization Checkpoint:**
- gen-l10n fails → Check ARB syntax (valid JSON)
- Missing key → Ensure key exists in both app_en.arb and app_pt.arb
- Placeholder mismatch → Verify placeholder names match

### Debug Protocol

When a checkpoint fails:

```
1. Get exact error message from user
2. Analyze the error type:
   - Compilation error → Syntax or type issue
   - Runtime error → Logic or null safety issue
   - Static analysis warning → Code quality issue
3. Provide targeted fix
4. Re-verify before proceeding
```

## Success Criteria

This skill succeeds when:

1. **Pattern-First**: Every implementation follows detected codebase patterns
2. **Checkpoint-Driven**: User confirms each checkpoint before proceeding
3. **Quality Gates**: Every checkpoint passes flutter analyze
4. **Proper Delegation**: Database and testing work delegated to specialized skills
5. **Roadmap Sync**: Checkboxes updated as work completes
6. **Test-Ready**: All code has DI and is testable
7. **Localized**: All UI strings in both ARB files
8. **Clean Progress**: Clear visibility into completion status

## References

### Pattern Reference Files

| Pattern | Reference File |
|---------|----------------|
| Enum | `lib/models/meal_type.dart` |
| Model | `lib/models/recipe.dart` |
| Service | `lib/core/services/recommendation_cache_service.dart` |
| Widget/Screen | `lib/screens/weekly_plan_screen.dart` |
| Provider | `lib/core/providers/recipe_provider.dart` |
| Exception | `lib/core/errors/gastrobrain_exceptions.dart` |
| DI | `lib/core/di/service_provider.dart` |

### Related Skills

| Skill | When to Delegate |
|-------|------------------|
| `gastrobrain-database-migration` | Schema changes required |
| `gastrobrain-testing-implementation` | Phase 3 testing work |
| `gastrobrain-issue-roadmap` | Need to review/create roadmap |
| `gastrobrain-refactoring` | Extraction needed during implementation |

### Documentation

| Doc | Purpose |
|-----|---------|
| `CLAUDE.md` | Project conventions and patterns |
| `docs/architecture/Gastrobrain-Codebase-Overview.md` | Architecture details |
| `docs/workflows/L10N_PROTOCOL.md` | Localization guidelines |
| `docs/testing/EDGE_CASE_TESTING_GUIDE.md` | Testing standards |

---

**Remember**: An experienced developer writes code that follows patterns, handles edge cases, and is immediately testable. Quality over speed. Each checkpoint verified before the next.
