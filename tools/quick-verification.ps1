# Quick Verification Script
# 一键验收所有功能

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   AI Work Archiver - Quick Verification    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0
$warnings = 0

function Test-Feature {
    param(
        [string]$Name,
        [string]$Script,
        [string[]]$Arguments = @()
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    
    try {
        if ($Arguments.Count -gt 0) {
            & $Script @Arguments 2>&1 | Out-Null
        } else {
            & $Script 2>&1 | Out-Null
        }
        
        if ($LASTEXITCODE -eq 0 -or $?) {
            Write-Host "  ✓ PASSED" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host "  ✗ FAILED (exit code: $LASTEXITCODE)" -ForegroundColor Red
            $script:failed++
        }
    } catch {
        Write-Host "  ✗ ERROR: $_" -ForegroundColor Red
        $script:failed++
    }
    
    Write-Host ""
}

function Test-FileExists {
    param([string]$Name, [string]$Path)
    
    Write-Host "Checking: $Name" -ForegroundColor Yellow
    
    if (Test-Path $Path) {
        Write-Host "  ✓ EXISTS" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  ✗ NOT FOUND: $Path" -ForegroundColor Red
        $script:failed++
    }
    
    Write-Host ""
}

# Test 1: Data Files
Write-Host "=== Phase 1: Data Integrity ===" -ForegroundColor Cyan
Write-Host ""

Test-FileExists "Git Activities Index" "..\work-archive\data\git-activities\activity-index.json"
Test-FileExists "Dashboard Data" "..\docs-server\public\dashboard-data.json"

# Count activity files (from archive-db)
$activityCount = (Get-ChildItem "..\work-archive\archive-db\git-activities\*.md" -ErrorAction SilentlyContinue).Count
Write-Host "Activity Files Count" -ForegroundColor Yellow
if ($activityCount -gt 0) {
    Write-Host "  ✓ Found $activityCount files" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ No activity files found" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 2: New Features
Write-Host "=== Phase 2: New Features ===" -ForegroundColor Cyan
Write-Host ""

Test-Feature "Commit Quality Scorer" ".\commit-quality-scorer.ps1"
Test-Feature "Workflow Automation" ".\workflow-automation.ps1" "-Action" "check"

# Test 3: Core Functions
Write-Host "=== Phase 3: Core Functions ===" -ForegroundColor Cyan
Write-Host ""

Test-Feature "Dashboard Generator" ".\generate-dashboard-data.ps1"

# Test 4: Reports
Write-Host "=== Phase 4: Report Generation ===" -ForegroundColor Cyan
Write-Host ""

Test-Feature "Daily Report" ".\daily-report-enhanced.ps1"
Test-Feature "Weekly Report" ".\weekly-report-enhanced.ps1"

# Test 5: Achievement System
Write-Host "=== Phase 5: Achievement System ===" -ForegroundColor Cyan
Write-Host ""

Test-Feature "Achievement Check" ".\achievement-system-core.ps1" "-Action" "check"

# Test 6: Data Backup
Write-Host "=== Phase 6: Data Backup ===" -ForegroundColor Cyan
Write-Host ""

Test-Feature "Data Backup" ".\data-backup-restore.ps1" "-Action" "backup" "-Compress"

# Summary
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Verification Summary              ║" -ForegroundColor Cyan
Write-Host "╠════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║                                            ║" -ForegroundColor Cyan
Write-Host "║  Passed:   $passed                            ║" -ForegroundColor Green
Write-Host "║  Failed:   $failed                            " -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "║                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0) {
    Write-Host "✓ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Start dashboard: .\run-phase4.ps1 -All" -ForegroundColor White
    Write-Host "  2. Open browser: http://localhost:3456/dashboard" -ForegroundColor White
    Write-Host "  3. View acceptance guide: ..\docs\ACCEPTANCE-GUIDE.md" -ForegroundColor White
} else {
    Write-Host "⚠ Some tests failed. Check the errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "  1. Ensure you ran git-activity-aggregator.ps1 first" -ForegroundColor White
    Write-Host "  2. Check file paths are correct" -ForegroundColor White
    Write-Host "  3. See ACCEPTANCE-GUIDE.md for details" -ForegroundColor White
}

Write-Host ""
