# System Notification Handler
# Sends desktop notifications for achievements and milestones

param(
    [string]$Title = "",
    [string]$Message = "",
    [string]$Type = "info",  # info, success, warning, achievement
    [switch]$TestNotification
)

function Show-BalloonNotification($title, $message, $type = "info") {
    Add-Type -AssemblyName System.Windows.Forms
    
    $icon = switch ($type) {
        "success" { [System.Windows.Forms.ToolTipIcon]::Info }
        "warning" { [System.Windows.Forms.ToolTipIcon]::Warning }
        "achievement" { [System.Windows.Forms.ToolTipIcon]::Info }
        default { [System.Windows.Forms.ToolTipIcon]::Info }
    }
    
    $balloon = New-Object System.Windows.Forms.NotifyIcon
    $balloon.Icon = [System.Drawing.SystemIcons]::Information
    $balloon.BalloonTipIcon = $icon
    $balloon.BalloonTipTitle = $title
    $balloon.BalloonTipText = $message
    $balloon.Visible = $true
    $balloon.ShowBalloonTip(5000)
    
    # Hide after 5 seconds
    Start-Sleep -Seconds 5
    $balloon.Dispose()
}

function Show-ToastNotification($title, $message, $type = "info") {
    # Windows 10/11 toast notification using BurntToast module
    try {
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast -ErrorAction SilentlyContinue
            
            $toastConfig = @{
                Text = $title, $message
                AppLogo = ""
            }
            
            if ($type -eq "achievement") {
                $toastConfig['AppId'] = 'AI Work Archiver - Achievement'
            }
            
            New-BurntToastNotification @toastConfig
            Write-Host "Toast notification sent" -ForegroundColor Green
        } else {
            Write-Host "BurntToast module not installed. Using balloon notification." -ForegroundColor Yellow
            Show-BalloonNotification $title $message $type
        }
    } catch {
        Show-BalloonNotification $title $message $type
    }
}

# Main logic
if ($TestNotification) {
    Write-Host "Testing notification..." -ForegroundColor Yellow
    
    Show-ToastNotification "Test Notification" "This is a test message from AI Work Archiver" "info"
    
    Start-Sleep -Seconds 2
    
    Show-ToastNotification "Achievement Unlocked!" "You earned: 3-Day Streak (+15 points)" "achievement"
    
    Write-Host "Notifications sent!" -ForegroundColor Green
} elseif ($Title -and $Message) {
    Show-ToastNotification $Title $Message $Type
    Write-Host "Notification sent: $Title" -ForegroundColor Green
} else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\notification-sender.ps1 -TestNotification" -ForegroundColor White
    Write-Host "  .\notification-sender.ps1 -Title 'Title' -Message 'Message'" -ForegroundColor White
    Write-Host "  .\notification-sender.ps1 -Title 'Title' -Message 'Message' -Type achievement" -ForegroundColor White
}
