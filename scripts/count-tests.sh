#!/usr/bin/env bash
# count-tests.sh — Gastrobrain test suite counter
#
# Usage:
#   bash scripts/count-tests.sh          # static count + parse latest logs
#   bash scripts/count-tests.sh --static # static count only (no log parsing)
#
# Naming conventions for test_logs/:
#   Full unit suite  → YYMMDD_full_test_suite_result.log
#   Integration/E2E  → YYMMDD_integration_test_result.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
TEST_DIR="$ROOT/test"
LOG_DIR="$ROOT/test_logs"
STATIC_ONLY="${1:-}"

# ── helpers ────────────────────────────────────────────────────────────────────

count_cases() {
  local dir="$1"
  grep -rh --include="*_test.dart" -c "testWidgets\|^[[:space:]]*test(" "$dir" 2>/dev/null \
    | awk '{s+=$1} END {print s+0}'
}

count_files() {
  local dir="$1"
  find "$dir" -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' '
}

# Parse the final summary line from a Flutter test log.
# Flutter format: MM:SS +passed [-failed]: All tests passed!
#             or: MM:SS +passed -failed: Some tests failed.
parse_log() {
  local file="$1"
  local last
  last=$(grep -E "^[0-9]+:[0-9]+ \+[0-9]+" "$file" | tail -1)
  if [[ -z "$last" ]]; then
    echo "  (unreadable log)"
    return
  fi

  local passed failed status
  passed=$(echo "$last" | sed 's/.*+\([0-9]*\).*/\1/')
  failed=$(echo "$last" | grep -o ' -[0-9]*' | grep -o '[0-9]*' || echo "0")
  failed="${failed:-0}"
  if echo "$last" | grep -q "All tests passed"; then
    status="PASSED"
  else
    status="FAILED"
  fi

  echo "  Result : $status"
  echo "  Passed : $passed"
  if [[ "$failed" != "0" ]]; then
    echo "  Failed : $failed"
  fi
}

latest_log() {
  local pattern="$1"
  ls -t "$LOG_DIR"/$pattern 2>/dev/null | head -1 || true
}

# ── static counts ──────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Gastrobrain Test Suite — Static Count"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════════════════"
echo ""

WIDGETS_FILES=$(count_files "$TEST_DIR/widgets")
WIDGETS_CASES=$(count_cases "$TEST_DIR/widgets")

EDGE_FILES=$(count_files "$TEST_DIR/edge_cases")
EDGE_CASES=$(count_cases "$TEST_DIR/edge_cases")

REGRESSION_FILES=$(count_files "$TEST_DIR/regression")
REGRESSION_CASES=$(count_cases "$TEST_DIR/regression")

# "core" tests: everything except widgets/, edge_cases/, regression/
CORE_CASES=$(
  for sub in core database models screens services unit utils validators mocks; do
    d="$TEST_DIR/$sub"
    [[ -d "$d" ]] && count_cases "$d" || echo 0
  done | awk '{s+=$1} END {print s}'
)
CORE_FILES=$(
  for sub in core database models screens services unit utils validators mocks; do
    d="$TEST_DIR/$sub"
    [[ -d "$d" ]] && count_files "$d" || echo 0
  done | awk '{s+=$1} END {print s}'
)

TOTAL_UNIT=$((WIDGETS_CASES + EDGE_CASES + REGRESSION_CASES + CORE_CASES))
TOTAL_FILES=$((WIDGETS_FILES + EDGE_FILES + REGRESSION_FILES + CORE_FILES))

printf "  %-35s %5s cases   %3s files\n" "Widgets / dialog tests" "$WIDGETS_CASES" "$WIDGETS_FILES"
printf "  %-35s %5s cases   %3s files\n" "Edge case tests"        "$EDGE_CASES"    "$EDGE_FILES"
printf "  %-35s %5s cases   %3s files\n" "Regression tests"       "$REGRESSION_CASES" "$REGRESSION_FILES"
printf "  %-35s %5s cases   %3s files\n" "Core / service / model tests" "$CORE_CASES" "$CORE_FILES"
echo "  ───────────────────────────────────────────────────────"
printf "  %-35s %5s cases   %3s files\n" "TOTAL (unit suite)" "$TOTAL_UNIT" "$TOTAL_FILES"
echo ""

# Integration test static count
INT_DIR="$ROOT/integration_test"
if [[ -d "$INT_DIR" ]]; then
  INT_FILES=$(count_files "$INT_DIR")
  INT_CASES=$(count_cases "$INT_DIR")
  printf "  %-35s %5s cases   %3s files\n" "Integration / E2E tests" "$INT_CASES" "$INT_FILES"
  echo ""
fi

# ── log parsing ────────────────────────────────────────────────────────────────

if [[ "$STATIC_ONLY" == "--static" ]]; then
  echo "  (Log parsing skipped — --static flag set)"
  echo ""
  exit 0
fi

if [[ ! -d "$LOG_DIR" ]]; then
  echo "  No test_logs/ directory found — skipping log parse."
  echo ""
  exit 0
fi

echo "═══════════════════════════════════════════════════════"
echo "  Latest Log Results"
echo "═══════════════════════════════════════════════════════"
echo ""

UNIT_LOG=$(latest_log "*_full_test_suite_result.log")
if [[ -n "$UNIT_LOG" ]]; then
  echo "  Unit suite  : $(basename "$UNIT_LOG")"
  parse_log "$UNIT_LOG"
else
  echo "  Unit suite  : no log found"
  echo "  (expected naming: YYMMDD_full_test_suite_result.log)"
fi
echo ""

E2E_LOG=$(latest_log "*_integration_test_result.log")
if [[ -n "$E2E_LOG" ]]; then
  echo "  E2E suite   : $(basename "$E2E_LOG")"
  parse_log "$E2E_LOG"
else
  echo "  E2E suite   : no log found"
  echo "  (expected naming: YYMMDD_integration_test_result.log)"
fi
echo ""

echo "═══════════════════════════════════════════════════════"
echo "  Doc-ready summary (approximate floors):"
echo ""
echo "  - ${WIDGETS_CASES}+ dialog/widget tests across ${WIDGETS_FILES} files"
echo "  - ${EDGE_CASES}+ edge case tests across ${EDGE_FILES} files"
echo "  - ${CORE_CASES}+ core/service/model tests across ${CORE_FILES} files"
echo "  - ${TOTAL_UNIT}+ total unit/widget tests"
if [[ -d "$INT_DIR" ]]; then
  echo "  - ${INT_CASES}+ integration/E2E test cases"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
