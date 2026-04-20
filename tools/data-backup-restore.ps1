# Data Backup and Restore Tool
# Backs up and restores work archive data

param(
    [string]$Action = "backup",  # backup, restore, list
    [string]$BackupDir = "",
    [switch]$Compress
)

$ArchiveBasePath = Join-Path (Join-Path $PSScriptRoot "..") "work-archive"

if (-not $BackupDir) {
    $BackupDir = Join-Path $ArchiveBasePath "backups"
}

function Backup-Data($backupDir, $compress) {
    Write-Host "Starting backup..." -ForegroundColor Yellow
    
    # Create timestamped backup folder
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $backupDir "backup_$timestamp"
    
    if (-not (Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    }
    
    $items = @(
        "daily-reports",
        "weekly-reports",
        "monthly-reports",
        "archive-db",
        "data"
    )
    
    $backedUpCount = 0
    
    foreach ($item in $items) {
        $sourcePath = Join-Path $ArchiveBasePath $item
        
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $backupPath $item
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            $backedUpCount++
            Write-Host "  Backed up: $item" -ForegroundColor Green
        }
    }
    
    # Create backup manifest
    $manifest = @{
        timestamp = $timestamp
        items = $items
        count = $backedUpCount
        compress = $compress
    }
    
    $manifestFile = Join-Path $backupPath "backup-manifest.json"
    $manifest | ConvertTo-Json | Out-File $manifestFile -Encoding UTF8
    
    # Compress if requested
    if ($compress) {
        $zipFile = "$backupPath.zip"
        Write-Host "Compressing backup..." -ForegroundColor Yellow
        Compress-Archive -Path $backupPath -DestinationPath $zipFile -Force
        Write-Host "Compressed to: $zipFile" -ForegroundColor Green
        return $zipFile
    }
    
    return $backupPath
}

function Restore-Data($backupPath) {
    Write-Host "Starting restore from: $backupPath" -ForegroundColor Yellow
    
    if (-not (Test-Path $backupPath)) {
        Write-Host "Backup not found: $backupPath" -ForegroundColor Red
        return
    }
    
    # Handle zip files
    if ($backupPath -match "\.zip$") {
        $extractPath = Join-Path $env:TEMP "work-archive-restore"
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        Expand-Archive -Path $backupPath -DestinationPath $extractPath
        
        # Find the actual backup folder
        $folders = Get-ChildItem -Path $extractPath -Directory
        if ($folders.Count -gt 0) {
            $backupPath = $folders[0].FullName
        }
    }
    
    $items = @(
        "daily-reports",
        "weekly-reports",
        "monthly-reports",
        "archive-db",
        "data"
    )
    
    $restoredCount = 0
    
    foreach ($item in $items) {
        $sourcePath = Join-Path $backupPath $item
        $destPath = Join-Path $ArchiveBasePath $item
        
        if (Test-Path $sourcePath) {
            if (Test-Path $destPath) {
                # Ask for confirmation
                Write-Host "  $destPath already exists. Overwriting..." -ForegroundColor Yellow
                Remove-Item $destPath -Recurse -Force
            }
            
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            $restoredCount++
            Write-Host "  Restored: $item" -ForegroundColor Green
        }
    }
    
    Write-Host "`nRestore complete! $restoredCount items restored." -ForegroundColor Green
}

function List-Backups($backupDir) {
    Write-Host "Available Backups" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    if (-not (Test-Path $backupDir)) {
        Write-Host "No backups found in: $backupDir" -ForegroundColor Yellow
        return
    }
    
    $backups = Get-ChildItem -Path $backupDir -Directory | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "No backups found" -ForegroundColor Yellow
        return
    }
    
    foreach ($backup in $backups) {
        $manifestFile = Join-Path $backup.FullName "backup-manifest.json"
        
        if (Test-Path $manifestFile) {
            $manifest = Get-Content $manifestFile | ConvertFrom-Json
            $size = (Get-ChildItem $backup.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [Math]::Round($size / 1MB, 2)
            
            Write-Host "Backup: $($backup.Name)" -ForegroundColor White
            Write-Host "  Date: $($manifest.timestamp)" -ForegroundColor Gray
            Write-Host "  Items: $($manifest.count)" -ForegroundColor Gray
            Write-Host "  Size: $sizeMB MB" -ForegroundColor Gray
            Write-Host "  Path: $($backup.FullName)" -ForegroundColor Gray
            Write-Host ""
        }
    }
}

# Main logic
switch ($Action) {
    "backup" {
        Write-Host "Backup Tool" -ForegroundColor Cyan
        Write-Host "===========" -ForegroundColor Cyan
        $result = Backup-Data $BackupDir $Compress
        Write-Host "`nBackup completed: $result" -ForegroundColor Green
    }
    "restore" {
        Write-Host "Restore Tool" -ForegroundColor Cyan
        Write-Host "============" -ForegroundColor Cyan
        
        if ($BackupDir -match "backup_") {
            Restore-Data $BackupDir
        } else {
            # List backups and ask user to choose
            List-Backups $BackupDir
            Write-Host "`nSpecify backup path with -BackupDir parameter" -ForegroundColor Yellow
        }
    }
    "list" {
        List-Backups $BackupDir
    }
}
