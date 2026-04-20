# Phase 4 Quick Start
# One-click startup script for Phase 4

param(
    [switch]$Dashboard,     # Start dashboard
    [switch]$Achievements,  # Check achievements
    [switch]$All,           # Run all
    [switch]$ServerOnly,    # Start server only
    [switch]$GenerateOnly,  # Generate data only
    [switch]$Status         # Check status
)

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = $PSScriptRoot
$docsServerDir = Join-Path (Join-Path $scriptDir "..") "docs-server"

function Start-DocsServer {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "[Phase 4] Starting Documentation Server..." -ForegroundColor Cyan
    
    # 检查是否已在运行
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3456/" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "[OK] Server already running!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Access URLs:" -ForegroundColor Cyan
            Write-Host "  Unified Center: http://localhost:3456/overview" -ForegroundColor Yellow
            Write-Host "  Dashboard: http://localhost:3456/dashboard" -ForegroundColor Yellow
            Write-Host "  Documents: http://localhost:3456/" -ForegroundColor Yellow
            Write-Host ""
            return
        }
    } catch {
        # Server not running, continue to start
    }
    
    # 生成仪表板数据
    Write-Host "Generating dashboard data..." -ForegroundColor Yellow
    & (Join-Path $scriptDir "generate-dashboard-data.ps1")
    
    # 启动服务器
    Set-Location $docsServerDir
    Start-Process -FilePath "node" -ArgumentList "server.js" -WindowStyle Hidden
    
    Start-Sleep -Seconds 3
    
    # 验证服务器是否启动
    $started = $false
    for ($i = 0; $i -lt 5; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3456/" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $started = $true
                break
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Host "" -ForegroundColor Yellow
    if ($started) {
        Write-Host "[OK] Server started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Access URLs:" -ForegroundColor Cyan
        Write-Host "  Unified Center: http://localhost:3456/overview" -ForegroundColor Yellow
        Write-Host "  Dashboard: http://localhost:3456/dashboard" -ForegroundColor Yellow
        Write-Host "  Documents: http://localhost:3456/" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press Ctrl+C in the server window to stop." -ForegroundColor Gray
    } else {
        Write-Host "[WARN] Server may not have started properly" -ForegroundColor Red
        Write-Host "Try running: cd $docsServerDir; node server.js" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Stop-DocsServer {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "[Phase 4] Stopping Documentation Server..." -ForegroundColor Yellow
    
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -match "server\.js" 
    }
    
    if ($processes) {
        $processes | Stop-Process -Force
        Write-Host "[OK] Server stopped" -ForegroundColor Green
    } else {
        Write-Host "Server not running" -ForegroundColor Gray
    }
}

function Check-Achievements {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "[Phase 4] Checking Achievements..." -ForegroundColor Cyan
    try {
        & (Join-Path $scriptDir "achievement-system-core.ps1") -Action check 2>&1 | Out-Null
        Write-Host "[OK] Achievements checked" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Achievement check skipped" -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "[Phase 4] System Status" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # 检查服务器状态
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -match "server\.js" 
    }
    
    if ($processes) {
        Write-Host "Doc Server: [RUNNING]" -ForegroundColor Green
        Write-Host "URL: http://localhost:3456/dashboard" -ForegroundColor Green
    } else {
        Write-Host "Doc Server: [NOT RUNNING]" -ForegroundColor Red
    }
    
    # 检查成就数据
    $achievementFile = Join-Path $scriptDir "..\work-archive\data\achievements\achievements.json"
    if (Test-Path $achievementFile) {
        $data = Get-Content $achievementFile | ConvertFrom-Json
        Write-Host "Achievement Data: [UPDATED] ($($data.lastCheck))" -ForegroundColor Green
        Write-Host "Level: $($data.level.current.name)" -ForegroundColor Yellow
        Write-Host "Points: $($data.achievements.totalPoints)" -ForegroundColor Yellow
    } else {
        Write-Host "Achievement Data: [NOT GENERATED]" -ForegroundColor Red
    }
    
    # 检查仪表板数据
    $dashboardFile = Join-Path $docsServerDir "public\dashboard-data.json"
    if (Test-Path $dashboardFile) {
        $data = Get-Content $dashboardFile | ConvertFrom-Json
        Write-Host "Dashboard Data: [UPDATED] ($($data.generatedAt))" -ForegroundColor Green
    } else {
        Write-Host "Dashboard Data: [NOT GENERATED]" -ForegroundColor Red
    }
}

# Main logic
if ($Status) {
    Show-Status
} else {
    if ($Dashboard) {
        Start-DocsServer
    }
    if ($Achievements) {
        Check-Achievements
    }
    if ($All) {
        # Skip achievements to avoid blocking, just start server
        Start-DocsServer
    }
    if ($GenerateOnly) {
        Write-Host "Generating dashboard data..." -ForegroundColor Yellow
        & (Join-Path $scriptDir "generate-dashboard-data.ps1")
    }
    if ($ServerOnly) {
        Start-DocsServer
    }
    if (-not $Dashboard -and -not $Achievements -and -not $All -and -not $GenerateOnly -and -not $ServerOnly -and -not $Status) {
        Start-DocsServer
    }
}
