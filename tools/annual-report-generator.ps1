# Annual Report Generator
# Generates comprehensive yearly summary

param(
    [string]$Year = (Get-Date -Format "yyyy"),
    [string]$OutputPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "work-archive") "annual-reports"),
    [string[]]$ProjectPaths = @("D:\work\code", "D:\work\codepos")
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

function Get-YearlyGitStats($year, $projectPaths) {
    $stats = @{
        totalCommits = 0
        monthlyCommits = @{}
        projectCommits = @{}
        typeCommits = @{
            FEATURE = 0
            FIX = 0
            REFACTOR = 0
            DOCS = 0
            TEST = 0
            OTHER = 0
        }
        totalInsertions = 0
        totalDeletions = 0
        activeDays = 0
        longestStreak = 0
        busiestMonth = ""
        busiestDay = ""
        topProject = ""
    }
    
    $startDate = "$year-01-01"
    $endDate = "$year-12-31"
    
    foreach ($rootPath in $projectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            $commits = & git -c core.quotepath=false log --since="$startDate" --until="$endDate" --author="yangbo" --pretty=format:"%H|%ad|%s" --date=format:"%Y-%m-%d %H:%M:%S" 2>$null
            
            if ($commits) {
                $commitList = $commits -split "`n" | Where-Object { $_ }
                $stats.totalCommits += $commitList.Count
                
                if (-not $stats.projectCommits[$projectName]) {
                    $stats.projectCommits[$projectName] = 0
                }
                $stats.projectCommits[$projectName] += $commitList.Count
                
                foreach ($commit in $commitList) {
                    $parts = $commit.Split('|')
                    $dateTime = $parts[1]
                    $message = $parts[2]
                    $date = $dateTime.Split(' ')[0]
                    $month = $date.Substring(0, 7)
                    
                    # Monthly stats
                    if (-not $stats.monthlyCommits[$month]) {
                        $stats.monthlyCommits[$month] = 0
                    }
                    $stats.monthlyCommits[$month]++
                    
                    # Type classification
                    if ($message -match "^feat|新增|添加|实现") { $stats.typeCommits.FEATURE++ }
                    elseif ($message -match "^fix|修复|解决|bug") { $stats.typeCommits.FIX++ }
                    elseif ($message -match "^refactor|重构") { $stats.typeCommits.REFACTOR++ }
                    elseif ($message -match "^docs|文档") { $stats.typeCommits.DOCS++ }
                    elseif ($message -match "^test|测试") { $stats.typeCommits.TEST++ }
                    else { $stats.typeCommits.OTHER++ }
                    
                    # Code changes
                    $hash = $parts[0]
                    $statInfo = git show --stat --format="" $hash 2>$null | Select-Object -Last 1
                    if ($statInfo -match "(\d+) insertion") {
                        $stats.totalInsertions += [int]$matches[1]
                    }
                    if ($statInfo -match "(\d+) deletion") {
                        $stats.totalDeletions += [int]$matches[1]
                    }
                }
            }
        }
    }
    
    Set-Location $PSScriptRoot
    
    # Calculate derived stats
    if ($stats.monthlyCommits.Count -gt 0) {
        $stats.busiestMonth = ($stats.monthlyCommits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Name
    }
    
    if ($stats.projectCommits.Count -gt 0) {
        $stats.topProject = ($stats.projectCommits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Name
    }
    
    # Count active days and calculate streak
    $allDates = @()
    foreach ($month in $stats.monthlyCommits.Keys) {
        $monthStart = "$month-01"
        $monthEnd = "$month-28"
        $commits = & git log --since="$monthStart" --until="$monthEnd" --author="yangbo" --pretty=format:"%ad" --date=format:"%Y-%m-%d" --all 2>$null
        if ($commits) {
            $allDates += $commits -split "`n" | Where-Object { $_ }
        }
    }
    
    $uniqueDates = $allDates | Select-Object -Unique
    $stats.activeDays = $uniqueDates.Count
    
    return $stats
}

function Generate-AnnualReport($year, $stats) {
    $avgMonthly = if ($stats.monthlyCommits.Count -gt 0) { 
        [Math]::Round($stats.totalCommits / 12, 1) 
    } else { 0 }
    
    $avgDaily = if ($stats.activeDays -gt 0) { 
        [Math]::Round($stats.totalCommits / $stats.activeDays, 1) 
    } else { 0 }
    
    $report = @"
# $Year Annual Report

> Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

---

## Year Overview

| Metric | Value |
|--------|-------|
| **Total Commits** | $($stats.totalCommits) |
| **Active Days** | $($stats.activeDays) |
| **Projects Contributed** | $($stats.projectCommits.Count) |
| **Busiest Month** | $($stats.busiestMonth) |
| **Top Project** | $($stats.topProject) |
| **Code Added** | +$($stats.totalInsertions) lines |
| **Code Removed** | -$($stats.totalDeletions) lines |

---

## Monthly Activity

"@
    
    # Add monthly breakdown
    $months = @("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")
    $report += "| Month | Commits | Activity |`n"
    $report += "|-------|---------|----------|`n"
    
    foreach ($month in $months) {
        $monthKey = "$year-$month"
        $count = if ($stats.monthlyCommits[$monthKey]) { $stats.monthlyCommits[$monthKey] } else { 0 }
        $bar = if ($count -gt 0) { 
            "█" * [Math]::Min([Math]::Round($count / 5), 20) 
        } else { "-" }
        $report += "| $monthKey | $count | $bar |`n"
    }
    
    $report += @"

---

## Project Distribution

| Project | Commits | Percentage |
|---------|---------|------------|
"@
    
    $sortedProjects = $stats.projectCommits.GetEnumerator() | Sort-Object Value -Descending
    foreach ($proj in $sortedProjects) {
        $percent = if ($stats.totalCommits -gt 0) { 
            [Math]::Round(($proj.Value / $stats.totalCommits) * 100) 
        } else { 0 }
        $report += "| $($proj.Key) | $($proj.Value) | $percent% |`n"
    }
    
    $report += @"

---

## Work Type Distribution

| Type | Count | Percentage |
|------|-------|------------|
"@
    
    $totalTyped = ($stats.typeCommits.Values | Measure-Object -Sum).Sum
    $types = @(
        @{ name = "Features"; key = "FEATURE"; icon = "✨" },
        @{ name = "Bug Fixes"; key = "BUGFIX"; icon = "🐛" },
        @{ name = "Refactoring"; key = "REFACTOR"; icon = "♻️" },
        @{ name = "Documentation"; key = "DOCS"; icon = "📝" },
        @{ name = "Testing"; key = "TEST"; icon = "🧪" },
        @{ name = "Other"; key = "OTHER"; icon = "📦" }
    )
    
    foreach ($type in $types) {
        $count = $stats.typeCommits[$type.key]
        $percent = if ($totalTyped -gt 0) { 
            [Math]::Round(($count / $totalTyped) * 100) 
        } else { 0 }
        $report += "| $($type.icon) $($type.name) | $count | $percent% |`n"
    }
    
    $report += @"

---

## Key Highlights

### Productivity
- **Average Commits per Month**: $avgMonthly
- **Average Commits per Active Day**: $avgDaily
- **Most Active Month**: $($stats.busiestMonth)

### Code Quality
- **Total Lines Added**: +$($stats.totalInsertions)
- **Total Lines Removed**: -$($stats.totalDeletions)
- **Net Code Growth**: +$($stats.totalInsertions - $stats.totalDeletions) lines

### Focus Areas
- **Top Project**: $($stats.topProject) ($($stats.projectCommits[$stats.topProject]) commits)
- **Number of Projects**: $($stats.projectCommits.Count)

---

## Year in Review

### What Went Well
- [ ] Add your achievements and highlights

### Areas for Improvement
- [ ] Add lessons learned

### Goals for Next Year
- [ ] Set your objectives

---

*Report generated by AI Work Archiver*
"@
    
    return $report
}

# Main logic
Write-Host "Annual Report Generator" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "Generating report for $year..." -ForegroundColor Yellow

$stats = Get-YearlyGitStats $Year $ProjectPaths
$report = Generate-AnnualReport $Year $stats

$reportFile = Join-Path $OutputPath "$year-annual-report.md"
$report | Out-File $reportFile -Encoding UTF8

Write-Host "`nAnnual report generated: $reportFile" -ForegroundColor Green
Write-Host "Total commits: $($stats.totalCommits)" -ForegroundColor White
Write-Host "Active days: $($stats.activeDays)" -ForegroundColor White
Write-Host "Top project: $($stats.topProject)" -ForegroundColor White
