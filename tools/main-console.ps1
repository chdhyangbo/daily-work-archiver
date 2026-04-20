# AI Work Archiver - Main Console
# Interactive menu for running all tools

$toolsDir = $PSScriptRoot
$archiveDir = Join-Path $PSScriptRoot "..\work-archive"
$dataDir = Join-Path $archiveDir "data"

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  AI Work Archiver - Main Console" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Show-Header
    
    Write-Host "[One-Click Run]" -ForegroundColor Green
    Write-Host "  1. Run all tools (full process)" -ForegroundColor White
    Write-Host "  2. Quick run (skip Git scan)" -ForegroundColor White
    Write-Host "  3. Run specific phase" -ForegroundColor White
    Write-Host ""
    
    Write-Host "[Data View]" -ForegroundColor Green
    Write-Host "  4. View data overview" -ForegroundColor White
    Write-Host "  5. Open unified display center (Web)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "[Tool Management]" -ForegroundColor Green
    Write-Host "  6. Verify all functions" -ForegroundColor White
    Write-Host "  7. Backup data" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  0. Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Run-Tool {
    param([string]$Name, [string]$Script, [string[]]$Arguments = @())
    
    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor Cyan
    
    try {
        $scriptPath = Join-Path $toolsDir $Script
        if (Test-Path $scriptPath) {
            if ($Arguments.Count -gt 0) {
                & $scriptPath @Arguments 2>&1 | Out-Null
            } else {
                & $scriptPath 2>&1 | Out-Null
            }
            
            if ($LASTEXITCODE -eq 0 -or $?) {
                Write-Host "OK: Complete" -ForegroundColor Green
            } else {
                Write-Host "FAIL: Exit code $LASTEXITCODE" -ForegroundColor Red
            }
        } else {
            Write-Host "FAIL: Script not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

function Run-AllTools {
    param([switch]$SkipGitScan = $false)
    
    Show-Header
    Write-Host "Running all tools..." -ForegroundColor Magenta
    Write-Host ""
    
    $startTime = Get-Date
    
    if (-not $SkipGitScan) {
        Run-Tool "Git Activity Aggregator" "git-activity-aggregator.ps1"
    }
    
    Run-Tool "Commit Quality Scorer" "commit-quality-scorer.ps1"
    Run-Tool "Workflow Automation" "workflow-automation.ps1" "-Action" "check"
    Run-Tool "Work Advisor" "work-advisor.ps1"
    Run-Tool "Growth Tracker" "growth-tracker.ps1"
    Run-Tool "Time Optimizer" "time-optimizer.ps1"
    Run-Tool "Change Impact Analyzer" "change-impact-analyzer.ps1"
    Run-Tool "Project Health Monitor" "project-health-monitor.ps1"
    Run-Tool "Project Retro" "project-retro-generator.ps1"
    Run-Tool "Smart Report" "smart-report-summarizer.ps1" "-ReportType" "weekly"
    Run-Tool "Achievement Cards" "achievement-card-generator.ps1"
    Run-Tool "API Data" "data-dashboard-api.ps1"
    Run-Tool "Dashboard Data" "generate-dashboard-data.ps1"
    
    $endTime = Get-Date
    $duration = [Math]::Round(($endTime - $startTime).TotalSeconds, 1)
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "All complete! Time: ${duration}s" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-DataOverview {
    Show-Header
    Write-Host "Data Overview" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
    
    $activityCount = (Get-ChildItem (Join-Path $archiveDir "archive-db\git-activities\*.md") -ErrorAction SilentlyContinue).Count
    Write-Host "Git Activity Data:" -ForegroundColor Yellow
    Write-Host "  Files: $activityCount" -ForegroundColor White
    $indexFile = Join-Path $dataDir "git-activities\activity-index.json"
    if (Test-Path $indexFile) {
        $index = Get-Content $indexFile | ConvertFrom-Json
        Write-Host "  Total commits: $($index.totalCommits)" -ForegroundColor White
    }
    Write-Host ""
    
    $qualityDir = Join-Path $dataDir "commit-quality"
    Write-Host "Quality Data:" -ForegroundColor Yellow
    if (Test-Path $qualityDir) {
        $summaryFile = Join-Path $qualityDir "quality-summary.json"
        if (Test-Path $summaryFile) {
            $summary = Get-Content $summaryFile | ConvertFrom-Json
            Write-Host "  Scored: $($summary.totalCommits)" -ForegroundColor White
            Write-Host "  Average: $($summary.averageScore)/100" -ForegroundColor White
        }
    } else {
        Write-Host "  Not generated" -ForegroundColor Red
    }
    Write-Host ""
    
    $growthDir = Join-Path $dataDir "growth"
    Write-Host "Growth Data:" -ForegroundColor Yellow
    $growthFile = Join-Path $growthDir "growth-report.json"
    if (Test-Path $growthFile) {
        $growth = Get-Content $growthFile | ConvertFrom-Json
        Write-Host "  Projects: $($growth.summary.totalProjects)" -ForegroundColor White
        Write-Host "  Commits: $($growth.summary.totalCommits)" -ForegroundColor White
    } else {
        Write-Host "  Not generated" -ForegroundColor Red
    }
    Write-Host ""
    
    $healthDir = Join-Path $dataDir "project-health"
    Write-Host "Health Data:" -ForegroundColor Yellow
    $healthFile = Join-Path $healthDir "health-report.json"
    if (Test-Path $healthFile) {
        $health = Get-Content $healthFile | ConvertFrom-Json
        Write-Host "  Projects: $($health.summary.totalProjects)" -ForegroundColor White
        Write-Host "  Healthy: $($health.summary.healthyCount)" -ForegroundColor Green
        Write-Host "  At Risk: $($health.summary.atRiskCount)" -ForegroundColor Red
    } else {
        Write-Host "  Not generated" -ForegroundColor Red
    }
    Write-Host ""
    
    Write-Host "Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Verify-AllFunctions {
    Show-Header
    Write-Host "Verifying all functions..." -ForegroundColor Magenta
    Write-Host ""
    
    $scriptPath = Join-Path $toolsDir "quick-verification.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath
    } else {
        Write-Host "Verification script not found" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Open-Dashboard {
    Show-Header
    Write-Host "Starting unified display center..." -ForegroundColor Cyan
    Write-Host ""
    
    $serverDir = Join-Path $PSScriptRoot "..\docs-server"
    $serverScript = Join-Path $serverDir "server.js"
    if (Test-Path $serverScript) {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$serverDir'; node server.js"
        Write-Host "OK: Web service started" -ForegroundColor Green
        Write-Host ""
        Write-Host "Access URLs:" -ForegroundColor Cyan
        Write-Host "  Unified Center: http://localhost:3456/overview" -ForegroundColor Yellow
        Write-Host "  Dashboard: http://localhost:3456/dashboard" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "FAIL: Server script not found" -ForegroundColor Red
    }
    
    Write-Host "Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Backup-Data {
    Show-Header
    Write-Host "Starting data backup..." -ForegroundColor Cyan
    Write-Host ""
    
    $scriptPath = Join-Path $toolsDir "data-backup-restore.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath -Action backup -Compress
    } else {
        Write-Host "Backup script not found" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to return..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main loop
while ($true) {
    Show-Menu
    
    $choice = Read-Host "Select operation (0-7)"
    
    switch ($choice) {
        "1" { Run-AllTools }
        "2" { Run-AllTools -SkipGitScan }
        "3" {
            Show-Header
            Write-Host "Select Phase:" -ForegroundColor Cyan
            Write-Host "  1. Phase 1 - Core Enhancement" -ForegroundColor White
            Write-Host "  2. Phase 2 - Smart Analysis" -ForegroundColor White
            Write-Host "  3. Phase 3 - Deep Insights" -ForegroundColor White
            Write-Host "  4. Phase 4 - AI Integration" -ForegroundColor White
            $phaseChoice = Read-Host "Select (1-4)"
            
            switch ($phaseChoice) {
                "1" { Run-Tool "Phase 1" "run-all-tools.ps1" "-Phase1" }
                "2" { Run-Tool "Phase 2" "run-all-tools.ps1" "-Phase2" }
                "3" { Run-Tool "Phase 3" "run-all-tools.ps1" "-Phase3" }
                "4" { Run-Tool "Phase 4" "run-all-tools.ps1" "-Phase4" }
            }
            
            Write-Host ""
            Write-Host "Press any key to return..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" { Show-DataOverview }
        "5" { Open-Dashboard }
        "6" { Verify-AllFunctions }
        "7" { Backup-Data }
        "0" { 
            Write-Host ""; Write-Host "Goodbye!" -ForegroundColor Green; 
            exit 
        }
        default {
            Write-Host "Invalid choice, try again" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
