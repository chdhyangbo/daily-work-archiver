import { logger } from '../utils/logger.js';

export async function suggestTimeOptimization(
  projectPaths: string[],
  author: string,
  days: number = 30
): Promise<void> {
  logger.section('Time Optimization Suggestions');

  const { execSync } = await import('child_process');

  const hourDistribution: Record<number, number> = {};
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
          const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%ad" --date=format:"%H"`;
          const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

          if (commitsOutput.trim()) {
            const hours = commitsOutput.split('\n').filter(line => line.trim());
            hours.forEach(h => {
              const hour = parseInt(h.trim());
              hourDistribution[hour] = (hourDistribution[hour] || 0) + 1;
              totalCommits++;
            });
          }
        } catch (error) {}
      }
    } catch (error) {}
  }

  // 找出高峰时段
  const peakHours = Object.entries(hourDistribution)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(e => parseInt(e[0]));

  logger.section('Your Peak Hours:');
  peakHours.forEach(hour => {
    const count = hourDistribution[hour];
    logger.info(`  ${hour.toString().padStart(2, '0')}:00 - ${count} commits`);
  });

  logger.section('Suggestions:');
  logger.info('  1. Schedule important tasks during your peak hours');
  logger.info('  2. Take breaks between coding sessions');
  logger.info('  3. Use morning hours for complex problems');
  logger.info('  4. Reserve afternoon for reviews and meetings');
}
