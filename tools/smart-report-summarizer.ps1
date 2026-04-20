# Smart Report Summarizer
# Generates intelligent summary reports from data analysis

param(
    [string]$ReportType = "weekly",
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$GrowthDir = (Join-Path $PSScriptRoot "..\work-archive\data\growth"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\reports\smart")
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Generate-WeeklySummary {
    param(
        [string]$ActivitiesDir,
        [string]$QualityDir,
        [string]$GrowthDir
    )

    $today = Get-Date
    $weekStart = $today.AddDays(-[int]$today.DayOfWeek)
    $weekStartStr = $weekStart.ToString("yyyy-MM-dd")
    $todayStr = $today.ToString("yyyy-MM-dd")

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return "No activity data found" }

    $weeklyCommits = @()
    $weeklyProjects = @{}
    $weeklyTypes = @{}
    $totalChanged = 0

    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        if ($date -lt $weekStartStr -or $date -gt $todayStr) { continue }
        foreach ($commit in $data.commits) {
            $weeklyCommits += $commit
            $project = $commit.project
            if (-not $weeklyProjects.ContainsKey($project)) {
                $weeklyProjects[$project] = 0
            }
            $weeklyProjects[$project]++
            $commitType = $commit.type
            if (-not $weeklyTypes.ContainsKey($commitType)) {
                $weeklyTypes[$commitType] = 0
            }
            $weeklyTypes[$commitType]++
            $totalChanged += $commit.changed
        }
    }

    if ($weeklyCommits.Count -eq 0) { return "No commits this week" }

    $report = @()
    $report += "# Weekly Work Summary"
    $report += ""
    $report += "**Period**: $weekStartStr to $todayStr"
    $report += ""
    $report += "## Overview"
    $report += ""
    $report += "This week completed **$($weeklyCommits.Count)** commits across **$($weeklyProjects.Count)** projects, with **$totalChanged** lines of code changed."
    $report += ""

    $report += "## Project Progress"
    $report += ""
    $sortedProjects = $weeklyProjects.GetEnumerator() | Sort-Object Value -Descending
    foreach ($entry in $sortedProjects) {
        $report += "- **$($entry.Key)**: $($entry.Value) commits"
    }
    $report += ""

    $report += "## Work Type Distribution"
    $report += ""
    $typeNames = @{
        "FEATURE" = "New Feature"
        "FIX" = "Bug Fix"
        "REFACTOR" = "Refactor"
        "DOCS" = "Documentation"
        "TEST" = "Testing"
        "OTHER" = "Other"
    }
    $sortedTypes = $weeklyTypes.GetEnumerator() | Sort-Object Value -Descending
    foreach ($entry in $sortedTypes) {
        $typeName = if ($typeNames.ContainsKey($entry.Key)) { $typeNames[$entry.Key] } else { $entry.Key }
        $report += "- $typeName`: $($entry.Value) times"
    }
    $report += ""

    $qualitySummaryFile = Join-Path $QualityDir "quality-summary.json"
    if (Test-Path $qualitySummaryFile) {
        $qualityData = Get-Content $qualitySummaryFile | ConvertFrom-Json
        $avgScore = $qualityData.averageScore
        $report += "## Code Quality"
        $report += ""
        $report += "Average quality score: **$avgScore/100**"
        $report += ""
        if ($avgScore -ge 80) {
            $report += "- Excellent code quality this week, keep it up!"
        } elseif ($avgScore -ge 70) {
            $report += "- Good code quality, room for improvement"
        } else {
            $report += "- Code quality needs attention, focus on commit message standards"
        }
        $report += ""
    }

    $growthFile = Join-Path $GrowthDir "growth-report.json"
    if (Test-Path $growthFile) {
        $growthData = Get-Content $growthFile | ConvertFrom-Json
        $milestones = $growthData.milestones
        if ($milestones -and $milestones.Count -gt 0) {
            $report += "## Milestones"
            $report += ""
            foreach ($ms in $milestones) {
                $report += "- **$($ms.title)**: $($ms.date)"
            }
            $report += ""
        }
    }

    $report += "## Suggestions"
    $report += ""
    if ($weeklyCommits.Count -gt 20) {
        $report += "- High output this week, consider documenting key achievements"
    }
    $fixCount = if ($weeklyTypes.ContainsKey("FIX")) { $weeklyTypes["FIX"] } else { 0 }
    $fixRatio = $fixCount / $weeklyCommits.Count
    if ($fixRatio -gt 0.4) {
        $report += "- High bug fix ratio ($([Math]::Round($fixRatio * 100, 1))%), consider strengthening code review"
    }
    if ($weeklyProjects.Count -gt 5) {
        $report += "- Working on multiple projects simultaneously, focus on reducing context switching"
    }
    $report += ""

    return $report -join "`n"
}

function Generate-DailySummary {
    param(
        [string]$ActivitiesDir
    )

    $today = Get-Date -Format "yyyy-MM-dd"
    $todayFile = Join-Path $ActivitiesDir "$today.json"
    if (-not (Test-Path $todayFile)) {
        return "# Daily Summary`n`nNo activity today"
    }

    $data = Get-Content $todayFile | ConvertFrom-Json
    $commits = $data.commits

    if ($commits.Count -eq 0) {
        return "# Daily Summary`n`nNo commits today"
    }

    $report = @()
    $report += "# Daily Summary - $today"
    $report += ""
    $report += "Completed **$($commits.Count)** commits today"
    $report += ""
    $report += "## Details"
    $report += ""
    foreach ($commit in $commits) {
        $report += "- [$($commit.project)] $($commit.subject) (+$($commit.added) -$($commit.deleted))"
    }
    $report += ""

    return $report -join "`n"
}

function Generate-MonthlySummary {
    param(
        [string]$ActivitiesDir,
        [string]$QualityDir
    )

    $today = Get-Date
    $monthStart = Get-Date -Year $today.Year -Month $today.Month -Day 1
    $monthStartStr = $monthStart.ToString("yyyy-MM-dd")
    $todayStr = $today.ToString("yyyy-MM-dd")

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return "No activity data" }

    $monthlyCommits = @()
    $projectStats = @{}
    $totalChanged = 0

    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        if ($date -lt $monthStartStr -or $date -gt $todayStr) { continue }
        foreach ($commit in $data.commits) {
            $monthlyCommits += $commit
            $project = $commit.project
            if (-not $projectStats.ContainsKey($project)) {
                $projectStats[$project] = @{ commits = 0; changed = 0 }
            }
            $projectStats[$project].commits++
            $projectStats[$project].changed += $commit.changed
            $totalChanged += $commit.changed
        }
    }

    if ($monthlyCommits.Count -eq 0) {
        return "# Monthly Summary`n`nNo activity this month"
    }

    $report = @()
    $report += "# Monthly Summary"
    $report += ""
    $report += "**Period**: $monthStartStr to $todayStr"
    $report += ""
    $report += "## Overview"
    $report += ""
    $report += "This month completed **$($monthlyCommits.Count)** commits, changed **$totalChanged** lines"
    $report += ""
    $report += "## Project Contributions"
    $report += ""
    foreach ($entry in $projectStats.GetEnumerator()) {
        $report += "- **$($entry.Key)**: $($entry.Value.commits) commits, $($entry.Value.changed) lines"
    }
    $report += ""
    $report += "## Work Rhythm"
    $report += ""
    $activeDays = $activityFiles | Where-Object { $_.Name -ne "activity-index.json" -and $_.Name -ge "$monthStartStr" -and $_.Name -le "$todayStr" }
    $workingDays = ([datetime]::Today - $monthStart).Days + 1
    $activityRate = [Math]::Round(($activeDays.Count / $workingDays) * 100, 1)
    $report += "- Active days: $($activeDays.Count) / $workingDays days ($activityRate%)"
    $report += ""

    return $report -join "`n"
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Report Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$reportContent = ""
$outputFile = ""

switch ($ReportType.ToLower()) {
    "daily" {
        Write-Host "Generating daily report..." -ForegroundColor Yellow
        $reportContent = Generate-DailySummary -ActivitiesDir $ActivitiesDir
        $outputFile = Join-Path $OutputDir "$(Get-Date -Format 'yyyy-MM-dd')-daily.md"
    }
    "weekly" {
        Write-Host "Generating weekly report..." -ForegroundColor Yellow
        $reportContent = Generate-WeeklySummary -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir -GrowthDir $GrowthDir
        $outputFile = Join-Path $OutputDir "$(Get-Date -Format 'yyyy-MM-dd')-weekly.md"
    }
    "monthly" {
        Write-Host "Generating monthly report..." -ForegroundColor Yellow
        $reportContent = Generate-MonthlySummary -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir
        $outputFile = Join-Path $OutputDir "$(Get-Date -Format 'yyyy-MM')-monthly.md"
    }
    default {
        Write-Host "Unknown report type: $ReportType" -ForegroundColor Red
        exit 1
    }
}

if ($reportContent) {
    $reportContent | Out-File $outputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Report saved to: $outputFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Preview:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $reportContent
    Write-Host "========================================" -ForegroundColor Cyan
}
