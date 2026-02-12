# Example 3: Test Suite Health Monitoring

## Scenario

The developer wants to review the overall health of the test suite after completing milestone 0.1.7. This is a periodic health check to ensure the test suite is maintainable, comprehensive, and performing well.

**Process:** Health Monitoring (3 Checkpoints)

---

## Walkthrough

### CHECKPOINT 1: Metrics Collection

```
Test Suite Health Check

CHECKPOINT 1: Metrics Collection
───────────────────────────────────────

Running metrics collection...

Test Counts:
  Total tests: 611
  Unit tests: 445 (72.8%)
  Widget tests: 142 (23.2%)
  Integration tests: 24 (3.9%)

Pass Rate:
  Last run: 611/611 (100%)
  Previous week: 604/607 (99.5%)
  Improvement: +7 tests, +0.5% pass rate

Execution Time:
  Total duration: 5m 47s
  Avg per test: 568ms
  Slowest tests:
    1. meal_recording_dialog_full_test.dart (12.3s)
    2. weekly_plan_integration_test.dart (8.7s)
    3. recommendation_service_test.dart (4.2s)

Coverage (from last coverage run):
  Overall: 87.3%
  Models: 94.2%
  Services: 89.1%
  Widgets: 78.4%
  Screens: 71.2%

Skipped Tests: 0
Pending Tests: 0

Metrics collected. Proceed to assessment? (y/n)
```

**User:** y

---

### CHECKPOINT 2: Health Assessment

```
───────────────────────────────────────
CHECKPOINT 2: Health Assessment

Health Indicators:

HEALTHY:
  - Pass rate: 100% - All tests passing consistently
  - Test growth: +7 tests this week - Active test development
  - Coverage trend: +1.2% this month - Steadily improving
  - No skipped tests - Full suite executing
  - Model coverage: 94.2% - Well above 90% target
  - Service coverage: 89.1% - Approaching 90% target

WATCH:
  - Widget coverage: 78.4% - Below 80% target (gap: 1.6%)
    Components under 80%:
    - meal_type_dropdown.dart: 65% (new, needs more tests)
    - calendar_widget.dart: 72% (edge cases missing)
  - Screen coverage: 71.2% - Slightly above 70% target
    Components under 70%:
    - weekly_plan_screen.dart: 68% (navigation not tested)
  - Slowest test: 12.3s - meal_recording_dialog_full_test
    (Acceptable but monitor for growth)

UNHEALTHY:
  - None identified

Flaky Test Candidates:
  Checking recent test history...
  - meal_recording_dialog_test.dart:89 (timed out once last week)
    Running 10x stability check...
    Result: 10/10 passes - STABLE (last week was likely environment issue)
  - No confirmed flaky tests

Test Distribution:
  Unit : Widget : Integration = 73 : 23 : 4
  Assessment: Good balance. Unit-heavy is appropriate for this project.
  Widget tests could grow slightly (target: 25%).
  Integration tests adequate for current feature set.

Coverage Gaps (components below target):

| Component | Coverage | Target | Gap | Priority |
|-----------|----------|--------|-----|----------|
| meal_type_dropdown.dart | 65% | 80% | 15% | High (new) |
| calendar_widget.dart | 72% | 80% | 8% | Medium |
| weekly_plan_screen.dart | 68% | 70% | 2% | Low |

Overall Health: GOOD

The test suite is healthy with strong pass rates, growing coverage,
and no flaky tests. Main improvement area is widget test coverage
for newer components.

Assessment complete. Create improvement plan? (y/n)
```

**User:** y

---

### CHECKPOINT 3: Improvement Plan

```
───────────────────────────────────────
CHECKPOINT 3: Improvement Plan

Based on health assessment:

PRIORITY 1 - Fix Now (quick wins):

1. [ ] Add widget tests for MealTypeDropdown
   - Missing: null selection, disabled state, localization
   - Coverage gain: 65% -> ~90%
   - Est: 1.5 hours
   - Impact: Brings newest widget up to standard

2. [ ] Add edge case tests for CalendarWidget
   - Missing: month boundary, empty weeks, year transition
   - Coverage gain: 72% -> ~85%
   - Est: 2 hours
   - Impact: Addresses coverage gap in important widget

PRIORITY 2 - Fix Soon:

3. [ ] Add navigation tests for WeeklyPlanScreen
   - Missing: screen transitions, back button, deep linking
   - Coverage gain: 68% -> ~78%
   - Est: 2 hours
   - Impact: Improves screen coverage toward target

4. [ ] Investigate slow test: meal_recording_dialog_full_test (12.3s)
   - Possible: Too many pumpAndSettle calls, heavy setup
   - Target: Reduce to <8s
   - Est: 1 hour
   - Impact: Faster test suite execution

5. [ ] Improve service coverage: meal_service.dart
   - Missing: Error handling paths, edge cases
   - Coverage gain: 89% -> ~93%
   - Est: 1.5 hours
   - Impact: Services above 90% target

PRIORITY 3 - Backlog:

6. [ ] Add more integration tests for new features
   - Meal type selection workflow
   - Shopping list generation
   - Est: 3 hours
   - Impact: Better end-to-end validation

7. [ ] Create test execution time baseline document
   - Track per-test timing trends
   - Identify slow tests before they become problems
   - Est: 1 hour
   - Impact: Proactive performance monitoring

Recommended Targets for Next Sprint:
- Pass rate: Maintain 100%
- Coverage: Reach 88% overall (from 87.3%)
- Widget coverage: Reach 82% (from 78.4%)
- Flaky tests: Maintain 0
- Execution time: Keep under 6 minutes

Total Improvement Effort: ~12 hours

Quick Wins (items 1-2): ~3.5 hours → +3-4% widget coverage
Full Plan (all items): ~12 hours → ~88% overall, faster suite

Create issues for these improvements? (y/n/select items)
```

**User:** Create issues for items 1, 2, and 4.

```
Creating issues...

Issue 1: "testing: add comprehensive widget tests for MealTypeDropdown"
  Labels: testing, UI, P2-Medium
  Story points: 3
  Status: Created ✓

Issue 2: "testing: add edge case tests for CalendarWidget"
  Labels: testing, UI, P2-Medium
  Story points: 3
  Status: Created ✓

Issue 3: "testing: investigate and optimize slow meal_recording_dialog_full_test"
  Labels: testing, performance, P3-Low
  Story points: 2
  Status: Created ✓

All issues created and added to project backlog.

Health check complete! ✓

Summary:
- Overall health: GOOD
- Pass rate: 100% (611/611)
- Coverage: 87.3% (trending up)
- Flaky tests: 0
- 3 improvement issues created
- Next review: After next sprint
```

---

## Result

After the health check:
- **Test suite confirmed healthy** (100% pass rate, growing coverage)
- **Coverage gaps identified** with specific components and test suggestions
- **No flaky tests found** (previous timeout was environmental)
- **3 improvement issues created** for upcoming sprints
- **Clear targets set** for next health check (88% overall, 82% widgets)
- **Execution time monitored** (5m 47s, within acceptable range)
