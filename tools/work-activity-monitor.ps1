# 工作活动自动监控脚本
# 功能：监控 D:\work\code和 D:\work\codepos 目录的文件变化
# 用法：.\work-activity-monitor.ps1 [Start|Stop|Status|Report]

param(
    [ValidateSet("Start", "Stop", "Status", "Report")]
    [string]$Action = "Status",
    [string]$MonitorPath1 = "D:\work\code",
    [string]$MonitorPath2 = "D:\work\codepos",
    [string]$OutputPath = "d:\work\ai\lingma\.lingma\skills\work-archive"
)

$ErrorActionPreference = "Stop"
$mutexName = "Global\WorkActivityMonitorMutex"
$runningFilePath = Join-Path $OutputPath "monitor-running.txt"

function Start-Monitor {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  启动工作活动监控" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查是否已经在运行
    if (Test-Path $runningFilePath) {
        $lastRun = Get-Content $runningFilePath
        Write-Host "⚠️  监控已在运行（启动时间：$lastRun）" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # 创建监控目录
    $monitorDataPath = Join-Path $OutputPath "archive-db\file-monitor"
    if (-not (Test-Path $monitorDataPath)) {
        New-Item -ItemType Directory -Path $monitorDataPath -Force | Out-Null
    }
    
    # 记录启动时间
    Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath $runningFilePath -Encoding UTF8
    
    Write-Host "✅ 监控已启动" -ForegroundColor Green
    Write-Host ""
    Write-Host "监控范围:" -ForegroundColor Yellow
    Write-Host "  • $MonitorPath1"
    Write-Host "  • $MonitorPath2"
    Write-Host ""
    Write-Host "数据保存位置:" -ForegroundColor Yellow
    Write-Host "  $monitorDataPath"
    Write-Host ""
    Write-Host "停止监控命令:" -ForegroundColor Cyan
    Write-Host "  .\work-activity-monitor.ps1 Stop"
    Write-Host ""
    Write-Host "查看报告命令:" -ForegroundColor Cyan
    Write-Host "  .\work-activity-monitor.ps1 Report"
    Write-Host ""
    
    # 启动后台监控任务
    $jobScript = {
        param($path1, $path2, $dataPath, $runningFile)
        
        $watcher1 = New-Object System.IO.FileSystemWatcher
        $watcher1.Path = $path1
        $watcher1.IncludeSubdirectories = $true
        $watcher1.EnableRaisingEvents = $true
        $watcher1.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor 
                                  [System.IO.NotifyFilters]::DirectoryName -bor 
                                  [System.IO.NotifyFilters]::LastWrite -bor 
                                  [System.IO.NotifyFilters]::Size
        
        $watcher2 = New-Object System.IO.FileSystemWatcher
        $watcher2.Path = $path2
        $watcher2.IncludeSubdirectories = $true
        $watcher2.EnableRaisingEvents = $true
        $watcher2.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor 
                                  [System.IO.NotifyFilters]::DirectoryName -bor 
                                  [System.IO.NotifyFilters]::LastWrite -bor 
                                  [System.IO.NotifyFilters]::Size
        
        $activityLog = @()
        $lastActivity = @{}
        
        $onChange = {
            $eventArgs = $Event.SourceEventArgs
            $fullPath = $eventArgs.FullPath
            
            # 过滤临时文件和系统文件
            if ($eventArgs.Name -match "^~\$|\.tmp$|\.swp$") { return }
            if ($fullPath -match "\\node_modules\\|\\.git\\|\\bin\\|\\obj\\|\\.vs\\") { return }
            
            $now = Get-Date
            $projectName = Split-Path (Split-Path $fullPath -Parent) -Leaf
            $relativePath = $fullPath.Replace($eventArgs.ChangeRequestPath, "").TrimStart("\")
            $fileType = [System.IO.Path]::GetExtension($fullPath)
            
            # 去重（同一文件在短时间内多次触发只记录一次）
            $key = "$fullPath-$([int]($now.Ticks / 10000000))"
            if ($lastActivity.ContainsKey($key)) { return }
            $lastActivity[$key] = $true
            
            # 限制字典大小
            if ($lastActivity.Count -gt 1000) {
                $lastActivity.Clear()
            }
            
            $activity = [PSCustomObject]@{
                Timestamp = $now.ToString("yyyy-MM-dd HH:mm:ss")
                Project = $projectName
                File = $relativePath
                FileType = $fileType
                ChangeType = $eventArgs.ChangeType.ToString()
                FullPath = $fullPath
            }
            
            $script:activityLog += $activity
            
            # 每 50 条记录保存一次
            if ($script:activityLog.Count -ge 50) {
                $today = Get-Date -Format "yyyy-MM-dd"
                $logFile = Join-Path $using:dataPath "$today.csv"
                $script:activityLog | Export-Csv -Path $logFile -Append -NoTypeInformation -Encoding UTF8
                $script:activityLog = @()
            }
        }
        
        Register-ObjectEvent -InputObject $watcher1 -EventName "Changed" -Action $onChange -SupportEvent:$false | Out-Null
        Register-ObjectEvent -InputObject $watcher1 -EventName "Created" -Action $onChange -SupportEvent:$false | Out-Null
        Register-ObjectEvent -InputObject $watcher1 -EventName "Renamed" -Action $onChange -SupportEvent:$false | Out-Null
        
        Register-ObjectEvent -InputObject $watcher2 -EventName "Changed" -EventName "Changed" -Action $onChange -SupportEvent:$false | Out-Null
        Register-ObjectEvent -InputObject $watcher2 -EventName "Created" -Action $onChange -SupportEvent:$false | Out-Null
        Register-ObjectEvent -InputObject $watcher2 -EventName "Renamed" -Action $onChange -SupportEvent:$false | Out-Null
        
        # 保持运行
        while (Test-Path $runningFile) {
            Start-Sleep -Seconds 5
            
            # 定期保存
            if ($activityLog.Count -gt 0) {
                $today = Get-Date -Format "yyyy-MM-dd"
                $logFile = Join-Path $dataPath "$today.csv"
                $activityLog | Export-Csv -Path $logFile -Append -NoTypeInformation -Encoding UTF8
                $activityLog = @()
            }
        }
        
        # 清理
        $watcher1.Dispose()
        $watcher2.Dispose()
        [System.GC]::Collect()
    }
    
    # 启动后台作业
    Start-Job -ScriptBlock $jobScript -ArgumentList $MonitorPath1, $MonitorPath2, $monitorDataPath, $runningFilePath | Out-Null
    
    Write-Host "💡 提示：" -ForegroundColor Cyan
    Write-Host "• 监控会在后台静默运行，几乎不占用资源"
    Write-Host "• 下班前运行 '.\work-activity-monitor.ps1 Report' 查看今日活动"
    Write-Host "• 离开公司时记得运行 '.\work-activity-monitor.ps1 Stop' 停止监控"
    Write-Host ""
}

function Stop-Monitor {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  停止工作活动监控" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $runningFilePath)) {
        Write-Host "ℹ️  监控未运行" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # 删除运行标记文件
    Remove-Item $runningFilePath -Force
    
    # 停止所有相关的后台作业
    $jobs = Get-Job | Where-Object { $_.Name -like "*work-activity*" }
    foreach ($job in $jobs) {
        Stop-Job $job
        Remove-Job $job
    }
    
    Write-Host "✅ 监控已停止" -ForegroundColor Green
    Write-Host ""
    
    # 生成最终报告
    $today = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $OutputPath "archive-db\file-monitor\$today.csv"
    
    if (Test-Path $logFile) {
        $activities = Import-Csv $logFile -Encoding UTF8
        $totalActivities = $activities.Count
        
        Write-Host "📊 今日统计:" -ForegroundColor Yellow
        Write-Host "  • 记录活动：$totalActivities 次"
        Write-Host "  • 数据文件：$logFile"
        Write-Host ""
    }
    
    Write-Host "下次启动命令:" -ForegroundColor Cyan
    Write-Host "  .\work-activity-monitor.ps1 Start"
    Write-Host ""
}

function Get-MonitorStatus {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  监控状态查询" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $runningFilePath) {
        $startTime = Get-Content $runningFilePath
        Write-Host "✅ 监控正在运行" -ForegroundColor Green
        Write-Host ""
        Write-Host "启动时间：$startTime" -ForegroundColor White
        Write-Host ""
        
        # 计算运行时长
        try {
            $start = [DateTime]::ParseExact($startTime, "yyyy-MM-dd HH:mm:ss", $null)
            $duration = (Get-Date) - $start
            Write-Host "运行时长：$([int]$duration.TotalHours) 小时 $([int]$duration.Minutes) 分钟" -ForegroundColor White
        } catch {}
        
        Write-Host ""
        
        # 显示今日统计
        $today = Get-Date -Format "yyyy-MM-dd"
        $logFile = Join-Path $OutputPath "archive-db\file-monitor\$today.csv"
        
        if (Test-Path $logFile) {
            $activities = Import-Csv $logFile -Encoding UTF8
            Write-Host "今日记录：$($activities.Count) 次活动" -ForegroundColor Yellow
            
            # 按项目分组
            $byProject = $activities | Group-Object -Property Project | Sort-Object Count -Descending
            Write-Host ""
            Write-Host "活跃项目 TOP 5:" -ForegroundColor Yellow
            for ($i = 0; $i -lt [Math]::Min(5, $byProject.Count); $i++) {
                Write-Host "  $($i + 1). $($byProject[$i].Name): $($byProject[$i].Count) 次" -ForegroundColor White
            }
        } else {
            Write-Host "今日暂无活动记录" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ 监控未运行" -ForegroundColor Red
        Write-Host ""
        Write-Host "启动命令:" -ForegroundColor Cyan
        Write-Host "  .\work-activity-monitor.ps1 Start"
    }
    
    Write-Host ""
}

function Get-Report {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  今日工作活动报告" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $today = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $OutputPath "archive-db\file-monitor\$today.csv"
    
    if (-not (Test-Path $logFile)) {
        Write-Host "ℹ️  今日暂无活动记录" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "提示：" -ForegroundColor Cyan
        Write-Host "1. 先运行 '.\work-activity-monitor.ps1 Start' 启动监控"
        Write-Host "2. 正常工作，系统会自动记录"
        Write-Host "3. 再次运行此命令查看报告"
        Write-Host ""
        return
    }
    
    $activities = Import-Csv $logFile -Encoding UTF8
    
    if ($activities.Count -eq 0) {
        Write-Host "ℹ️  今日暂无活动记录" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # 统计分析
    $totalActivities = $activities.Count
    $uniqueFiles = ($activities | Select-Object File -Unique).Count
    $byProject = $activities | Group-Object -Property Project | Sort-Object Count -Descending
    $byFileType = $activities | Group-Object -Property FileType | Sort-Object Count -Descending
    $byChangeType = $activities | Group-Object -Property ChangeType
    
    Write-Host "📊 今日概览" -ForegroundColor Yellow
    Write-Host "  • 总活动数：$totalActivities 次" -ForegroundColor White
    Write-Host "  • 涉及文件：$uniqueFiles 个" -ForegroundColor White
    Write-Host "  • 活跃项目：$($byProject.Count) 个" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 活跃项目 TOP 5" -ForegroundColor Yellow
    for ($i = 0; $i -lt [Math]::Min(5, $byProject.Count); $i++) {
        $percent = [math]::Round(($byProject[$i].Count / $totalActivities) * 100, 1)
        Write-Host "  $($i + 1). $($byProject[$i].Name): $($byProject[$i].Count) 次 ($percent%)" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "📄 文件类型分布" -ForegroundColor Yellow
    for ($i = 0; $i -lt [Math]::Min(10, $byFileType.Count); $i++) {
        Write-Host "  • $($byFileType[$i].Name): $($byFileType[$i].Count) 次" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "🔄 变更类型" -ForegroundColor Yellow
    foreach ($change in $byChangeType) {
        Write-Host "  • $($change.Name): $($change.Count) 次" -ForegroundColor White
    }
    Write-Host ""
    
    # 生成 Markdown 报告
    $markdownContent = @"
# 工作活动报告 - $today

## 📊 今日概览
- **总活动数**: $totalActivities 次
- **涉及文件**: $uniqueFiles 个
- **活跃项目**: $($byProject.Count) 个

---

## 📁 活跃项目

"@
    
    foreach ($project in $byProject) {
        $projectActivities = $project.Group
        $percent = [math]::Round(($project.Count / $totalActivities) * 100, 1)
        
        $markdownContent += @"

### $($project.Name) ($percent%)
- **活动次数**: $($project.Count)
- **涉及文件**: $(($projectActivities | Select-Object File -Unique).Count) 个

**主要文件类型**:
"@
        
        $topFiles = $projectActivities | Group-Object -Property FileType | Sort-Object Count -Descending | Select-Object -First 5
        foreach ($fileType in $topFiles) {
            $markdownContent += "`n- $($fileType.Name): $($fileType.Count) 次"
        }
    }
    
    # 保存报告
    $reportFile = Join-Path $OutputPath "archive-db\file-monitor\reports\$today.md"
    $reportDir = Split-Path $reportFile -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $markdownContent | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host "✅ 详细报告已保存至：$reportFile" -ForegroundColor Green
    Write-Host ""
}

# 根据参数执行相应操作
switch ($Action) {
    "Start" { Start-Monitor }
    "Stop" { Stop-Monitor }
    "Status" { Get-MonitorStatus }
    "Report" { Get-Report }
}
