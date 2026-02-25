# Gastrobrain Code Quality Watchdog — Root Rules

This file governs all subdirectories under `lib/`. Subfolder `CLAUDE.md` files
inherit these rules and only declare what differs for their context.

---

## Passive Watchdog Behavior

After **any file modification or creation**, silently check the touched file
against the active thresholds (root thresholds below, overridden by subfolder
files where present). Do not announce the check or interrupt the main task.

If a threshold is tripped, append a proto-issue to `.github/refactoring-backlog.md`
(create the file if it doesn't exist), then continue normally.

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

- **Silent** — Never mention the watchdog check in responses.
- **Non-blocking** — Never pause the main task or ask for confirmation.
- **No duplicates** — Check before appending: skip if same file + same smell already exists in the backlog.
- **No triaging** — Just flag. Prioritization happens during Sprint Planning.
- **Not a blocker** — A flagged file does not prevent feature work from proceeding.

---

## Integration

Backlog feeds the **Refactoring Skill** (`.github/skills/gastrobrain-refactoring/SKILL.md`).
Review `.github/refactoring-backlog.md` during Sprint Planning as part of the 20% quality allocation.