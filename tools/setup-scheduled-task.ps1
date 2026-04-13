# Auto-Generate Daily Report Script
# This script creates a scheduled task to automatically generate daily reports at 6:00 PM every workday

param(
    [switch]$Uninstall  # Remove the scheduled task
)

$taskName = "Auto Daily Report Generator"
$scriptPath = "d:\work\ai\lingma\.lingma\skills\tools\git-work-tracker.ps1"
$logPath = "d:\work\ai\lingma\.lingma\skills\work-archive\logs"

# Create log directory if not exists
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

if ($Uninstall) {
    # Uninstall the scheduled task
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Uninstalling Scheduled Task..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host "Scheduled task removed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "The auto daily report generation has been disabled." -ForegroundColor Yellow
        Write-Host "You can re-enable it anytime by running: .\setup-scheduled-task.ps1" -ForegroundColor Gray
    } catch {
        Write-Host "Scheduled task not found or removal failed." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
} else {
    # Install the scheduled task
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Setting Up Scheduled Task" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  Task Name: $taskName" -ForegroundColor White
    Write-Host "  Schedule: Monday-Friday at 6:00 PM" -ForegroundColor White
    Write-Host "  Script: $scriptPath" -ForegroundColor White
    Write-Host ""
    
    # Create the action
    $action = New-ScheduledTaskAction `
        -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -TodayOnly -AutoGenerateReport"
    
    # Create the trigger (Monday to Friday at 6:00 PM)
    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday `
        -At 6pm
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -WakeToRun
    
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "Task already exists. Updating..." -ForegroundColor Yellow
        
        # Update the existing task
        Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null
        
        Write-Host "Scheduled task updated successfully!" -ForegroundColor Green
    } else {
        # Register new task
        try {
            Register-ScheduledTask `
                -TaskName $taskName `
                -Action $action `
                -Trigger $trigger `
                -Settings $settings `
                -Description "Automatically generates daily work report by scanning Git commits from all projects" `
                -ErrorAction Stop
            
            Write-Host "Scheduled task created successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to create scheduled task." -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
            Write-Host "Tip: Run PowerShell as Administrator to create scheduled tasks." -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host ""
    Write-Host "What happens now:" -ForegroundColor Yellow
    Write-Host "  Every weekday at 6:00 PM, the system will:" -ForegroundColor White
    Write-Host "    1. Scan all Git repositories in D:\work\code and D:\work\codepos" -ForegroundColor Gray
    Write-Host "    2. Collect today's commits from all projects" -ForegroundColor Gray
    Write-Host "    3. Generate a comprehensive daily report" -ForegroundColor Gray
    Write-Host "    4. Save the report to your archive" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Next scheduled run:" -ForegroundColor Yellow
    $nextRun = (Get-Date).Date.AddHours(18)
    if ((Get-Date) -gt $nextRun) {
        $nextRun = $nextRun.AddDays(1)
        if ($nextRun.DayOfWeek -eq [DayOfWeek]::Saturday) {
            $nextRun = $nextRun.AddDays(2)
        } elseif ($nextRun.DayOfWeek -eq [DayOfWeek]::Sunday) {
            $nextRun = $nextRun.AddDays(1)
        }
    }
    Write-Host "  $nextRun" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Manual commands:" -ForegroundColor Yellow
    Write-Host "  Generate report now: .\git-work-tracker.ps1 -TodayOnly" -ForegroundColor Cyan
    Write-Host "  Disable auto-report: .\setup-scheduled-task.ps1 -Uninstall" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
