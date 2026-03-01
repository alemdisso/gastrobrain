# Watchdog — core/services/

Inherits root rules from `lib/CLAUDE.md`. The overrides and additions below
apply to all files in `lib/core/services/`.

---

## Threshold Overrides

| Smell | Threshold | Severity | Notes |
|---|---|---|---|
| File length | > 200 lines | 🟡 High | Services growing large signals SRP drift |
| File length | > 350 lines | 🔴 Critical | |
| Public methods per class | > 7 | 🟡 High | Too broad a responsibility surface |
| Public methods per class | > 12 | 🔴 Critical | |

---

## Service-Specific Smells

| Smell | Trigger | Severity |
|---|---|---|
| Multiple responsibility domains | Service handles 2+ unrelated feature areas (e.g. meals + recipes) | 🟡 High |
| Direct UI imports | Service imports Flutter widgets or BuildContext | 🔴 Critical |
| Missing error handling | Public method with DB call but no try/catch or exception rethrow | 🟡 High |
| Inconsistent exception handling | Some methods catch, others don't, no clear pattern | 🟡 High |

---

## Healthy Service Pattern (reference)

```
[Feature]Service  → single feature domain
                  → depends on DatabaseHelper (injected)
                  → all public methods documented
                  → consistent exception handling (rethrow GastrobrainException)
                  → registered in ServiceProvider
                  → has corresponding test file
```

See `example_2_service_extraction.md` in the Refactoring Skill for a
complete walkthrough.