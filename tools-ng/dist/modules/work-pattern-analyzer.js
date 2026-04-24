import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
export async function analyzeWorkPattern(projectPaths, author, days = 90) {
    logger.section('Analyzing Work Patterns...');
    const since = new Date();
    since.setDate(since.getDate() - days);
    const sinceStr = since.toISOString().split('T')[0];
    const hourDistribution = {};
    const dayDistribution = {};
    const dailyCommits = {};
    let totalCommits = 0;
    for (const rootPath of projectPaths) {
        try {
            const command = `dir /s /b /ad "${rootPath}\\.git"`;
            const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
            const gitDirs = output.split('\n').filter(line => line.trim());
            for (const gitDir of gitDirs) {
                const projectPath = gitDir.replace(/\\.git$/, '');
                try {
                    process.chdir(projectPath);
                    const logCommand = `git -c core.quotepath=false log --since="${sinceStr}" --author="${author}" --pretty=format:"%ad" --date=format:"%Y-%m-%d %H"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const lines = commitsOutput.split('\n').filter(line => line.trim());
                        for (const line of lines) {
                            const [date, hour] = line.split(' ');
                            const hourNum = parseInt(hour);
                            const dayOfWeek = new Date(date).toLocaleDateString('en-US', { weekday: 'long' });
                            hourDistribution[hourNum] = (hourDistribution[hourNum] || 0) + 1;
                            dayDistribution[dayOfWeek] = (dayDistribution[dayOfWeek] || 0) + 1;
                            if (!dailyCommits[date]) {
                                dailyCommits[date] = 0;
                            }
                            dailyCommits[date]++;
                            totalCommits++;
                        }
                    }
                }
                catch (error) {
                    logger.warn(`    Error: ${error.message}`);
                }
            }
        }
        catch (error) {
            logger.warn(`Error scanning ${rootPath}: ${error.message}`);
        }
    }
    // 分析结果
    const peakHour = Object.entries(hourDistribution).sort((a, b) => b[1] - a[1])[0];
    const peakDay = Object.entries(dayDistribution).sort((a, b) => b[1] - a[1])[0];
    // 计算连续提交天数
    const sortedDates = Object.keys(dailyCommits).sort();
    let currentStreak = 0;
    let maxStreak = 0;
    let lastDate = null;
    for (const date of sortedDates) {
        const currentDate = new Date(date);
        if (lastDate) {
            const diff = (currentDate.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24);
            if (diff === 1) {
                currentStreak++;
            }
            else {
                currentStreak = 1;
            }
        }
        else {
            currentStreak = 1;
        }
        if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
        }
        lastDate = currentDate;
    }
    const activeDays = Object.keys(dailyCommits).length;
    const avgCommitsPerDay = activeDays > 0 ? totalCommits / activeDays : 0;
    // 输出报告
    logger.section('Work Pattern Analysis');
    logger.success(`Total commits: ${totalCommits} (${days} days)`);
    logger.info(`Active days: ${activeDays}`);
    logger.info(`Average commits/day: ${avgCommitsPerDay.toFixed(1)}`);
    logger.info(`Max streak: ${maxStreak} days`);
    logger.section('Peak Activity:');
    logger.info(`  Hour: ${peakHour ? `${peakHour[0]}:00 (${peakHour[1]} commits)` : 'N/A'}`);
    logger.info(`  Day: ${peakDay ? `${peakDay[0]} (${peakDay[1]} commits)` : 'N/A'}`);
    logger.section('Hourly Distribution:');
    for (let hour = 0; hour < 24; hour++) {
        const count = hourDistribution[hour] || 0;
        if (count > 0) {
            const bar = '█'.repeat(Math.min(count, 50));
            logger.info(`  ${hour.toString().padStart(2, '0')}:00 ${bar} (${count})`);
        }
    }
    logger.section('Day Distribution:');
    const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    daysOfWeek.forEach(day => {
        const count = dayDistribution[day] || 0;
        if (count > 0) {
            const bar = '█'.repeat(Math.min(count, 50));
            logger.info(`  ${day.padEnd(10)} ${bar} (${count})`);
        }
    });
}
//# sourceMappingURL=work-pattern-analyzer.js.map