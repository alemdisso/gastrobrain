# Architecture Decision Record (ADR) Template

Use this template when documenting significant technical decisions.

**Location:** `docs/decisions/ADR-NNN-[kebab-case-title].md`

**Numbering:** Use sequential numbering (ADR-001, ADR-002, etc.). Check existing ADRs before assigning a number.

---

## When to Create an ADR

Create an ADR when:
- Choosing between multiple valid implementation approaches
- Making a decision that's hard to reverse later
- Selecting technology, libraries, or patterns that affect multiple components
- The rationale might not be obvious to future readers
- A decision was debated and the reasoning should be preserved

Do NOT create an ADR for:
- Routine implementation choices with only one reasonable option
- Minor formatting or naming decisions
- Temporary workarounds (document as TODO instead)

---

## Template

```markdown
# ADR-NNN: [Decision Title]

**Date:** YYYY-MM-DD
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-NNN]
**Issue:** #XXX (if related to a GitHub issue)

## Context

[What is the issue that we're seeing that motivates this decision?
What constraints exist? What requirements must be met?
Provide enough background for a future reader to understand the situation.]

## Decision

[What is the change that we're proposing and/or doing?
Be specific about the approach chosen.]

## Rationale

[Why did we choose this approach over alternatives?
What factors were most important in making this decision?]

Key factors:
- [Factor 1 - e.g., "Follows existing pattern used for FrequencyType"]
- [Factor 2 - e.g., "Simpler to implement and test"]
- [Factor 3 - e.g., "Meets current requirements without over-engineering"]

## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

### Negative

- [Trade-off 1]
- [Trade-off 2]

### Mitigation

- [How we address the negative consequences]
- [What we'd do if circumstances change]

## Alternatives Considered

### [Alternative 1 Name]

[Description of the alternative approach.]

**Rejected because:**
- [Reason 1]
- [Reason 2]

### [Alternative 2 Name]

[Description of the alternative approach.]

**Rejected because:**
- [Reason 1]
- [Reason 2]

## Implementation Notes

[Optional: Brief notes on how this decision was implemented.
Link to the relevant code, PR, or issue.]

- **Files affected:** [list key files]
- **Pattern used:** [reference if applicable]
- **Migration needed:** [Yes/No - describe if yes]
```

---

## ADR Status Definitions

| Status | Meaning |
|--------|---------|
| **Proposed** | Under discussion, not yet decided |
| **Accepted** | Decision made and in effect |
| **Deprecated** | No longer relevant (technology removed, feature deleted) |
| **Superseded** | Replaced by a newer ADR (link to replacement) |

---

## Usage Notes

- Keep ADRs short and focused on the decision, not the implementation details
- The Context section should be understandable by someone unfamiliar with the project
- Always document at least one alternative that was considered
- Update the Status field when circumstances change
- Never delete an ADR - mark it as Deprecated or Superseded instead
- Link ADRs from relevant architecture documentation
