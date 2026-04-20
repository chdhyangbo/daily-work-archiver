# Growth Tracker - Track skill evolution and milestones

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\growth"),
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $OutputDir "growth-report.json"
}

function Track-Growth {
    param(
        [string]$ActivitiesDir
    )

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return @{} }
    
    $techStack = @{}
    $milestones = @()
    $monthlyStats = @{}
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        $month = $date.Substring(0, 7)
        
        if (-not $monthlyStats.ContainsKey($month)) {
            $monthlyStats[$month] = @{ commits = 0; projects = @{}; types = @{} }
        }
        $monthlyStats[$month].commits += $data.totalCommits
        
        foreach ($commit in $data.commits) {
            $project = $commit.project
            $type = $commit.type
            
            if (-not $monthlyStats[$month].projects.ContainsKey($project)) {
                $monthlyStats[$month].projects[$project] = 0
            }
            $monthlyStats[$month].projects[$project]++
            
            if (-not $monthlyStats[$month].types.ContainsKey($type)) {
                $monthlyStats[$month].types[$type] = 0
            }
            $monthlyStats[$month].types[$type]++
            
            if (-not $techStack.ContainsKey($project)) {
                $techStack[$project] = @{
                    firstSeen = $date
                    lastSeen = $date
                    totalCommits = 0
                }
            }
            $techStack[$project].totalCommits++
            if ($date -gt $techStack[$project].lastSeen) {
                $techStack[$project].lastSeen = $date
            }
        }
    }
    
    # Identify milestones
    $totalCommits = 0
    $sortedMonths = $monthlyStats.Keys | Sort-Object
    
    foreach ($month in $sortedMonths) {
        $totalCommits += $monthlyStats[$month].commits
        
        if ($totalCommits -ge 10 -and -not ($milestones | Where-Object { $_.type -eq "10-commits" })) {
            $milestones += [ordered]@{
                type = "10-commits"
                title = "First 10 commits"
                date = $month
                description = "Completed 10 commits"
            }
        }
        
        if ($totalCommits -ge 100 -and -not ($milestones | Where-Object { $_.type -eq "100-commits" })) {
            $milestones += [ordered]@{
                type = "100-commits"
                title = "100 commits milestone"
                date = $month
                description = "Reached 100 total commits"
            }
        }
        
        if ($totalCommits -ge 500 -and -not ($milestones | Where-Object { $_.type -eq "500-commits" })) {
            $milestones += [ordered]@{
                type = "500-commits"
                title = "500 commits milestone"
                date = $month
                description = "Reached 500 total commits"
            }
        }
    }
    
    # Build tech stack timeline
    $techTimeline = @()
    foreach ($project in $techStack.Keys) {
        $techTimeline += [ordered]@{
            project = $project
            firstCommit = $techStack[$project].firstSeen
            lastCommit = $techStack[$project].lastSeen
            totalCommits = $techStack[$project].totalCommits
        }
    }
    $techTimeline = $techTimeline | Sort-Object firstCommit
    
    # Monthly trend
    $monthlyTrend = @()
    foreach ($month in $sortedMonths) {
        $stats = $monthlyStats[$month]
        $monthlyTrend += [ordered]@{
            month = $month
            commits = $stats.commits
            projects = $stats.projects.Keys.Count
            topProject = ($stats.projects.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
        }
    }
    
    return @{
        techTimeline = $techTimeline
        monthlyTrend = $monthlyTrend
        milestones = $milestones
        totalProjects = $techStack.Keys.Count
        totalCommits = $totalCommits
    }
}

function Generate-GrowthReport {
    param(
        [hashtable]$Growth,
        [string]$OutputFile
    )
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        summary = [ordered]@{
            totalProjects = $Growth.totalProjects
            totalCommits = $Growth.totalCommits
            milestonesReached = $Growth.milestones.Count
        }
        techTimeline = $Growth.techTimeline
        monthlyTrend = $Growth.monthlyTrend
        milestones = $Growth.milestones
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Growth Tracker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Tracking growth..." -ForegroundColor Yellow
$growth = Track-Growth -ActivitiesDir $ActivitiesDir

Write-Host "Generating report..." -ForegroundColor Yellow
$report = Generate-GrowthReport -Growth $growth -OutputFile $OutputFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Growth Report Generated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total projects: $($report.summary.totalProjects)" -ForegroundColor White
Write-Host "  Total commits: $($report.summary.totalCommits)" -ForegroundColor White
Write-Host "  Milestones: $($report.summary.milestonesReached)" -ForegroundColor White
Write-Host ""
Write-Host "Milestones:" -ForegroundColor Cyan
foreach ($ms in $report.milestones) {
    Write-Host "  ✓ $($ms.title) - $($ms.date)" -ForegroundColor Green
}
Write-Host ""
Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
