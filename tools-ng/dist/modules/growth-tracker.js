import { logger } from '../utils/logger.js';
export async function trackGrowth(projectPaths, author, months = 12) {
    logger.section('Growth Tracker');
    const { execSync } = await import('child_process');
    const metrics = [];
    const now = new Date();
    for (let i = months - 1; i >= 0; i--) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const year = date.getFullYear();
        const month = date.getMonth();
        const monthStr = `${year}-${(month + 1).toString().padStart(2, '0')}`;
        const startDate = `${year}-${(month + 1).toString().padStart(2, '0')}-01`;
        const endDate = `${year}-${(month + 1).toString().padStart(2, '0')}-31 23:59:59`;
        let monthCommits = 0;
        const monthProjects = new Set();
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
                        const logCommand = `git -c core.quotepath=false log --since="${startDate}" --until="${endDate}" --author="${author}" --pretty=format:"%H"`;
                        const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                        if (commitsOutput.trim()) {
                            const count = commitsOutput.split('\n').filter(line => line.trim()).length;
                            monthCommits += count;
                            if (count > 0)
                                monthProjects.add(projectName);
                        }
                    }
                    catch (error) { }
                }
            }
            catch (error) { }
        }
        metrics.push({
            month: monthStr,
            commits: monthCommits,
            projects: monthProjects.size,
            streakDays: 0
        });
    }
    logger.section('Growth Trends');
    metrics.forEach(m => {
        const bar = '█'.repeat(Math.min(m.commits, 50));
        logger.info(`${m.month}: ${bar} (${m.commits} commits, ${m.projects} projects)`);
    });
}
//# sourceMappingURL=growth-tracker.js.map