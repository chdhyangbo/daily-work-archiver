# Data Dashboard API
# 为Web仪表板提供API接口

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$GrowthDir = (Join-Path $PSScriptRoot "..\work-archive\data\growth"),
    [string]$HealthDir = (Join-Path $PSScriptRoot "..\work-archive\data\project-health"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\docs-server\public\api"),
    [string]$Port = "3456"
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Generate-QualityReport {
    param(
        [string]$QualityDir,
        [string]$OutputDir
    )

    $summaryFile = Join-Path $QualityDir "quality-summary.json"
    $trendFile = Join-Path $QualityDir "quality-trend.json"
    $topFile = Join-Path $QualityDir "top-commits.json"
    $projectFile = Join-Path $QualityDir "project-quality.json"

    $report = @{}
    if (Test-Path $summaryFile) {
        $report.summary = Get-Content $summaryFile | ConvertFrom-Json
    } else {
        $report.summary = $null
    }
    
    if (Test-Path $trendFile) {
        $report.trend = Get-Content $trendFile | ConvertFrom-Json
    } else {
        $report.trend = @()
    }
    
    if (Test-Path $topFile) {
        $report.topCommits = Get-Content $topFile | ConvertFrom-Json
    } else {
        $report.topCommits = @()
    }
    
    if (Test-Path $projectFile) {
        $report.projectQuality = Get-Content $projectFile | ConvertFrom-Json
    } else {
        $report.projectQuality = @()
    }

    $outputFile = Join-Path $OutputDir "quality-report.json"
    $report | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding UTF8
}

function Generate-GrowthReport {
    param(
        [string]$GrowthDir,
        [string]$OutputDir
    )

    $growthFile = Join-Path $GrowthDir "growth-report.json"

    if (Test-Path $growthFile) {
        $report = Get-Content $growthFile | ConvertFrom-Json
    } else {
        $report = @{
            summary = @{
                totalProjects = 0
                totalCommits = 0
                milestonesReached = 0
            }
            milestones = @()
            monthlyTrend = @()
        }
    }

    $outputFile = Join-Path $OutputDir "growth-report.json"
    $report | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding UTF8
}

function Generate-HealthReport {
    param(
        [string]$HealthDir,
        [string]$OutputDir
    )

    $healthFile = Join-Path $HealthDir "health-report.json"

    if (Test-Path $healthFile) {
        $report = Get-Content $healthFile | ConvertFrom-Json
    } else {
        $report = @{
            summary = @{
                totalProjects = 0
                healthyCount = 0
                moderateCount = 0
                atRiskCount = 0
                criticalCount = 0
            }
            projects = @()
        }
    }

    $outputFile = Join-Path $OutputDir "health-report.json"
    $report | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding UTF8
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Dashboard API Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Generating quality report..." -ForegroundColor Yellow
Generate-QualityReport -QualityDir $QualityDir -OutputDir $OutputDir

Write-Host "Generating growth report..." -ForegroundColor Yellow
Generate-GrowthReport -GrowthDir $GrowthDir -OutputDir $OutputDir

Write-Host "Generating health report..." -ForegroundColor Yellow
Generate-HealthReport -HealthDir $HealthDir -OutputDir $OutputDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "API Data Generated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Available endpoints:" -ForegroundColor Cyan
Write-Host "  /api/quality-report.json" -ForegroundColor White
Write-Host "  /api/growth-report.json" -ForegroundColor White
Write-Host "  /api/health-report.json" -ForegroundColor White
Write-Host ""
Write-Host "Access via: http://localhost:$Port/api/quality-report.json" -ForegroundColor Yellow
