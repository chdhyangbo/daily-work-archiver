# Achievement Card Generator
# 生成可分享的成就卡片（HTML+CSS格式）

param(
    [string]$AchievementData = "",
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\achievement-cards"),
    [string]$AchievementType = "all"
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Generate-AchievementCard {
    param(
        [hashtable]$Achievement,
        [string]$OutputDir
    )

    $title = $Achievement.title
    $description = $Achievement.description
    $icon = $Achievement.icon
    $unlockedAt = $Achievement.unlockedAt
    $points = $Achievement.points
    $level = $Achievement.level

    # 根据等级选择颜色
    $bgColor = switch ($level) {
        "legendary" { "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }
        "epic" { "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)" }
        "rare" { "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)" }
        "common" { "linear-gradient(135deg, #43e97b 0%, #38f9d 100%)" }
        default { "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }
    }

    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .card {
            width: 400px;
            min-height: 300px;
            background: $bgColor;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            color: white;
        }
        .header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }
        .icon {
            font-size: 48px;
            margin-right: 15px;
        }
        .title {
            font-size: 24px;
            font-weight: bold;
        }
        .description {
            font-size: 16px;
            margin-bottom: 20px;
            line-height: 1.6;
        }
        .stats {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
        }
        .stat {
            text-align: center;
        }
        .stat-value {
            font-size: 28px;
            font-weight: bold;
        }
        .stat-label {
            font-size: 12px;
            opacity: 0.9;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.3);
            font-size: 12px;
            text-align: center;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <div class="icon">$icon</div>
            <div class="title">$title</div>
        </div>
        <div class="description">$description</div>
        <div class="stats">
            <div class="stat">
                <div class="stat-value">$points</div>
                <div class="stat-label">POINTS</div>
            </div>
            <div class="stat">
                <div class="stat-value">$level</div>
                <div class="stat-label">LEVEL</div>
            </div>
            <div class="stat">
                <div class="stat-value">$unlockedAt</div>
                <div class="stat-label">UNLOCKED</div>
            </div>
        </div>
        <div class="footer">
            AI Work Archiver - Achievement System
        </div>
    </div>
</body>
</html>
"@

    $fileName = "$title-$(Get-Date -Format 'yyyyMMddHHmmss').html"
    $outputFile = Join-Path $OutputDir $fileName
    $htmlContent | Out-File $outputFile -Encoding UTF8

    return $outputFile
}

function Load-Achievements {
    param(
        [string]$AchievementData,
        [string]$AchievementType
    )

    $achievements = @()

    # 从成就系统加载
    $achievementFile = Join-Path $PSScriptRoot "..\work-archive\data\achievements.json"
    if (Test-Path $achievementFile) {
        $data = Get-Content $achievementFile | ConvertFrom-Json
        foreach ($ach in $data) {
            if ($AchievementType -eq "all" -or $ach.type -eq $AchievementType) {
                if ($ach.unlocked) {
                    $achievements += @{
                        title = $ach.name
                        description = $ach.description
                        icon = $ach.icon
                        unlockedAt = $ach.unlockedAt
                        points = $ach.points
                        level = $ach.level
                    }
                }
            }
        }
    }

    # 如果没有成就数据，生成示例成就
    if ($achievements.Count -eq 0) {
        $achievements += @{
            title = "First Commit"
            description = "完成第一次Git提交，开启代码之旅！"
            icon = "🚀"
            unlockedAt = Get-Date -Format "yyyy-MM-dd"
            points = 10
            level = "common"
        }
        $achievements += @{
            title = "100 Commits"
            description = "累计完成100次提交，坚持不懈！"
            icon = "🏆"
            unlockedAt = Get-Date -Format "yyyy-MM-dd"
            points = 100
            level = "epic"
        }
        $achievements += @{
            title = "Quality Master"
            description = "提交质量平均分超过85分，代码质量大师！"
            icon = "⭐"
            unlockedAt = Get-Date -Format "yyyy-MM-dd"
            points = 50
            level = "rare"
        }
    }

    return $achievements
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Achievement Card Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Loading achievements..." -ForegroundColor Yellow
$achievements = Load-Achievements -AchievementData $AchievementData -AchievementType $AchievementType

if ($achievements.Count -eq 0) {
    Write-Host "No unlocked achievements found." -ForegroundColor Yellow
    exit
}

Write-Host "Generating cards for $($achievements.Count) achievements..." -ForegroundColor Yellow
Write-Host ""

$generatedCards = @()
foreach ($achievement in $achievements) {
    Write-Host "Generating: $($achievement.title)" -ForegroundColor White
    $outputFile = Generate-AchievementCard -Achievement $achievement -OutputDir $OutputDir
    $generatedCards += $outputFile
    Write-Host "  Saved to: $outputFile" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Cards Generated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Total cards: $($generatedCards.Count)" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view cards, open the HTML files in your browser." -ForegroundColor Yellow
