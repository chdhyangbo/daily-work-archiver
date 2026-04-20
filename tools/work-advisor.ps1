# Smart Work Advisor
# 基于历史数据生成个性化工作建议

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\work-advice"),
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $OutputDir "work-advice-$(Get-Date -Format 'yyyy-MM-dd').json"
}

function Analyze-WorkPattern {
    param(
        [string]$ActivitiesDir,
        [string]$QualityDir
    )

    $advice = @()
    
    # Load activity data
    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return $advice }
    
    $allCommits = @()
    $hourlyDist = @{}
    $dailyDist = @{}
    
    for ($h = 0; $h -lt 24; $h++) {
        $hourlyDist[$h] = 0
    }
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date
        
        if (-not $dailyDist.ContainsKey($date)) {
            $dailyDist[$date] = 0
        }
        $dailyDist[$date] += $data.totalCommits
        
        foreach ($commit in $data.commits) {
            $allCommits += $commit
            $hour = $commit.hour
            $hourlyDist[$hour]++
        }
    }
    
    # Analysis 1: Best coding hours
    $peakHours = $hourlyDist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3
    $bestHour = $peakHours[0].Key
    $bestHourCount = $peakHours[0].Value
    
    $advice += [ordered]@{
        category = "Time Optimization"
        priority = "High"
        title = "Best Coding Hours"
        description = "Your most productive hour is $bestHour:00 with $bestHourCount commits"
        suggestion = "Schedule important tasks during $bestHour:00-$($bestHour+2):00 for maximum productivity"
        metric = "Peak productivity at hour $bestHour"
    }
    
    # Analysis 2: Work consistency
    $sortedDates = $dailyDist.Keys | Sort-Object
    $gaps = @()
    $lastDate = $null
    
    foreach ($date in $sortedDates) {
        if ($lastDate) {
            $current = [DateTime]::Parse($date)
            $last = [DateTime]::Parse($lastDate)
            $gap = ($current - $last).Days - 1
            
            if ($gap -gt 2) {
                $gaps += $gap
            }
        }
        $lastDate = $date
    }
    
    if ($gaps.Count -gt 0) {
        $avgGap = ($gaps | Measure-Object -Average).Average
        $advice += [ordered]@{
            category = "Consistency"
            priority = "Medium"
            title = "Irregular Work Pattern"
            description = "Found $($gaps.Count) gaps of 3+ days between commits (avg: $([Math]::Round($avgGap, 1)) days)"
            suggestion = "Try to commit at least once every 2 days to maintain momentum"
            metric = "$($gaps.Count) long gaps detected"
        }
    } else {
        $advice += [ordered]@{
            category = "Consistency"
            priority = "Low"
            title = "Excellent Consistency"
            description = "Your commit pattern is very regular"
            suggestion = "Keep up the good work! Consider mentoring others on consistency"
            metric = "No significant gaps"
        }
    }
    
    # Analysis 3: Quality trend
    $trendFile = Join-Path $QualityDir "quality-trend.json"
    if (Test-Path $trendFile) {
        $trend = Get-Content $trendFile | ConvertFrom-Json
        $recent7 = $trend | Where-Object { 
            $date = [DateTime]::Parse($_.date)
            $daysAgo = ((Get-Date) - $date).Days
            $daysAgo -le 7
        }
        
        $older7 = $trend | Where-Object {
            $date = [DateTime]::Parse($_.date)
            $daysAgo = ((Get-Date) - $date).Days
            $daysAgo -gt 7 -and $daysAgo -le 14
        }
        
        if ($recent7.Count -gt 0 -and $older7.Count -gt 0) {
            $recentAvg = ($recent7 | Measure-Object avgScore -Average).Average
            $olderAvg = ($older7 | Measure-Object avgScore -Average).Average
            $diff = $recentAvg - $olderAvg
            
            if ($diff -lt -5) {
                $advice += [ordered]@{
                    category = "Quality"
                    priority = "High"
                    title = "Quality Declining"
                    description = "Commit quality dropped from $([Math]::Round($olderAvg, 1)) to $([Math]::Round($recentAvg, 1)) in the last week"
                    suggestion = "Review your recent commits. Focus on writing better commit messages and smaller, focused changes"
                    metric = "Quality drop: $([Math]::Round($diff, 1)) points"
                }
            } elseif ($diff -gt 5) {
                $advice += [ordered]@{
                    category = "Quality"
                    priority = "Low"
                    title = "Quality Improving"
                    description = "Commit quality improved from $([Math]::Round($olderAvg, 1)) to $([Math]::Round($recentAvg, 1))"
                    suggestion = "Great progress! Continue following good practices"
                    metric = "Quality improvement: +$([Math]::Round($diff, 1)) points"
                }
            }
        }
    }
    
    # Analysis 4: Project focus
    $projectCounts = @{}
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        foreach ($commit in $data.commits) {
            $project = $commit.project
            if (-not $projectCounts.ContainsKey($project)) {
                $projectCounts[$project] = 0
            }
            $projectCounts[$project]++
        }
    }
    
    if ($projectCounts.Count -gt 3) {
        $topProjects = $projectCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3
        $totalCommits = ($projectCounts.Values | Measure-Object -Sum).Sum
        $topPercent = [Math]::Round(($topProjects.Value | Measure-Object -Sum).Sum / $totalCommits * 100, 1)
        
        $advice += [ordered]@{
            category = "Focus"
            priority = "Medium"
            title = "Multiple Project Context"
            description = "You are working on $($projectCounts.Count) projects. Top 3 account for $topPercent of commits"
            suggestion = "Consider time-blocking: dedicate specific days to specific projects to reduce context switching"
            metric = "$($projectCounts.Count) active projects"
        }
    }
    
    # Analysis 5: Work-life balance
    $nightCommits = 0
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        foreach ($commit in $data.commits) {
            $hour = $commit.hour
            if ($hour -ge 22 -or $hour -lt 6) {
                $nightCommits++
            }
        }
    }
    
    $totalCommits = $allCommits.Count
    $nightPercent = [Math]::Round($nightCommits / $totalCommits * 100, 1)
    
    if ($nightPercent -gt 20) {
        $advice += [ordered]@{
            category = "Health"
            priority = "High"
            title = "Late Night Work Pattern"
            description = "$nightPercent of commits are made between 22:00-06:00"
            suggestion = "Try to finish work before 22:00. Late night coding reduces code quality and health"
            metric = "$nightCommits late night commits ($nightPercent)"
        }
    }
    
    return $advice
}

function Generate-AdviceReport {
    param(
        [array]$Advice,
        [string]$OutputFile
    )
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        totalAdvice = $Advice.Count
        highPriority = ($Advice | Where-Object { $_.priority -eq "High" }).Count
        mediumPriority = ($Advice | Where-Object { $_.priority -eq "Medium" }).Count
        lowPriority = ($Advice | Where-Object { $_.priority -eq "Low" }).Count
        advice = $Advice
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Work Advisor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Analyzing work patterns..." -ForegroundColor Yellow
$advice = Analyze-WorkPattern -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir

Write-Host "Generating advice report..." -ForegroundColor Yellow
$report = Generate-AdviceReport -Advice $advice -OutputFile $OutputFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Analysis Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total advice: $($report.totalAdvice)" -ForegroundColor White
Write-Host "  High priority: $($report.highPriority)" -ForegroundColor Red
Write-Host "  Medium priority: $($report.mediumPriority)" -ForegroundColor Yellow
Write-Host "  Low priority: $($report.lowPriority)" -ForegroundColor Green
Write-Host ""
Write-Host "Top Recommendations:" -ForegroundColor Cyan

$highPriority = $advice | Where-Object { $_.priority -eq "High" }
if ($highPriority.Count -gt 0) {
    foreach ($item in $highPriority) {
        Write-Host "  [HIGH] $($item.title)" -ForegroundColor Red
        Write-Host "    $($item.suggestion)" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
