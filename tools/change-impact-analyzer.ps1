# Change Impact Analyzer - Analyze code change impact

param(
    [string]$ActivitiesDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\change-impact"),
    [string]$OutputFile = ""
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $OutputDir "impact-analysis.json"
}

function Analyze-Impact {
    param(
        [string]$ActivitiesDir
    )

    $activityFiles = Get-ChildItem -Path $ActivitiesDir -Filter "*.json" | Where-Object { $_.Name -ne "activity-index.json" }
    if ($activityFiles.Count -eq 0) { return @{} }
    
    $commitImpacts = @()
    $projectImpact = @{}
    $highRiskCommits = @()
    
    foreach ($file in $activityFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        
        foreach ($commit in $data.commits) {
            $changed = $commit.changed
            $type = $commit.type
            
            # Calculate impact score (0-100)
            $impactScore = 0
            
            # Size factor (0-40)
            if ($changed -le 50) { $impactScore += 10 }
            elseif ($changed -le 200) { $impactScore += 20 }
            elseif ($changed -le 500) { $impactScore += 30 }
            elseif ($changed -le 1000) { $impactScore += 35 }
            else { $impactScore += 40 }
            
            # Type factor (0-30)
            $typeImpact = @{
                "FIX" = 25
                "FEATURE" = 20
                "REFACTOR" = 30
                "DOCS" = 10
                "TEST" = 15
                "OTHER" = 20
            }
            if ($typeImpact.ContainsKey($type)) {
                $impactScore += $typeImpact[$type]
            }
            
            # Time factor (0-30) - commits during work hours less risky
            $hour = $commit.hour
            if ($hour -ge 9 -and $hour -le 17) {
                $impactScore += 15
            } else {
                $impactScore += 25  # Higher risk outside work hours
            }
            
            # Risk level
            $riskLevel = "Low"
            if ($impactScore -ge 80) { $riskLevel = "Critical" }
            elseif ($impactScore -ge 60) { $riskLevel = "High" }
            elseif ($impactScore -ge 40) { $riskLevel = "Medium" }
            
            $impactEntry = [ordered]@{
                hash = $commit.shortHash
                date = $commit.date
                project = $commit.project
                subject = $commit.subject
                type = $type
                changed = $changed
                hour = $hour
                impactScore = $impactScore
                riskLevel = $riskLevel
            }
            
            $commitImpacts += $impactEntry
            
            if ($riskLevel -eq "Critical" -or $riskLevel -eq "High") {
                $highRiskCommits += $impactEntry
            }
            
            # Project impact aggregation
            if (-not $projectImpact.ContainsKey($commit.project)) {
                $projectImpact[$commit.project] = @{
                    totalCommits = 0
                    avgImpact = 0
                    highRiskCount = 0
                    totalImpact = 0
                }
            }
            $projectImpact[$commit.project].totalCommits++
            $projectImpact[$commit.project].totalImpact += $impactScore
            if ($riskLevel -eq "Critical" -or $riskLevel -eq "High") {
                $projectImpact[$commit.project].highRiskCount++
            }
        }
    }
    
    # Calculate project averages
    foreach ($project in $projectImpact.Keys) {
        $p = $projectImpact[$project]
        $p.avgImpact = [Math]::Round($p.totalImpact / $p.totalCommits, 1)
    }
    
    return [ordered]@{
        commitImpacts = $commitImpacts
        highRiskCommits = $highRiskCommits
        projectImpact = $projectImpact
        summary = [ordered]@{
            totalCommits = $commitImpacts.Count
            highRiskCount = $highRiskCommits.Count
            avgImpactScore = [Math]::Round(($commitImpacts | Measure-Object impactScore -Average).Average, 1)
        }
    }
}

function Generate-ImpactReport {
    param(
        [hashtable]$Impact,
        [string]$OutputFile
    )
    
    $report = [ordered]@{
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        summary = $Impact.summary
        highRiskCommits = $Impact.highRiskCommits | Select-Object -First 20
        projectImpact = $Impact.projectImpact
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Change Impact Analyzer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Analyzing changes..." -ForegroundColor Yellow
$impact = Analyze-Impact -ActivitiesDir $ActivitiesDir

Write-Host "Generating report..." -ForegroundColor Yellow
$report = Generate-ImpactReport -Impact $impact -OutputFile $OutputFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Impact Analysis Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total commits: $($report.summary.totalCommits)" -ForegroundColor White
Write-Host "  High risk commits: $($report.summary.highRiskCount)" -ForegroundColor Red
Write-Host "  Average impact: $($report.summary.avgImpactScore)/100" -ForegroundColor White
Write-Host ""
Write-Host "High Risk Commits (Top 5):" -ForegroundColor Cyan
$report.highRiskCommits | Select-Object -First 5 | ForEach-Object {
    Write-Host "  [$($_.riskLevel)] $($_.subject)" -ForegroundColor Red
    Write-Host "    Impact: $($_.impactScore), Changed: $($_.changed)" -ForegroundColor Yellow
    Write-Host ""
}
Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
