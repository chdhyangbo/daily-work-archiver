# 成就与徽章系统

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
        name = "初次提交"
        description = "完成第一次代码提交"
        requirement = "提交次数 >= 1"
        icon = "🌱"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 1 }
        points = 10
    }
    COMMIT_10 = @{
        id = "COMMIT_10"
        name = "初出茅庐"
        description = "累计提交10次"
        requirement = "提交次数 >= 10"
        icon = "🌿"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 10 }
        points = 20
    }
    COMMIT_100 = @{
        id = "COMMIT_100"
        name = "代码工匠"
        description = "累计提交100次"
        requirement = "提交次数 >= 100"
        icon = "🌳"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 100 }
        points = 50
    }
    COMMIT_1000 = @{
        id = "COMMIT_1000"
        name = "代码大师"
        description = "累计提交1000次"
        requirement = "提交次数 >= 1000"
        icon = "🏆"
        category = "milestone"
        condition = { param($s) $s.totalCommits -ge 1000 }
        points = 200
    }
    STREAK_3 = @{
        id = "STREAK_3"
        name = "三日连续"
        description = "连续3天有提交记录"
        requirement = "连续提交天数 >= 3"
        icon = "🔥"
        category = "consistency"
        condition = { param($s) $s.maxStreak -ge 3 }
        points = 15
    }
    STREAK_7 = @{
        id = "STREAK_7"
        name = "周周不懈"
        description = "连续7天有提交记录"
        requirement = "连续提交天数 >= 7"
        icon = "⚡"
        category = "consistency"
        condition = { param($s) $s.maxStreak -ge 7 }
        points = 30
    }
    MULTI_PROJECT = @{
        id = "MULTI_PROJECT"
        name = "多面手"
        description = "参与3个以上项目"
        requirement = "参与项目数 >= 3"
        icon = "🎯"
        category = "contribution"
        condition = { param($s) $s.projectCount -ge 3 }
        points = 30
    }
}

$Levels = @(
    @{ name = "代码新人"; minPoints = 0; icon = "🥉" }
    @{ name = "初级开发"; minPoints = 100; icon = "🥈" }
    @{ name = "中级开发"; minPoints = 300; icon = "🥇" }
    @{ name = "高级开发"; minPoints = 600; icon = "💎" }
    @{ name = "专家"; minPoints = 1000; icon = "👑" }
    @{ name = "传奇"; minPoints = 2000; icon = "🌟" }
)

$IconMap = @{
    SEED = "🌱"
    SEEDLING = "🌿"
    TREE = "🌳"
    TROPHY = "🏆"
    FIRE = "🔥"
    LIGHTNING = "⚡"
    TARGET = "🎯"
    BRONZE = "🥉"
    SILVER = "🥈"
    GOLD = "🥇"
    DIAMOND = "💎"
    CROWN = "👑"
    LEGEND = "🌟"
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
    $allAchievements = @()
    
    foreach ($achievement in $Achievements.Values) {
        $condition = $achievement.condition
        $result = & $condition $stats
        
        $achData = @{
            id = $achievement.id
            name = $achievement.name
            description = $achievement.description
            requirement = $achievement.requirement
            icon = $achievement.icon
            category = $achievement.category
            points = $achievement.points
            unlocked = $result
            progress = 0
        }
        
        $allAchievements += $achData
        
        if ($result) {
            $unlocked += $achievement
            $totalPoints += $achievement.points
            $achData.progress = 100
        }
    }
    
    return @{
        unlocked = $unlocked.Count
        totalPoints = $totalPoints
        totalPossible = ($Achievements.Values | Measure-Object -Property points -Sum).Sum
        list = $allAchievements
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
    $outputData = @{
        lastCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        stats = @{
            totalCommits = $stats.totalCommits
            projectCount = $stats.projectCount
            maxStreak = $stats.maxStreak
        }
        achievements = @{
            unlocked = $achievements.unlocked
            totalPoints = $achievements.totalPoints
            totalPossible = $achievements.totalPossible
            list = $achievements.list
        }
        level = @{
            current = $level.current
            next = $level.next
            progress = $level.progress
        }
    }
    $outputData | ConvertTo-Json -Depth 5 | Out-File $dataFile -Encoding UTF8
    
    Write-Host "`nAchievement Report" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Level: $($level.current.icon) $($level.current.name)" -ForegroundColor Yellow
    Write-Host "Points: $($achievements.totalPoints) / $($achievements.totalPossible)" -ForegroundColor Yellow
    Write-Host "Progress: $($level.progress)%" -ForegroundColor Yellow
    Write-Host "Unlocked: $($achievements.unlocked.Count) / $($Achievements.Count)" -ForegroundColor Green
    
    Write-Host "`nUnlocked Achievements:" -ForegroundColor Green
    foreach ($ach in $achievements.unlocked) {
        Write-Host "  $($ach.icon) $($ach.name) - $($ach.description) (+$($ach.points)pts)" -ForegroundColor White
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
            $unlocked = $data.achievements.unlocked | Where-Object { $_.id -eq $ach.id }
            $color = if ($unlocked) { "Green" } else { "Gray" }
            Write-Host "  $($ach.icon) $($ach.name)" -ForegroundColor $color
        }
    }
    else {
        Write-Host "No data found. Run with -Action check first." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\achievement-system-core.ps1 -Action check   # Check achievements" -ForegroundColor White
    Write-Host "  .\achievement-system-core.ps1 -Action list    # List all achievements" -ForegroundColor White
}
