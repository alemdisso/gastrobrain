# Gastrobrain Documentation Master

Organize, update, and enrich project documentation through checkpoint-driven audits and post-implementation updates ensuring consistency and completeness.

## Quick Start

```bash
# In Claude Code, invoke the skill:
/gastrobrain-documentation-master

# Or use trigger phrases:
"Audit project documentation"
"Update documentation for #268"
"Document the recommendation engine"
"Write an ADR for meal type enum"
"Improve the README"
```

The skill will:
1. Detect context type (audit, post-implementation, or specific task)
2. Run the appropriate checkpoint process
3. Update/create documentation with user approval at each step
4. Verify accuracy and cross-references

## What This Skill Does

- Audits existing documentation for gaps and accuracy
- Updates documentation after code changes
- Creates new documentation using consistent templates
- Adds dartdoc comments to source files
- Generates architecture diagrams (Mermaid)
- Documents significant decisions (ADRs)
- Organizes documentation structure
- Verifies links and cross-references
- Enforces documentation standards

## Three Processes

### Process A: Full Audit (6 Checkpoints)

```
CP1: Inventory → CP2: Gap Analysis → CP3: Structure → CP4: Quality → CP5: Plan → CP6: Execute
 └─ Catalog all    └─ Find missing    └─ Assess org   └─ Check       └─ Prioritize  └─ Make
    docs              content            & navigation    accuracy       improvements    updates
```

**Use when:** Comprehensive documentation review needed.

### Process B: Post-Implementation Update (4 Checkpoints)

```
CP1: Identify Impacts → CP2: Update Core Docs → CP3: Add Code Docs → CP4: Create Examples
 └─ What docs need       └─ README, arch,        └─ Dartdoc for       └─ Guides, usage
    updating?               workflow docs            new/changed code     examples
```

**Use when:** Feature, fix, or refactoring has been completed.

### Process C: Specific Documentation Task (3 Checkpoints)

```
CP1: Plan → CP2: Draft → CP3: Review & Finalize
 └─ Outline   └─ Write      └─ Verify accuracy
    & scope      content        & save
```

**Use when:** Creating a specific document (architecture doc, ADR, pattern doc).

## Documentation Types Managed

| Type | Location | Example |
|------|----------|---------|
| Project Overview | `README.md` | Feature list, quick start |
| Architecture | `docs/architecture/` | System design, data models |
| Workflow Guides | `docs/workflows/` | Issue management, l10n |
| Testing Guides | `docs/testing/` | Dialog tests, edge cases |
| Feature Guides | `docs/guides/` | How to use meal types |
| Pattern Docs | `docs/patterns/` | Widget patterns, service patterns |
| Decision Records | `docs/decisions/` | ADR-001-meal-type-enum.md |
| Code Comments | `lib/` | Dartdoc in source files |

## Templates Included

| Template | Purpose |
|----------|---------|
| `feature_guide_template.md` | Document a new feature |
| `architecture_doc_template.md` | Document a component/service |
| `pattern_doc_template.md` | Capture a reusable pattern |
| `adr_template.md` | Record an architecture decision |
| `api_doc_template.md` | Document a service API |

## Standards Enforced

| Standard | File | Covers |
|----------|------|--------|
| Code Documentation | `code_documentation_standards.md` | Dartdoc conventions |
| Markdown | `markdown_standards.md` | Formatting rules |
| Diagrams | `diagram_standards.md` | Mermaid conventions |

## Example Walkthroughs

### Example 1: Post-Implementation Update
**Scenario:** Documentation update after implementing meal type feature (#XXX)
**Process:** 4 checkpoints - identify impacts, update core docs, add code docs, create guide
**See:** `examples/example_1_post_implementation.md`

### Example 2: Full Documentation Audit
**Scenario:** Comprehensive review of all project documentation
**Process:** 6 checkpoints - inventory, gaps, structure, quality, plan, execute
**See:** `examples/example_2_full_audit.md`

### Example 3: Architecture Documentation
**Scenario:** Creating architecture documentation for the recommendation engine
**Process:** 3 checkpoints - plan, draft, review
**See:** `examples/example_3_architecture_doc.md`

## Documentation Maintenance Checklist

After every feature/fix, before marking issue complete:

```
Core Documentation:
- [ ] README.md updated (if feature visible to users)
- [ ] Architecture docs updated (if structure changed)
- [ ] Workflow docs updated (if process changed)

Code Documentation:
- [ ] Public classes have dartdoc comments
- [ ] Public methods have dartdoc comments
- [ ] Complex logic has inline comments

Links & References:
- [ ] Internal links working
- [ ] Cross-references accurate
- [ ] New docs linked from parent docs
```

## When to Use This Skill

**Use when:**
- Feature branch completed, docs need updating
- Want comprehensive documentation review
- Creating architecture or pattern documentation
- Documenting a significant decision (ADR)
- Improving code documentation (dartdoc)
- Organizing documentation structure

**Don't use when:**
- Making code changes (use senior-dev-implementation)
- Running tests (use testing-implementation)
- Reviewing code quality (use code-review)
- Planning sprints (use sprint-planner)

## File Structure

```
gastrobrain-documentation-master/
├── SKILL.md                               # Complete skill documentation
├── README.md                              # This file
├── templates/
│   ├── feature_guide_template.md         # Feature documentation
│   ├── architecture_doc_template.md      # Architecture docs
│   ├── pattern_doc_template.md           # Pattern documentation
│   ├── adr_template.md                   # Decision records
│   └── api_doc_template.md               # API documentation
├── standards/
│   ├── code_documentation_standards.md   # Dartdoc conventions
│   ├── markdown_standards.md             # Markdown formatting
│   └── diagram_standards.md              # Mermaid diagram conventions
└── examples/
    ├── example_1_post_implementation.md  # Doc update after feature
    ├── example_2_full_audit.md           # Complete doc audit
    └── example_3_architecture_doc.md     # Creating arch docs
```

## References

- **SKILL.md**: Complete process documentation with all checkpoints
- **Templates**: Ready-to-use document templates
- **Standards**: Formatting and documentation conventions
- **Examples**: Real-world walkthrough scenarios
- **CLAUDE.md**: Project conventions and patterns

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: Ready for use
