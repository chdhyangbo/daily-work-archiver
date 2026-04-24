import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';
export async function generateAnnualReport(year, projectPaths, author, outputBaseDir) {
    logger.section(`Generating Annual Report ${year}...`);
    const startDate = `${year}-01-01`;
    const endDate = `${year}-12-31 23:59:59`;
    let totalCommits = 0;
    const monthlyCommits = {};
    const projectCommits = {};
    const typeCommits = { FEATURE: 0, FIX: 0, REFACTOR: 0, DOCS: 0, TEST: 0, OTHER: 0 };
    let totalInsertions = 0;
    let totalDeletions = 0;
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
                    const logCommand = `git -c core.quotepath=false log --since="${startDate}" --until="${endDate}" --author="${author}" --pretty=format:"%H|%ad|%s" --date=format:"%Y-%m-%d"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const commitList = commitsOutput.split('\n').filter(line => line.trim());
                        totalCommits += commitList.length;
                        if (!projectCommits[projectName]) {
                            projectCommits[projectName] = 0;
                        }
                        projectCommits[projectName] += commitList.length;
                        for (const commit of commitList) {
                            const [hash, date, message] = commit.split('|');
                            const month = date.substring(0, 7);
                            monthlyCommits[month] = (monthlyCommits[month] || 0) + 1;
                            const type = classifyCommit(message);
                            typeCommits[type]++;
                            try {
                                const statInfo = execSync(`git show --stat --format="" ${hash}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                                const lastLine = statInfo.trim().split('\n').pop() || '';
                                const insMatch = lastLine.match(/(\d+) insertion/);
                                if (insMatch)
                                    totalInsertions += parseInt(insMatch[1]);
                                const delMatch = lastLine.match(/(\d+) deletion/);
                                if (delMatch)
                                    totalDeletions += parseInt(delMatch[1]);
                            }
                            catch (e) { }
                        }
                    }
                }
                catch (error) {
                    logger.warn(`    Error in ${projectName}: ${error.message}`);
                }
            }
        }
        catch (error) {
            logger.warn(`Error scanning ${rootPath}: ${error.message}`);
        }
    }
    // 生成报告
    const outputDir = path.join(outputBaseDir, 'annual-reports');
    await ensureDir(outputDir);
    const reportFile = path.join(outputDir, `${year}-annual-report.md`);
    let report = `# ${year} 年度工作总结\n\n`;
    report += `**Total Commits**: ${totalCommits}\n`;
    report += `**Code Changes**: +${totalInsertions} -${totalDeletions}\n`;
    report += `**Projects**: ${Object.keys(projectCommits).length}\n\n`;
    report += '## Monthly Activity\n\n| Month | Commits |\n|-------|--------|\n';
    for (let month = 1; month <= 12; month++) {
        const key = `${year}-${month.toString().padStart(2, '0')}`;
        const count = monthlyCommits[key] || 0;
        if (count > 0) {
            report += `| ${key} | ${count} |\n`;
        }
    }
    report += '\n## Project Contributions\n\n| Project | Commits |\n|---------|--------|\n';
    Object.entries(projectCommits).sort((a, b) => b[1] - a[1]).forEach(([proj, count]) => {
        report += `| ${proj} | ${count} |\n`;
    });
    report += '\n## Commit Types\n\n| Type | Count |\n|------|-------|\n';
    Object.entries(typeCommits).forEach(([type, count]) => {
        if (count > 0)
            report += `| ${type} | ${count} |\n`;
    });
    await writeFile(reportFile, report);
    logger.success(`Annual report saved to: ${reportFile}`);
}
function classifyCommit(message) {
    const lower = message.toLowerCase();
    if (lower.includes('feat') || lower.includes('新增'))
        return 'FEATURE';
    if (lower.includes('fix') || lower.includes('修复'))
        return 'FIX';
    if (lower.includes('refactor') || lower.includes('重构'))
        return 'REFACTOR';
    if (lower.includes('docs') || lower.includes('文档'))
        return 'DOCS';
    if (lower.includes('test') || lower.includes('测试'))
        return 'TEST';
    return 'OTHER';
}
//# sourceMappingURL=annual-report.js.map