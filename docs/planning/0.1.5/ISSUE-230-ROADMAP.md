# Issue #230: Add Test Coverage Reporting

**Issue:** [#230](https://github.com/alemdisso/gastrobrain/issues/230)
**Type:** Infrastructure
**Priority:** P1 - Critical (blocks other issues)
**Estimate:** S = 2 points (~3-5 hours)
**Status:** Planning

---

## Overview

Set up automated test coverage reporting using Codecov to provide visibility into testing quality.

**Current State:**
- CI workflow already has Codecov action configured (`.github/workflows/ci.yml`)
- `CODECOV_TOKEN` may need to be added to GitHub secrets
- Coverage badge NOT in README
- Local coverage documentation incomplete

**Goal:**
- Codecov integration fully active
- Coverage badge visible in README
- Local development workflow documented
- Coverage exclusion script for generated files

---

## Prerequisites

- GitHub repository access
- Codecov account (free for open source)

## Dependencies

- **Blocks:** #247, #248, #249 (coverage improvement issues)
- **Blocked by:** None

---

## Implementation Phases

### Phase 1: Verify/Setup Codecov Account

**Objective:** Ensure Codecov integration is properly configured

**Tasks:**
- [ ] Create Codecov account at https://codecov.io (if not exists)
- [ ] Link GitHub repository to Codecov
- [ ] Obtain `CODECOV_TOKEN` from Codecov dashboard
- [ ] Verify `CODECOV_TOKEN` is in GitHub repository secrets
- [ ] If missing, add token to Settings > Secrets and variables > Actions

**Verification:**
- [ ] Codecov dashboard shows repository
- [ ] GitHub secrets contains `CODECOV_TOKEN`

**Estimated time:** 30-45 minutes

---

### Phase 2: Verify CI Integration

**Objective:** Confirm coverage is uploading correctly

**Tasks:**
- [ ] Review existing CI workflow (already has Codecov action)
- [ ] Trigger a test run on develop branch
- [ ] Check Codecov dashboard for uploaded coverage report
- [ ] Verify coverage data appears correctly

**Current CI Configuration** (`.github/workflows/ci.yml`):
```yaml
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage reports to Codecov
  uses: codecov/codecov-action@v4
  with:
    file: coverage/lcov.info
    fail_ci_if_error: false
    token: ${{ secrets.CODECOV_TOKEN }}
```

**If coverage not uploading:**
- [ ] Check CI logs for Codecov action errors
- [ ] Verify token is valid and not expired
- [ ] Check if `coverage/lcov.info` is being generated

**Verification:**
- [ ] Codecov shows coverage report from recent CI run
- [ ] Coverage percentage is visible in dashboard

**Estimated time:** 30-60 minutes

---

### Phase 3: Add Coverage Badge to README

**Objective:** Display coverage percentage badge in README

**Tasks:**
- [ ] Get badge markdown from Codecov dashboard
- [ ] Add badge to top of README.md (after title)
- [ ] Format: `[![codecov](https://codecov.io/gh/alemdisso/gastrobrain/graph/badge.svg)](https://codecov.io/gh/alemdisso/gastrobrain)`

**Location in README.md:**
```markdown
# Gastrobrain

[![codecov](https://codecov.io/gh/alemdisso/gastrobrain/graph/badge.svg)](https://codecov.io/gh/alemdisso/gastrobrain)

A personal cooking companion app...
```

**Verification:**
- [ ] Badge displays in GitHub README
- [ ] Badge shows current coverage percentage
- [ ] Clicking badge links to Codecov report

**Estimated time:** 15 minutes

---

### Phase 4: Document Local Coverage Workflow

**Objective:** Enable developers to generate coverage reports locally

**Tasks:**
- [ ] Add "Test Coverage" section to README.md
- [ ] Document local coverage generation commands
- [ ] Include lcov installation instructions
- [ ] Link to full coverage report

**Content to add to README.md (in "Running Tests" section):**
```markdown
### Test Coverage

Generate coverage report locally:
```bash
# Generate coverage
flutter test --coverage

# View summary (requires lcov)
lcov --summary coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html  # Linux
```

**Current coverage:** [![codecov](https://codecov.io/gh/alemdisso/gastrobrain/graph/badge.svg)](https://codecov.io/gh/alemdisso/gastrobrain)

**Full report:** [Codecov Dashboard](https://codecov.io/gh/alemdisso/gastrobrain)
```

**Verification:**
- [ ] README contains coverage documentation
- [ ] Commands work in WSL environment
- [ ] Links to Codecov dashboard work

**Estimated time:** 30 minutes

---

### Phase 5: Coverage Exclusions (Optional)

**Objective:** Exclude generated files from coverage reports

**Tasks:**
- [ ] Create `coverage/lcov_exclude.sh` script
- [ ] Exclude patterns: `*.g.dart`, `*.freezed.dart`, `lib/l10n/*.dart`, `lib/main.dart`
- [ ] Update CI workflow to run exclusion script (if needed)
- [ ] Test exclusions locally

**Script content:**
```bash
#!/bin/bash
# Remove generated files from coverage report
lcov --remove coverage/lcov.info \
  '*.g.dart' \
  '*.freezed.dart' \
  'lib/l10n/*.dart' \
  'lib/main.dart' \
  -o coverage/lcov.info
```

**Note:** This phase is optional - can be deferred if coverage looks reasonable without exclusions.

**Verification:**
- [ ] Generated files excluded from coverage metrics
- [ ] Coverage percentage reflects tested code only

**Estimated time:** 30 minutes (if needed)

---

### Phase 6: Final Verification

**Objective:** Confirm everything works end-to-end

**Tasks:**
- [ ] Create a test PR or push to develop
- [ ] Verify Codecov comments on PR (if enabled)
- [ ] Confirm badge updates after merge
- [ ] Verify coverage trend is being tracked
- [ ] Run `flutter analyze` - no issues
- [ ] Run `flutter test` - all pass

**Verification:**
- [ ] Codecov integration fully functional
- [ ] Badge displays correct percentage
- [ ] Documentation complete
- [ ] No regressions

**Estimated time:** 15-30 minutes

---

## Deliverables Checklist

- [ ] Codecov account linked to repository
- [ ] `CODECOV_TOKEN` in GitHub secrets
- [ ] Coverage badge in README.md
- [ ] Local coverage documentation in README.md
- [ ] Coverage exclusion script (optional)
- [ ] Coverage visible in Codecov dashboard

---

## Risk Assessment

**Low Risk:**
- Using established external service (Codecov)
- CI integration already partially exists
- No code changes required (only documentation and config)

**Potential Issues:**
- Codecov token might need refresh
- Badge might cache old values initially
- lcov might not be installed in WSL

**Mitigations:**
- Check Codecov documentation for token issues
- Badge updates are usually quick (within minutes)
- Document lcov installation: `sudo apt-get install lcov`

---

## Success Criteria

- [ ] Codecov dashboard shows coverage for gastrobrain
- [ ] README displays coverage badge with percentage
- [ ] Clicking badge links to detailed Codecov report
- [ ] Local coverage generation works
- [ ] Coverage data enables #247, #248, #249 work

---

## Reference Documentation

- [docs/testing/TEST_COVERAGE_SETUP.md](../../testing/TEST_COVERAGE_SETUP.md) - Best practices guide
- [Codecov Documentation](https://docs.codecov.io/)
- [Flutter Test Coverage](https://docs.flutter.dev/cookbook/testing/coverage)

---

## Notes

- CI already has `flutter test --coverage` and Codecov action
- Focus is on verification and documentation, not new setup
- This is foundational for all coverage improvement work in 0.1.5
