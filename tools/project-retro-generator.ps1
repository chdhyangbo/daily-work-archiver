# Project Retrospective Generator

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\retrospectives"),
    [string]$ProjectName = "",
    [string]$StartDate = "",
    [string]$EndDate = "",
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Generate-Retrospective {
    param(
        [string]$ActivitiesDir,
        [string]$QualityDir,
        [string]$ProjectName,
        [string]$StartDate,
        [string]$EndDate
    )

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return @{} }
    
    $commits = @()
    $projectCommits = @()
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        
        if ($StartDate -and $date -lt $StartDate) { continue }
        if ($EndDate -and $date -gt $EndDate) { continue }
        
        foreach ($commit in $data.commits) {
            $commits += $commit
            
            if ($ProjectName -eq "" -or $commit.project -eq $ProjectName) {
                $projectCommits += $commit
            }
        }
    }
    
    if ($projectCommits.Count -eq 0) { return @{} }
    
    # Project timeline
    $sortedCommits = $projectCommits | Sort-Object dateTime
    $firstCommit = $sortedCommits[0].date
    $lastCommit = $sortedCommits[-1].date
    $duration = ([DateTime]::Parse($lastCommit) - [DateTime]::Parse($firstCommit)).Days
    
    # Statistics
    $totalCommits = $projectCommits.Count
    $totalChanged = ($projectCommits | Measure-Object changed -Sum).Sum
    $avgChanged = [Math]::Round($totalChanged / $totalCommits, 0)
    
    # Commit type distribution
    $typeDist = @{}
    foreach ($commit in $projectCommits) {
        $type = $commit.type
        if (-not $typeDist.ContainsKey($type)) { $typeDist[$type] = 0 }
        $typeDist[$type]++
    }
    
    # Project distribution (if no specific project)
    $projectDist = @{}
    if ($ProjectName -eq "") {
        foreach ($commit in $projectCommits) {
            $project = $commit.project
            if (-not $projectDist.ContainsKey($project)) { $projectDist[$project] = 0 }
            $projectDist[$project]++
        }
    }
    
    # Key achievements
    $achievements = @()
    
    if ($totalCommits -ge 10) {
        $achievements += "Completed $totalCommits commits"
    }
    if ($totalChanged -ge 1000) {
        $achievements += "Modified $totalChanged lines of code"
    }
    
    $topType = $typeDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    if ($topType) {
        $achievements += "Main focus: $($topType.Key) ($($topType.Value) commits)"
    }
    
    # Challenges
    $challenges = @()
    
    if ($avgChanged -gt 500) {
        $challenges += "Large average commit size ($avgChanged lines)"
    }
    
    $fixCount = if ($typeDist.ContainsKey("FIX")) { $typeDist["FIX"] } else { 0 }
    $fixRatio = $fixCount / $totalCommits
    if ($fixRatio -gt 0.5) {
        $challenges += "High bug fix ratio ($([Math]::Round($fixRatio * 100, 1))%)"
    }
    
    # Quality metrics
    $avgQuality = 0
    $scoresFile = Join-Path $QualityDir "commit-scores.json"
    if (Test-Path $scoresFile) {
        $scores = Get-Content $scoresFile | ConvertFrom-Json
        $projectScores = $scores | Where-Object { $_.project -eq $ProjectName -or $ProjectName -eq "" }
        if ($projectScores.Count -gt 0) {
            $avgQuality = [Math]::Round(($projectScores | Measure-Object score -Average).Average, 1)
        }
    }
    
    # Lessons learned
    $lessons = @()
    
    if ($duration -gt 30) {
        $lessons += "Long-term project consistency is important"
    }
    if ($typeDist.ContainsKey("REFACTOR") -and $typeDist["REFACTOR"] -gt 5) {
        $lessons += "Regular refactoring improves code quality"
    }
    
    # Recommendations
    $recommendations = @()
    
    if ($avgQuality -lt 70 -and $avgQuality -gt 0) {
        $recommendations += "Focus on improving commit message quality"
    }
    if ($fixRatio -gt 0.4) {
        $recommendations += "Consider adding more tests to prevent bugs"
    }
    
    return [ordered]@{
        project = if ($ProjectName) { $ProjectName } else { "All Projects" }
        period = [ordered]@{
            start = $firstCommit
            end = $lastCommit
            durationDays = $duration
        }
        statistics = [ordered]@{
            totalCommits = $totalCommits
            totalChanged = $totalChanged
            avgChanged = $avgChanged
            commitTypes = $typeDist
            projectDistribution = $projectDist
            avgQuality = $avgQuality
        }
        achievements = $achievements
        challenges = $challenges
        lessonsLearned = $lessons
        recommendations = $recommendations
    }
}

function Generate-RetroReport {
    param(
        [hashtable]$Retro,
        [string]$OutputFile
    )
    
    if ($Retro.Count -eq 0) {
        Write-Host "No data found for the specified criteria" -ForegroundColor Yellow
        return $null
    }
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        retrospective = $Retro
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Retrospective Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $OutputFile) {
    $projectPart = if ($ProjectName) { $ProjectName } else { "all" }
    $datePart = Get-Date -Format "yyyy-MM-dd"
    $OutputFile = Join-Path $OutputDir "retro-$projectPart-$datePart.json"
}

Write-Host "Generating retrospective..." -ForegroundColor Yellow
$retro = Generate-Retrospective -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir -ProjectName $ProjectName -StartDate $StartDate -EndDate $EndDate

Write-Host "Saving report..." -ForegroundColor Yellow
$report = Generate-RetroReport -Retro $retro -OutputFile $OutputFile

if ($null -ne $report) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Retrospective Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Project: $($retro.project)" -ForegroundColor Cyan
    Write-Host "Period: $($retro.period.start) to $($retro.period.end) ($($retro.period.durationDays) days)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Statistics:" -ForegroundColor Cyan
    Write-Host "  Total commits: $($retro.statistics.totalCommits)" -ForegroundColor White
    Write-Host "  Total changes: $($retro.statistics.totalChanged) lines" -ForegroundColor White
    Write-Host "  Average quality: $($retro.statistics.avgQuality)/100" -ForegroundColor White
    Write-Host ""
    Write-Host "Achievements:" -ForegroundColor Green
    foreach ($a in $retro.achievements) {
        Write-Host "  ✓ $a" -ForegroundColor White
    }
    Write-Host ""
    if ($retro.challenges.Count -gt 0) {
        Write-Host "Challenges:" -ForegroundColor Yellow
        foreach ($c in $retro.challenges) {
            Write-Host "  ⚠ $c" -ForegroundColor White
        }
        Write-Host ""
    }
    Write-Host "Recommendations:" -ForegroundColor Cyan
    foreach ($r in $retro.recommendations) {
        Write-Host "  → $r" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
}
