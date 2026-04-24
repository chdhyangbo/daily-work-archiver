import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';
export async function trackGitWork(projectPaths, author, filter, outputBaseDir) {
    logger.section(`Tracking Git Work (${filter})...`);
    const stats = {
        totalCommits: 0,
        projects: {},
        dailySummary: {},
        weeklySummary: {},
        monthlySummary: {}
    };
    const now = new Date();
    let sinceDate;
    switch (filter) {
        case 'today':
            sinceDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            break;
        case 'week':
            sinceDate = new Date(now);
            sinceDate.setDate(now.getDate() - 7);
            break;
        case 'month':
            sinceDate = new Date(now);
            sinceDate.setMonth(now.getMonth() - 1);
            break;
        default:
            sinceDate = new Date(now);
            sinceDate.setFullYear(now.getFullYear() - 1);
    }
    const since = sinceDate.toISOString().split('T')[0];
    const until = now.toISOString().split('T')[0] + ' 23:59:59';
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
                    const logCommand = `git -c core.quotepath=false log --since="${since}" --until="${until}" --author="${author}" --pretty=format:"%H|%ad" --date=format:"%Y-%m-%d"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const commitList = commitsOutput.split('\n').filter(line => line.trim());
                        if (!stats.projects[projectName]) {
                            stats.projects[projectName] = { commits: 0, insertions: 0, deletions: 0 };
                        }
                        stats.projects[projectName].commits += commitList.length;
                        stats.totalCommits += commitList.length;
                        for (const commit of commitList) {
                            const date = commit.split('|')[1];
                            if (!stats.dailySummary[date]) {
                                stats.dailySummary[date] = 0;
                            }
                            stats.dailySummary[date]++;
                            const weekKey = getWeekKey(date);
                            if (!stats.weeklySummary[weekKey]) {
                                stats.weeklySummary[weekKey] = 0;
                            }
                            stats.weeklySummary[weekKey]++;
                            const monthKey = date.substring(0, 7);
                            if (!stats.monthlySummary[monthKey]) {
                                stats.monthlySummary[monthKey] = 0;
                            }
                            stats.monthlySummary[monthKey]++;
                        }
                    }
                }
                catch (error) {
                    logger.warn(`    Error in project ${projectName}: ${error.message}`);
                }
            }
        }
        catch (error) {
            logger.warn(`Error scanning ${rootPath}: ${error.message}`);
        }
    }
    // 输出结果
    logger.success(`Total commits: ${stats.totalCommits}`);
    logger.section('Projects:');
    Object.entries(stats.projects).forEach(([name, data]) => {
        logger.info(`  ${name}: ${data.commits} commits`);
    });
    // 保存报告
    const reportDir = path.join(outputBaseDir, 'archive-db', 'git-work');
    await ensureDir(reportDir);
    const reportFile = path.join(reportDir, `${now.toISOString().split('T')[0]}.md`);
    let report = `# Git Work Summary - ${filter}\n\n`;
    report += `**Date**: ${now.toISOString().split('T')[0]}\n`;
    report += `**Total Commits**: ${stats.totalCommits}\n\n`;
    report += '## Projects\n\n| Project | Commits |\n|---------|--------|\n';
    Object.entries(stats.projects).forEach(([name, data]) => {
        report += `| ${name} | ${data.commits} |\n`;
    });
    await writeFile(reportFile, report);
    logger.success(`Report saved to: ${reportFile}`);
}
function getWeekKey(date) {
    const d = new Date(date);
    const startOfYear = new Date(d.getFullYear(), 0, 1);
    const days = Math.floor((d.getTime() - startOfYear.getTime()) / (24 * 60 * 60 * 1000));
    const weekNum = Math.ceil((days + startOfYear.getDay() + 1) / 7);
    return `${d.getFullYear()}-W${weekNum.toString().padStart(2, '0')}`;
}
//# sourceMappingURL=git-work-tracker.js.map