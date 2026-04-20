[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Phase 5: Advanced Integrations
# Quick start script for all Phase 5 features

param(
    [switch]$ExportPDF,        # Export reports to PDF
    [switch]$GenerateCards,    # Generate achievement cards
    [switch]$TestNotify,       # Test notifications
    [switch]$Backup,           # Backup data
    [switch]$AnnualReport,     # Generate annual report
    [switch]$All,              # Run all features
    [string]$Action = "run"    # run, help
)

$scriptDir = $PSScriptRoot

function Show-Help {
    Write-Host "Phase 5: Advanced Integrations" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Features:" -ForegroundColor Yellow
    Write-Host "  -ExportPDF       Export reports to HTML (for PDF conversion)" -ForegroundColor White
    Write-Host "  -GenerateCards   Generate achievement share cards" -ForegroundColor White
    Write-Host "  -TestNotify      Test desktop notifications" -ForegroundColor White
    Write-Host "  -Backup          Backup all data" -ForegroundColor White
    Write-Host "  -AnnualReport    Generate annual report" -ForegroundColor White
    Write-Host "  -All             Run all features" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\run-phase5.ps1 -ExportPDF -ExportAllDaily" -ForegroundColor White
    Write-Host "  .\run-phase5.ps1 -GenerateCards -AchievementId FIRE" -ForegroundColor White
    Write-Host "  .\run-phase5.ps1 -Backup -Compress" -ForegroundColor White
    Write-Host "  .\run-phase5.ps1 -AnnualReport -Year 2026" -ForegroundColor White
}

# Main logic
if ($Action -eq "help" -or (-not $ExportPDF -and -not $GenerateCards -and -not $TestNotify -and -not $Backup -and -not $AnnualReport -and -not $All)) {
    Show-Help
    return
}

if ($All) {
    Write-Host "Running all Phase 5 features..." -ForegroundColor Yellow
    Write-Host ""
    
    # 1. Export PDFs
    Write-Host "[1/5] Exporting PDFs..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "pdf-exporter.ps1") -ExportAllDaily -ExportAllWeekly
    
    Write-Host ""
    
    # 2. Generate Achievement Cards
    Write-Host "[2/5] Generating achievement cards..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "achievement-image-generator.ps1")
    
    Write-Host ""
    
    # 3. Test Notifications
    Write-Host "[3/5] Testing notifications..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "notification-sender.ps1") -TestNotification
    
    Write-Host ""
    
    # 4. Backup Data
    Write-Host "[4/5] Backing up data..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "data-backup-restore.ps1") -Action backup -Compress
    
    Write-Host ""
    
    # 5. Annual Report
    Write-Host "[5/5] Generating annual report..." -ForegroundColor Cyan
    $currentYear = Get-Date -Format "yyyy"
    & (Join-Path $scriptDir "annual-report-generator.ps1") -Year $currentYear
    
    Write-Host ""
    Write-Host "All Phase 5 features completed!" -ForegroundColor Green
} else {
    if ($ExportPDF) {
        & (Join-Path $scriptDir "pdf-exporter.ps1") @args
    }
    if ($GenerateCards) {
        & (Join-Path $scriptDir "achievement-image-generator.ps1") @args
    }
    if ($TestNotify) {
        & (Join-Path $scriptDir "notification-sender.ps1") -TestNotification
    }
    if ($Backup) {
        & (Join-Path $scriptDir "data-backup-restore.ps1") @args
    }
    if ($AnnualReport) {
        & (Join-Path $scriptDir "annual-report-generator.ps1") @args
    }
}
