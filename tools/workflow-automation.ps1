# Workflow Automation Engine - Simplified

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$QualityDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [string]$RulesFile = (Join-Path $PSScriptRoot "..\work-archive\data\automation-rules.json"),
    [string]$LogsDir = (Join-Path $PSScriptRoot "..\work-archive\logs"),
    [string]$Action = "check"
)

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

function Get-DefaultRules {
    return @(
        [ordered]@{
            id = "no-commit-3days"
            name = "No commit 3 days"
            enabled = $true
            type = "inactivity"
            condition = [ordered]@{ days = 3 }
            action = "notify"
            message = "You have not committed for 3 days"
        }
        [ordered]@{
            id = "no-commit-7days"
            name = "No commit 7 days"
            enabled = $true
            type = "inactivity"
            condition = [ordered]@{ days = 7 }
            action = "notify"
            message = "Warning: 7 days without commits"
        }
        [ordered]@{
            id = "milestone-50"
            name = "50 commits milestone"
            enabled = $true
            type = "milestone"
            condition = [ordered]@{ count = 50 }
            action = "celebrate"
            message = "Congratulations on 50 commits"
        }
        [ordered]@{
            id = "milestone-100"
            name = "100 commits milestone"
            enabled = $true
            type = "milestone"
            condition = [ordered]@{ count = 100 }
            action = "celebrate"
            message = "Amazing! 100 commits achieved"
        }
        [ordered]@{
            id = "late-night"
            name = "Late night commits"
            enabled = $true
            type = "time-pattern"
            condition = [ordered]@{ startHour = 23; endHour = 6 }
            action = "notify"
            message = "Late night commits detected, rest well"
        }
        [ordered]@{
            id = "friday-report"
            name = "Friday report"
            enabled = $false
            type = "schedule"
            condition = [ordered]@{ dayOfWeek = 5; hour = 17 }
            action = "generate-report"
            message = "Auto-generate weekly report"
        }
        [ordered]@{
            id = "quality-drop"
            name = "Quality drop alert"
            enabled = $true
            type = "quality"
            condition = [ordered]@{ avgScore = 70; window = 7 }
            action = "notify"
            message = "Commit quality has dropped"
        }
        [ordered]@{
            id = "streak-5"
            name = "5 day streak"
            enabled = $true
            type = "streak"
            condition = [ordered]@{ days = 5 }
            action = "celebrate"
            message = "Great! 5 day commit streak"
        }
        [ordered]@{
            id = "streak-10"
            name = "10 day streak"
            enabled = $true
            type = "streak"
            condition = [ordered]@{ days = 10 }
            action = "celebrate"
            message = "Excellent! 10 day commit streak"
        }
    )
}

function Load-Rules {
    param([string]$RulesFile)
    
    if (Test-Path $RulesFile) {
        $rules = Get-Content $RulesFile | ConvertFrom-Json
        Write-Host "Loaded $($rules.Count) rules" -ForegroundColor Green
        return $rules
    } else {
        Write-Host "Creating default rules..." -ForegroundColor Yellow
        $rules = Get-DefaultRules
        $rules | ConvertTo-Json -Depth 5 | Out-File $RulesFile -Encoding UTF8
        return $rules
    }
}

function Check-Inactivity {
    param([hashtable]$Condition, [string]$ActivitiesDir)
    
    $days = $Condition.days
    $cutoffDate = (Get-Date).AddDays(-$days).ToString("yyyy-MM-dd")
    $today = Get-Date -Format "yyyy-MM-dd"
    
    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    
    $latestDate = $null
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        if (-not $latestDate -or $data.date -gt $latestDate) {
            $latestDate = $data.date
        }
    }
    
    if ($latestDate) {
        $lastActivity = [DateTime]::Parse($latestDate)
        $daysSince = ([DateTime]::Parse($today) - $lastActivity).Days
        
        if ($daysSince -ge $days) {
            return @{ triggered = $true; message = "Last activity: $daysSince days ago" }
        }
    }
    
    return @{ triggered = $false }
}

function Check-Milestone {
    param([hashtable]$Condition, [string]$ActivitiesDir)
    
    $targetCount = $Condition.count
    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    
    $totalCommits = 0
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $totalCommits += $data.totalCommits
    }
    
    if ($totalCommits -ge $targetCount) {
        return @{ triggered = $true; message = "Total commits: $totalCommits" }
    }
    
    return @{ triggered = $false }
}

function Check-TimePattern {
    param([hashtable]$Condition, [string]$ActivitiesDir, [int]$DaysBack = 7)
    
    $startHour = $Condition.startHour
    $endHour = $Condition.endHour
    $cutoffDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-dd")
    
    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    
    $lateNightCommits = 0
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        if ($data.date -lt $cutoffDate) { continue }
        
        foreach ($commit in $data.commits) {
            $hour = $commit.hour
            if ($hour -ge $startHour -or $hour -lt $endHour) {
                $lateNightCommits++
            }
        }
    }
    
    if ($lateNightCommits -gt 0) {
        return @{ triggered = $true; message = "Found $lateNightCommits late night commits" }
    }
    
    return @{ triggered = $false }
}

function Check-Quality {
    param([hashtable]$Condition, [string]$QualityDir)
    
    $targetScore = $Condition.avgScore
    $window = $Condition.window
    $trendFile = Join-Path $QualityDir "quality-trend.json"
    
    if (-not (Test-Path $trendFile)) {
        return @{ triggered = $false }
    }
    
    $trend = Get-Content $trendFile | ConvertFrom-Json
    $cutoffDate = (Get-Date).AddDays(-$window).ToString("yyyy-MM-dd")
    $recentTrend = $trend | Where-Object { $_.date -ge $cutoffDate }
    
    if ($recentTrend.Count -gt 0) {
        $avgScore = ($recentTrend | Measure-Object avgScore -Average).Average
        
        if ($avgScore -lt $targetScore) {
            return @{ triggered = $true; message = "Quality dropped to $avgScore" }
        }
    }
    
    return @{ triggered = $false }
}

function Check-Streak {
    param([hashtable]$Condition, [string]$ActivitiesDir)
    
    $targetDays = $Condition.days
    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    $dates = @()
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $dates += $data.date
    }
    
    $sortedDates = $dates | Sort-Object
    $maxStreak = 0
    $currentStreak = 1
    $lastDate = $null
    
    foreach ($date in $sortedDates) {
        if ($lastDate) {
            $current = [DateTime]::Parse($date)
            $last = [DateTime]::Parse($lastDate)
            $diff = ($current - $last).Days
            
            if ($diff -eq 1) {
                $currentStreak++
            } else {
                $currentStreak = 1
            }
        }
        
        if ($currentStreak -gt $maxStreak) {
            $maxStreak = $currentStreak
        }
        $lastDate = $date
    }
    
    if ($maxStreak -ge $targetDays) {
        return @{ triggered = $true; message = "Current streak: $maxStreak days" }
    }
    
    return @{ triggered = $false }
}

function Check-AllRules {
    param([array]$Rules, [string]$ActivitiesDir, [string]$QualityDir)
    
    Write-Host "Checking $($Rules.Count) rules..." -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    
    foreach ($rule in $Rules) {
        if (-not $rule.enabled) {
            Write-Host "  SKIP: $($rule.name)" -ForegroundColor Gray
            continue
        }
        
        $checkResult = @{ triggered = $false }
        
        switch ($rule.type) {
            "inactivity" { $checkResult = Check-Inactivity -Condition $rule.condition -ActivitiesDir $ActivitiesDir }
            "milestone" { $checkResult = Check-Milestone -Condition $rule.condition -ActivitiesDir $ActivitiesDir }
            "time-pattern" { $checkResult = Check-TimePattern -Condition $rule.condition -ActivitiesDir $ActivitiesDir }
            "quality" { $checkResult = Check-Quality -Condition $rule.condition -QualityDir $QualityDir }
            "streak" { $checkResult = Check-Streak -Condition $rule.condition -ActivitiesDir $ActivitiesDir }
        }
        
        if ($checkResult.triggered) {
            Write-Host "  TRIGGER: $($rule.name)" -ForegroundColor Red
            Write-Host "    $($checkResult.message)" -ForegroundColor Yellow
            Write-Host "    $($rule.message)" -ForegroundColor Green
        } else {
            Write-Host "  OK: $($rule.name)" -ForegroundColor Green
        }
        Write-Host ""
        
        $results += @{
            rule = $rule.name
            triggered = $checkResult.triggered
            message = $checkResult.message
        }
    }
    
    return $results
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Workflow Automation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rules = Load-Rules -RulesFile $RulesFile

switch ($Action) {
    "check" {
        $results = Check-AllRules -Rules $rules -ActivitiesDir $ActivitiesDir -QualityDir $QualityDir
        
        $triggeredCount = ($results | Where-Object { $_.triggered -eq $true }).Count
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Complete: $triggeredCount triggered" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    }
    "list" {
        foreach ($rule in $rules) {
            $status = if ($rule.enabled) { "ON" } else { "OFF" }
            Write-Host "  [$status] $($rule.name) ($($rule.type))" -ForegroundColor White
        }
    }
}
