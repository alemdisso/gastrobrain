# Enhanced integration test stress testing with emulator health checks
# Usage Examples:
#   .\scripts\stress_test_integration.ps1 -Iterations 20
#   .\scripts\stress_test_integration.ps1 -Iterations 50 -TestsFile "flaky_tests.txt"

param(
    [int]$Iterations = 10,
    [string]$TestsFile = "",  # Path to file containing test list (one per line)
    [int]$RestartEmulatorEvery = 5,  # Restart emulator every N runs (0 = never)
    [switch]$SkipEmulatorCheck  # Skip emulator health checks (faster but riskier)
)

$ErrorActionPreference = "Continue"

# Create log directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "test_logs\stress_$timestamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Determine test path
$testPath = "integration_test\"
$testDescription = "ALL integration tests"
$testList = @()

if ($TestsFile) {
    if (-not (Test-Path $TestsFile)) {
        Write-Host "Error: Test file not found: $TestsFile" -ForegroundColor Red
        exit 1
    }

    # Read test list from file (ignore empty lines and comments)
    $testList = Get-Content $TestsFile |
        Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") } |
        ForEach-Object { $_.Trim() }

    if ($testList.Count -eq 0) {
        Write-Host "Error: No tests found in $TestsFile" -ForegroundColor Red
        exit 1
    }

    $testPath = ($testList | ForEach-Object { "integration_test\$_" }) -join " "
    $testDescription = "$($testList.Count) test(s) from $TestsFile"
}

# Log configuration
$configFile = "$outputDir\config.txt"
$configContent = @"
=== STRESS TEST CONFIGURATION ===
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Iterations: $Iterations
Tests: $testDescription
Restart Emulator: Every $RestartEmulatorEvery runs $(if ($RestartEmulatorEvery -eq 0) { "(disabled)" })
Skip Health Checks: $SkipEmulatorCheck

"@

if ($testList.Count -gt 0) {
    $configContent += "Test List:`n"
    $testList | ForEach-Object { $configContent += "  - $_`n" }
} else {
    $configContent += "Test Path: $testPath`n"
}

$configContent | Out-File -FilePath $configFile

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "          INTEGRATION TEST STRESS TESTING                       " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Iterations:       $Iterations"
Write-Host "  Tests:            $testDescription"
Write-Host "  Emulator Restart: Every $RestartEmulatorEvery runs" $(if ($RestartEmulatorEvery -eq 0) { "(disabled)" })
Write-Host "  Logs:             $outputDir"
Write-Host ""
Write-Host "Estimated duration: $([math]::Round($Iterations * 0.5, 1)) hours (assuming 30min per run)" -ForegroundColor Gray
Write-Host ""

# Counters
$passed = 0
$failed = 0
$emulatorRestarts = 0

# Function to check emulator health
function Test-EmulatorHealth {
    Write-Host "  Checking emulator health..." -NoNewline

    $devices = adb devices 2>&1 | Select-String "emulator-\d+.*device$"

    if ($devices) {
        # Additional health check: Can we reach the package service?
        $pmCheck = adb shell pm list packages -3 2>&1
        if ($LASTEXITCODE -eq 0 -and $pmCheck -notmatch "Can't find service") {
            Write-Host " OK - Healthy" -ForegroundColor Green
            return $true
        }
    }

    Write-Host " FAIL - Dead or unresponsive" -ForegroundColor Red
    return $false
}

# Function to restart emulator services
function Restart-EmulatorServices {
    Write-Host "  Restarting ADB services..." -ForegroundColor Yellow

    adb kill-server | Out-Null
    Start-Sleep -Seconds 2
    adb start-server | Out-Null
    Start-Sleep -Seconds 3

    # Verify it worked
    $devices = adb devices 2>&1
    if ($devices -match "emulator-\d+.*device") {
        Write-Host "  OK - ADB services restarted successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  FAIL - ADB restart failed" -ForegroundColor Red
        return $false
    }
}

# Main test loop
for ($i = 1; $i -le $Iterations; $i++) {
    $runStart = Get-Date
    $runTime = $runStart.ToString("HH:mm:ss")

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  RUN $i/$Iterations at $runTime" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow

    # Check if we should restart emulator
    if ($RestartEmulatorEvery -gt 0 -and $i -gt 1 -and ($i - 1) % $RestartEmulatorEvery -eq 0) {
        Write-Host ""
        Write-Host "Proactive emulator service restart (every $RestartEmulatorEvery runs)" -ForegroundColor Cyan
        Restart-EmulatorServices | Out-Null
        $emulatorRestarts++
        Write-Host ""
    }

    # Health check before run
    if (-not $SkipEmulatorCheck) {
        if (-not (Test-EmulatorHealth)) {
            Write-Host ""
            Write-Host "WARNING: Emulator is unhealthy, attempting to restart services..." -ForegroundColor Yellow

            if (Restart-EmulatorServices) {
                $emulatorRestarts++
                Write-Host "  Continuing with test run..." -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "CRITICAL: Cannot restore emulator health" -ForegroundColor Red
                Write-Host "   Manual intervention required:" -ForegroundColor Yellow
                Write-Host "   1. Close and restart the Android emulator" -ForegroundColor Gray
                Write-Host "   2. Wait for emulator to fully boot" -ForegroundColor Gray
                Write-Host "   3. Press Enter to retry, or Ctrl+C to abort" -ForegroundColor Gray
                $null = Read-Host

                if (Test-EmulatorHealth) {
                    Write-Host "  OK - Emulator restored!" -ForegroundColor Green
                } else {
                    Write-Host "  FAIL - Still unhealthy. Aborting." -ForegroundColor Red
                    break
                }
            }
        }
    }

    # Run tests
    $logTime = Get-Date -Format "HHmmss"
    $logFile = "$outputDir\run_${i}_$logTime.log"

    Write-Host ""
    Write-Host "Running tests..." -ForegroundColor White

    # Execute flutter test
    $testOutput = flutter test $testPath.Split() --reporter=expanded 2>&1 | Tee-Object -FilePath $logFile
    $exitCode = $LASTEXITCODE

    $runEnd = Get-Date
    $duration = ($runEnd - $runStart).ToString("hh\:mm\:ss")

    # Add metadata
    $metadata = @"

=== RUN METADATA ===
Run: $i
Exit Code: $exitCode
Start: $($runStart.ToString("yyyy-MM-dd HH:mm:ss"))
End: $($runEnd.ToString("yyyy-MM-dd HH:mm:ss"))
Duration: $duration
Emulator Restarts (total): $emulatorRestarts
Tests: $testDescription
"@
    Add-Content -Path $logFile -Value $metadata

    # Check for emulator crash during test
    $hasEmulatorCrash = Select-String -Path $logFile -Pattern "Can't find service: (activity|package)" -Quiet

    # Record result
    if ($exitCode -ne 0) {
        Write-Host ""
        Write-Host "FAILED: Run $i" -ForegroundColor Red
        Write-Host "   Duration: $duration" -ForegroundColor Gray

        if ($hasEmulatorCrash) {
            Write-Host "   Cause: Emulator crash detected" -ForegroundColor Yellow
            Add-Content -Path $logFile -Value "Emulator Crash: YES"
        }

        Add-Content -Path "$outputDir\summary.txt" -Value "FAILED"
        $failed++
    } else {
        Write-Host ""
        Write-Host "PASSED: Run $i" -ForegroundColor Green
        Write-Host "   Duration: $duration" -ForegroundColor Gray
        Add-Content -Path "$outputDir\summary.txt" -Value "PASSED"
        $passed++
    }

    # Progress update
    $remaining = $Iterations - $i
    $avgDuration = ($runEnd - $runStart).TotalMinutes
    $eta = [math]::Round($remaining * $avgDuration / 60, 1)

    Write-Host ""
    Write-Host "Progress: $i/$Iterations complete | P:$passed F:$failed | ETA: ~$eta hours" -ForegroundColor Cyan

    # Small delay between runs
    if ($i -lt $Iterations) {
        Start-Sleep -Seconds 3
    }
}

# Final summary
$totalEnd = Get-Date
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                   STRESS TEST COMPLETE                         " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Total Runs:         $Iterations"
Write-Host "  Passed:             $passed" -ForegroundColor Green
Write-Host "  Failed:             $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate:          $([math]::Round($passed / $Iterations * 100, 1))%"
Write-Host "  Emulator Restarts:  $emulatorRestarts"
Write-Host ""
Write-Host "Logs saved to: $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow

if ($failed -gt 0) {
    Write-Host "  1. Analyze failures:" -ForegroundColor White
    Write-Host "     dart scripts\analyze_test_logs.dart $outputDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Check for emulator crashes:" -ForegroundColor White
    Write-Host '     Select-String -Path $outputDir\*.log -Pattern "Can' + "'" + 't find service" | Group-Object Filename' -ForegroundColor Gray
} else {
    Write-Host "  All tests passed! No flakiness detected." -ForegroundColor Green
}

Write-Host ""
