# Test Coverage Reporting - Best Practices Guide

**Document Version:** 1.0
**Last Updated:** 2025-12-31
**Project Stage:** 0.1.4 - Early development, growing test suite

---

## Overview

This document outlines best practices for implementing test coverage reporting in Gastrobrain, tailored to our current project stage (early versions, active testing infrastructure development).

## Recommended Approach

### 1. Use Codecov (External Service)

**Decision:** Use [Codecov](https://codecov.io) for coverage tracking and reporting.

**Why Codecov:**
- ✅ **Free for open source** projects
- ✅ **Zero maintenance** - hosted service, no infrastructure to manage
- ✅ **Great UI** - visual coverage reports, file browser, trend graphs
- ✅ **Easy GitHub integration** - automatic PR comments showing coverage changes
- ✅ **Automatic badges** - beautiful, up-to-date coverage badges
- ✅ **Industry standard** - most Flutter/Dart projects use it

**vs. Self-hosted alternatives:**
- ❌ More work to maintain
- ❌ Need to host artifacts and generate reports manually
- ❌ Manual badge generation
- ❌ Less visibility and fewer features

### 2. Start with Visibility Only (No Enforcement)

**Decision:** Enable coverage reporting for visibility, but **do not enforce** coverage thresholds initially.

**Why no thresholds yet:**
- ✅ Establish baseline first (understand where we are)
- ✅ Don't block development in early stages
- ✅ Use coverage to **inform** decisions, not **gate** changes
- ✅ Allow gradual, sustainable improvement

**Recommended progression:**
1. **0.1.4 (Now):** Set up reporting, establish baseline (~40-60%)
2. **0.1.5-0.1.6:** Use reports to identify critical gaps, improve coverage organically
3. **0.2.0+:** Consider soft targets (e.g., "aim for 70%")
4. **1.0.0+:** Maybe enforce thresholds for critical code paths

### 3. Documentation Location

**Decision:** Add coverage instructions to **README.md** in a "Development" or "Testing" section.

**Why README:**
- ✅ Visible to all contributors immediately
- ✅ First place developers look for project info
- ✅ Shows commitment to quality
- ✅ Easy to find and update

**Example structure for README:**
```markdown
## Development

### Running Tests
```bash
flutter test
```

### Test Coverage

Generate and view coverage locally:
```bash
# Generate coverage report
flutter test --coverage

# View HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
# or: xdg-open coverage/html/index.html  # Linux
```

**Current coverage:** ![codecov](https://codecov.io/gh/alemdisso/gastrobrain/branch/main/graph/badge.svg)

**Full coverage report:** https://codecov.io/gh/alemdisso/gastrobrain
```

### 4. CI/CD Integration

**Decision:** Extend existing test workflow to generate and upload coverage.

**Why extend existing workflow:**
- ✅ Don't duplicate test runs (waste of CI time)
- ✅ Coverage generated automatically on every test run
- ✅ Simpler workflow maintenance

**Implementation:**

Add to `.github/workflows/test.yml`:
```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: false  # Don't fail build on coverage upload errors
          flags: unittests
          name: gastrobrain-coverage
```

**Setup required:**
1. Create free Codecov account linked to GitHub repo
2. Add `CODECOV_TOKEN` to GitHub repository secrets (Codecov provides this)
3. Modify workflow as shown above

### 5. Coverage Exclusions

**What to exclude from coverage reports:**

**Mandatory exclusions:**
- `*.g.dart` - Generated code (json_serializable, build_runner)
- `*.freezed.dart` - Generated freezed models
- `main.dart` - Entry point (hard to test meaningfully)
- `lib/l10n/*.dart` - Generated localization files

**Optional exclusions (for now):**
- Some widget files - can focus on logic first, add widget coverage later
- However, **do NOT exclude** critical screens or complex widgets

**How to exclude:**

Create `coverage/lcov_exclude.sh` script:
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

Add to CI workflow after generating coverage:
```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Filter coverage
  run: |
    chmod +x coverage/lcov_exclude.sh
    ./coverage/lcov_exclude.sh
```

### 6. Best Practices for Our Stage

**DO:**
- ✅ Use coverage to **identify gaps** in critical code (DatabaseHelper, services, business logic)
- ✅ Track **trends over time** - is coverage increasing as we add tests?
- ✅ Review coverage reports when adding new features
- ✅ Aim to **not decrease** overall coverage with new code
- ✅ Use PR comments from Codecov to understand impact of changes
- ✅ Focus coverage efforts on high-value code (data layer, business logic)

**DON'T:**
- ❌ Set strict enforcement thresholds yet (blocks early development)
- ❌ Aim for 100% coverage (diminishing returns, wastes time)
- ❌ Obsess over coverage percentage as a metric
- ❌ Let coverage become a vanity metric (quality > quantity)
- ❌ Write tests just to increase coverage (write meaningful tests)

### 7. Realistic Coverage Goals by Area

For a project at our size and stage, these are healthy coverage targets:

| Area | Target Coverage | Priority | Reasoning |
|------|----------------|----------|-----------|
| **Database operations** | 80-90% | Critical | Core functionality, easy to test, high value |
| **Business logic/services** | 70-80% | High | Important behavior, testable, moderate complexity |
| **Providers/state management** | 60-70% | Medium | Important but some boilerplate |
| **Widgets/UI** | 40-60% | Lower | Expensive to test, lower ROI, focus on logic first |
| **Overall project** | 60-70% | - | Excellent for early-stage project |

**Focus areas for testing effort:**
1. **DatabaseHelper** and database operations (highest ROI)
2. **Recommendation service** and business logic
3. **Providers** and state management
4. **Critical screens** and user workflows
5. **Edge cases** and error handling

**Lower priority:**
- Simple getters/setters
- Boilerplate code
- Purely visual widgets (can test with manual QA)

## Implementation Plan

### Minimal MVP (Recommended for 0.1.4)

**Scope:** Set up basic coverage reporting with Codecov integration.

**Tasks:**
1. Create Codecov account and link GitHub repository
2. Add `CODECOV_TOKEN` to GitHub repository secrets
3. Modify `.github/workflows/test.yml` to upload coverage
4. Add coverage badge and instructions to README.md
5. Document local coverage generation commands
6. Create coverage exclusion script (optional but recommended)
7. Test coverage workflow on a PR

**Estimated effort:** S - 2 points (~3-5 hours)

**What you get:**
- ✅ Coverage badge in README showing current percentage
- ✅ Automatic coverage reports on every PR
- ✅ Trend tracking over time
- ✅ Easy identification of untested critical code
- ✅ Professional quality indicator for the project

**What you DON'T get (intentionally):**
- ❌ Coverage enforcement (no build failures)
- ❌ Strict coverage targets
- ❌ Detailed coverage analysis (available but not mandatory)

## Local Development Workflow

### Generating Coverage Reports

**Quick check:**
```bash
# Generate coverage
flutter test --coverage

# Check overall coverage percentage
lcov --summary coverage/lcov.info
```

**Detailed HTML report:**
```bash
# Generate coverage
flutter test --coverage

# Generate HTML report (requires lcov installed)
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

**Installing lcov:**
```bash
# macOS
brew install lcov

# Ubuntu/Debian
sudo apt-get install lcov

# Windows (via chocolatey)
choco install lcov
```

### Interpreting Coverage Reports

**Coverage types:**
- **Line coverage:** % of code lines executed during tests
- **Function coverage:** % of functions called during tests
- **Branch coverage:** % of conditional branches tested

**Focus on:**
- **Untested critical paths:** DatabaseHelper methods, business logic
- **Low coverage in high-risk areas:** Error handling, edge cases
- **New code:** Ensure new features have reasonable coverage

**Don't worry about:**
- 100% coverage (unrealistic and wasteful)
- Generated code coverage (excluded)
- Simple getters/setters (low value)

## Maintenance

### Regular Review

**Weekly (during active development):**
- Check coverage trends in Codecov dashboard
- Review PR coverage comments for significant changes
- Identify 1-2 critical untested areas to improve

**Per milestone:**
- Review overall coverage progress
- Update coverage goals if needed
- Identify testing gaps for next milestone

**Never:**
- Don't obsess over daily percentage changes
- Don't block PRs purely on coverage drops (investigate, but be pragmatic)

### Updating Exclusions

If new generated code patterns emerge:
1. Update `coverage/lcov_exclude.sh`
2. Document why exclusion is needed
3. Test locally before committing

## Resources

**Tools:**
- [Codecov](https://codecov.io) - Coverage hosting and reporting
- [Flutter Test Coverage](https://flutter.dev/docs/cookbook/testing/integration/introduction#5-test-your-app) - Official Flutter docs
- [lcov](https://github.com/linux-test-project/lcov) - Local HTML report generation

**Best Practices:**
- [Martin Fowler - Test Coverage](https://martinfowler.com/bliki/TestCoverage.html)
- [Google Testing Blog - Code Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html)

---

## Document History

- **2025-12-31:** Initial version - Best practices for 0.1.4 stage
