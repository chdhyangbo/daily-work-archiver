# Weekly Report Generator with Burndown Chart
# 增强版周报生成器（含燃尽图）

param(
    [string]$WeekStart = ((Get-Date).AddDays(-([int](Get-Date).DayOfWeek + 6) % 7).ToString("yyyy-MM-dd")),
    [string]$OutputPath = (Join-Path $PSScriptRoot ".." "work-archive" "weekly-reports"),
    [string[]]$ProjectPaths = @("D:\work\code", "D:\work\codepos")
)

# 获取一周的日期范围
function Get-WeekRange($startDate) {
    $start = [DateTime]::Parse($startDate)
    $dates = @()
    for ($i = 0; $i -lt 7; $i++) {
        $dates += $start.AddDays($i).ToString("yyyy-MM-dd")
    }
    return $dates
}

# 获取Git统计数据（按天）
function Get-GitStatsByDay($dates, $projectPaths) {
    $stats = @{}
    
    foreach ($date in $dates) {
        $stats[$date] = @{
            commits = 0
            insertions = 0
            deletions = 0
            projects = @{}
        }
    }
    
    foreach ($rootPath in $projectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            foreach ($date in $dates) {
                $since = "$date 00:00:00"
                $until = "$date 23:59:59"
                
                $commits = & git -c core.quotepath=false log --since="$since" --until="$until" --author="yangbo" --pretty=format:"%H|%s" --date=format:"%Y-%m-%d" 2>$null
                
                if ($commits) {
                    $commitList = $commits -split "`n" | Where-Object { $_ }
                    $stats[$date].commits += $commitList.Count
                    
                    if (-not $stats[$date].projects[$projectName]) {
                        $stats[$date].projects[$projectName] = 0
                    }
                    $stats[$date].projects[$projectName] += $commitList.Count
                    
                    # 统计代码变更
                    foreach ($commit in $commitList) {
                        $hash = $commit.Split('|')[0]
                        $statInfo = git show --stat --format="" $hash 2>$null | Select-Object -Last 1
                        if ($statInfo -match "(\d+) insertion") {
                            $stats[$date].insertions += [int]$matches[1]
                        }
                        if ($statInfo -match "(\d+) deletion") {
                            $stats[$date].deletions += [int]$matches[1]
                        }
                    }
                }
            }
        }
    }
    
    Set-Location $PSScriptRoot
    return $stats
}

# 获取时间追踪数据（按天）
function Get-TimeStatsByDay($dates) {
    $stats = @{}
    $dataDir = Join-Path $PSScriptRoot ".." "work-archive" "data" "time-tracking"
    
    foreach ($date in $dates) {
        $file = Join-Path $dataDir "$date.json"
        if (Test-Path $file) {
            $data = Get-Content $file | ConvertFrom-Json
            $totalMinutes = 0
            $typeSummary = @{}
            $projectSummary = @{}
            
            foreach ($session in $data.sessions) {
                $totalMinutes += $session.duration
                
                if (-not $typeSummary[$session.type]) {
                    $typeSummary[$session.type] = 0
                }
                $typeSummary[$session.type] += $session.duration
                
                if (-not $projectSummary[$session.project]) {
                    $projectSummary[$session.project] = 0
                }
                $projectSummary[$session.project] += $session.duration
            }
            
            $stats[$date] = @{
                hours = [Math]::Round($totalMinutes / 60, 1)
                types = $typeSummary
                projects = $projectSummary
            }
        } else {
            $stats[$date] = @{
                hours = 0
                types = @{}
                projects = @{}
            }
        }
    }
    
    return $stats
}

# 生成ASCII燃尽图
function Generate-BurndownChart($gitStats, $dates) {
    $chart = "```\n本周提交趋势:\n\n"
    
    $maxCommits = ($dates | ForEach-Object { $gitStats[$_].commits } | Measure-Object -Maximum).Maximum
    if ($maxCommits -eq 0) { $maxCommits = 1 }
    
    $chart += "提交数  "
    foreach ($date in $dates) {
        $day = [DateTime]::Parse($date).ToString("ddd")
        $chart += "$day "
    }
    $chart += "\n"
    
    for ($level = 10; $level -ge 1; $level--) {
        $threshold = $maxCommits * $level / 10
        $chart += "       "
        foreach ($date in $dates) {
            $commits = $gitStats[$date].commits
            if ($commits -ge $threshold) {
                $chart += "██ "
            } elseif ($commits -ge $threshold * 0.5) {
                $chart += "▓▓ "
            } elseif ($commits -ge $threshold * 0.25) {
                $chart += "▒▒ "
            } else {
                $chart += "░░ "
            }
        }
        $chart += "\n"
    }
    
    $chart += "       "
    foreach ($date in $dates) {
        $dayNum = [DateTime]::Parse($date).Day
        $chart += "$($dayNum.ToString().PadLeft(2)) "
    }
    $chart += "\n```"
    
    return $chart
}

# 生成项目时间分配饼图（ASCII）
function Generate-TimePieChart($timeStats, $dates) {
    # 汇总一周的项目时间
    $projectTotals = @{}
    $totalHours = 0
    
    foreach ($date in $dates) {
        if ($timeStats[$date].projects) {
            foreach ($proj in $timeStats[$date].projects.Keys) {
                if (-not $projectTotals[$proj]) {
                    $projectTotals[$proj] = 0
                }
                $hours = $timeStats[$date].projects[$proj] / 60
                $projectTotals[$proj] += $hours
                $totalHours += $hours
            }
        }
    }
    
    if ($totalHours -eq 0) {
        return "本周暂无时间记录"
    }
    
    $chart = "```\n本周时间分配 ($([Math]::Round($totalHours, 1)) 小时):\n\n"
    
    $sorted = $projectTotals.GetEnumerator() | Sort-Object Value -Descending
    $colors = @("🟥", "🟧", "🟨", "🟩", "🟦", "🟪", "⬜")
    $colorIdx = 0
    
    foreach ($proj in $sorted) {
        $percent = [Math]::Round(($proj.Value / $totalHours) * 100)
        $barLength = [Math]::Round($percent / 2)
        $bar = "█" * $barLength
        $color = $colors[$colorIdx % $colors.Length]
        $chart += "$color $($proj.Key.PadRight(20)) $bar $($percent)% ($([Math]::Round($proj.Value, 1))h)\n"
        $colorIdx++
    }
    
    $chart += "```"
    return $chart
}

# 生成周报
function Generate-WeeklyReport($weekStart, $dates, $gitStats, $timeStats) {
    $weekEnd = $dates[-1]
    $weekNum = [DateTime]::Parse($weekStart).ToString("yyyy-W") + ([Math]::Floor(([DateTime]::Parse($weekStart).DayOfYear - 1) / 7) + 1).ToString().PadLeft(2, '0')
    
    # 汇总统计
    $totalCommits = 0
    $totalInsertions = 0
    $totalDeletions = 0
    $allProjects = @{}
    $dailyCommits = @()
    
    foreach ($date in $dates) {
        $stats = $gitStats[$date]
        $totalCommits += $stats.commits
        $totalInsertions += $stats.insertions
        $totalDeletions += $stats.deletions
        $dailyCommits += $stats.commits
        
        foreach ($proj in $stats.projects.Keys) {
            if (-not $allProjects[$proj]) {
                $allProjects[$proj] = 0
            }
            $allProjects[$proj] += $stats.projects[$proj]
        }
    }
    
    $avgCommits = if ($dailyCommits.Count -gt 0) { 
        [Math]::Round(($dailyCommits | Measure-Object -Average).Average, 1) 
    } else { 0 }
    
    $activeDays = ($dailyCommits | Where-Object { $_ -gt 0 }).Count
    
    # 燃尽图
    $burndownChart = Generate-BurndownChart $gitStats $dates
    $timePieChart = Generate-TimePieChart $timeStats $dates
    
    $report = @"
# $weekNum 工作周报

> 统计周期: $weekStart ~ $weekEnd

---

## 📊 本周概览

| 指标 | 数值 | 趋势 |
|------|------|------|
| **总提交数** | $totalCommits | $(if ($totalCommits -ge 35) { "🔥" } elseif ($totalCommits -ge 21) { "📈" } else { "📉" }) |
| **代码新增** | +$totalInsertions | - |
| **代码删除** | -$totalDeletions | - |
| **活跃天数** | $activeDays/7 | $(if ($activeDays -ge 5) { "💪" } else { "⚠️" }) |
| **日均提交** | $avgCommits | - |

---

## 📈 提交趋势

$burndownChart

---

## ⏰ 时间分配

$timePieChart

---

## 🚀 项目贡献

| 项目 | 提交数 | 占比 | 代码变更 |
|------|--------|------|----------|
"@
    
    $sortedProjects = $allProjects.GetEnumerator() | Sort-Object Value -Descending
    foreach ($proj in $sortedProjects) {
        $percent = [Math]::Round(($proj.Value / $totalCommits) * 100)
        $report += "`n| $($proj.Key) | $($proj.Value) | $percent% | - |"
    }
    
    $report += @"

---

## 📅 每日详情

"@
    
    foreach ($date in $dates) {
        $dayName = [DateTime]::Parse($date).ToString("dddd")
        $git = $gitStats[$date]
        $time = $timeStats[$date]
        
        $report += "`n### $date ($dayName)`n"
        $report += "- **提交**: $($git.commits) 次`n"
        $report += "- **代码**: +$($git.insertions) / -$($git.deletions)`n"
        if ($time.hours -gt 0) {
            $report += "- **工时**: $($time.hours) 小时`n"
        }
        
        if ($git.projects.Count -gt 0) {
            $report += "- **项目**: $($git.projects.Keys -join ', ')`n"
        }
    }
    
    $report += @"

---

## 🎯 下周计划

- [ ] 继续推进主要项目开发
- [ ] 完成代码审查任务
- [ ] 补充单元测试

---

*报告由 AI Work Archiver 自动生成*
"@
    
    return $report
}

# 主逻辑
$dates = Get-WeekRange $WeekStart
Write-Host "正在生成本周报告 ($WeekStart ~ $($dates[-1]))..." -ForegroundColor Yellow

$gitStats = Get-GitStatsByDay $dates $ProjectPaths
$timeStats = Get-TimeStatsByDay $dates

$report = Generate-WeeklyReport $WeekStart $dates $gitStats $timeStats

# 保存报告
$year = [DateTime]::Parse($WeekStart).Year
$weekNum = [Math]::Floor(([DateTime]::Parse($WeekStart).DayOfYear - 1) / 7) + 1
$reportFile = Join-Path $OutputPath "$year-W$($weekNum.ToString().PadLeft(2, '0')).md"

# 确保目录存在
$reportDir = Split-Path $reportFile -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ 周报已生成: $reportFile" -ForegroundColor Green
Write-Host ""
Write-Host $report
