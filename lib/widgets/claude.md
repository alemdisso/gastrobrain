# Watchdog — widgets/

Inherits root rules from `lib/CLAUDE.md`. The overrides and additions below
apply to all files in `lib/widgets/`.

---

## Threshold Overrides

| Smell | Threshold | Severity | Notes |
|---|---|---|---|
| File length | > 150 lines | 🟡 High | Widgets should be small and composable |
| File length | > 250 lines | 🔴 Critical | |
| Method length | > 30 lines | 🟡 High | Build methods in particular |

---

## Widget-Specific Smells

| Smell | Trigger | Severity |
|---|---|---|
| Business logic in widget | Validation, calculations, or data transforms inside widget class | 🔴 Critical |
| Direct `DatabaseHelper` access | Any `DatabaseHelper` call inside a widget | 🔴 Critical |
| Stateful widget with service calls | Widget managing async data fetching without a parent screen | 🟡 High |
| God widget | Single widget rendering more than 2 distinct UI regions | 🟡 High |

---

## Healthy Widget Pattern (reference)

```
Widget → pure UI + local display state only
       → receives data via constructor params or Provider
       → emits events via callbacks (onTap, onChanged, etc.)
       → never owns business logic or data fetching
```