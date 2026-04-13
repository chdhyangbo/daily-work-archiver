# 自动工作记录 - 一键启动脚本
# 功能：快速启用 Git 监控和文件监控

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🚀 自动工作记录系统 - 快速配置" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$toolsPath = "d:\work\ai\lingma\.lingma\skills\tools"
$quickStartPath = "d:\work\ai\lingma\.lingma\skills\AUTO-TRACKING-QUICKSTART.md"

Write-Host "📋 三种自动化方案，请选择：" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] Git 监控（最简单，推荐首选）" -ForegroundColor White
Write-Host "      ✅ 零配置，正常写代码即可" -ForegroundColor Gray
Write-Host "      ✅ 下班前运行一次，自动生成日报" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] 文件监控（增强版，双保险）" -ForegroundColor White
Write-Host "      ✅ 实时监控所有文件变化" -ForegroundColor Gray
Write-Host "      ✅ 包含未提交的代码" -ForegroundColor Gray
Write-Host "      ✅ 了解时间分配" -ForegroundColor Gray
Write-Host ""
Write-Host "  [3] 混合模式（最强大，完全体）" -ForegroundColor White
Write-Host "      ✅ Git + 文件监控双重保障" -ForegroundColor Gray
Write-Host "      ✅ 最完整的工作记录" -ForegroundColor Gray
Write-Host "      ✅ 智能分析和报告" -ForegroundColor Gray
Write-Host ""
Write-Host "  [4] 查看详细说明文档" -ForegroundColor White
Write-Host ""
Write-Host "  [5] 退出" -ForegroundColor White
Write-Host ""

$choice = Read-Host "请输入选项 (1-5)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  方案 A: Git 监控" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "💡 使用说明:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "每天下班前运行以下命令:" -ForegroundColor White
        Write-Host "  cd $toolsPath" -ForegroundColor Cyan
        Write-Host "  .\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "就这么简单！系统会:" -ForegroundColor Yellow
        Write-Host "  1. 扫描今天所有 Git 提交" -ForegroundColor White
        Write-Host "  2. 自动分析项目和任务类型" -ForegroundColor White
        Write-Host "  3. 生成完整的日报" -ForegroundColor White
        Write-Host ""
        
        Write-Host "🎯 现在就试试？" -ForegroundColor Yellow
        $run = Read-Host "是否立即运行 Git 扫描？(y/n)"
        
        if ($run -eq "y" -or $run -eq "Y") {
            Set-Location $toolsPath
            & .\git-work-tracker.ps1 -TodayOnly
        }
        
        Write-Host ""
        Write-Host "✅ 配置完成！" -ForegroundColor Green
        Write-Host ""
        Write-Host "记住命令:" -ForegroundColor Yellow
        Write-Host "  cd $toolsPath" -ForegroundColor Cyan
        Write-Host "  .\git-work-tracker.ps1 -TodayOnly" -ForegroundColor Cyan
        Write-Host ""
    }
    
    "2" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  方案 B: 文件监控" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "💡 使用说明:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "早上到公司:" -ForegroundColor White
        Write-Host "  cd $toolsPath" -ForegroundColor Cyan
        Write-Host "  .\work-activity-monitor.ps1 Start" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "下班前查看报告:" -ForegroundColor White
        Write-Host "  .\work-activity-monitor.ps1 Report" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "离开公司时停止:" -ForegroundColor White
        Write-Host "  .\work-activity-monitor.ps1 Stop" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "🎯 现在就启动监控？" -ForegroundColor Yellow
        $start = Read-Host "是否立即启动文件监控？(y/n)"
        
        if ($start -eq "y" -or $start -eq "Y") {
            Set-Location $toolsPath
            & .\work-activity-monitor.ps1 Start
        }
        
        Write-Host ""
        Write-Host "✅ 配置完成！" -ForegroundColor Green
        Write-Host ""
        Write-Host "记住命令:" -ForegroundColor Yellow
        Write-Host "  启动：.\work-activity-monitor.ps1 Start" -ForegroundColor Cyan
        Write-Host "  报告：.\work-activity-monitor.ps1 Report" -ForegroundColor Cyan
        Write-Host "  停止：.\work-activity-monitor.ps1 Stop" -ForegroundColor Cyan
        Write-Host ""
    }
    
    "3" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  方案 C: 混合模式（Git + 文件监控）" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "💡 最佳实践:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "早上到公司 (9:00):" -ForegroundColor White
        Write-Host "  .\work-activity-monitor.ps1 Start" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "下班前 (18:00):" -ForegroundColor White
        Write-Host "  .\work-activity-monitor.ps1 Report" -ForegroundColor Cyan
        Write-Host "  .\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "离开公司:" -ForegroundColor White
        Write-Host "  .\work-activity-monitor.ps1 Stop" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "🎯 立即配置？" -ForegroundColor Yellow
        $setup = Read-Host "是否立即设置混合模式？(y/n)"
        
        if ($setup -eq "y" -or $setup -eq "Y") {
            Write-Host ""
            Write-Host "步骤 1/2: 启动文件监控..." -ForegroundColor Yellow
            Set-Location $toolsPath
            & .\work-activity-monitor.ps1 Start
            
            Write-Host ""
            Write-Host "步骤 2/2: 扫描 Git 活动..." -ForegroundColor Yellow
            & .\git-work-tracker.ps1 -TodayOnly
            
            Write-Host ""
            Write-Host "✅ 混合模式已启动！" -ForegroundColor Green
            Write-Host ""
        }
        
        Write-Host ""
        Write-Host "记住命令:" -ForegroundColor Yellow
        Write-Host "  早上：.\work-activity-monitor.ps1 Start" -ForegroundColor Cyan
        Write-Host "  晚上：.\work-activity-monitor.ps1 Report" -ForegroundColor Cyan
        Write-Host "         .\git-work-tracker.ps1 -TodayOnly" -ForegroundColor Cyan
        Write-Host ""
    }
    
    "4" {
        Write-Host ""
        Write-Host "正在打开详细说明文档..." -ForegroundColor Yellow
        Write-Host ""
        
        if (Test-Path $quickStartPath) {
            Invoke-Item $quickStartPath
            Write-Host "✅ 已打开详细说明文档" -ForegroundColor Green
        } else {
            Write-Host "❌ 文档不存在：$quickStartPath" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
    "5" {
        Write-Host ""
        Write-Host "👋 再见！随时可以重新运行此脚本进行配置" -ForegroundColor Cyan
        Write-Host ""
    }
    
    default {
        Write-Host ""
        Write-Host "❌ 无效的选项，请重新运行脚本" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 返回到原始目录
Set-Location $PSScriptRoot
