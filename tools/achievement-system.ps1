# Achievement & Badge System (ASCII Compatible Version)

param(
    [string]$Action = "check",
    [string]$OutputPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "work-archive") "data\achievements")
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$Achievements = @{
    FIRST_COMMIT = @{
        id = "FIRST_COMMIT"
        name = "Initial Commit"
        description = "First code commit"
        icon = "SEED"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 1 }
        points = 10
    }
    COMMIT_10 = @{
        id = "COMMIT_10"
        name = "Getting Started"
        description = "10 commits reached"
        icon = "SEEDLING"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 10 }
        points = 20
    }
    COMMIT_100 = @{
        id = "COMMIT_100"
        name = "Code Craftsman"
        description = "100 commits reached"
        icon = "TREE"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 100 }
        points = 50
    }
    COMMIT_1000 = @{
        id = "COMMIT_1000"
        name = "Code Master"
        description = "1000 commits reached"
        icon = "TROPHY"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 1000 }
        points = 200
    }
    STREAK_3 = @{
        id = "STREAK_3"
        name = "3-Day Streak"
        description = "3 consecutive days of commits"
        icon = "FIRE"
        category = "consistency"
        condition = { param($s) $s.maxStreak -ge 3 }
        points = 15
    }
    STREAK_7 = @{
        id = "STREAK_7"
        name = "Week Warrior"
        description = "7 consecutive days of commits"
        icon = "LIGHTNING"
        category = "consistency"
        condition = { param($s) $s.maxStreak -ge 7 }
        points = 30
    }
    MULTI_PROJECT = @{
        id = "MULTI_PROJECT"
        name = "Multi-tasker"
        description = "Contributed to 3+ projects"
        icon = "TARGET"
        category = "contribution"
        condition = { param($s) $s.projectCount -ge 3 }
        points = 30
    }
}

$Levels = @(
    @{ name = "Code Rookie"; minPoints = 0; icon = "BRONZE" }
    @{ name = "Junior Dev"; minPoints = 100; icon = "SILVER" }
    @{ name = "Mid Dev"; minPoints = 300; icon = "GOLD" }
    @{ name = "Senior Dev"; minPoints = 600; icon = "DIAMOND" }
    @{ name = "Expert"; minPoints = 1000; icon = "CROWN" }
    @{ name = "Legend"; minPoints = 2000; icon = "LEGEND" }
)

$IconMap = @{
    SEED = "U+1F331"
    SEEDLING = "U+1F33F"
    TREE = "U+1F333"
    TROPHY = "U+1F3C6"
    FIRE = "U+1F525"
    LIGHTNING = "U+26A1"
    TARGET = "U+1F3AF"
    BRONZE = "U+1F949"
    SILVER = "U+1F948"
    GOLD = "U+1F947"
    DIAMOND = "U+1F48E"
    CROWN = "U+1F451"
    LEGEND = "U+1F3C6"
}

function Convert-Icon($iconName) {
    $code = $IconMap[$iconName]
    if ($code -match "U\+([0-9A-F]+)") {
        return [char]"0x$($matches[1])"
    }
    return $iconName
}

function Get-GitStatistics($projectPaths) {
    $stats = @{
        totalCommits = 0
        projectCount = 0
        maxProjectCommits = 0
        maxStreak = 0
        maxDailyCommits = 0
        dailyCommits = @{}
    }
    
    $projectCommits = @{}
    
    foreach ($rootPath in $projectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            $commits = & git -c core.quotepath=false log --all --author="yangbo" --pretty=format:"%H|%ad" --date=format:"%Y-%m-%d" 2>$null
            
            if ($commits) {
                $commitList = $commits -split "`n" | Where-Object { $_ }
                
                if (-not $projectCommits[$projectName]) {
                    $projectCommits[$projectName] = 0
                }
                $projectCommits[$projectName] += $commitList.Count
                $stats.totalCommits += $commitList.Count
                
                foreach ($commit in $commitList) {
                    $date = $commit.Split('|')[1]
                    if (-not $stats.dailyCommits[$date]) {
                        $stats.dailyCommits[$date] = 0
                    }
                    $stats.dailyCommits[$date]++
                }
            }
        }
    }
    
    Set-Location $PSScriptRoot
    
    $stats.projectCount = $projectCommits.Count
    if ($projectCommits.Count -gt 0) {
        $stats.maxProjectCommits = ($projectCommits.Values | Measure-Object -Maximum).Maximum
    }
    
    $sortedDates = $stats.dailyCommits.Keys | Sort-Object
    $currentStreak = 0
    $maxStreak = 0
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
        } else {
            $currentStreak = 1
        }
        
        if ($currentStreak -gt $maxStreak) {
            $maxStreak = $currentStreak
        }
        $lastDate = $date
    }
    
    $stats.maxStreak = $maxStreak
    
    if ($stats.dailyCommits.Count -gt 0) {
        $stats.maxDailyCommits = ($stats.dailyCommits.Values | Measure-Object -Maximum).Maximum
    }
    
    return $stats
}

function Check-Achievements($stats) {
    $unlocked = @()
    $totalPoints = 0
    
    foreach ($achievement in $Achievements.Values) {
        $condition = $achievement.condition
        $result = & $condition $stats
        
        if ($result) {
            $unlocked += $achievement
            $totalPoints += $achievement.points
        }
    }
    
    return @{
        unlocked = $unlocked
        totalPoints = $totalPoints
        totalPossible = ($Achievements.Values | Measure-Object -Property points -Sum).Sum
    }
}

function Get-CurrentLevel($points) {
    $currentLevel = $Levels[0]
    
    foreach ($level in $Levels) {
        if ($points -ge $level.minPoints) {
            $currentLevel = $level
        }
    }
    
    $nextLevel = $null
    $progress = 100
    foreach ($level in $Levels) {
        if ($level.minPoints -gt $points) {
            $nextLevel = $level
            $prevLevel = $Levels[$Levels.IndexOf($level) - 1]
            $range = $level.minPoints - $prevLevel.minPoints
            $earned = $points - $prevLevel.minPoints
            $progress = [Math]::Round(($earned / $range) * 100)
            break
        }
    }
    
    return @{
        current = $currentLevel
        next = $nextLevel
        progress = $progress
    }
}

$projectPaths = @("D:\work\code", "D:\work\codepos")

if ($Action -eq "check") {
    Write-Host "Checking achievements..." -ForegroundColor Yellow
    
    $stats = Get-GitStatistics $projectPaths
    $achievements = Check-Achievements $stats
    $level = Get-CurrentLevel $achievements.totalPoints
    
    $dataFile = Join-Path $OutputPath "achievements.json"
    @{
        lastCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        stats = $stats
        achievements = $achievements
        level = $level
    } | ConvertTo-Json -Depth 10 | Out-File $dataFile -Encoding UTF8
    
    Write-Host "`nAchievement Report" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Level: $($level.current.icon) - $($level.current.name)" -ForegroundColor Yellow
    Write-Host "Points: $($achievements.totalPoints) / $($achievements.totalPossible)" -ForegroundColor Yellow
    Write-Host "Progress: $($level.progress)%" -ForegroundColor Yellow
    Write-Host "Unlocked: $($achievements.unlocked.Count) / $($Achievements.Count)" -ForegroundColor Green
    
    Write-Host "`nUnlocked Achievements:" -ForegroundColor Green
    foreach ($ach in $achievements.unlocked) {
        $icon = Convert-Icon $ach.icon
        Write-Host "  $icon $($ach.name) - $($ach.description) (+$($ach.points)pts)" -ForegroundColor White
    }
    
    Write-Host "`nData saved to: $dataFile" -ForegroundColor Gray
}
elseif ($Action -eq "list") {
    $dataFile = Join-Path $OutputPath "achievements.json"
    if (Test-Path $dataFile) {
        $data = Get-Content $dataFile | ConvertFrom-Json
        Write-Host "`nCurrent Status" -ForegroundColor Cyan
        Write-Host "===============" -ForegroundColor Cyan
        Write-Host "Level: $($data.level.current.name)" -ForegroundColor Yellow
        Write-Host "Points: $($data.achievements.totalPoints)" -ForegroundColor Yellow
        Write-Host "Unlocked: $($data.achievements.unlocked.Count) / $($Achievements.Count)" -ForegroundColor Green
        
        Write-Host "`nAll Achievements:" -ForegroundColor Cyan
        foreach ($ach in $Achievements.Values) {
            $icon = Convert-Icon $ach.icon
            Write-Host "  $icon $($ach.name)" -ForegroundColor $(if ($ach.id -in $data.achievements.unlocked.id) { "Green" } else { "Gray" })
        }
    }
    else {
        Write-Host "No data found. Run with -Action check first." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\achievement-system.ps1 -Action check   # Check achievements" -ForegroundColor White
    Write-Host "  .\achievement-system.ps1 -Action list    # List all achievements" -ForegroundColor White
}
