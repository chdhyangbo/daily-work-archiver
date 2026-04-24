import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';
export async function monitorProjectHealth(projectPaths, author, days = 30, outputBaseDir) {
    logger.section('Project Health Monitor');
    const since = new Date();
    since.setDate(since.getDate() - days);
    const sinceStr = since.toISOString().split('T')[0];
    const healthReports = [];
    for (const rootPath of projectPaths) {
        try {
            const command = `dir /s /b /ad "${rootPath}\\.git"`;
            const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
            const gitDirs = output.split('\n').filter(line => line.trim());
            for (const gitDir of gitDirs) {
                const projectPath = gitDir.replace(/\\.git$/, '');
                const projectName = projectPath.split(/[\/\\]/).pop() || '';
                try {
                    process.chdir(projectPath);
                    const logCommand = `git -c core.quotepath=false log --since="${sinceStr}" --author="${author}" --pretty=format:"%H|%s" --no-merges`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    const health = { name: projectName, commits: 0, avgCommitSize: 0, healthScore: 100, issues: [] };
                    if (commitsOutput.trim()) {
                        const commits = commitsOutput.split('\n').filter(line => line.trim());
                        health.commits = commits.length;
                        let totalSize = 0;
                        for (const commit of commits.slice(0, 10)) {
                            const [hash] = commit.split('|');
                            try {
                                const statOutput = execSync(`git show --stat --format="" ${hash}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                                const lastLine = statOutput.trim().split('\n').pop() || '';
                                const insMatch = lastLine.match(/(\d+) insertion/);
                                const delMatch = lastLine.match(/(\d+) deletion/);
                                const size = (insMatch ? parseInt(insMatch[1]) : 0) + (delMatch ? parseInt(delMatch[1]) : 0);
                                totalSize += size;
                            }
                            catch (error) { }
                        }
                        health.avgCommitSize = totalSize / Math.min(commits.length, 10);
                    }
                    // 健康评分
                    if (health.commits === 0) {
                        health.healthScore -= 30;
                        health.issues.push('No recent commits');
                    }
                    if (health.avgCommitSize > 500) {
                        health.healthScore -= 20;
                        health.issues.push('Large commit sizes');
                    }
                    if (health.commits < 5) {
                        health.healthScore -= 10;
                        health.issues.push('Low activity');
                    }
                    health.healthScore = Math.max(0, health.healthScore);
                    healthReports.push(health);
                }
                catch (error) { }
            }
        }
        catch (error) { }
    }
    logger.section('Project Health Report:');
    healthReports.forEach(report => {
        const status = report.healthScore >= 80 ? '✅' : report.healthScore >= 60 ? '⚠️' : '❌';
        logger.info(`${status} ${report.name} (Score: ${report.healthScore}/100)`);
        if (report.issues.length > 0) {
            logger.info(`  Issues: ${report.issues.join(', ')}`);
        }
    });
    // 保存报告
    const outputDir = path.join(outputBaseDir, 'data', 'health-reports');
    await ensureDir(outputDir);
    const reportFile = path.join(outputDir, `health-${new Date().toISOString().split('T')[0]}.md`);
    let report = `# Project Health Report\n\n`;
    report += `**Date**: ${new Date().toISOString().split('T')[0]}\n\n`;
    healthReports.forEach(r => {
        report += `## ${r.name}\n- **Score**: ${r.healthScore}/100\n- **Commits**: ${r.commits}\n- **Avg Size**: ${r.avgCommitSize.toFixed(0)} lines\n\n`;
    });
    await writeFile(reportFile, report);
}
//# sourceMappingURL=project-health-monitor.js.map