import { logger } from '../utils/logger.js';
import { readJsonFile, writeJsonFile, ensureDir } from '../core/fs.js';
import path from 'path';
import { analyzeQualityMetrics } from './quality-metrics.js';
export async function generateDashboardData(projectPaths, author, outputBaseDir) {
    logger.section('Generating Dashboard Data...');
    const { execSync } = await import('child_process');
    const { readdirSync, statSync } = await import('fs');
    let totalCommits = 0;
    const projects = {};
    const dailyCommits = {};
    const contributions = [];
    const recentCommits = [];
    const hourlyDistribution = {};
    const typeDistribution = { FEATURE: 0, FIX: 0, REFACTOR: 0, DOCS: 0, TEST: 0, OTHER: 0 };
    // Load git activity data for detailed analysis
    const gitActivitiesDir = path.join(outputBaseDir, 'data', 'git-activities');
    let qualityMetrics = null;
    try {
        if (readdirSync(gitActivitiesDir).length > 0) {
            logger.info('Analyzing quality metrics from git activities...');
            qualityMetrics = await analyzeQualityMetrics(gitActivitiesDir, 90);
            logger.success('Quality metrics analysis complete');
        }
    }
    catch (error) {
        logger.warn(`Quality metrics analysis failed: ${error.message}`);
    }
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
                    const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%ad" --date=format:"%Y-%m-%d"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const commitList = commitsOutput.split('\n').filter(line => line.trim());
                        totalCommits += commitList.length;
                        projects[projectName] = commitList.length;
                        commitList.forEach((commit) => {
                            const date = commit.trim();
                            dailyCommits[date] = (dailyCommits[date] || 0) + 1;
                        });
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
    // Process git activity data for richer dashboard
    if (qualityMetrics) {
        try {
            const activityFiles = readdirSync(gitActivitiesDir)
                .filter(f => f.endsWith('.json') && f !== 'activity-index.json')
                .sort()
                .reverse();
            // Build contributions array
            for (const file of activityFiles) {
                const filePath = path.join(gitActivitiesDir, file);
                const data = await readJsonFile(filePath);
                if (data.date && data.totalCommits) {
                    contributions.push({ date: data.date, count: data.totalCommits });
                    // Count types
                    if (data.types) {
                        Object.entries(data.types).forEach(([type, count]) => {
                            if (typeDistribution[type] !== undefined) {
                                typeDistribution[type] += count;
                            }
                        });
                    }
                    // Get recent commits
                    if (data.commits && recentCommits.length < 25) {
                        data.commits.forEach((commit) => {
                            recentCommits.push({
                                date: commit.date,
                                message: commit.subject || commit.message,
                                project: commit.project,
                                hash: commit.shortHash || ''
                            });
                        });
                    }
                    // Hourly distribution
                    if (data.commits) {
                        data.commits.forEach((commit) => {
                            const hour = commit.hour;
                            if (hour !== undefined) {
                                hourlyDistribution[hour] = (hourlyDistribution[hour] || 0) + 1;
                            }
                        });
                    }
                }
            }
            contributions.sort((a, b) => a.date.localeCompare(b.date));
            recentCommits.sort((a, b) => b.date.localeCompare(a.date));
        }
        catch (error) {
            logger.warn(`Error processing git activities: ${error.message}`);
        }
    }
    // Calculate week commits and streak
    const today = new Date();
    const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const weekAgoStr = weekAgo.toISOString().split('T')[0];
    const todayStr = today.toISOString().split('T')[0];
    const weekCommits = contributions
        .filter(c => c.date >= weekAgoStr && c.date <= todayStr)
        .reduce((sum, c) => sum + c.count, 0);
    // Calculate current streak
    let currentStreak = 0;
    const contributionDates = new Set(contributions.map(c => c.date));
    let checkDate = new Date(today);
    // Check if there's a commit today
    if (!contributionDates.has(todayStr)) {
        checkDate.setDate(checkDate.getDate() - 1);
    }
    while (contributionDates.has(checkDate.toISOString().split('T')[0])) {
        currentStreak++;
        checkDate.setDate(checkDate.getDate() - 1);
    }
    // Calculate max streak
    let maxStreak = 0;
    let tempStreak = 0;
    const sortedDates = contributions.map(c => c.date).sort();
    for (let i = 0; i < sortedDates.length; i++) {
        if (i === 0) {
            tempStreak = 1;
        }
        else {
            const prevDate = new Date(sortedDates[i - 1]);
            const currDate = new Date(sortedDates[i]);
            const diff = Math.round((currDate.getTime() - prevDate.getTime()) / (24 * 60 * 60 * 1000));
            if (diff === 1) {
                tempStreak++;
            }
            else {
                tempStreak = 1;
            }
        }
        maxStreak = Math.max(maxStreak, tempStreak);
    }
    const dashboardData = {
        contributions,
        level: {
            achievements: { total: 16, unlocked: 7 },
            name: 'Mid Dev',
            points: totalCommits
        },
        typeDistribution,
        recentCommits: recentCommits.slice(0, 25),
        projectDistribution: projects,
        stats: {
            weekHours: 0,
            todayCommits: dailyCommits[todayStr] || 0,
            maxStreak,
            totalCommits,
            currentStreak,
            todayHours: 0,
            weekCommits
        },
        summary: {
            weekHours: 0,
            todayCommits: dailyCommits[todayStr] || 0,
            maxStreak,
            totalCommits,
            currentStreak,
            todayHours: 0,
            weekCommits
        },
        qualityScore: 82.6,
        qualityLevels: { S: 20, A: 468, B: 70, C: 4, D: 0 },
        achievements: {
            unlocked: 7,
            totalPoints: totalCommits,
            level: 'Mid Dev'
        },
        hourlyDistribution,
        generatedAt: new Date().toISOString()
    };
    // Add quality metrics if available
    if (qualityMetrics) {
        dashboardData.qualityMetrics = qualityMetrics;
    }
    const outputFile = path.join(outputBaseDir, 'data', 'dashboard-data.json');
    await ensureDir(path.dirname(outputFile));
    await writeJsonFile(outputFile, dashboardData);
    logger.success(`Dashboard data saved to: ${outputFile}`);
    // Also copy to docs-server public directory
    const docsServerPublic = path.resolve(__dirname, '../../../docs-server/public');
    const docsOutputFile = path.join(docsServerPublic, 'dashboard-data.json');
    try {
        const { copyFile } = await import('fs/promises');
        await ensureDir(docsServerPublic);
        await copyFile(outputFile, docsOutputFile);
        logger.success(`Dashboard data copied to: ${docsOutputFile}`);
    }
    catch (error) {
        logger.warn(`Could not copy to docs-server: ${error.message}`);
    }
}
//# sourceMappingURL=dashboard-data.js.map