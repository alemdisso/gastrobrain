# Gastrobrain Agent Skills

Agent skills for systematic, checkpoint-driven development workflow.

## Philosophy

All skills follow a **checkpoint-based approach**:
- Generate → Verify → Proceed
- One step at a time with user confirmation
- Early error detection
- High confidence in results

## Available Skills

### ✅ Implemented Skills

#### [Testing Implementation](gastrobrain-testing-implementation/)
**ONE test at a time to prevent pattern error propagation**

```
Triggers: "Implement Phase 3 for #XXX", "add tests for #XXX"
Approach: Generate test 1 → verify → learn → generate test 2 → verify...
Time: ~20-30 min for 5-8 tests
```

**Why it works:** Catches pattern errors in first test, not after writing 8 broken tests.

---

#### [Database Migration](gastrobrain-database-migration/)
**Checkpoint-based migrations with rollback verification**

```
Triggers: "Create migration for #XXX", "implement database changes"
Checkpoints: File → Up → Rollback → Model → Seed → Tests (4-7 total)
Time: ~15-50 min depending on complexity
```

**Why it works:** Database state verified at each step, rollback tested before proceeding.

---

#### [Code Review](gastrobrain-code-review/)
**Systematic pre-merge quality verification**

```
Triggers: "Review #XXX", "pre-merge check", "ready to merge"
Checkpoints: Git → Roadmap → Criteria → Tech → Quality → L10n → Merge (7 total)
Time: ~15-20 min
```

**Why it works:** Nothing overlooked, clear pass/warning/fail status, merge confidence.

---

### 📋 Skills with Creation Prompts (Ready to Implement)

#### Sprint Planning Skill
**Not yet implemented - creation prompt available**

```
Purpose: Sprint capacity planning with velocity insights
Triggers: "Help me plan sprint 0.1.X", "plan next sprint"
Approach: Analyze issues → velocity-based capacity → sequencing → risk assessment
```

**Status:** Creation prompt exists, skill implementation pending

#### Issue Roadmap Skill
**Not yet implemented - creation prompt available**

```
Purpose: Generate 4-phase roadmap for issue
Triggers: "I want to deal with #XXX", "create roadmap for #XXX"
Approach: Fetch issue → generate roadmap → identify files → testing strategy
```

**Status:** Creation prompt exists, skill implementation pending

---

### 🔮 Planned Skills (Coming Later)

- **Localization Update** - Bilingual ARB file management
- **UI Component Implementation** - Widget creation with conventions
- **Service/Repository Implementation** - Service layer patterns
- **Refactoring** - Safe refactoring with test coverage
- **Issue Closing** - Systematic issue finalization

See [Skills Master Index](../../docs/architecture/gastrobrain-skills-master-index.md) for details on planned skills.

---

## Quick Usage Examples

### Testing Implementation
```
You: "Implement Phase 3 testing for #199"
Skill: Analyzes roadmap, creates test plan with count (e.g., 6 tests)
       TEST 1/6 → [generates] → "Does it pass? (y/n)"
       TEST 2/6 → [applies learnings] → "Does it pass? (y/n)"
       ...continues until all tests complete
```

### Database Migration
```
You: "Create migration for #285"
Skill: Determines version (v13), plans 5 checkpoints
       CP 1/5: Migration file → "Ready? (y/n)"
       CP 2/5: Schema changes (up) → "Verify in DB? (y/n)"
       CP 3/5: Rollback (down) → "Test up→down→up? (y/n)"
       ...continues through all checkpoints
```

### Code Review
```
You: "Review #199"
Skill: Loads issue + roadmap, runs 7-checkpoint review
       CP 1/7: Git status ✓ Clean
       CP 2/7: Roadmap ✓ All phases complete
       CP 3/7: Acceptance criteria ✓ All met
       CP 4/7: flutter analyze ✓ 0 issues, flutter test ✓ 615 passing
       ...continues → generates merge instructions
```

---

## How Checkpoints Work

Every skill follows this pattern:

```
CHECKPOINT X/Y: [Name]
Goal: [What this accomplishes]

Tasks:
- [ ] Task 1
- [ ] Task 2

[Generates complete code/runs checks]

Verification:
[Specific steps to verify]

Database/System State After Checkpoint:
[Expected state]

Ready to proceed to Checkpoint X+1? (y/n)

[WAIT for user confirmation]
```

**Key principle:** Never rush. Verify each step before next.

---

## When to Use Each Skill

### Testing Implementation
- ✅ Ready to implement Phase 3 (Testing) from roadmap
- ✅ Want tests generated one-at-a-time with verification
- ✅ Need to avoid pattern errors propagating to all tests

### Database Migration
- ✅ Need to modify database schema
- ✅ Adding tables, columns, or indexes
- ✅ Want safe migrations with tested rollback

### Code Review
- ✅ Feature branch complete, ready for develop merge
- ✅ Want systematic pre-merge quality check
- ✅ Need confidence all standards met before merging

---

## Success Metrics

**Testing Implementation:**
- ✅ Tests pass on first try (patterns learned incrementally)
- ✅ No "fix 8 tests with same error" scenarios
- ✅ Faster overall (catch errors early)

**Database Migration:**
- ✅ Zero data loss incidents
- ✅ Rollback verified every time
- ✅ Migrations feel safer

**Code Review:**
- ✅ Fewer bugs after merge to develop
- ✅ Consistent quality standards
- ✅ Clear merge decisions

---

## Complete Documentation

For comprehensive overview including:
- **10-skill ecosystem** (3 implemented, 2 with creation prompts, 5 planned)
- **Skill interaction maps** (how skills work together)
- **Implementation roadmap** (phases 1-4)
- **Real-world examples** (Issue #199 walkthrough)
- **Success metrics and guidelines**

### Skills Status
- ✅ **Implemented** (3): Testing, Database Migration, Code Review
- 📋 **Creation prompts ready** (2): Sprint Planning, Issue Roadmap
- 🔮 **Planned** (5): Localization, UI Component, Service/Repository, Refactoring, Issue Closing

See: [**Skills Master Index**](../../docs/architecture/gastrobrain-skills-master-index.md)

---

## Development Guidelines

### Creating a New Skill

1. **Use it manually first** (3-5 times) to understand pain points
2. **Document manual workflow** with verification steps
3. **Design checkpoint structure** (4-7 checkpoints)
4. **Create SKILL.md** using existing skills as template
5. **Test with real work** and refine

### Checkpoint Design Principles

- **4-7 checkpoints** per skill (too few = risky, too many = tedious)
- **Each checkpoint verifiable** independently
- **User confirmation** between checkpoints
- **Clear success criteria** (what does "pass" mean?)
- **Remediation guidance** if checkpoint fails

---

## Directory Structure

```
.github/skills/
├── README.md (this file)
├── gastrobrain-testing-implementation/
│   ├── SKILL.md
│   ├── README.md
│   ├── templates/
│   └── examples/
├── gastrobrain-database-migration/
│   ├── SKILL.md
│   ├── README.md
│   ├── templates/
│   └── examples/
└── gastrobrain-code-review/
    ├── SKILL.md
    ├── README.md (pending)
    ├── templates/ (pending)
    └── examples/ (pending)
```

Each skill directory contains:
- **SKILL.md** - Complete skill documentation
- **README.md** - Quick reference
- **templates/** - Checkpoint templates
- **examples/** - Real-world examples

---

## Questions?

- **Architecture overview:** See [Skills Master Index](../../docs/architecture/gastrobrain-skills-master-index.md)
- **Testing patterns:** See [Testing Guide](../../docs/testing/)
- **Workflow:** See [Issue Workflow](../../docs/workflows/ISSUE_WORKFLOW.md)

---

**Version:** 1.0.0
**Last Updated:** January 2026
**Skills Implemented:** 3/10 (Testing, Database, Code Review)
