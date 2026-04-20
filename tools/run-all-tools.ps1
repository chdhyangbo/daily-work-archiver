# Master Runner - 一键运行所有工具

param(
    [switch]$All,
    [switch]$Phase1,
    [switch]$Phase2,
    [switch]$Phase3,
    [switch]$Phase4,
    [switch]$Reports,
    [switch]$Dashboard
)

$toolsDir = $PSScriptRoot

function Run-Tool {
    param(
        [string]$Name,
        [string]$Script,
        [string[]]$Arguments = @()
    )

    Write-Host ""
    Write-Host "[$Name]" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    try {
        $scriptPath = Join-Path $toolsDir $Script
        if (Test-Path $scriptPath) {
            if ($Arguments.Count -gt 0) {
                & $scriptPath @Arguments
            } else {
                & $scriptPath
            }
        } else {
            Write-Host "  Script not found: $Script" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

if ($All) {
    Write-Host "Running ALL tools..." -ForegroundColor Magenta

    # Phase 1
    if ($Phase1 -or $All) {
        Run-Tool "Git Activity Aggregator" "git-activity-aggregator.ps1"
        Run-Tool "Commit Quality Scorer" "commit-quality-scorer.ps1"
        Run-Tool "Workflow Automation" "workflow-automation.ps1" "-Action" "check"
    }

    # Phase 2
    if ($Phase2 -or $All) {
        Run-Tool "Work Advisor" "work-advisor.ps1"
        Run-Tool "Growth Tracker" "growth-tracker.ps1"
        Run-Tool "Time Optimizer" "time-optimizer.ps1"
    }

    # Phase 3
    if ($Phase3 -or $All) {
        Run-Tool "Change Impact Analyzer" "change-impact-analyzer.ps1"
        Run-Tool "Project Health Monitor" "project-health-monitor.ps1"
        Run-Tool "Project Retro Generator" "project-retro-generator.ps1"
    }

    # Phase 4
    if ($Phase4 -or $All) {
        Run-Tool "Smart Report Summarizer" "smart-report-summarizer.ps1" "-ReportType" "weekly"
        Run-Tool "Achievement Card Generator" "achievement-card-generator.ps1"
        Run-Tool "Data Dashboard API" "data-dashboard-api.ps1"
    }

    # Reports
    if ($Reports -or $All) {
        Run-Tool "Daily Report" "daily-report-enhanced.ps1"
        Run-Tool "Weekly Report" "weekly-report-enhanced.ps1"
    }

    # Dashboard
    if ($Dashboard -or $All) {
        Run-Tool "Generate Dashboard Data" "generate-dashboard-data.ps1"
    }
} elseif ($Phase1) {
    Run-Tool "Git Activity Aggregator" "git-activity-aggregator.ps1"
    Run-Tool "Commit Quality Scorer" "commit-quality-scorer.ps1"
    Run-Tool "Workflow Automation" "workflow-automation.ps1" "-Action" "check"
} elseif ($Phase2) {
    Run-Tool "Work Advisor" "work-advisor.ps1"
    Run-Tool "Growth Tracker" "growth-tracker.ps1"
    Run-Tool "Time Optimizer" "time-optimizer.ps1"
} elseif ($Phase3) {
    Run-Tool "Change Impact Analyzer" "change-impact-analyzer.ps1"
    Run-Tool "Project Health Monitor" "project-health-monitor.ps1"
    Run-Tool "Project Retro Generator" "project-retro-generator.ps1"
} elseif ($Phase4) {
    Run-Tool "Smart Report Summarizer" "smart-report-summarizer.ps1" "-ReportType" "weekly"
    Run-Tool "Achievement Card Generator" "achievement-card-generator.ps1"
    Run-Tool "Data Dashboard API" "data-dashboard-api.ps1"
} elseif ($Reports) {
    Run-Tool "Daily Report" "daily-report-enhanced.ps1"
    Run-Tool "Weekly Report" "weekly-report-enhanced.ps1"
} elseif ($Dashboard) {
    Run-Tool "Generate Dashboard Data" "generate-dashboard-data.ps1"
} else {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\run-all-tools.ps1 -All              # Run all tools" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Phase1           # Run Phase 1 tools" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Phase2           # Run Phase 2 tools" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Phase3           # Run Phase 3 tools" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Phase4           # Run Phase 4 tools" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Reports          # Generate reports" -ForegroundColor White
    Write-Host "  .\run-all-tools.ps1 -Dashboard        # Update dashboard" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
