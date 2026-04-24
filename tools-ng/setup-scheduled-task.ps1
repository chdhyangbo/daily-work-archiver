# 定时任务设置脚本
# Setup Scheduled Tasks for Work Archiver

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "⏰ 设置定时任务 - Work Archiver" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置
$taskName = "LingmaWorkArchiver"
$toolsNgDir = "d:\work\ai\lingma\.lingma\skills\tools-ng"
$scriptPath = Join-Path $toolsNgDir "check-reminders.ps1"

# 步骤 1: 创建检查提醒的 PowerShell 脚本
Write-Host "📝 步骤 1: 创建提醒检查脚本..." -ForegroundColor Yellow

$checkScript = @'
# check-reminders.ps1
# 定时检查并发送提醒

$toolsNgDir = "d:\work\ai\lingma\.lingma\skills\tools-ng"
Set-Location $toolsNgDir

# 检查并发送提醒
npm run reminder -- -a check

# 生成提醒计划（如果有新目标）
npm run reminder -- -a schedule
'@

$scriptDir = $toolsNgDir
if (-not (Test-Path $scriptDir)) {
    New-Item -ItemType Directory -Force -Path $scriptDir | Out-Null
}

Set-Content -Path $scriptPath -Value $checkScript -Encoding UTF8
Write-Host "✅ 脚本已创建: $scriptPath" -ForegroundColor Green
Write-Host ""

# 步骤 2: 检查是否已存在同名任务
Write-Host "🔍 步骤 2: 检查现有任务..." -ForegroundColor Yellow
$existingTask = schtasks /Query /TN $taskName 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  任务 '$taskName' 已存在" -ForegroundColor Yellow
    $response = Read-Host "是否删除并重新创建？(y/n)"
    if ($response -eq 'y') {
        schtasks /Delete /TN $taskName /F
        Write-Host "✅ 旧任务已删除" -ForegroundColor Green
    } else {
        Write-Host "❌ 已取消" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "✅ 没有同名任务" -ForegroundColor Green
}
Write-Host ""

# 步骤 3: 创建定时任务
Write-Host "⏰ 步骤 3: 创建定时任务..." -ForegroundColor Yellow

# 创建每日 3 个时间点的触发器
$triggers = @(
    (New-ScheduledTaskTrigger -Daily -At "09:00"),
    (New-ScheduledTaskTrigger -Daily -At "14:00"),
    (New-ScheduledTaskTrigger -Daily -At "17:00")
)

# 任务配置
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WorkingDirectory $toolsNgDir

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false

# 使用当前用户运行
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

# 注册任务（使用第一个触发器）
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $triggers[0] `
    -Settings $settings `
    -Principal $principal `
    -Description "AI Work Archiver - 定时检查和发送目标提醒（每日 3 次：9:00, 14:00, 17:00）" `
    | Out-Null

# 添加额外的触发器
$task = Get-ScheduledTask -TaskName $taskName
$task.Triggers += $triggers[1]
$task.Triggers += $triggers[2]
$task | Set-ScheduledTask | Out-Null

Write-Host "✅ 定时任务已创建" -ForegroundColor Green
Write-Host ""

# 步骤 4: 验证任务
Write-Host "🔍 步骤 4: 验证任务..." -ForegroundColor Yellow
$taskInfo = schtasks /Query /TN $taskName /V /FO LIST 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 任务验证成功" -ForegroundColor Green
    Write-Host ""
    Write-Host "任务信息:" -ForegroundColor Cyan
    $taskInfo | Select-String "TaskName|Status|Trigger" | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "❌ 任务验证失败" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 定时任务设置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "任务名称: $taskName" -ForegroundColor White
Write-Host "执行时间: 每天 09:00, 14:00, 17:00" -ForegroundColor White
Write-Host "执行脚本: $scriptPath" -ForegroundColor White
Write-Host ""
Write-Host "手动测试:" -ForegroundColor Yellow
Write-Host "  powershell -File `"$scriptPath`"" -ForegroundColor Gray
Write-Host ""
Write-Host "查看任务:" -ForegroundColor Yellow
Write-Host "  schtasks /Query /TN `"$taskName`"" -ForegroundColor Gray
Write-Host ""
Write-Host "删除任务:" -ForegroundColor Yellow
Write-Host "  schtasks /Delete /TN `"$taskName`" /F" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
