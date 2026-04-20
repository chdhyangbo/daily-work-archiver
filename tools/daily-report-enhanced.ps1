# Enhanced Daily Report Generator
# 增强版日报生成器

param(
    [switch]$Today,
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [string]$OutputPath = (Join-Path $PSScriptRoot ".." "work-archive" "daily-reports"),
    [string[]]$ProjectPaths = @("D:\work\code", "D:\work\codepos")
)

# 加载时间追踪数据
function Load-TimeData($date) {
    $timeFile = Join-Path $PSScriptRoot ".." "work-archive" "data" "time-tracking" "$date.json"
    if (Test-Path $timeFile) {
        return Get-Content $timeFile | ConvertFrom-Json
    }
    return @{ sessions = @() }
}

# 加载项目进度
function Load-ProjectProgress($projectPath) {
    $configFile = Join-Path $projectPath ".project-config.yml"
    if (-not (Test-Path $configFile)) {
        return $null
    }
    
    # 简单YAML解析
    $content = Get-Content $configFile -Raw
    $config = @{}
    
    if ($content -match "project:\s*(.+)") {
        $config.project = $matches[1].Trim()
    }
    
    $config.milestones = @()
    $lines = $content -split "`n"
    $inMilestone = $false
    $currentMilestone = @{}
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        if ($trimmed -eq "-" -and -not $inMilestone) {
            $inMilestone = $true
            $currentMilestone = @{}
        } elseif ($inMilestone -and $trimmed -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2]
            $currentMilestone[$key] = $value
        } elseif ($trimmed -eq "" -and $inMilestone) {
            if ($currentMilestone.Count -gt 0) {
                $config.milestones += $currentMilestone
            }
            $inMilestone = $false
        }
    }
    
    if ($currentMilestone.Count -gt 0) {
        $config.milestones += $currentMilestone
    }
    
    return $config
}

# 计算项目进度
function Get-ProgressPercentage($milestones) {
    if (-not $milestones -or $milestones.Count -eq 0) {
        return 0
    }
    
    $totalEstimated = 0
    $totalCompleted = 0
    
    foreach ($ms in $milestones) {
        $estimated = [int]$ms.estimated
        $completed = [int]$ms.completed
        $totalEstimated += $estimated
        $totalCompleted += [Math]::Min($completed, $estimated)
    }
    
    if ($totalEstimated -eq 0) { return 0 }
    return [Math]::Round(($totalCompleted / $totalEstimated) * 100)
}

# 获取Git提交统计
function Get-GitStats($date, $projectPaths) {
    $stats = @{
        totalCommits = 0
        projects = @{}
        filesChanged = 0
        insertions = 0
        deletions = 0
    }
    
    foreach ($rootPath in $projectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            $since = "$date 00:00:00"
            $until = "$date 23:59:59"
            
            $commits = & git -c core.quotepath=false log --since="$since" --until="$until" --author="yangbo" --pretty=format:"%H" 2>$null
            
            if ($commits) {
                $commitList = $commits -split "`n" | Where-Object { $_ }
                $commitCount = $commitList.Count
                
                $stats.totalCommits += $commitCount
                $stats.projects[$projectName] = $commitCount
                
                # 统计代码变更
                foreach ($hash in $commitList) {
                    $statInfo = git show --stat --format="" $hash 2>$null | Select-Object -Last 1
                    if ($statInfo -match "(\d+) insertion") {
                        $stats.insertions += [int]$matches[1]
                    }
                    if ($statInfo -match "(\d+) deletion") {
                        $stats.deletions += [int]$matches[1]
                    }
                    if ($statInfo -match "(\d+) file") {
                        $stats.filesChanged += [int]$matches[1]
                    }
                }
            }
        }
    }
    
    Set-Location $PSScriptRoot
    return $stats
}

# 生成增强日报
function Generate-EnhancedReport($date) {
    $gitStats = Get-GitStats $date $ProjectPaths
    $timeData = Load-TimeData $date
    
    # 计算时间统计
    $timeSummary = @{}
    $projectTime = @{}
    $totalMinutes = 0
    
    foreach ($session in $timeData.sessions) {
        $totalMinutes += $session.duration
        
        if (-not $timeSummary[$session.type]) {
            $timeSummary[$session.type] = 0
        }
        $timeSummary[$session.type] += $session.duration
        
        if (-not $projectTime[$session.project]) {
            $projectTime[$session.project] = 0
        }
        $projectTime[$session.project] += $session.duration
    }
    
    $totalHours = [Math]::Round($totalMinutes / 60, 1)
    
    # 加载项目进度
    $projectProgress = @()
    foreach ($rootPath in $ProjectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        $projects = Get-ChildItem -Path $rootPath -Directory -ErrorAction SilentlyContinue
        foreach ($proj in $projects) {
            $progress = Load-ProjectProgress $proj.FullName
            if ($progress) {
                $percent = Get-ProgressPercentage $progress.milestones
                $projectProgress += @{
                    name = $progress.project
                    percent = $percent
                    milestones = $progress.milestones
                }
            }
        }
    }
    
    # 生成报告
    $report = @"
# $date 工作日报

## 📊 今日概览
- **工作时长**: $totalHours 小时
- **提交次数**: $($gitStats.totalCommits) 次
- **代码变更**: +$($gitStats.insertions) / -$($gitStats.deletions)
- **活跃项目**: $($gitStats.projects.Count) 个

"@

    # 项目进度部分
    if ($projectProgress.Count -gt 0) {
        $report += "`n## 🎯 项目进展`n`n"
        
        foreach ($proj in $projectProgress) {
            $report += "### $($proj.name) (整体: $($proj.percent)%)`n"
            
            # 查找进行中的里程碑
            $inProgress = $proj.milestones | Where-Object { 
                [int]$_.completed -lt [int]$_.estimated 
            } | Select-Object -First 1
            
            if ($inProgress) {
                $msProgress = if ($inProgress.estimated -gt 0) {
                    [Math]::Min(100, [Math]::Round(([int]$inProgress.completed / [int]$inProgress.estimated) * 100))
                } else { 0 }
                
                $report += "**当前里程碑**: $($inProgress.name) ($msProgress%)`n`n"
            }
            
            # 今日提交
            if ($gitStats.projects[$proj.name]) {
                $report += "**