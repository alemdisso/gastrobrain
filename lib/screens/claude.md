# Watchdog — screens/

Inherits root rules from `lib/CLAUDE.md`. The overrides and additions below
apply to all files in `lib/screens/`.

---

## Threshold Overrides

| Smell | Threshold | Severity | Notes |
|---|---|---|---|
| File length | > 250 lines | 🟡 High | Screens bloat faster than other files |
| File length | > 400 lines | 🔴 Critical | |
| Method length | > 40 lines | 🟡 High | UI methods should stay concise |

---

## Screen-Specific Smells

| Smell | Trigger | Severity |
|---|---|---|
| Direct `DatabaseHelper` access | Any `DatabaseHelper` call outside a service | 🔴 Critical |
| Business logic in build methods | Calculations, validation, or data transforms inside `build()` | 🟡 High |
| 3+ distinct responsibilities | State + UI + DB + business logic mixed | 🟡 High |
| Missing service injection | Screen manages data without a service layer | 🟡 High |

---

## Healthy Screen Pattern (reference)

```
Screen → State management + UI only
      → delegates data ops to [Feature]Service
      → delegates business logic to [Operation]Service
```

See `example_1_long_screen_refactor.md` in the Refactoring Skill for a
complete walkthrough.