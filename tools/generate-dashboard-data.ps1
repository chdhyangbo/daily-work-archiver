# Dashboard Data Generator
# Reads from git-activities directory

param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\docs-server\public\dashboard-data.json"),
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities")
)

function Get-GitStats($activitiesDir) {
    $stats = @{
        totalCommits = 0
        dailyCommits = @{}
        hourlyCommits = @{}
        projectCommits = @{}
        typeCommits = @{
            FEATURE = 0
            FIX = 0
            REFACTOR = 0
            DOCS = 0
            TEST = 0
            OTHER = 0
        }
        recentCommits = @()
    }
    
    for ($h = 0; $h -lt 24; $h++) {
        $stats.hourlyCommits[$h.ToString()] = 0
    }
    
    if (-not (Test-Path $activitiesDir)) {
        Write-Host "Warning: git-activities directory not found" -ForegroundColor Yellow
        return $stats
    }
    
    $activityFiles = Get-ChildItem -Path $activitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    
    if ($activityFiles.Count -eq 0) {
        Write-Host "Warning: No activity data files found" -ForegroundColor Yellow
        return $stats
    }
    
    Write-Host "Reading $($activityFiles.Count) activity files..." -ForegroundColor Gray
    
    $allCommits = @()
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        
        if (-not $stats.dailyCommits[$data.date]) {
            $stats.dailyCommits[$data.date] = 0
        }
        $stats.dailyCommits[$data.date] += $data.totalCommits
        
        $stats.typeCommits.FEATURE += $data.types.FEATURE
        $stats.typeCommits.FIX += $data.types.FIX
        $stats.typeCommits.REFACTOR += $data.types.REFACTOR
        $stats.typeCommits.DOCS += $data.types.DOCS
        $stats.typeCommits.TEST += $data.types.TEST
        $stats.typeCommits.OTHER += $data.types.OTHER
        
        foreach ($commit in $data.commits) {
            $stats.totalCommits++
            
            $stats.hourlyCommits[$commit.hour.ToString()]++
            
            if (-not $stats.projectCommits[$commit.project]) {
                $stats.projectCommits[$commit.project] = 0
            }
            $stats.projectCommits[$commit.project]++
            
            $allCommits += @{
                hash = $commit.shortHash
                date = $commit.date
                dateTime = $commit.dateTime
                message = if ($commit.message.Length -gt 50) { $commit.message.Substring(0, 50) + "..." } else { $commit.message }
                project = $commit.project
            }
        }
    }
    
    if ($allCommits.Count -gt 0) {
        $sorted = $allCommits | Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending
        $stats.recentCommits = @($sorted | Select-Object -First 20 | ForEach-Object {
            @{
                hash = $_.hash
                date = $_.date
                message = $_.message
                project = $_.project
            }
        })
    }
    
    return $stats
}

function Get-AchievementData() {
    $achievementFile = Join-Path $PSScriptRoot "..\work-archive\data\achievements\achievements.json"
    
    if (Test-Path $achievementFile) {
        $data = Get-Content $achievementFile | ConvertFrom-Json
        return @{
            level = $data.level.current.name
            points = $data.achievements.totalPoints
            unlocked = $data.achievements.unlocked.Count
            total = 16
        }
    }
    
    return @{
        level = "Beginner"
        points = 0
        unlocked = 0
        total = 16
    }
}

function Get-TimeData() {
    $dataDir = Join-Path $PSScriptRoot "..\work-archive\data\time-tracking"
    $today = Get-Date -Format "yyyy-MM-dd"
    $weekStart = (Get-Date).AddDays(-([int](Get-Date).DayOfWeek + 6) % 7).ToString("yyyy-MM-dd")
    
    $todayMinutes = 0
    $weekMinutes = 0
    
    $todayFile = Join-Path $dataDir "$today.json"
    if (Test-Path $todayFile) {
        $data = Get-Content $todayFile | ConvertFrom-Json
        foreach ($session in $data.sessions) {
            $todayMinutes += $session.duration
        }
    }
    
    for ($i = 0; $i -lt 7; $i++) {
        $date = ([DateTime]::Parse($weekStart)).AddDays($i).ToString("yyyy-MM-dd")
        $file = Join-Path $dataDir "$date.json"
        if (Test-Path $file) {
            $data = Get-Content $file | ConvertFrom-Json
            foreach ($session in $data.sessions) {
                $weekMinutes += $session.duration
            }
        }
    }
    
    return @{
        today = [Math]::Round($todayMinutes / 60, 1)
        week = [Math]::Round($weekMinutes / 60, 1)
    }
}

function Get-ContributionData($dailyCommits) {
    $contributions = @()
    $today = Get-Date
    $startOfYear = Get-Date -Year $today.Year -Month 1 -Day 1
    
    for ($d = 0; $d -lt ($today - $startOfYear).Days + 1; $d++) {
        $date = $startOfYear.AddDays($d).ToString("yyyy-MM-dd")
        $count = if ($dailyCommits[$date]) { $dailyCommits[$date] } else { 0 }
        
        $contributions += @{
            date = $date
            count = $count
        }
    }
    
    return $contributions
}

function Generate-DashboardData($gitStats) {
    $achievementData = Get-AchievementData
    $timeData = Get-TimeData
    
    $sortedDates = $gitStats.dailyCommits.Keys | Sort-Object
    $maxStreak = 0
    $currentStreak = 0
    $lastDate = $null
    
    foreach ($date in $sortedDates) {
        if ($lastDate) {
            $current = [DateTime]::Parse($date)
            $last = [DateTime]::Parse($lastDate)
            if (($current - $last).Days -eq 1) {
                $currentStreak++
            } else {
                $currentStreak = 1
            }
        } else {
            $currentStreak = 1
        }
        
        if ($currentStreak -gt $maxStreak) {
            $maxStreak = $currentStreak
        }
        $lastDate = $date
    }
    
    $today = Get-Date -Format "yyyy-MM-dd"
    $todayCommits = if ($gitStats.dailyCommits[$today]) { $gitStats.dailyCommits[$today] } else { 0 }
    
    $weekStart = (Get-Date).AddDays(-([int](Get-Date).DayOfWeek + 6) % 7).ToString("yyyy-MM-dd")
    $weekCommits = 0
    for ($i = 0; $i -lt 7; $i++) {
        $date = ([DateTime]::Parse($weekStart)).AddDays($i).ToString("yyyy-MM-dd")
        if ($gitStats.dailyCommits[$date]) {
            $weekCommits += $gitStats.dailyCommits[$date]
        }
    }
    
    return @{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        summary = @{
            totalCommits = $gitStats.totalCommits
            todayCommits = $todayCommits
            weekCommits = $weekCommits
            currentStreak = $maxStreak
            maxStreak = $maxStreak
            todayHours = $timeData.today
            weekHours = $timeData.week
        }
        level = @{
            name = $achievementData.level
            points = $achievementData.points
            achievements = @{
                unlocked = $achievementData.unlocked
                total = $achievementData.total
            }
        }
        hourlyDistribution = $gitStats.hourlyCommits
        projectDistribution = $gitStats.projectCommits
        typeDistribution = $gitStats.typeCommits
        recentCommits = $gitStats.recentCommits
        contributions = Get-ContributionData $gitStats.dailyCommits
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dashboard Data Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/2] Reading git-activities data..." -ForegroundColor Yellow
$gitStats = Get-GitStats $ActivitiesDir

Write-Host "[2/2] Generating dashboard data..." -ForegroundColor Yellow
$dashboardData = Generate-DashboardData $gitStats

$dir = Split-Path $OutputPath -Parent
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$dashboardData | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "Dashboard data saved: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total commits: $($dashboardData.summary.totalCommits)" -ForegroundColor White
Write-Host "  Today commits: $($dashboardData.summary.todayCommits)" -ForegroundColor White
Write-Host "  Streak: $($dashboardData.summary.currentStreak)" -ForegroundColor White
Write-Host "  Level: $($dashboardData.level.name)" -ForegroundColor White
Write-Host "  Points: $($dashboardData.level.points)" -ForegroundColor White
