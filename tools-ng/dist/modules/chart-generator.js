import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';
export async function generateChartHTML(projectPaths, author, outputBaseDir) {
    logger.section('Chart Generator');
    const { readJsonFile } = await import('../core/fs.js');
    const dailyData = {};
    const now = new Date();
    for (const rootPath of projectPaths) {
        try {
            const command = `dir /s /b /ad "${rootPath}\\.git"`;
            const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
            const gitDirs = output.split('\n').filter(line => line.trim());
            for (const gitDir of gitDirs) {
                const projectPath = gitDir.replace(/\\.git$/, '');
                try {
                    process.chdir(projectPath);
                    const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%ad" --date=format:"%Y-%m-%d"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const dates = commitsOutput.split('\n').filter(line => line.trim());
                        dates.forEach(date => {
                            dailyData[date] = (dailyData[date] || 0) + 1;
                        });
                    }
                }
                catch (error) { }
            }
        }
        catch (error) { }
    }
    // 生成HTML图表
    const outputDir = path.join(outputBaseDir, 'visualizations');
    await ensureDir(outputDir);
    const htmlFile = path.join(outputDir, `${now.getFullYear()}-overview.html`);
    const html = `<!DOCTYPE html>
<html>
<head>
  <title>Work Overview ${now.getFullYear()}</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial; margin: 40px; }
    .chart-container { max-width: 800px; margin: 20px auto; }
  </style>
</head>
<body>
  <h1>Work Overview ${now.getFullYear()}</h1>
  <div class="chart-container">
    <canvas id="dailyChart"></canvas>
  </div>
  <script>
    const data = ${JSON.stringify(dailyData)};
    const dates = Object.keys(data).sort();
    const counts = dates.map(d => data[d]);
    
    new Chart(document.getElementById('dailyChart'), {
      type: 'bar',
      data: {
        labels: dates,
        datasets: [{
          label: 'Daily Commits',
          data: counts,
          backgroundColor: 'rgba(54, 162, 235, 0.5)'
        }]
      },
      options: { responsive: true }
    });
  </script>
</body>
</html>`;
    await writeFile(htmlFile, html);
    logger.success(`Chart saved to: ${htmlFile}`);
}
//# sourceMappingURL=chart-generator.js.map