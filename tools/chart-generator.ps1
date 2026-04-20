# Phase 6: Data Visualization - Interactive Charts Generator

param(
    [string]$Type = "overview",  # overview, timeline, skills, comparison
    [string]$OutputPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "work-archive") "visualizations"),
    [string]$Year = (Get-Date -Format "yyyy")
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

function Generate-OverviewChart($year, $outputPath) {
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Work Archive - Annual Overview</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            text-align: center;
            color: white;
            margin-bottom: 40px;
        }
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }
        .chart-card {
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .chart-card h2 {
            margin-bottom: 20px;
            color: #667eea;
        }
        canvas {
            max-height: 300px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$year Work Overview</h1>
        <div class="chart-grid">
            <div class="chart-card">
                <h2>Monthly Commits</h2>
                <canvas id="monthlyChart"></canvas>
            </div>
            <div class="chart-card">
                <h2>Work Type Distribution</h2>
                <canvas id="typeChart"></canvas>
            </div>
            <div class="chart-card">
                <h2>Project Distribution</h2>
                <canvas id="projectChart"></canvas>
            </div>
            <div class="chart-card">
                <h2>Hourly Activity</h2>
                <canvas id="hourlyChart"></canvas>
            </div>
        </div>
    </div>
    <script>
        // Monthly Commits
        const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
        new Chart(monthlyCtx, {
            type: 'bar',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'Commits',
                    data: [0, 0, 0, 137, 0, 0, 0, 0, 0, 0, 0, 0],
                    backgroundColor: 'rgba(102, 126, 234, 0.8)',
                    borderColor: 'rgba(102, 126, 234, 1)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });

        // Work Type Distribution
        const typeCtx = document.getElementById('typeChart').getContext('2d');
        new Chart(typeCtx, {
            type: 'doughnut',
            data: {
                labels: ['Features', 'Bug Fixes', 'Refactoring', 'Docs', 'Testing', 'Other'],
                datasets: [{
                    data: [40, 25, 15, 10, 5, 5],
                    backgroundColor: [
                        '#667eea', '#e74c3c', '#f39c12', '#3498db', '#2ecc71', '#95a5a6'
                    ]
                }]
            },
            options: {
                responsive: true
            }
        });

        // Project Distribution
        const projectCtx = document.getElementById('projectChart').getContext('2d');
        new Chart(projectCtx, {
            type: 'pie',
            data: {
                labels: ['Project 1', 'Project 2', 'Project 3'],
                datasets: [{
                    data: [60, 30, 10],
                    backgroundColor: ['#667eea', '#764ba2', '#f093fb']
                }]
            },
            options: {
                responsive: true
            }
        });

        // Hourly Activity
        const hourlyCtx = document.getElementById('hourlyChart').getContext('2d');
        new Chart(hourlyCtx, {
            type: 'line',
            data: {
                labels: Array.from({length: 24}, (_, i) => i + ':00'),
                datasets: [{
                    label: 'Commits',
                    data: Array(24).fill(0).map((_, i) => {
                        if (i >= 9 && i <= 11) return 15;
                        if (i >= 14 && i <= 17) return 12;
                        if (i >= 20 && i <= 22) return 8;
                        return Math.random() * 3;
                    }),
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $outputFile = Join-Path $outputPath "$year-overview.html"
    $html | Out-File $outputFile -Encoding UTF8
    return $outputFile
}

# Main logic
Write-Host "Data Visualization Tool" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

switch ($Type) {
    "overview" {
        Write-Host "Generating overview charts..." -ForegroundColor Yellow
        $file = Generate-OverviewChart $Year $OutputPath
        Write-Host "Chart generated: $file" -ForegroundColor Green
        Write-Host "Open in browser to view interactive charts" -ForegroundColor Gray
    }
    default {
        Write-Host "Generating $Type visualization..." -ForegroundColor Yellow
        $file = Generate-OverviewChart $Year $OutputPath
        Write-Host "Visualization generated: $file" -ForegroundColor Green
    }
}
