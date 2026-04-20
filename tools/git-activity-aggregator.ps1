# Git Activities Aggregator
param(
    [string[]]$ProjectPaths = @("D:\work\code", "D:\work\codepos"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\work-archive\data\git-activities"),
    [string]$Author = "yangbo",
    [int]$DaysBack = 365
)

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Collect-GitActivities {
    param(
        [string[]]$ProjectPaths,
        [string]$Author,
        [int]$DaysBack
    )
    
    $allActivities = @()
    $since = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-dd")
    
    foreach ($rootPath in $ProjectPaths) {
        if (-not (Test-Path $rootPath)) { continue }
        
        Write-Host "Scanning: $rootPath" -ForegroundColor Cyan
        
        $gitDirs = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -and $_.Name -eq ".git" }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $projectName = $gitDir.Parent.Name
            
            Write-Host "  Project: $projectName" -ForegroundColor Gray
            
            Set-Location $projectPath -ErrorAction SilentlyContinue
            
            try {
                $commits = & git -c core.quotepath=false log --since="$since" --author="$Author" --pretty=format:"%H|%ad|%an|%s" --date=format:"%Y-%m-%d %H:%M:%S" --no-merges 2>$null
                
                if ($commits) {
                    $commitList = $commits -split "`n" | Where-Object { $_ }
                    
                    foreach ($commit in $commitList) {
                        $parts = $commit.Split("|", 4)
                        if ($parts.Count -lt 4) { continue }
                        
                        $hash = $parts[0]
                        $dateTime = $parts[1]
                        $author = $parts[2]
                        $subject = $parts[3]
                        $date = $dateTime.Split(" ")[0]
                        $time = $dateTime.Split(" ")[1]
                        $hour = [int]$time.Split(":")[0]
                        
                        $statInfo = & git show --stat --format="" $hash 2>$null | Select-Object -Last 1
                        $insertions = 0
                        $deletions = 0
                        
                        if ($statInfo -match "(\d+) insertion") { $insertions = [int]$Matches[1] }
                        if ($statInfo -match "(\d+) deletion") { $deletions = [int]$Matches[1] }
                        
                        $type = "OTHER"
                        $lowerSubject = $subject.ToLower()
                        if ($lowerSubject -match "feat|新增|添加|实现|feature") { $type = "FEATURE" }
                        elseif ($lowerSubject -match "fix|修复|解决|bug|fixed") { $type = "FIX" }
                        elseif ($lowerSubject -match "refactor|重构") { $type = "REFACTOR" }
                        elseif ($lowerSubject -match "docs|文档") { $type = "DOCS" }
                        elseif ($lowerSubject -match "test|测试") { $type = "TEST" }

                        $shortHash = $hash.Substring(0, [Math]::Min(7, $hash.Length))

                        $activity = [PSCustomObject]@{
                            hash = $hash
                            shortHash = $shortHash
                            dateTime = $dateTime
                            date = $date
                            time = $time
                            hour = $hour
                            author = $author
                            project = $projectName
                            subject = $subject
                            message = $subject
                            type = $type
                            insertions = $insertions
                            deletions = $deletions
                            changed = $insertions + $deletions
                        }
                        
                        $allActivities += $activity
                    }
                }
            } catch {
                Write-Host "    Error: $_" -ForegroundColor Red
            }
        }
    }
    
    Set-Location $PSScriptRoot
    return $allActivities
}

function Save-ActivitiesByDate {
    param(
        [array]$Activities,
        [string]$OutputDir,
        [string]$ArchiveDbDir = (Join-Path $PSScriptRoot "..\work-archive\archive-db\git-activities")
    )
    
    Write-Host ""
    Write-Host "Saving activities by date..." -ForegroundColor Yellow
    
    # Ensure archive-db directory exists
    if (-not (Test-Path $ArchiveDbDir)) {
        New-Item -ItemType Directory -Path $ArchiveDbDir -Force | Out-Null
    }
    
    $groupedByDate = $Activities | Group-Object { $_.date }
    $savedFiles = 0
    
    foreach ($group in $groupedByDate) {
        $date = $group.Name
        $activities = $group.Group | Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending
        
        $commitsArray = @()
        foreach ($act in $activities) {
            $commitsArray += @{
                hash = $act.hash
                shortHash = $act.shortHash
                dateTime = $act.dateTime
                date = $act.date
                time = $act.time
                hour = $act.hour
                author = $act.author
                project = $act.project
                subject = $act.subject
                message = $act.message
                type = $act.type
                insertions = $act.insertions
                deletions = $act.deletions
                changed = $act.changed
            }
        }

        $featCount = ($activities | Where-Object { $_.type -eq "FEATURE" }).Count
        $fixCount = ($activities | Where-Object { $_.type -eq "FIX" }).Count
        $refactorCount = ($activities | Where-Object { $_.type -eq "REFACTOR" }).Count
        $docsCount = ($activities | Where-Object { $_.type -eq "DOCS" }).Count
        $testCount = ($activities | Where-Object { $_.type -eq "TEST" }).Count
        $otherCount = ($activities | Where-Object { $_.type -eq "OTHER" }).Count
        
        $uniqueProjects = ($activities | Select-Object -ExpandProperty project -Unique) -join ", "

        # Save JSON to data/git-activities
        $jsonData = @{
            date = $date
            totalCommits = $activities.Count
            projects = $uniqueProjects
            types = @{
                FEATURE = $featCount
                FIX = $fixCount
                REFACTOR = $refactorCount
                DOCS = $docsCount
                TEST = $testCount
                OTHER = $otherCount
            }
            commits = $commitsArray
        }
        
        $fileName = "$date.json"
        $filePath = Join-Path $OutputDir $fileName
        $jsonData | ConvertTo-Json -Depth 5 | Out-File $filePath -Encoding UTF8
        
        # Save Markdown to archive-db/git-activities
        Save-ActivitiesAsMarkdown -Date $date -Activities $activities -OutputDir $ArchiveDbDir
        
        $savedFiles++
    }
    
    Write-Host "Saved $savedFiles files to $OutputDir" -ForegroundColor Green
    Write-Host "Saved $savedFiles markdown files to $ArchiveDbDir" -ForegroundColor Green
}

function Save-ActivitiesAsMarkdown {
    param(
        [string]$Date,
        [array]$Activities,
        [string]$OutputDir
    )
    
    $totalCommits = $activities.Count
    $totalInsertions = ($activities | Measure-Object -Property insertions -Sum).Sum
    $totalDeletions = ($activities | Measure-Object -Property deletions -Sum).Sum
    $activeProjects = $activities | Select-Object -ExpandProperty project -Unique
    
    $mdContent = @"
## Git Activity Statistics for Today

**Total Commits**: $totalCommits  
**Active Projects**: $($activeProjects.Count)  
**Code Changes**: +$totalInsertions -$totalDeletions

---

"@
    
    # Group by project
    $groupedByProject = $activities | Group-Object -Property project
    
    foreach ($projGroup in $groupedByProject) {
        $projectName = $projGroup.Name
        $projActivities = $projGroup.Group
        $projCommits = $projActivities.Count
        $projInsertions = ($projActivities | Measure-Object -Property insertions -Sum).Sum
        $projDeletions = ($projActivities | Measure-Object -Property deletions -Sum).Sum
        
        $mdContent += @"
### Project: $projectName

**Commits**: $projCommits  
**Code**: +$projInsertions -$projDeletions

"@
        
        foreach ($act in $projActivities) {
            $mdContent += @"
#### [$($act.type)] $($act.subject)
- **Time**: $($act.dateTime)
- **Changes**: +$($act.insertions) -$($act.deletions)
- **Files**: 0
- **Tech**: 

"@
        }
    }
    
    $mdFileName = "$Date.md"
    $mdFilePath = Join-Path $OutputDir $mdFileName
    $mdContent | Out-File $mdFilePath -Encoding UTF8
}

function Create-ActivityIndex {
    param(
        [array]$Activities,
        [string]$OutputDir
    )
    
    Write-Host ""
    Write-Host "Creating activity index..." -ForegroundColor Yellow
    
    $stats = @{
        totalCommits = $Activities.Count
        dateRange = @{
            from = ($Activities | Sort-Object date | Select-Object -First 1).date
            to = ($Activities | Sort-Object date -Descending | Select-Object -First 1).date
        }
        projects = @{}
        types = @{
            FEATURE = 0
            FIX = 0
            REFACTOR = 0
            DOCS = 0
            TEST = 0
            OTHER = 0
        }
        totalInsertions = 0
        totalDeletions = 0
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    foreach ($activity in $Activities) {
        if (-not $stats.projects.ContainsKey($activity.project)) {
            $stats.projects[$activity.project] = 0
        }
        $stats.projects[$activity.project]++
        $stats.types[$activity.type]++
        $stats.totalInsertions += $activity.insertions
        $stats.totalDeletions += $activity.deletions
    }
    
    $indexFile = Join-Path $OutputDir "activity-index.json"
    $stats | ConvertTo-Json -Depth 3 | Out-File $indexFile -Encoding UTF8
    
    Write-Host "Index saved: $indexFile" -ForegroundColor Green
    Write-Host "  Total commits: $($stats.totalCommits)" -ForegroundColor White
    Write-Host "  Date range: $($stats.dateRange.from) to $($stats.dateRange.to)" -ForegroundColor White
    Write-Host "  Projects: $($stats.projects.Count)" -ForegroundColor White
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git Activity Aggregator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Collecting Git activities..." -ForegroundColor Yellow
$activities = Collect-GitActivities -ProjectPaths $ProjectPaths -Author $Author -DaysBack $DaysBack
Write-Host "  Collected $($activities.Count) commits" -ForegroundColor Green

Write-Host "[2/3] Saving activities by date..." -ForegroundColor Yellow
Save-ActivitiesByDate -Activities $activities -OutputDir $OutputDir

Write-Host "[3/3] Creating activity index..." -ForegroundColor Yellow
Create-ActivityIndex -Activities $activities -OutputDir $OutputDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Data: $OutputDir" -ForegroundColor White
Write-Host "Next: Run generate-dashboard-data.ps1" -ForegroundColor Yellow
