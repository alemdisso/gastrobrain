# Test Configuration Files

This directory contains test list files for targeted stress testing.

## Purpose

Instead of running the entire integration test suite (30+ minutes per run), these config files let you stress test specific suspected flaky tests with many more iterations.

## File Format

```text
# Comments start with #
# Paths are relative to integration_test/

e2e/e2e_meal_editing_fields_test.dart
services/recommendation_service_test.dart
```

## Usage

```powershell
.\scripts\stress_test_integration.ps1 -Iterations 50 -TestsFile "test_configs\flaky_tests.txt"
```

## Files

- **`flaky_tests.txt`** - Tests with known intermittent failures (issues #289, #290)

## Creating New Configs

Create a new `.txt` file with the tests you want to stress:

```powershell
# Example: Test all meal editing related tests
e2e/e2e_meal_editing_fields_test.dart
e2e/e2e_meal_editing_workflow_test.dart
e2e/e2e_meal_editing_edge_cases_test.dart
e2e/e2e_meal_editing_integration_test.dart
```

Then run:

```powershell
.\scripts\stress_test_integration.ps1 -Iterations 100 -TestsFile "test_configs\meal_editing_tests.txt"
```

## Best Practices

- **Name files descriptively** - `meal_editing_tests.txt`, not `tests.txt`
- **Add issue references** - Comment why tests are being stressed
- **Commit to git** - These document which tests need monitoring
- **Remove when fixed** - Delete or update when tests become stable
