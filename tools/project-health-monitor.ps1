# Project Health Monitor

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\project-health"),
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $OutputDir "health-report.json"
}

function Calculate-Health {
    param(
        [string]$ActivitiesDir,
        [string]$QualityDir
    )

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return @{} }
    
    $projectStats = @{}
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        
        foreach ($commit in $data.commits) {
            $project = $commit.project
            
            if (-not $projectStats.ContainsKey($project)) {
                $projectStats[$project] = @{
                    totalCommits = 0
                    firstCommit = $date
                    lastCommit = $date
                    commitsLast7Days = 0
                    commitsLast30Days = 0
                    fixCount = 0
                    featCount = 0
                    refactorCount = 0
                    avgQuality = 0
                    qualityCount = 0
                    activeMonths = @{}
                }
            }
            
            $stats = $projectStats[$project]
            $stats.totalCommits++
            
            if ($date -gt $stats.lastCommit) { $stats.lastCommit = $date }
            if ($date -lt $stats.firstCommit) { $stats.firstCommit = $date }
            
            $commitDate = [DateTime]::Parse($date)
            $daysAgo = ((Get-Date) - $commitDate).Days
            
            if ($daysAgo -le 7) { $stats.commitsLast7Days++ }
            if ($daysAgo -le 30) { $stats.commitsLast30Days++ }
            
            if ($commit.type -eq "FIX") { $stats.fixCount++ }
            if ($commit.type -eq "FEATURE") { $stats.featCount++ }
            if ($commit.type -eq "REFACTOR") { $stats.refactorCount++ }
            
            $month = $date.Substring(0, 7)
            $stats.activeMonths[$month] = $true
        }
    }
    
    # Load quality data if available
    $scoresFile = Join-Path $QualityDir "commit-scores.json"
    if (Test-Path $scoresFile) {
        $scores = Get-Content $scoresFile | ConvertFrom-Json
        foreach ($score in $scores) {
            $project = $score.project
            if ($projectStats.ContainsKey($project)) {
                $projectStats[$project].avgQuality += $score.score
                $projectStats[$project].qualityCount++
            }
        }
    }
    
    # Calculate health scores
    $healthReports = @()
    
    foreach ($project in $projectStats.Keys) {
        $stats = $projectStats[$project]
        
        # Health score calculation (0-100)
        $healthScore = 50
        
        # Activity (0-30)
        if ($stats.commitsLast7Days -gt 0) { $healthScore += 30 }
        elseif ($stats.commitsLast30Days -gt 5) { $healthScore += 20 }
        elseif ($stats.commitsLast30Days -gt 0) { $healthScore += 10 }
        
        # Quality (0-30)
        if ($stats.qualityCount -gt 0) {
            $avgQ = $stats.avgQuality / $stats.qualityCount
            if ($avgQ -ge 80) { $healthScore += 30 }
            elseif ($avgQ -ge 70) { $healthScore += 20 }
            elseif ($avgQ -ge 60) { $healthScore += 10 }
        }
        
        # Consistency (0-20)
        $monthCount = $stats.activeMonths.Keys.Count
        if ($monthCount -ge 3) { $healthScore += 20 }
        elseif ($monthCount -ge 2) { $healthScore += 15 }
        elseif ($monthCount -ge 1) { $healthScore += 10 }
        
        # Balance (0-20)
        $total = $stats.totalCommits
        if ($total -gt 0) {
            $fixRatio = $stats.fixCount / $total
            if ($fixRatio -ge 0.2 -and $fixRatio -le 0.5) { $healthScore += 20 }
            elseif ($fixRatio -ge 0.1 -and $fixRatio -le 0.7) { $healthScore += 10 }
        }
        
        $healthScore = [Math]::Min(100, [Math]::Max(0, $healthScore))
        
        # Health status
        $status = "Critical"
        if ($healthScore -ge 80) { $status = "Healthy" }
        elseif ($healthScore -ge 60) { $status = "Moderate" }
        elseif ($healthScore -ge 40) { $status = "At Risk" }
        
        # Alerts
        $alerts = @()
        if ($stats.commitsLast30Days -eq 0) {
            $alerts += "No commits in last 30 days"
        }
        if ($stats.qualityCount -gt 0) {
            $avgQ = $stats.avgQuality / $stats.qualityCount
            if ($avgQ -lt 60) {
                $alerts += "Low commit quality (avg: $([Math]::Round($avgQ, 1)))"
            }
        }
        
        $avgQuality = if ($stats.qualityCount -gt 0) { [Math]::Round($stats.avgQuality / $stats.qualityCount, 1) } else { 0 }
        
        $healthReports += [ordered]@{
            project = $project
            healthScore = $healthScore
            status = $status
            alerts = $alerts
            metrics = [ordered]@{
                totalCommits = $stats.totalCommits
                commitsLast7Days = $stats.commitsLast7Days
                commitsLast30Days = $stats.commitsLast30Days
                avgQuality = $avgQuality
                activeMonths = $monthCount
                firstCommit = $stats.firstCommit
                lastCommit = $stats.lastCommit
            }
        }
    }
    
    $healthReports = $healthReports | Sort-Object healthScore -Descending
    
    return [ordered]@{
        projects = $healthReports
        summary = [ordered]@{
            totalProjects = $healthReports.Count
            healthyCount = ($healthReports | Where-Object { $_.status -eq "Healthy" }).Count
            moderateCount = ($healthReports | Where-Object { $_.status -eq "Moderate" }).Count
            atRiskCount = ($healthReports | Where-Object { $_.status -eq "At Risk" }).Count
            criticalCount = ($healthReports | Where-Object { $_.status -eq "Critical" }).Count
        }
    }
}

function Generate-HealthReport {
    param(
        [hashtable]$Health,
        [string]$OutputFile
    )
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        summary = $Health.summary
        projects = $Health.projects
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Health Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Analyzing project health..." -ForegroundColor Yellow
$health = Calculate-Health -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir

Write-Host "Generating report..." -ForegroundColor Yellow
$report = Generate-HealthReport -Health $health -OutputFile $OutputFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Health Report Generated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total projects: $($report.summary.totalProjects)" -ForegroundColor White
Write-Host "  Healthy: $($report.summary.healthyCount)" -ForegroundColor Green
Write-Host "  Moderate: $($report.summary.moderateCount)" -ForegroundColor Yellow
Write-Host "  At Risk: $($report.summary.atRiskCount)" -ForegroundColor Red
Write-Host "  Critical: $($report.summary.criticalCount)" -ForegroundColor Red
Write-Host ""
Write-Host "Project Health:" -ForegroundColor Cyan
$report.projects | Select-Object -First 10 | ForEach-Object {
    $color = if ($_.status -eq "Healthy") { "Green" } elseif ($_.status -eq "Moderate") { "Yellow" } else { "Red" }
    Write-Host "  [$($_.status)] $($_.project) - Score: $($_.healthScore)" -ForegroundColor $color
    if ($_.alerts.Count -gt 0) {
        foreach ($alert in $_.alerts) {
            Write-Host "    Alert: $alert" -ForegroundColor Yellow
        }
    }
}
Write-Host ""
Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
