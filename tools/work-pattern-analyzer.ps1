# Work Pattern Analyzer
# 工作模式分析器 - 分析高效时段、专注时间、工作习惯

param(
    [string]$Period = "month",  # week, month, quarter
    [string]$StartDate = (Get-Date -Format "yyyy-MM-dd"),
    [string]$OutputPath = (Join-Path $PSScriptRoot ".." "work-archive" "analytics")
)

# 确保输出目录存在
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# 获取日期范围
function Get-DateRange($period, $startDate) {
    $start = [DateTime]::Parse($startDate)
    
    switch ($period) {
        "week" { $end = $start.AddDays(-7) }
        "month" { $end = $start.AddMonths(-1) }
        "quarter" { $end = $start.AddMonths(-3) }
        default { $end = $start.AddMonths(-1) }
    }
    
    $dates = @()
    $current = $end
    while ($current -le $start) {
        $dates += $current.ToString("yyyy-MM-dd")
        $current = $current.AddDays(1)
    }
    return $dates
}

# 加载Git数据
function Load-GitData($dates, $projectPaths) {
    $commits = @()
    
    foreach ($rootPath in $projectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            $since = "$($dates[0]) 00:00:00"
            $until = "$($dates[-1]) 23:59:59"
            
            $log = & git -c core.quotepath=false log --since="$since" --until="$until" --author="yangbo" --pretty=format:"%H|%ad|%s|%ae" --date=format:"%Y-%m-%d %H:%M:%S" 2>$null
            
            if ($log) {
                $log.Split("`n") | Where-Object { $_ } | ForEach-Object {
                    $parts = $_.Split('|')
                    $commits += @{
                        hash = $parts[0]
                        datetime = $parts[1]
                        message = $parts[2]
                        project = $projectName
                        hour = [int]$parts[1].Split(' ')[1].Split(':')[0]
                        dayOfWeek = [int][DateTime]::Parse($parts[1].Split(' ')[0]).DayOfWeek
                    }
                }
            }
        }
    }
    
    Set-Location $PSScriptRoot
    return $commits
}

# 加载时间追踪数据
function Load-TimeData($dates) {
    $sessions = @()
    $dataDir = Join-Path $PSScriptRoot ".." "work-archive" "data" "time-tracking"
    
    foreach ($date in $dates) {
        $file = Join-Path $dataDir "$date.json"
        if (Test-Path $file) {
            $data = Get-Content $file | ConvertFrom-Json
            foreach ($session in $data.sessions) {
                $sessions += $session
            }
        }
    }
    
    return $sessions
}

# 分析高效时段
function Analyze-ProductiveHours($commits) {
    $hourlyStats = @{}
    
    for ($h = 0; $h -lt 24; $h++) {
        $hourlyStats[$h] = 0
    }
    
    foreach ($commit in $commits) {
        $hourlyStats[$commit.hour]++
    }
    
    # 找出Top 5高效时段
    $topHours = $hourlyStats.GetEnumerator() | 
        Sort-Object Value -Descending | 
        Select-Object -First 5
    
    # 分析时段特征
    $morning = 0    # 6-12
    $afternoon = 0  # 12-18
    $evening = 0    # 18-22
    $night = 0      # 22-6
    
    foreach ($h in $hourlyStats.Keys) {
        $count = $hourlyStats[$h]
        if ($h -ge 6 -and $h -lt 12) { $morning += $count }
        elseif ($h -ge 12 -and $h -lt 18) { $afternoon += $count }
        elseif ($h -ge 18 -and $h -lt 22) { $evening += $count }
        else { $night += $count }
    }
    
    $total = $morning + $afternoon + $evening + $night
    if ($total -eq 0) { $total = 1 }
    
    $peakPeriod = if ($morning -ge $afternoon -and $morning -ge $evening) { "上午" }
                  elseif ($afternoon -ge $evening) { "下午" }
                  else { "晚上" }
    
    return @{
        hourly = $hourlyStats
        topHours = $topHours
        periods = @{
            morning = @{ count = $morning; percent = [Math]::Round(($morning/$total)*100) }
            afternoon = @{ count = $afternoon; percent = [Math]::Round(($afternoon/$total)*100) }
            evening = @{ count = $evening; percent = [Math]::Round(($evening/$total)*100) }
            night = @{ count = $night; percent = [Math]::Round(($night/$total)*100) }
        }
        peakPeriod = $peakPeriod
    }
}

# 分析专注时间
function Analyze-FocusTime($sessions) {
    if ($sessions.Count -eq 0) {
        return @{
            avgSession = 0
            maxSession = 0
            totalSessions = 0
            interruptions = 0
        }
    }
    
    $durations = $sessions | ForEach-Object { $_.duration }
    $avgDuration = ($durations | Measure-Object -Average).Average
    $maxDuration = ($durations | Measure-Object -Maximum).Maximum
    
    # 分析中断（短于15分钟的会话视为中断）
    $shortSessions = $durations | Where-Object { $_ -lt 15 }
    
    return @{
        avgSession = [Math]::Round($avgDuration, 1)
        maxSession = [Math]::Round($maxDuration, 1)
        totalSessions = $sessions.Count
        interruptions = $shortSessions.Count
        avgInterruptionRate = if ($sessions.Count -gt 0) { 
            [Math]::Round(($shortSessions.Count / $sessions.Count) * 100) 
        } else { 0 }
    }
}

# 分析工作日模式
function Analyze-WorkdayPattern($commits, $dates) {
    $dailyCommits = @{}
    foreach ($date in $dates) {
        $dailyCommits[$date] = 0
    }
    
    foreach ($commit in $commits) {
        $date = $commit.datetime.Split(' ')[0]
        if ($dailyCommits.ContainsKey($date)) {
            $dailyCommits[$date]++
        }
    }
    
    $activeDays = ($dailyCommits.Values | Where-Object { $_ -gt 0 }).Count
    $inactiveDays = $dates.Count - $activeDays
    
    # 计算连续提交天数
    $streaks = @()
    $currentStreak = 0
    $maxStreak = 0
    
    foreach ($date in $dates | Sort-Object) {
        if ($dailyCommits[$date] -gt 0) {
            $currentStreak++
            if ($currentStreak -gt $maxStreak) {
                $maxStreak = $currentStreak
            }
        } else {
            if ($currentStreak -gt 0) {
                $streaks += $currentStreak
            }
            $currentStreak = 0
        }
    }
    
    return @{
        activeDays = $activeDays
        inactiveDays = $inactiveDays
        activityRate = [Math]::Round(($activeDays / $dates.Count) * 100)
        maxStreak = $maxStreak
        avgStreak = if ($streaks.Count -gt 0) { 
            [Math]::Round(($streaks | Measure-Object -Average).Average) 
        } else { 0 }
    }
}

# 分析项目切换频率
function Analyze-ContextSwitching($commits) {
    if ($commits.Count -eq 0) {
        return @{ switchesPerDay = 0; mostSwitches = 0 }
    }
    
    # 按日期分组
    $byDate = @{}
    foreach ($commit in $commits) {
        $date = $commit.datetime.Split(' ')[0]
        if (-not $byDate[$date]) {
            $byDate[$date] = @()
        }
        $byDate[$date] += $commit
    }
    
    $dailySwitches = @()
    foreach ($date in $byDate.Keys) {
        $dayCommits = $byDate[$date] | Sort-Object datetime
        $switches = 0
        $currentProject = $null
        
        foreach ($commit in $dayCommits) {
            if ($currentProject -and $commit.project -ne $currentProject) {
                $switches++
            }
            $currentProject = $commit.project
        }
        
        $dailySwitches += $switches
    }
    
    return @{
        switchesPerDay = if ($dailySwitches.Count -gt 0) { 
            [Math]::Round(($dailySwitches | Measure-Object -Average).Average, 1) 
        } else { 0 }
        mostSwitches = if ($dailySwitches.Count -gt 0) { 
            ($dailySwitches | Measure-Object -Maximum).Maximum 
        } else { 0 }
    }
}

# 生成分析报告
function Generate-AnalysisReport($period, $dates, $hourAnalysis, $focusAnalysis, $workdayAnalysis, $switchAnalysis) {
    $report = @"
# 工作模式分析报告

> 分析周期: $($dates[0]) ~ $($dates[-1])
> 生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm")

---

## 🕐 高效时段分析

### 你的黄金时段
**$($hourAnalysis.peakPeriod)** 是你最高效的时段

### 时段分布
```
时段分布:
🌅 上午 (6-12点):  $($hourAnalysis.periods.morning.percent)% ($($hourAnalysis.periods.morning.count)次提交)
🌞 下午 (12-18点): $($hourAnalysis.periods.afternoon.percent)% ($($hourAnalysis.periods.afternoon.count)次提交)
🌙 晚上 (18-22点): $($hourAnalysis.periods.evening.percent)% ($($hourAnalysis.periods.evening.count)次提交)
🌑 深夜 (22-6点):  $($hourAnalysis.periods.night.percent)% ($($hourAnalysis.periods.night.count)次提交)
```

### Top 5 高效小时
"@
    
    foreach ($h in $hourAnalysis.topHours) {
        $time = "$($h.Key):00".PadLeft(5)
        $bar = "█" * [Math]::Min($h.Value, 20)
        $report += "`n$time $bar $($h.Value)次"
    }
    
    $report += @"

---

## 🎯 专注时间分析

| 指标 | 数值 | 评价 |
|------|------|------|
| 平均专注时长 | $($focusAnalysis.avgSession)分钟 | $(if ($focusAnalysis.avgSession -ge 45) { "✅ 优秀" } elseif ($focusAnalysis.avgSession -ge 25) { "📈 良好" } else { "⚠️ 需提升" }) |
| 最长专注时间 | $($focusAnalysis.maxSession)分钟 | - |
| 工作会话数 | $($focusAnalysis.totalSessions)次 | - |
| 中断次数 | $($focusAnalysis.interruptions)次 | $(if ($focusAnalysis.avgInterruptionRate -lt 20) { "✅ 可控" } else { "⚠️ 较多" }) |

---

## 📅 工作习惯分析

### 活跃度
- **活跃天数**: $($workdayAnalysis.activeDays)天 / $($workdayAnalysis.activeDays + $workdayAnalysis.inactiveDays)天
- **活跃率**: $($workdayAnalysis.activityRate)%
- **最长连续**: $($workdayAnalysis.maxStreak)天
- **平均连续**: $($workdayAnalysis.avgStreak)天

### 项目切换
- **日均切换**: $($switchAnalysis.switchesPerDay)次
- **最多切换**: $($switchAnalysis.mostSwitches)次/天

---

## 💡 个性化建议

"@
    
    # 根据分析结果生成建议
    $suggestions = @()
    
    if ($hourAnalysis.peakPeriod -eq "上午") {
        $suggestions += "1. **利用黄金时段**: 将重要、复杂的任务安排在上午9-11点"
    } elseif ($hourAnalysis.peakPeriod -eq "晚上") {
        $suggestions += "1. **调整作息**: 你晚上效率更高，可以尝试将核心工作安排在晚间"
    }
    
    if ($focusAnalysis.avgSession -lt 25) {
        $suggestions += "2. **提升专注力**: 尝试番茄工作法，设定25分钟专注+5分钟休息的周期"
    }
    
    if ($switchAnalysis.switchesPerDay -gt 3) {
        $suggestions += "3. **减少上下文切换**: 每天专注2-3个项目即可，避免频繁切换"
    }
    
    if ($workdayAnalysis.activityRate -lt 70) {
        $suggestions += "4. **保持连续性**: 尝试每天都做一些提交，保持工作节奏"
    }
    
    if ($suggestions.Count -eq 0) {
        $suggestions += "你的工作模式很健康！继续保持 💪"
    }
    
    $report += $suggestions -join "`n`n"
    
    $report += @"

---

## 📊 数据可视化

### 24小时提交热力图
"@
    
    # 生成24小时热力图
    for ($h = 0; $h -lt 24; $h += 4) {
        $report += "`n"
        for ($i = 0; $i -lt 4; $i++) {
            $hour = $h + $i
            $count = $hourAnalysis.hourly[$hour]
            $level = if ($count -ge 10) { "██" } elseif ($count -ge 5) { "▓▓" } elseif ($count -ge 1) { "▒▒" } else { "░░" }
            $report += "$($hour.ToString().PadLeft(2)):00 $level ($($count.ToString().PadLeft(2)))  "
        }
    }
    
    $report += @"

---

*报告由 AI Work Archiver 自动生成*
"@
    
    return $report
}

# 主逻辑
$projectPaths = @("D:\work\code", "D:\work\codepos")
$dates = Get-DateRange $Period $StartDate

Write-Host "正在分析工作模式 ($($dates[0]) ~ $($dates[-1]))..." -ForegroundColor Yellow

# 加载数据
$commits = Load-GitData $dates $projectPaths
$sessions = Load-TimeData $dates

Write-Host "找到 $($commits.Count) 次提交, $($sessions.Count) 个时间记录" -ForegroundColor Gray

# 执行分析
$hourAnalysis = Analyze-ProductiveHours $commits
$focusAnalysis = Analyze-FocusTime $sessions
$workdayAnalysis = Analyze-WorkdayPattern $commits $dates
$switchAnalysis = Analyze-ContextSwitching $commits

# 生成报告
$report = Generate-AnalysisReport $Period $dates $hourAnalysis $focusAnalysis $workdayAnalysis $switchAnalysis

# 保存报告
$reportFile = Join-Path $OutputPath "work-pattern-$Period-$(Get-Date -Format 'yyyyMMdd').md"
$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ 分析报告已生成: $reportFile" -ForegroundColor Green
Write-Host ""
Write-Host $report
