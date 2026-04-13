# Test script to verify all projects are found

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Project Discovery Test" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectDirs = @(
    "D:\work\code",
    "D:\work\codepos"
)

$totalProjects = 0

foreach ($rootDir in $projectDirs) {
    Write-Host "Scanning: $rootDir" -ForegroundColor Yellow
    
    if (-not (Test-Path $rootDir)) {
        Write-Host "  Directory not found!" -ForegroundColor Red
        continue
    }
    
    # Find all projects with .git directory (depth 1)
    $gitDirs = Get-ChildItem -Path $rootDir -Directory -Filter ".git" -Recurse -Depth 1 -ErrorAction SilentlyContinue
    
    $projectCount = ($gitDirs | Measure-Object).Count
    $totalProjects += $projectCount
    
    Write-Host "  Found $projectCount projects" -ForegroundColor Green
    
    if ($projectCount -gt 0) {
        Write-Host "  Projects:" -ForegroundColor Cyan
        foreach ($gitDir in $gitDirs | Select-Object -First 10) {
            Write-Host "    - $($gitDir.Parent.Name)" -ForegroundColor White
        }
        if ($projectCount -gt 10) {
            Write-Host "    ... and $($projectCount - 10) more" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total projects found: $totalProjects" -ForegroundColor Yellow
Write-Host ""
Write-Host "Directories scanned:" -ForegroundColor Yellow
Write-Host "  1. D:\work\code" -ForegroundColor White
Write-Host "  2. D:\work\codepos" -ForegroundColor White
Write-Host ""
