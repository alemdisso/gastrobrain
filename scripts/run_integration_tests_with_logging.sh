#!/bin/bash
# Script to run integration tests repeatedly and capture output for analysis

ITERATIONS=${1:-10}
OUTPUT_DIR="test_logs/integration_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "Running integration tests $ITERATIONS times..."
echo "Logs will be saved to: $OUTPUT_DIR"

for i in $(seq 1 $ITERATIONS); do
    echo "=== Run $i/$ITERATIONS at $(date +%H:%M:%S) ==="

    # Run tests and capture both stdout and stderr
    LOG_FILE="$OUTPUT_DIR/run_${i}_$(date +%H%M%S).log"

    flutter test integration_test/ --reporter=expanded 2>&1 | tee "$LOG_FILE"
    EXIT_CODE=${PIPESTATUS[0]}

    # Add metadata to log
    echo "" >> "$LOG_FILE"
    echo "=== RUN METADATA ===" >> "$LOG_FILE"
    echo "Run: $i" >> "$LOG_FILE"
    echo "Exit Code: $EXIT_CODE" >> "$LOG_FILE"
    echo "Timestamp: $(date --iso-8601=seconds)" >> "$LOG_FILE"

    if [ $EXIT_CODE -ne 0 ]; then
        echo "❌ Run $i FAILED (exit code: $EXIT_CODE)"
        echo "FAILED" >> "$OUTPUT_DIR/summary.txt"
    else
        echo "✅ Run $i PASSED"
        echo "PASSED" >> "$OUTPUT_DIR/summary.txt"
    fi

    # Small delay between runs
    sleep 2
done

echo ""
echo "=== TEST RUN COMPLETE ==="
echo "Total runs: $ITERATIONS"
echo "Passed: $(grep -c PASSED $OUTPUT_DIR/summary.txt 2>/dev/null || echo 0)"
echo "Failed: $(grep -c FAILED $OUTPUT_DIR/summary.txt 2>/dev/null || echo 0)"
echo "Logs saved to: $OUTPUT_DIR"
