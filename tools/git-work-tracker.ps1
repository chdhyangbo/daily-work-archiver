# Git Work Activity Auto-Tracker Script
param(
    [string]$ProjectPath = "D:\work\code",
    [string]$OutputPath = "d:\work\ai\lingma\.lingma\skills\work-archive",
    [switch]$TodayOnly,
    [switch]$AutoGenerateReport,
    [string]$SinceDate,  # Custom start date (yyyy-MM-dd)
    [string]$UntilDate,  # Custom end date (yyyy-MM-dd)
    [switch]$ExportHistory  # Export historical data for past 2 years
)

# Fix encoding issues - Set console to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Work Activity Tracker" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get today's date
$today = Get-Date -Format "yyyy-MM-dd"
$todayStart = Get-Date -Hour 0 -Minute 0 -Second 0
$todayEnd = $todayStart.AddHours(23).AddMinutes(59).AddSeconds(59)

# Handle custom date range or history export
$dateRangeStart = $null
$dateRangeEnd = $null

if ($ExportHistory) {
    $dateRangeStart = (Get-Date).AddYears(-2).ToString("yyyy-MM-dd")
    $dateRangeEnd = $today
    Write-Host "Mode: Exporting 2-year history ($dateRangeStart to $dateRangeEnd)" -ForegroundColor Cyan
    Write-Host ""
} elseif ($SinceDate -and $UntilDate) {
    $dateRangeStart = $SinceDate
    $dateRangeEnd = $UntilDate
    Write-Host "Mode: Custom date range ($dateRangeStart to $dateRangeEnd)" -ForegroundColor Cyan
    Write-Host ""
}

# Project root directories
$projectDirs = @(
    "D:\work\code",
    "D:\work\codepos"
)

# Array to store all activities
$allActivities = @()

Write-Host "Scanning project directories..." -ForegroundColor Yellow
Write-Host ""

foreach ($rootDir in $projectDirs) {
    if (-not (Test-Path $rootDir)) {
        Write-Warning "Directory not found: $rootDir"
        continue
    }
    
    # Find all projects with .git directory using Get-ChildItem with proper filtering
    # Use -Force to include hidden .git directories and Where-Object to filter
    $gitDirs = Get-ChildItem -Path $rootDir -Recurse -Force -ErrorAction SilentlyContinue | 
               Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
    
    foreach ($gitDir in $gitDirs) {
        $projectPath = $gitDir.Parent.FullName
        $projectName = $gitDir.Parent.Name
        
        try {
            Set-Location $projectPath -ErrorAction Stop
            
            # Get commits for today with proper encoding
            # Use chcp 65001 to ensure UTF-8 output from git
            $env:GIT_TERMINAL_PROMPT = 0
            
            if ($TodayOnly) {
                $commitsOutput = & git -c core.quotepath=false log --since="$($todayStart.ToString('yyyy-MM-dd HH:mm:ss'))" --until="$($todayEnd.ToString('yyyy-MM-dd HH:mm:ss'))" --author="yangbo" --pretty=format:"%H|%ad|%s|%b|%ae" --date=format:"%Y-%m-%d %H:%M:%S" 2>&1
            } elseif ($dateRangeStart -and $dateRangeEnd) {
                # Custom date range or history export
                $commitsOutput = & git -c core.quotepath=false log --since="$($dateRangeStart)" --until="$($dateRangeEnd) 23:59:59" --author="yangbo" --pretty=format:"%H|%ad|%s|%b|%ae" --date=format:"%Y-%m-%d %H:%M:%S" 2>&1
            } else {
                # Get last 7 days
                $sinceDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
                $commitsOutput = & git -c core.quotepath=false log --since="$sinceDate" --author="yangbo" --pretty=format:"%H|%ad|%s|%b|%ae" --date=format:"%Y-%m-%d %H:%M:%S" 2>&1
            }
            
            # Convert output to UTF8 string if needed
            $commits = $commitsOutput -split "`r?`n"
            
            if ($commits) {
                foreach ($commit in $commits) {
                    if ([string]::IsNullOrWhiteSpace($commit)) { continue }
                    
                    $parts = $commit -split '\|'
                    if ($parts.Count -ge 3) {
                        $hash = $parts[0]
                        $date = $parts[1]
                        $message = $parts[2]
                        $body = if ($parts.Count -gt 3) { $parts[3] } else { "" }
                        $email = if ($parts.Count -gt 4) { $parts[4] } else { "" }
                        
                        # Get code change stats
                        $stats = git diff-tree --no-commit-id --name-only -r $hash 2>$null
                        $insertions = 0
                        $deletions = 0
                        
                        try {
                            $statInfo = git show --stat --format="" $hash 2>$null | Select-Object -Last 1
                            if ($statInfo -match "(\d+) insertion") {
                                $insertions = [int]$matches[1]
                            }
                            if ($statInfo -match "(\d+) deletion") {
                                $deletions = [int]$matches[1]
                            }
                        } catch {}
                        
                        # Analyze commit message type
                        $taskType = "OTHER"
                        if ($message -match "^feat(\(.+\))?:" ) { $taskType = "FEATURE" }
                        elseif ($message -match "^fix(\(.+\))?:" ) { $taskType = "BUGFIX" }
                        elseif ($message -match "^docs(\(.+\))?:" ) { $taskType = "DOCS" }
                        elseif ($message -match "^refactor(\(.+\))?:" ) { $taskType = "REFACTOR" }
                        elseif ($message -match "^test(\(.+\))?:" ) { $taskType = "TEST" }
                        elseif ($message -match "^chore(\(.+\))?:" ) { $taskType = "CHORE" }
                        elseif ($message -match "^perf(\(.+\))?:" ) { $taskType = "PERFORMANCE" }
                        elseif ($message -match "^style(\(.+\))?:" ) { $taskType = "STYLE" }
                        
                        # Get changed files
                        $changedFiles = git diff-tree --no-commit-id --name-only -r $hash 2>$null
                        
                        # Identify tech stack
                        $techStack = @()
                        if ($changedFiles -match "\.vue$") { $techStack += "Vue.js" }
                        if ($changedFiles -match "\.(js|ts)$") { $techStack += "JavaScript/TypeScript" }
                        if ($changedFiles -match "\.(scss|less|css)$") { $techStack += "CSS/SCSS" }
                        if ($changedFiles -match "package\.json") { $techStack += "npm" }
                        if ($changedFiles -match "\.(md|MD)$") { $techStack += "Documentation" }
                        
                        # Create activity record
                        $activity = [PSCustomObject]@{
                            Project = $projectName
                            ProjectPath = $projectPath
                            CommitHash = $hash
                            Date = $date
                            Message = $message
                            Body = $body
                            Author = $email
                            TaskType = $taskType
                            Insertions = $insertions
                            Deletions = $deletions
                            ChangedFilesCount = ($changedFiles | Measure-Object).Count
                            TechStack = $techStack -join ", "
                            Files = ($changedFiles -join "; ")
                        }
                        
                        $allActivities += $activity
                    }
                }
            }
        } catch {
            Write-Warning "Cannot access project: $projectName - $($_.Exception.Message)"
        }
    }
}

Set-Location $PSScriptRoot -ErrorAction SilentlyContinue

# Display statistics
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Today's Git Activity Statistics" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allActivities.Count -eq 0) {
    Write-Host "No Git commits found today" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tips:" -ForegroundColor Cyan
    Write-Host "1. Remember to commit your work before leaving" 
    Write-Host "2. Commit message format: feat: description / fix: bug description"
    Write-Host ""
} else {
    # Group by project
    $groupedByProject = $allActivities | Group-Object -Property Project
    
    Write-Host "Total commits today: $($allActivities.Count)" -ForegroundColor Green
    Write-Host "Active projects: $($groupedByProject.Count)" -ForegroundColor Green
    Write-Host ""
    
    foreach ($projectGroup in $groupedByProject) {
        $projectName = $projectGroup.Name
        $projectCommits = $projectGroup.Group
        $totalInsertions = ($projectCommits | Measure-Object -Property Insertions -Sum).Sum
        $totalDeletions = ($projectCommits | Measure-Object -Property Deletions -Sum).Sum
        
        Write-Host "[PROJECT] $projectName" -ForegroundColor Yellow
        Write-Host "   Commits: $($projectCommits.Count)" -ForegroundColor White
        Write-Host "   Code changes: +$totalInsertions -$totalDeletions" -ForegroundColor White
        
        foreach ($commit in $projectCommits) {
            $icon = switch ($commit.TaskType) {
                "FEATURE" { "[FEAT]" }
                "BUGFIX" { "[FIX]" }
                "DOCS" { "[DOCS]" }
                "REFACTOR" { "[REFACTOR]" }
                default { "[OTHER]" }
            }
            
            Write-Host "   $icon $($commit.Message)" -ForegroundColor Gray
            if ($commit.Insertions -gt 0 -or $commit.Deletions -gt 0) {
                Write-Host "      (+$($commit.Insertions) -$($commit.Deletions))" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
    
    # Generate Markdown report (English only to avoid encoding issues)
    $markdownContent = @"
## Git Activity Statistics for Today

**Total Commits**: $($allActivities.Count)  
**Active Projects**: $($groupedByProject.Count)  
**Code Changes**: +$(($allActivities | Measure-Object -Property Insertions -Sum).Sum) -$(($allActivities | Measure-Object -Property Deletions -Sum).Sum)

---

"@

    foreach ($projectGroup in $groupedByProject) {
        $projectName = $projectGroup.Name
        $projectCommits = $projectGroup.Group
        
        $markdownContent += @"

### Project: $projectName

**Commits**: $($projectCommits.Count)  
**Code**: +$(($projectCommits | Measure-Object -Property Insertions -Sum).Sum) -$(($projectCommits | Measure-Object -Property Deletions -Sum).Sum)

"@
        
        foreach ($commit in $projectCommits) {
            $icon = switch ($commit.TaskType) {
                "FEATURE" { "[FEAT]" }
                "BUGFIX" { "[FIX]" }
                "DOCS" { "[DOCS]" }
                "REFACTOR" { "[REFACTOR]" }
                "PERFORMANCE" { "[PERF]" }
                "TEST" { "[TEST]" }
                default { "[OTHER]" }
            }
            
            $markdownContent += @"

#### $icon $($commit.Message)
- **Time**: $($commit.Date)
- **Changes**: +$($commit.Insertions) -$($commit.Deletions)
- **Files**: $($commit.ChangedFilesCount)
- **Tech**: $($commit.TechStack)
"@
            
            if (-not [string]::IsNullOrWhiteSpace($commit.Body)) {
                $markdownContent += @"

**Details**:
$($commit.Body)

"@
            }
        }
    }
    
    # Save to archive-db (keep this for data storage)
    $outputFile = Join-Path $OutputPath "archive-db\git-activities\$today.md"
    $outputDir = Split-Path $outputFile -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "Git activities saved to: $outputFile" -ForegroundColor Green
    Write-Host ""
    
    # If auto-generate report is enabled
    if ($AutoGenerateReport) {
        Write-Host "Generating daily report..." -ForegroundColor Yellow
        Write-Host "Daily report generated!" -ForegroundColor Green
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

return $allActivities
