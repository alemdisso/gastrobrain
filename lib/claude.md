# Gastrobrain Code Quality Watchdog — Root Rules

This file governs all subdirectories under `lib/`. Subfolder `CLAUDE.md` files
inherit these rules and only declare what differs for their context.

---

## Watchdog Triggers

### Trigger 1 — Modification (always active)

After **any file modification or creation**, silently check the touched file
against the active thresholds (root thresholds below, overridden by subfolder
files where present). If a threshold is tripped, append a proto-issue to
`.github/refactoring-backlog.md` (create if it doesn't exist), then continue.

### Trigger 2 — Analysis mode (planning/review skills only)

When a skill explicitly reads files for planning purposes — issue creation,
roadmap analysis, code review, or refactoring audit — check each file read
against the active thresholds and flag violations directly to the backlog
**without** requiring a file modification to have occurred.

Analysis mode applies when operating inside these skills:
- Issue Creation Skill
- Issue Roadmap Skill
- Code Review Skill
- Refactoring Skill (Checkpoint 1 — Code Analysis)
- Sprint Planning Skill

Analysis mode does **not** apply during implementation (Senior Developer Skill,
UI Component Skill, etc.) — those are covered by Trigger 1.

In both triggers, the same blocking rules apply: 🔴 Critical surfaces a
one-line notice, 🟡 High is silent.

---

## Default Thresholds (all lib/ subdirectories)

| Smell | Threshold | Severity |
|---|---|---|
| File length | > 300 lines | 🟡 High |
| File length | > 500 lines | 🔴 Critical |
| Method length | > 50 lines | 🟡 High |
| Method length | > 100 lines | 🔴 Critical |

---

## Proto-Issue Format

```
- [ ] 🔴 `lib/path/to/file.dart` — <smell> — flagged during: <brief context> — <YYYY-MM-DD>
```

Use 🔴 for Critical, 🟡 for High. One line per violation.

---

## Rules (apply everywhere)

- **Silent checking** — Never announce that a check is being performed.
- **🟡 High violations** — Append to backlog silently. Do not surface in response.
- **🔴 Critical violations** — Append to backlog AND emit a single line in the response before continuing:
  `⚠️ \`path/to/file.dart\` → refactoring-backlog.md (<smell>, 🔴 Critical)`
- **Non-blocking** — Never pause, ask for confirmation, or interrupt skill checkpoints. The notice is informational, not a gate.
- **No duplicates** — Check before appending: skip if same file + same smell already exists in the backlog.
- **No triaging** — Just flag. Prioritization happens during Sprint Planning.

---

## Integration

Backlog feeds the **Refactoring Skill** (`.github/skills/gastrobrain-refactoring/SKILL.md`).
Review `.github/refactoring-backlog.md` during Sprint Planning as part of the 20% quality allocation.