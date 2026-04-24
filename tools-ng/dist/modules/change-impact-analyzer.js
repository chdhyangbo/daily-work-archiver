import { logger } from '../utils/logger.js';
export async function generateChangeImpactReport(projectPath, author, days = 30, outputDir) {
    logger.section('Change Impact Analyzer');
    const { execSync } = await import('child_process');
    const since = new Date();
    since.setDate(since.getDate() - days);
    const sinceStr = since.toISOString().split('T')[0];
    try {
        process.chdir(projectPath);
        const logCommand = `git -c core.quotepath=false log --since="${sinceStr}" --author="${author}" --pretty=format:"%H|%s" --no-merges`;
        const output = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
        if (!output.trim()) {
            logger.warn('No commits found');
            return;
        }
        const commits = output.split('\n').filter(line => line.trim());
        const highImpactCommits = [];
        for (const commit of commits) {
            const [hash, subject] = commit.split('|');
            try {
                const statOutput = execSync(`git show --stat --format="" ${hash}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
                const lines = statOutput.trim().split('\n');
                const fileCount = lines.length;
                const lastLine = lines[lines.length - 1];
                const insMatch = lastLine.match(/(\d+) insertion/);
                const delMatch = lastLine.match(/(\d+) deletion/);
                const totalLines = (insMatch ? parseInt(insMatch[1]) : 0) + (delMatch ? parseInt(delMatch[1]) : 0);
                if (fileCount > 5 || totalLines > 500) {
                    highImpactCommits.push({ hash, subject, files: fileCount, lines: totalLines });
                }
            }
            catch (error) { }
        }
        logger.section('High Impact Changes:');
        highImpactCommits.forEach(commit => {
            logger.warn(`  ${commit.hash.substring(0, 7)}: ${commit.subject}`);
            logger.info(`    Files: ${commit.files}, Lines: ${commit.lines}`);
        });
        logger.success(`Total high-impact commits: ${highImpactCommits.length}`);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
}
//# sourceMappingURL=change-impact-analyzer.js.map