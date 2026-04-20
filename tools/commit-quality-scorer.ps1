# Git Commit Quality Scorer
param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\commit-quality"),
    [int]$DaysBack = 365
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Calculate-CommitQuality {
    param(
        [string]$Subject,
        [string]$Message,
        [int]$Changed,
        [string]$Type
    )

    $score = 50
    $details = @()

    # Length check
    $msgLength = if ($Message) { $Message.Length } else { $Subject.Length }
    if ($msgLength -ge 10 -and $msgLength -le 100) {
        $score += 15
        $details += "Length OK"
    } elseif ($msgLength -gt 100) {
        $score += 10
        $details += "Long msg"
    } elseif ($msgLength -ge 5) {
        $score += 5
        $details += "Short"
    } else {
        $details += "Too short"
    }

    # Format check
    $hasType = $false
    $typeWords = "feat","fix","docs","style","refactor","test","chore","perf","新增","修复","优化","重构","文档"
    foreach ($word in $typeWords) {
        if ($Subject.ToLower().Contains($word.ToLower())) {
            $hasType = $true
            break
        }
    }
    if ($hasType) {
        $score += 20
        $details += "Has type"
    } else {
        $details += "No type"
    }

    # Ticket check - use simple Contains instead of regex
    $hasTicket = $false
    $words = $Subject.Split("-")
    foreach ($word in $words) {
        if ($word -match "^\d+$" -and $Subject -match "[A-Z]") {
            $hasTicket = $true
            break
        }
    }
    if (-not $hasTicket -and $Subject.Contains("#")) {
        $hasTicket = $true
    }
    if ($hasTicket) {
        $score += 15
        $details += "Has ticket"
    } else {
        $details += "No ticket"
    }

    # Change size check
    if ($Changed -gt 0 -and $Changed -le 500) {
        $score += 10
        $details += "Size OK"
    } elseif ($Changed -gt 500 -and $Changed -le 2000) {
        $score += 5
        $details += "Large"
    } elseif ($Changed -gt 2000) {
        $score += 0
        $details += "Too large"
    } else {
        $score += 5
        $details += "Minor"
    }

    # Type scoring
    $typeScores = @{
        "FEATURE" = 8
        "FIX" = 10
        "REFACTOR" = 7
        "DOCS" = 6
        "TEST" = 9
        "OTHER" = 5
    }
    if ($typeScores.ContainsKey($Type)) {
        $score += $typeScores[$Type]
    }

    $score = [Math]::Max(0, [Math]::Min(100, $score))

    $level = "D"
    if ($score -ge 90) { $level = "S" }
    elseif ($score -ge 80) { $level = "A" }
    elseif ($score -ge 70) { $level = "B" }
    elseif ($score -ge 60) { $level = "C" }

    return @{
        score = $score
        level = $level
        details = $details -join ", "
    }
}

function Process-AllCommits {
    param(
        [string]$ActivitiesDir,
        [string]$OutputDir
    )

    if (-not (Test-Path $ActivitiesDir)) {
        Write-Host "Error: Activities dir not found" -ForegroundColor Red
        return
    }

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }

    if ($activityFiles.Count -eq 0) {
        Write-Host "No activity data found" -ForegroundColor Yellow
        return
    }

    Write-Host "Processing $($activityFiles.Count) files..." -ForegroundColor Cyan

    $allScores = @()
    $projectScores = @{}
    $typeScores = @{}
    $dailyScores = @{}

    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $date = $data.date

        foreach ($commit in $data.commits) {
            $quality = Calculate-CommitQuality -Subject $commit.subject -Message $commit.message -Changed $commit.changed -Type $commit.type

            $scoreEntry = [PSCustomObject]@{
                hash = $commit.shortHash
                date = $commit.date
                project = $commit.project
                subject = $commit.subject
                type = $commit.type
                changed = $commit.changed
                score = $quality.score
                level = $quality.level
                details = $quality.details
            }

            $allScores += $scoreEntry

            if (-not $projectScores.ContainsKey($commit.project)) {
                $projectScores[$commit.project] = @{ total = 0; count = 0 }
            }
            $projectScores[$commit.project].total += $quality.score
            $projectScores[$commit.project].count++

            if (-not $typeScores.ContainsKey($commit.type)) {
                $typeScores[$commit.type] = @{ total = 0; count = 0 }
            }
            $typeScores[$commit.type].total += $quality.score
            $typeScores[$commit.type].count++

            if (-not $dailyScores.ContainsKey($date)) {
                $dailyScores[$date] = @{ total = 0; count = 0 }
            }
            $dailyScores[$date].total += $quality.score
            $dailyScores[$date].count++
        }
    }

    # Save scores
    $scoresFile = Join-Path $OutputDir "commit-scores.json"
    $allScores | ConvertTo-Json -Depth 3 | Out-File $scoresFile -Encoding UTF8

    # Top 20
    $topCommits = $allScores | Sort-Object score -Descending | Select-Object -First 20
    $topFile = Join-Path $OutputDir "top-commits.json"
    $topCommits | ConvertTo-Json -Depth 3 | Out-File $topFile -Encoding UTF8

    # Project report
    $projectReport = @()
    foreach ($project in $projectScores.Keys) {
        $avg = [Math]::Round($projectScores[$project].total / $projectScores[$project].count, 1)
        $projectReport += @{
            project = $project
            avgScore = $avg
            commitCount = $projectScores[$project].count
        }
    }
    $projectReport = $projectReport | Sort-Object avgScore -Descending
    $projectFile = Join-Path $OutputDir "project-quality.json"
    $projectReport | ConvertTo-Json -Depth 3 | Out-File $projectFile -Encoding UTF8

    # Type report
    $typeReport = @()
    foreach ($type in $typeScores.Keys) {
        $avg = [Math]::Round($typeScores[$type].total / $typeScores[$type].count, 1)
        $typeReport += @{
            type = $type
            avgScore = $avg
            commitCount = $typeScores[$type].count
        }
    }
    $typeReport = $typeReport | Sort-Object avgScore -Descending
    $typeFile = Join-Path $OutputDir "type-quality.json"
    $typeReport | ConvertTo-Json -Depth 3 | Out-File $typeFile -Encoding UTF8

    # Daily trend
    $dailyTrend = @()
    $sortedDates = $dailyScores.Keys | Sort-Object
    foreach ($date in $sortedDates) {
        $avg = [Math]::Round($dailyScores[$date].total / $dailyScores[$date].count, 1)
        $dailyTrend += @{
            date = $date
            avgScore = $avg
            commitCount = $dailyScores[$date].count
        }
    }
    $trendFile = Join-Path $OutputDir "quality-trend.json"
    $dailyTrend | ConvertTo-Json -Depth 3 | Out-File $trendFile -Encoding UTF8

    # Summary
    $totalCommits = $allScores.Count
    $avgScore = [Math]::Round(($allScores | Measure-Object score -Average).Average, 1)
    $levelDistribution = @{
        S = ($allScores | Where-Object { $_.level -eq "S" }).Count
        A = ($allScores | Where-Object { $_.level -eq "A" }).Count
        B = ($allScores | Where-Object { $_.level -eq "B" }).Count
        C = ($allScores | Where-Object { $_.level -eq "C" }).Count
        D = ($allScores | Where-Object { $_.level -eq "D" }).Count
    }

    $topProj = "None"
    if ($projectReport.Count -gt 0) {
        $topProj = $projectReport[0].project
    }
    $bestTyp = "None"
    if ($typeReport.Count -gt 0) {
        $bestTyp = $typeReport[0].type
    }

    $summary = @{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        totalCommits = $totalCommits
        averageScore = $avgScore
        levelDistribution = $levelDistribution
        topProject = $topProj
        bestType = $bestTyp
    }

    $summaryFile = Join-Path $OutputDir "quality-summary.json"
    $summary | ConvertTo-Json -Depth 3 | Out-File $summaryFile -Encoding UTF8

    return @{
        allScores = $allScores
        summary = $summary
        topCommits = $topCommits
        projectReport = $projectReport
        typeReport = $typeReport
        dailyTrend = $dailyTrend
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git Commit Quality Scorer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scoring commits..." -ForegroundColor Yellow
$result = Process-AllCommits -ActivitiesDir $ActivitiesDir -OutputDir $OutputDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total: $($result.summary.totalCommits)" -ForegroundColor White
Write-Host "  Average: $($result.summary.averageScore)/100" -ForegroundColor White
Write-Host ""
Write-Host "Levels:" -ForegroundColor Cyan
Write-Host "  S: $($result.summary.levelDistribution.S)" -ForegroundColor White
Write-Host "  A: $($result.summary.levelDistribution.A)" -ForegroundColor White
Write-Host "  B: $($result.summary.levelDistribution.B)" -ForegroundColor White
Write-Host "  C: $($result.summary.levelDistribution.C)" -ForegroundColor White
Write-Host "  D: $($result.summary.levelDistribution.D)" -ForegroundColor White
Write-Host ""
Write-Host "Top Projects:" -ForegroundColor Cyan
$result.projectReport | Select-Object -First 5 | ForEach-Object {
    $pName = $_.project
    $pScore = $_.avgScore
    $pCount = $_.commitCount
    Write-Host "  $pName : $pScore ($pCount)" -ForegroundColor White
}
Write-Host ""
Write-Host "Saved to: $OutputDir" -ForegroundColor Green
