# Time Tracker
# 时间追踪脚本

param(
    [string]$Action = "status",  # start, stop, status, report
    [string]$Project = "",
    [string]$Task = "",
    [string]$Type = "coding"  # coding, meeting, learning, review
)

$dataDir = Join-Path $PSScriptRoot ".." "work-archive" "data" "time-tracking"
$currentSessionFile = Join-Path $dataDir ".current-session.json"

# 确保目录存在
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

# 获取今日数据文件
function Get-TodayFile {
    $date = Get-Date -Format "yyyy-MM-dd"
    return Join-Path $dataDir "$date.json"
}

# 加载今日数据
function Load-TodayData {
    $file = Get-TodayFile
    if (Test-Path $file) {
        return Get-Content $file | ConvertFrom-Json
    }
    return @{ sessions = @() }
}

# 保存今日数据
function Save-TodayData($data) {
    $file = Get-TodayFile
    $data | ConvertTo-Json -Depth 10 | Out-File $file -Encoding UTF8
}

# 开始计时
function Start-Timer($project, $task, $type) {
    # 检查是否有正在进行的会话
    if (Test-Path $currentSessionFile) {
        $current = Get-Content $currentSessionFile | ConvertFrom-Json
        $duration = ([DateTime]::Now - [DateTime]::Parse($current.startTime)).TotalMinutes
        Write-Host "⚠️ 已有进行中的会话: $($current.project) - $($current.task) ($([Math]::Round($duration))分钟)" -ForegroundColor Yellow
        Write-Host "请先停止当前会话" -ForegroundColor Yellow
        return
    }
    
    $session = @{
        project = $project
        task = $task
        type = $type
        startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $session | ConvertTo-Json | Out-File $currentSessionFile -Encoding UTF8
    Write-Host "⏱️ 开始计时: $project - $task [$type]" -ForegroundColor Green
}

# 停止计时
function Stop-Timer {
    if (-not (Test-Path $currentSessionFile)) {
        Write-Host "❌ 没有进行中的计时会话" -ForegroundColor Red
        return
    }
    
    $current = Get-Content $currentSessionFile | ConvertFrom-Json
    $endTime = Get-Date
    $startTime = [DateTime]::Parse($current.startTime)
    $duration = ($endTime - $startTime).TotalMinutes
    
    $session = @{
        project = $current.project
        task = $current.task
        type = $current.type
        startTime = $current.startTime
        endTime = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
        duration = [Math]::Round($duration)
    }
    
    $data = Load-TodayData
    $data.sessions += $session
    Save-TodayData $data
    
    Remove-Item $currentSessionFile
    Write-Host "✅ 停止计时: $($current.project) - $($current.task)" -ForegroundColor Green
    Write-Host "   时长: $([Math]::Round($duration)) 分钟" -ForegroundColor Gray
}

# 显示状态
function Show-Status {
    $data = Load-TodayData
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  今日时间追踪 ($(Get-Date -Format 'yyyy-MM-dd'))" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 显示进行中的会话
    if (Test-Path $currentSessionFile) {
        $current = Get-Content $currentSessionFile | ConvertFrom-Json
        $duration = ([DateTime]::Now - [DateTime]::Parse($current.startTime)).TotalMinutes
        Write-Host "🔄 进行中: $($current.project) - $($current.task)" -ForegroundColor Yellow
        Write-Host "   已进行: $([Math]::Round($duration)) 分钟" -ForegroundColor Gray
        Write-Host ""
    }
    
    # 统计今日会话
    if ($data.sessions.Count -eq 0) {
        Write-Host "今日暂无记录" -ForegroundColor Gray
    } else {
        Write-Host "今日记录:" -ForegroundColor Yellow
        
        $typeSummary = @{}
        $projectSummary = @{}
        $totalMinutes = 0
        
        foreach ($session in $data.sessions) {
            $hours = [Math]::Floor($session.duration / 60)
            $mins = $session.duration % 60
            $timeStr = if ($hours -gt 0) { "${hours}h ${mins}m" } else { "${mins}m" }
            
            Write-Host "  ✅ $($session.project) - $($session.task) [$($session.type)] - $timeStr" -ForegroundColor White
            
            # 统计
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
        
        # 显示总计
        $totalHours = [Math]::Round($totalMinutes / 60, 1)
        Write-Host ""
        Write-Host "总计: $totalHours 小时" -ForegroundColor Green
        
        # 按类型统计
        Write-Host ""
        Write-Host "按类型统计:" -ForegroundColor Yellow
        foreach ($type in $typeSummary.Keys) {
            $hours = [Math]::Round($typeSummary[$type] / 60, 1)
            $icon = switch ($type) {
                "coding" { "💻" }
                "meeting" { "🗣️" }
                "learning" { "📚" }
                "review" { "👀" }
                default { "📝" }
            }
            Write-Host "  $icon $type`: $hours 小时" -ForegroundColor White
        }
        
        # 按项目统计
        Write-Host ""
        Write-Host "按项目统计:" -ForegroundColor Yellow
        foreach ($project in $projectSummary.Keys) {
            $hours = [Math]::Round($projectSummary[$project] / 60, 1)
            Write-Host "  📁 $project`: $hours 小时" -ForegroundColor White
        }
    }
    
    Write-Host ""
}

# 生成日报片段
function Generate-Report {
    $data = Load-TodayData
    
    if ($data.sessions.Count -eq 0) {
        return ""
    }
    
    $typeSummary = @{}
    $projectSummary = @{}
    $totalMinutes = 0
    
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
    
    $totalHours = [Math]::Round($totalMinutes / 60, 1)
    
    $report = @"

## ⏰ 时间分配
| 项目 | 时长 | 占比 |
|------|------|------|
"@
    
    foreach ($project in $projectSummary.Keys | Sort-Object { $projectSummary[$_] } -Descending) {
        $hours = [Math]::Round($projectSummary[$project] / 60, 1)
        $percent = [Math]::Round(($projectSummary[$project] / $totalMinutes) * 100)
        $report += "`n| $project | ${hours}h | ${percent}% |"
    }
    
    $report += "`n\n**总计**: $totalHours 小时\n"
    
    return $report
}

# 主逻辑
switch ($Action) {
    "start" {
        if (-not $Project -or -not $Task) {
            Write-Host "用法: .\time-tracker.ps1 -Action start -Project '项目名' -Task '任务名' [-Type coding]" -ForegroundColor Yellow
            return
        }
        Start-Timer $Project $Task $Type
    }
    "stop" {
        Stop-Timer
    }
    "status" {
        Show-Status
    }
    "report" {
        Write-Host (Generate-Report)
    }
    default {
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  .\time-tracker.ps1 -Action start -Project '项目名' -Task '任务名'" -ForegroundColor White
        Write-Host "  .\time-tracker.ps1 -Action stop" -ForegroundColor White
        Write-Host "  .\time-tracker.ps1 -Action status" -ForegroundColor White
        Write-Host "  .\time-tracker.ps1 -Action report" -ForegroundColor White
    }
}
