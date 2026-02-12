# PowerShell script to run integration tests repeatedly and capture output
# Usage: .\scripts\run_integration_tests_with_logging.ps1 -Iterations 10

param(
    [int]$Iterations = 10
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "test_logs\integration_$timestamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Running integration tests $Iterations times..." -ForegroundColor Cyan
Write-Host "Logs will be saved to: $outputDir" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

for ($i = 1; $i -le $Iterations; $i++) {
    $runTime = Get-Date -Format "HH:mm:ss"
    Write-Host "=== Run $i/$Iterations at $runTime ===" -ForegroundColor Yellow

    $logTime = Get-Date -Format "HHmmss"
    $logFile = "$outputDir\run_${i}_$logTime.log"

    # Run tests and capture output
    flutter test integration_test/ --reporter=expanded 2>&1 | Tee-Object -FilePath $logFile
    $exitCode = $LASTEXITCODE

    # Add metadata
    Add-Content -Path $logFile -Value ""
    Add-Content -Path $logFile -Value "=== RUN METADATA ==="
    Add-Content -Path $logFile -Value "Run: $i"
    Add-Content -Path $logFile -Value "Exit Code: $exitCode"
    Add-Content -Path $logFile -Value "Timestamp: $(Get-Date -Format o)"

    if ($exitCode -ne 0) {
        Write-Host "❌ Run $i FAILED (exit code: $exitCode)" -ForegroundColor Red
        Add-Content -Path "$outputDir\summary.txt" -Value "FAILED"
        $failed++
    } else {
        Write-Host "✅ Run $i PASSED" -ForegroundColor Green
        Add-Content -Path "$outputDir\summary.txt" -Value "PASSED"
        $passed++
    }

    # Small delay between runs
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=== TEST RUN COMPLETE ===" -ForegroundColor Cyan
Write-Host "Total runs: $Iterations"
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Logs saved to: $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "To analyze logs, run:" -ForegroundColor Yellow
Write-Host "  dart scripts\analyze_test_logs.dart $outputDir" -ForegroundColor White
