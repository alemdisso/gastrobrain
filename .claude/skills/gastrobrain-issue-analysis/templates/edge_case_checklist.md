# Edge Case Identification Checklist

Use this checklist to systematically identify edge cases for any feature or change.

## Issue Reference

| Field | Value |
|-------|-------|
| Issue | #XXX |
| Feature/Change | [Brief description] |
| Date | YYYY-MM-DD |

---

## Data Edge Cases

### Null/Empty Values

- [ ] **Null input**: What if the primary input is null?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

- [ ] **Empty string**: What if text input is empty?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

- [ ] **Empty list/collection**: What if a list has no items?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

- [ ] **Missing optional fields**: What if optional data isn't provided?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

### Boundary Values

- [ ] **Minimum value**: What's the smallest valid value?
  - Value: [Minimum]
  - Handling: [Expected behavior]

- [ ] **Maximum value**: What's the largest valid value?
  - Value: [Maximum]
  - Handling: [Expected behavior]

- [ ] **Zero/negative**: Are zero or negative values valid?
  - Valid: [Yes/No]
  - Handling: [Expected behavior]

- [ ] **Overflow**: What if value exceeds storage capacity?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

### Invalid Data

- [ ] **Wrong type**: What if data type is unexpected?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

- [ ] **Malformed data**: What if data format is incorrect?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

- [ ] **Invalid enum value**: What if enum value doesn't exist?
  - Scenario: [Database has unknown value]
  - Handling: [Default/error handling]

- [ ] **Corrupted data**: What if stored data is corrupted?
  - Scenario: [When this could happen]
  - Handling: [Expected behavior]

---

## State Edge Cases

### Loading States

- [ ] **Initial load**: What shows while data loads?
  - UI: [Loading indicator/skeleton]

- [ ] **Slow load**: What if loading takes > 3 seconds?
  - UI: [Progress indication]

- [ ] **Load failure**: What if loading fails?
  - UI: [Error state with retry]

- [ ] **Partial load**: What if some data loads but not all?
  - UI: [Partial display handling]

### Empty States

- [ ] **No data**: What if there's no data to display?
  - UI: [Empty state message/illustration]

- [ ] **Filtered to empty**: What if filters exclude everything?
  - UI: [No results message]

- [ ] **First use**: What does a new user see?
  - UI: [Onboarding/empty state]

### Error States

- [ ] **Network error**: What if network is unavailable?
  - UI: [Offline message]
  - Behavior: [Retry/cached data]

- [ ] **Database error**: What if database operation fails?
  - UI: [Error message]
  - Behavior: [Retry option]

- [ ] **Permission denied**: What if user lacks permission?
  - UI: [Access denied message]

- [ ] **Validation error**: What if input validation fails?
  - UI: [Field-level error messages]

---

## UI Edge Cases

### Screen Sizes

- [ ] **Small screen (320px)**: Does UI fit on small phones?
  - Issues: [Potential overflow areas]
  - Solution: [Responsive adjustments]

- [ ] **Large screen (tablet)**: Does UI scale up well?
  - Issues: [Potential layout issues]
  - Solution: [Tablet adaptations]

- [ ] **Landscape mode**: Does UI work in landscape?
  - Issues: [Potential layout issues]
  - Solution: [Orientation handling]

### Text Content

- [ ] **Long text**: What if text is very long?
  - Example: [Very long recipe name]
  - Solution: [Truncation/wrapping]

- [ ] **Short text**: What if text is very short?
  - Example: [Single character name]
  - Solution: [Minimum width handling]

- [ ] **Special characters**: What if text has special chars?
  - Example: [Emojis, unicode, symbols]
  - Solution: [Proper encoding/display]

- [ ] **RTL text**: What if text is right-to-left?
  - Consideration: [RTL language support]
  - Solution: [Directionality handling]

### Interactions

- [ ] **Keyboard visible**: What if keyboard covers content?
  - Solution: [Scroll adjustment]

- [ ] **Rapid tapping**: What if user taps rapidly?
  - Solution: [Debounce/disable during action]

- [ ] **Double submit**: What if form is submitted twice?
  - Solution: [Prevent duplicate submission]

- [ ] **Back navigation**: What if user presses back?
  - Solution: [Proper navigation handling]

---

## Timing Edge Cases

### Concurrency

- [ ] **Concurrent edits**: What if same item edited twice?
  - Scenario: [Two sessions editing same record]
  - Solution: [Last-write-wins/conflict detection]

- [ ] **Race condition**: What if operations complete out of order?
  - Scenario: [Async operations finishing unexpectedly]
  - Solution: [Proper async handling]

- [ ] **Stale data**: What if displayed data is outdated?
  - Solution: [Refresh mechanism]

### Interruptions

- [ ] **App backgrounded**: What if app goes to background mid-operation?
  - Solution: [Save state/resume]

- [ ] **App killed**: What if app is force-closed?
  - Solution: [Recover gracefully on restart]

- [ ] **Network lost mid-operation**: What if connection drops?
  - Solution: [Retry/error handling]

---

## Integration Edge Cases

### Database

- [ ] **Migration with existing data**: Does migration preserve data?
  - Test: [Migration up/down with data]

- [ ] **Rollback scenario**: Can we rollback safely?
  - Test: [Down migration]

- [ ] **Large dataset**: Does it work with many records?
  - Test: [Performance with 1000+ records]

### External Dependencies

- [ ] **Service unavailable**: What if external service is down?
  - Solution: [Fallback/error handling]

- [ ] **API changes**: What if API response changes?
  - Solution: [Defensive parsing]

- [ ] **Version mismatch**: What if app version differs from data?
  - Solution: [Version checking/migration]

---

## Localization Edge Cases

- [ ] **Missing translation**: What if translation key is missing?
  - Solution: [Fallback to default language]

- [ ] **Text length variance**: Do translations fit in UI?
  - Example: [Portuguese is often longer than English]
  - Solution: [Flexible layouts]

- [ ] **Date/number formats**: Are formats localized?
  - Solution: [Use locale-aware formatters]

- [ ] **Pluralization**: Are plurals handled correctly?
  - Example: ["1 recipe" vs "2 recipes"]
  - Solution: [ICU plural syntax]

---

## Backward Compatibility

- [ ] **Existing users**: Do existing users see their data correctly?
  - Test: [Load existing data after change]

- [ ] **Nullable new fields**: Are new fields nullable for existing records?
  - Solution: [Default values/null handling]

- [ ] **Removed features**: What if user had data from removed feature?
  - Solution: [Graceful degradation]

---

## Summary

| Category | Edge Cases Identified | Priority |
|----------|----------------------|----------|
| Data | X cases | [High/Med/Low] |
| State | X cases | [High/Med/Low] |
| UI | X cases | [High/Med/Low] |
| Timing | X cases | [High/Med/Low] |
| Integration | X cases | [High/Med/Low] |
| Localization | X cases | [High/Med/Low] |
| Compatibility | X cases | [High/Med/Low] |
| **Total** | **X cases** | |

---

## Test Coverage Required

Based on identified edge cases:

### Unit Tests
- [ ] [Test for edge case 1]
- [ ] [Test for edge case 2]
- [ ] [Test for edge case 3]

### Widget Tests
- [ ] [Test for edge case 1]
- [ ] [Test for edge case 2]

### Edge Case Tests (test/edge_cases/)
- [ ] [Test for edge case 1]
- [ ] [Test for edge case 2]

---

*Checklist completed on [date]*
