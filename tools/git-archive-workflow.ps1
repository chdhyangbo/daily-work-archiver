# Git Archive Workflow Orchestrator
# Git归档工作流编排器 - 自动触发所有依赖Git数据的脚本
# 用途：当Git归档完成后，自动运行日报、周报、质量分析等依赖脚本

param(
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [string]$GitDataDir = "$PSScriptRoot\..\work-archive\data\git-activities",
    [switch]$SkipGitArchive,    # 跳过Git归档（如果已手动运行）
    [switch]$QuickMode,         # 快速模式（只运行核心脚本）
    [switch]$FullMode           # 完整模式（运行所有脚本）
)

$toolsDir = $PSScriptRoot
$workArchiveDir = "$PSScriptRoot\..\work-archive"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git归档工作流编排器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "执行日期: $Date" -ForegroundColor Yellow
Write-Host "运行模式: $(if ($QuickMode) { '快速模式' } elseif ($FullMode) { '完整模式' } else { '标准模式' })" -ForegroundColor Yellow
Write-Host ""

# 记录执行开始时间
$startTime = Get-Date
$executedTools = @()
$failedTools = @()

# 辅助函数：运行单个工具
function Invoke-Tool {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$Arguments = @(),
        [string]$Category = "通用"
    )
    
    Write-Host ""
    Write-Host "[$Category] $Name" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Cyan
    
    $toolStartTime = Get-Date
    
    try {
        $fullPath = Join-Path $toolsDir $ScriptPath
        
        if (-not (Test-Path $fullPath)) {
            Write-Host "  ⚠ 脚本不存在: $ScriptPath" -ForegroundColor Yellow
            return $false
        }
        
        # 执行脚本
        if ($Arguments.Count -gt 0) {
            & $fullPath @Arguments 2>&1 | Out-Null
        } else {
            & $fullPath 2>&1 | Out-Null
        }
        
        $duration = ((Get-Date) - $toolStartTime).TotalSeconds
        Write-Host "  ✓ 完成 (耗时: $([Math]::Round($duration, 1))秒)" -ForegroundColor Green
        
        $executedTools += @{
            Name = $Name
            Category = $Category
            Duration = $duration
            Status = "Success"
        }
        
        return $true
    } catch {
        $duration = ((Get-Date) - $toolStartTime).TotalSeconds
        Write-Host "  ✗ 失败: $_" -ForegroundColor Red
        Write-Host "  (耗时: $([Math]::Round($duration, 1))秒)" -ForegroundColor Gray
        
        $failedTools += @{
            Name = $Name
            Category = $Category
            Duration = $duration
            Error = $_.Exception.Message
        }
        
        return $false
    }
}

# ============================================
# 工作流阶段 1: Git数据归档
# ============================================
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  阶段 1: Git数据归档                   ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

if (-not $SkipGitArchive) {
    Invoke-Tool "Git活动数据归档" "git-activity-aggregator.ps1" @(
        "-Date", $Date
    ) "Git归档"
} else {
    Write-Host "  ⏭ 跳过Git归档（已手动运行）" -ForegroundColor Yellow
}

# 验证Git数据是否生成
$gitDataFile = Join-Path $GitDataDir "$Date.json"
if (Test-Path $gitDataFile) {
    Write-Host "  ✓ Git数据文件已生成: $gitDataFile" -ForegroundColor Green
} else {
    Write-Host "  ⚠ 未找到Git数据文件，后续脚本可能受影响" -ForegroundColor Yellow
}

# ============================================
# 工作流阶段 2: 核心报告生成（必运行）
# ============================================
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  阶段 2: 核心报告生成                  ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

Invoke-Tool "日报生成" "daily-report-enhanced.ps1" @(
    "-Date", $Date
) "核心报告"

# ============================================
# 工作流阶段 3: 质量与分析（标准模式）
# ============================================
if (-not $QuickMode) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  阶段 3: 质量与分析                    ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

    Invoke-Tool "提交质量评分" "commit-quality-scorer.ps1" @() "质量分析"
    
    Invoke-Tool "提交分类统计" "commit-classifier.ps1" @(
        "-Today"
    ) "质量分析"
    
    Invoke-Tool "工作模式分析" "work-pattern-analyzer.ps1" @() "质量分析"
}

# ============================================
# 工作流阶段 4: 周报/月报（周末/月末运行）
# ============================================
$dayOfWeek = (Get-Date).DayOfWeek
$isFriday = ($dayOfWeek -eq [DayOfWeek]::Friday)
$isMonthEnd = (Get-Date).Day -ge 28

if ($isFriday -or $FullMode) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  阶段 4: 周期报告                      ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
    
    if ($isFriday) {
        Write-Host "  检测到今天是周五，自动生成周报..." -ForegroundColor Yellow
    }
    
    Invoke-Tool "周报生成" "weekly-report-enhanced.ps1" @() "周期报告"
}

if ($isMonthEnd -or $FullMode) {
    if ($isMonthEnd) {
        Write-Host "  检测到今天是月末，自动生成月报..." -ForegroundColor Yellow
    }
    
    Invoke-Tool "月报仪表板" "monthly-dashboard.ps1" @() "周期报告"
}

# ============================================
# 工作流阶段 5: 高级分析（完整模式）
# ============================================
if ($FullMode) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  阶段 5: 高级分析                      ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

    Invoke-Tool "变更影响分析" "change-impact-analyzer.ps1" @() "高级分析"
    
    Invoke-Tool "项目健康监控" "project-health-monitor.ps1" @() "高级分析"
    
    Invoke-Tool "智能工作建议" "work-advisor.ps1" @() "高级分析"
    
    Invoke-Tool "个人成长追踪" "growth-tracker.ps1" @() "高级分析"
    
    Invoke-Tool "时间优化助手" "time-optimizer.ps1" @() "高级分析"
}

# ============================================
# 工作流阶段 6: 仪表板与成就（标准模式）
# ============================================
if (-not $QuickMode) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  阶段 6: 仪表板与成就                  ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

    Invoke-Tool "仪表板数据生成" "generate-dashboard-data.ps1" @() "仪表板"
    
    Invoke-Tool "成就系统更新" "achievement-system-core.ps1" @(
        "-Action", "check"
    ) "仪表板"
    
    Invoke-Tool "数据API更新" "data-dashboard-api.ps1" @() "仪表板"
}

# ============================================
# 工作流阶段 7: 报告汇总（标准模式）
# ============================================
if (-not $QuickMode) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  阶段 7: 报告汇总                      ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta

    Invoke-Tool "智能报告摘要" "smart-report-summarizer.ps1" @(
        "-ReportType", "daily"
    ) "报告汇总"
}

# ============================================
# 执行总结
# ============================================
$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  执行完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "总耗时: $([Math]::Round($totalDuration, 1)) 秒" -ForegroundColor Yellow
Write-Host ""
Write-Host "执行统计:" -ForegroundColor Cyan
Write-Host "  ✓ 成功: $($executedTools.Count) 个脚本" -ForegroundColor Green
Write-Host "  ✗ 失败: $($failedTools.Count) 个脚本" -ForegroundColor Red
Write-Host ""

if ($executedTools.Count -gt 0) {
    Write-Host "已执行脚本列表:" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Cyan
    
    $executedTools | ForEach-Object {
        Write-Host "  ✓ [$($_.Category)] $($_.Name) - $([Math]::Round($_.Duration, 1))秒" -ForegroundColor Green
    }
}

if ($failedTools.Count -gt 0) {
    Write-Host ""
    Write-Host "失败脚本列表:" -ForegroundColor Red
    Write-Host ("-" * 60) -ForegroundColor Red
    
    $failedTools | ForEach-Object {
        Write-Host "  ✗ [$($_.Category)] $($_.Name)" -ForegroundColor Red
        Write-Host "    错误: $($_.Error)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "数据输出位置:" -ForegroundColor Cyan
Write-Host "  📁 Git活动数据: $GitDataDir" -ForegroundColor Gray
Write-Host "  📁 日报: $(Join-Path $workArchiveDir 'daily-reports')" -ForegroundColor Gray
Write-Host "  📁 周报: $(Join-Path $workArchiveDir 'weekly-reports')" -ForegroundColor Gray
Write-Host "  📁 质量数据: $(Join-Path $workArchiveDir 'data/commit-quality')" -ForegroundColor Gray
Write-Host "  📁 仪表板数据: $(Join-Path $workArchiveDir 'data/dashboard-data.json')" -ForegroundColor Gray
Write-Host ""

# 保存执行日志
$logDir = Join-Path $workArchiveDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir "workflow-$Date.log"
$logContent = @"
工作流执行日志 - $Date
执行时间: $startTime
总耗时: $([Math]::Round($totalDuration, 1)) 秒

成功脚本 ($($executedTools.Count)):
$($executedTools | ForEach-Object { "  ✓ [$($_.Category)] $($_.Name) - $([Math]::Round($_.Duration, 1))秒" })

失败脚本 ($($failedTools.Count)):
$($failedTools | ForEach-Object { "  ✗ [$($_.Category)] $($_.Name) - $($_.Error)" })
"@

$logContent | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "📄 执行日志已保存: $logFile" -ForegroundColor Gray
Write-Host ""
