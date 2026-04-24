import { logger } from '../utils/logger.js';
export async function provideWorkAdvice(projectPaths, author, days = 30) {
    logger.section('Smart Work Advisor');
    const { execSync } = await import('child_process');
    let totalCommits = 0;
    const hourDistribution = {};
    let totalStreak = 0;
    for (const rootPath of projectPaths) {
        try {
            const command = `dir /s /b /ad "${rootPath}\\.git"`;
            const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
            const gitDirs = output.split('\n').filter(line => line.trim());
            for (const gitDir of gitDirs) {
                const projectPath = gitDir.replace(/\\.git$/, '');
                try {
                    process.chdir(projectPath);
                    const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%ad" --date=format:"%Y-%m-%d %H"`;
                    const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                    if (commitsOutput.trim()) {
                        const lines = commitsOutput.split('\n').filter(line => line.trim());
                        totalCommits += lines.length;
                        lines.forEach(line => {
                            const [date, hour] = line.split(' ');
                            hourDistribution[parseInt(hour)] = (hourDistribution[parseInt(hour)] || 0) + 1;
                        });
                    }
                }
                catch (error) { }
            }
        }
        catch (error) { }
    }
    logger.section('Work Advice:');
    const avgCommitsPerDay = totalCommits / days;
    if (avgCommitsPerDay < 1) {
        logger.warn('  ⚠️ Low activity detected');
        logger.info('  Suggestion: Try to commit more regularly');
    }
    else if (avgCommitsPerDay >= 3) {
        logger.success('  ✅ Great activity level!');
    }
    const peakHour = Object.entries(hourDistribution).sort((a, b) => b[1] - a[1])[0];
    if (peakHour) {
        logger.info(`  Your peak hour: ${peakHour[0]}:00 (${peakHour[1]} commits)`);
        logger.info('  Suggestion: Schedule important tasks during this time');
    }
    logger.section('General Tips:');
    logger.info('  1. Commit small changes frequently');
    logger.info('  2. Write clear commit messages');
    logger.info('  3. Take regular breaks');
    logger.info('  4. Review your code before committing');
    logger.info('  5. Keep learning and improving');
}
//# sourceMappingURL=work-advisor.js.map