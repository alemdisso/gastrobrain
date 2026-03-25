# Test Suite Governance

Guidelines for keeping test documentation accurate without imposing excessive maintenance overhead.

## Philosophy

Exact test counts in documentation are a snapshot that drifts. The strategy here is:

- **Approximate floors in docs** — use `500+` style counts that remain true as the suite grows, only needing updates at major architectural shifts.
- **Script for precise counts** — run `scripts/count-tests.sh` anytime you need an accurate number (e.g. before updating docs, during sprint retrospectives, or when the floor language feels stale).
- **Log files as ground truth** — the most accurate count comes from an actual test run log, not static file analysis.

## Running the Counter Script

```bash
bash scripts/count-tests.sh          # static count + parse latest logs
bash scripts/count-tests.sh --static # static count only
```

The script outputs:
- A breakdown by test category (widgets, edge cases, core/services, regression)
- Results parsed from the latest run logs in `test_logs/`
- A doc-ready summary with approximate floor counts

## Log File Naming Conventions

Logs saved to `test_logs/` should follow these naming conventions so the script can detect the latest run automatically:

| Suite | Command | Log naming convention |
|---|---|---|
| Full unit suite | `flutter test ./test` | `YYMMDD_full_test_suite_result.log` |
| Full integration/E2E suite | `flutter test integration_test` | `YYMMDD_integration_test_result.log` |
| Ad-hoc E2E run | single test file | `YYMMDD_e2e_<description>.log` |

Example: `260325_full_test_suite_result.log`

## When to Update Documented Counts

Update the approximate counts in `docs/README.md` and `docs/architecture/Gastrobrain-Codebase-Overview.md` when:

1. **Milestone release** — run the script and update floors if any category has grown by 20%+ since last update.
2. **Major test phase completes** — e.g. after a dedicated testing issue adds a significant batch (50+ tests) to a single category.

You do **not** need to update docs after routine feature work that adds a handful of tests.

## Where Counts Appear

| File | Section | Notes |
|---|---|---|
| `docs/README.md` | Testing Documentation Hierarchy | Per-category counts with file counts |
| `docs/architecture/Gastrobrain-Codebase-Overview.md` | Test Coverage Overview & Breakdown | Total count + per-category breakdown |

## Related Scripts and Tooling

- `scripts/count-tests.sh` — the primary count tool (this governance doc's companion)
- `scripts/analyze_test_logs.dart` — deep analysis for flaky test detection across multiple runs
- `scripts/README_TEST_LOGGING.md` — full guide to integration test logging and stress testing
