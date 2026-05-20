# Issue #383 Roadmap — Auto-rollback to last known good schema version

**Issue**: safety: auto-rollback to last known good schema version when migration fails  
**Branch**: feature/383-auto-rollback-migration-failure  
**Milestone**: 0.2.12 — Architecture & Editor  
**Story Points**: 8 (8.0 adjusted)

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary
When a migration fails at startup, the app currently records the error but leaves the
database in a partially-migrated state. `rollbackToVersion()` exists in `MigrationRunner`
but is only wired to the developer screen. This issue connects it to the startup failure
path so the database always returns to a known-good version, with a blocking error screen
when rollback itself fails.

### Technical Design Decision

**Selected Approach:** Pre-acknowledge on success + severity filter

On every successful startup, all previous error records are acknowledged (cleared). When
migrations fail, a new error is recorded with `severity = 'warning'` (rollback succeeded)
or `severity = 'fatal'` (rollback failed). This eliminates the stale-fatal-screen-after-
recovery bug and ensures the error screen is shown on every broken launch.

**Alternatives Considered:**
- Explicit acknowledge per severity: rejected — old fatal records persist after a fix ships,
  causing the error screen to re-appear on an otherwise healthy launch.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| addPostFrameCallback + mounted | `home_screen.dart:26-43` | Fatal routing in initState |
| sqflite_ffi in-memory test | `migration_integration_test.dart:37-51` | Test setup |
| _BrokenMigration inner class | `migration_integration_test.dart:18-35` | Broken migration for tests |
| kDebugMode guard | `package:flutter/foundation.dart` | Debug-only technical detail |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| No-op down() (migration 107) | Rollback succeeds naturally; empty down() doesn't throw |
| First migration fails (no partial state) | Guard: skip rollback if currentVersion == versionBefore |
| Rollback fails (fatal) | Inner try/catch; record 'fatal'; show MigrationErrorScreen |
| Successful launch after previous fatal | _acknowledgeAllMigrationErrors() in success path |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| ArgumentError from rollbackToVersion when nothing to rollback | Medium | Guard with currentVersion > versionBefore |
| Widget tree not ready for navigation in initState | Medium | addPostFrameCallback + !mounted |
| ALTER TABLE fails on fresh install (column already in CREATE TABLE) | Low | PRAGMA table_info check before ALTER |

### Implementation Checklist (Phase 2)

- [ ] Step 1a: Update `_ensureMigrationErrorsTable` — add severity to schema + ALTER TABLE fallback
- [ ] Step 1b: Update `_recordMigrationFailure` — add `String severity` param
- [ ] Step 1c: Add `_acknowledgeAllMigrationErrors()` private method
- [ ] Step 1d: Add `_attemptRollbackAndRecord()` private helper
- [ ] Step 1e: Restructure `_initializeMigrationSystem` — capture versionBefore, split try/catch
- [ ] Step 1f: Update `hasPendingMigrationFailure()` — filter to `severity = 'warning'`
- [ ] Step 1g: Add `hasFatalMigrationError()` public method
- [ ] Step 2: Create `lib/screens/migration_error_screen.dart`
- [ ] Step 3: Update `home_screen.dart` — fatal routing before warning check
- [ ] Step 4: Add l10n strings to app_en.arb + app_pt.arb; run flutter gen-l10n
- [ ] Step 5: Write `test/database/migration_rollback_test.dart`
- [ ] Step 6: `flutter test && flutter analyze`

### Files Summary

**To Create:**
- `lib/screens/migration_error_screen.dart`
- `test/database/migration_rollback_test.dart`

**To Modify:**
- `lib/database/database_helper.dart` (severity column, rollback wiring, new methods)
- `lib/screens/home_screen.dart` (fatal routing)
- `lib/l10n/app_en.arb` (+2 strings)
- `lib/l10n/app_pt.arb` (+2 strings)

---

*Phase 1 analysis completed: 2026-05-19*  
*Ready for Phase 2 implementation*
