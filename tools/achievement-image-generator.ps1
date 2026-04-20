# Achievement Image Generator
# Creates shareable achievement cards as HTML

param(
    [string]$AchievementId = "",
    [string]$OutputPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "work-archive") "exports")
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$AchievementData = @{
    SEED = @{
        name = "Initial Commit"
        description = "First code commit completed"
        icon = "SEED"
        color = "#27ae60"
        points = 10
    }
    SEEDLING = @{
        name = "Getting Started"
        description = "10 commits milestone reached"
        icon = "SEEDLING"
        color = "#2ecc71"
        points = 20
    }
    TREE = @{
        name = "Code Craftsman"
        description = "100 commits milestone achieved"
        icon = "TREE"
        color = "#16a085"
        points = 50
    }
    TROPHY = @{
        name = "Code Master"
        description = "1000 commits - Legendary status"
        icon = "TROPHY"
        color = "#f39c12"
        points = 200
    }
    FIRE = @{
        name = "3-Day Streak"
        description = "3 consecutive days of commits"
        icon = "FIRE"
        color = "#e74c3c"
        points = 15
    }
    LIGHTNING = @{
        name = "Week Warrior"
        description = "7 consecutive days of commits"
        icon = "LIGHTNING"
        color = "#e67e22"
        points = 30
    }
    TARGET = @{
        name = "Multi-tasker"
        description = "Contributed to 3+ projects"
        icon = "TARGET"
        color = "#3498db"
        points = 30
    }
}

function Generate-AchievementCard($achievementId, $outputPath) {
    $achievement = $AchievementData[$achievementId]
    
    if (-not $achievement) {
        Write-Host "Achievement not found: $achievementId" -ForegroundColor Red
        Write-Host "Available: $($AchievementData.Keys -join ', ')" -ForegroundColor Gray
        return $null
    }
    
    $fileName = "$($achievementId)-achievement-card.html"
    $outputFile = Join-Path $outputPath $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        .card {
            width: 600px;
            background: linear-gradient(135deg, $($achievement.color) 0%, $($achievement.color)dd 100%);
            border-radius: 20px;
            padding: 50px 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            color: white;
            text-align: center;
        }
        .icon {
            font-size: 80px;
            margin-bottom: 20px;
            filter: drop-shadow(0 4px 8px rgba(0,0,0,0.2));
        }
        .achievement-label {
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 3px;
            opacity: 0.9;
            margin-bottom: 10px;
        }
        .achievement-name {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 15px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .achievement-description {
            font-size: 18px;
            opacity: 0.95;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .points-badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 10px 30px;
            border-radius: 50px;
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 30px;
            border: 2px solid rgba(255,255,255,0.3);
        }
        .footer {
            font-size: 12px;
            opacity: 0.8;
            margin-top: 20px;
        }
        .date {
            font-size: 14px;
            opacity: 0.9;
            margin-bottom: 10px;
        }
        .divider {
            width: 60px;
            height: 3px;
            background: rgba(255,255,255,0.5);
            margin: 20px auto;
            border-radius: 2px;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">$($achievement.icon)</div>
        <div class="achievement-label">Achievement Unlocked</div>
        <div class="achievement-name">$($achievement.name)</div>
        <div class="divider"></div>
        <div class="achievement-description">$($achievement.description)</div>
        <div class="points-badge">+ $($achievement.points) Points</div>
        <div class="date">Unlocked: $(Get-Date -Format "yyyy-MM-dd")</div>
        <div class="divider"></div>
        <div class="footer">
            AI Work Archiver | Personal Development Tracker
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File $outputFile -Encoding UTF8
    
    Write-Host "Achievement card generated: $outputFile" -ForegroundColor Green
    return $outputFile
}

function Generate-AllCards($outputPath) {
    $generatedFiles = @()
    
    foreach ($achievementId in $AchievementData.Keys) {
        $file = Generate-AchievementCard $achievementId $outputPath
        if ($file) {
            $generatedFiles += $file
        }
    }
    
    return $generatedFiles
}

# Main logic
Write-Host "Achievement Card Generator" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if ($AchievementId) {
    Generate-AchievementCard $AchievementId $OutputPath
} else {
    Write-Host "`nGenerating all achievement cards..." -ForegroundColor Yellow
    $files = Generate-AllCards $OutputPath
    Write-Host "Generated $($files.Count) achievement cards" -ForegroundColor Green
    Write-Host "`nFiles saved to: $OutputPath" -ForegroundColor Gray
    Write-Host "`nTo use:" -ForegroundColor Yellow
    Write-Host "1. Open HTML file in browser" -ForegroundColor Gray
    Write-Host "2. Take screenshot or print to PDF" -ForegroundColor Gray
    Write-Host "3. Share on social media!" -ForegroundColor Gray
}
