# Time Optimizer - Analyze time usage and provide schedule suggestions

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$TimeTrackerFile = (Join-Path $PSScriptRoot "..\work-archive\data\time-tracker.json"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\time-optimization"),
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $OutputDir "time-optimization.json"
}

function Analyze-TimeUsage {
    param(
        [string]$ActivitiesDir
    )

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return @{} }
    
    $hourlyCommits = @{}
    $dailyCommits = @{}
    $weeklyCommits = @{}
    
    for ($h = 0; $h -lt 24; $h++) { $hourlyCommits[$h] = 0 }
    for ($d = 0; $d -lt 7; $d++) { $weeklyCommits[$d] = 0 }
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = [DateTime]::Parse($data.date)
        $dayOfWeek = [int]$date.DayOfWeek
        $dailyCommits[$data.date] = $data.totalCommits
        $weeklyCommits[$dayOfWeek] += $data.totalCommits
        
        foreach ($commit in $data.commits) {
            $hour = $commit.hour
            $hourlyCommits[$hour]++
        }
    }
    
    # Find peak hours
    $peakHours = $hourlyCommits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5
    $bestHour = [int]$peakHours[0].Key
    
    # Find peak days
    $dayNames = "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    $peakDays = @()
    foreach ($entry in ($weeklyCommits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3)) {
        $peakDays += [ordered]@{
            day = $dayNames[[int]$entry.Key]
            commits = [int]$entry.Value
        }
    }
    
    # Efficiency score
    $totalCommits = ($hourlyCommits.Values | Measure-Object -Sum).Sum
    $workingHours = 0
    $productiveHours = 0
    
    for ($h = 8; $h -lt 18; $h++) {
        $workingHours += $hourlyCommits[$h]
    }
    $workHourPercent = [Math]::Round($workingHours / $totalCommits * 100, 1)
    
    # Recommendations
    $recommendations = @()
    
    $recommendations += [ordered]@{
        type = "Best Hours"
        suggestion = "Your best hour is $bestHour`:00. Schedule complex tasks then."
        priority = "High"
    }
    
    $recommendations += [ordered]@{
        type = "Best Days"
        suggestion = "Most productive on $($peakDays[0].day). Use for important work."
        priority = "High"
    }
    
    if ($workHourPercent -lt 60) {
        $recommendations += [ordered]@{
            type = "Work Hour Optimization"
            suggestion = "Only $workHourPercent of commits during 8-18. Try to work more during business hours."
            priority = "Medium"
        }
    } else {
        $recommendations += [ordered]@{
            type = "Work Hour Optimization"
            suggestion = "Good! $workHourPercent of commits during business hours."
            priority = "Low"
        }
    }
    
    # Generate next week schedule
    $schedule = @()
    for ($d = 0; $d -lt 7; $d++) {
        $schedule += [ordered]@{
            day = $dayNames[$d]
            focus = if ($weeklyCommits[$d] -gt ($totalCommits / 7)) { "High priority tasks" } else { "Maintenance tasks" }
            expectedCommits = [Math]::Round($weeklyCommits[$d] / ($activityFiles.Count / 7), 0)
        }
    }
    
    return [ordered]@{
        hourlyDistribution = $hourlyCommits
        weeklyDistribution = $weeklyCommits
        bestHour = $bestHour
        peakDays = $peakDays
        workHourPercent = $workHourPercent
        recommendations = $recommendations
        suggestedSchedule = $schedule
    }
}

function Generate-TimeReport {
    param(
        [hashtable]$Analysis,
        [string]$OutputFile
    )
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        analysis = $Analysis
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Time Optimizer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Analyzing time usage..." -ForegroundColor Yellow
$analysis = Analyze-TimeUsage -ActivitiesDir $ActivitiesDir

Write-Host "Generating report..." -ForegroundColor Yellow
$report = Generate-TimeReport -Analysis $analysis -OutputFile $OutputFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Time Optimization Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Key Insights:" -ForegroundColor Cyan
Write-Host "  Best hour: $($analysis.bestHour):00" -ForegroundColor White
Write-Host "  Work hours efficiency: $($analysis.workHourPercent)%" -ForegroundColor White
Write-Host ""
Write-Host "Top 3 productive days:" -ForegroundColor Cyan
foreach ($day in $analysis.peakDays) {
    Write-Host "  $($day.day): $($day.commits) commits" -ForegroundColor White
}
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
foreach ($rec in $analysis.recommendations) {
    Write-Host "  [$($rec.priority)] $($rec.type)" -ForegroundColor Yellow
    Write-Host "    $($rec.suggestion)" -ForegroundColor White
    Write-Host ""
}
Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
