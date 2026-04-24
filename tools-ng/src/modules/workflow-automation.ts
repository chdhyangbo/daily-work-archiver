import { logger } from '../utils/logger.js';

export interface WorkflowRule {
  name: string;
  condition: (stats: any) => boolean;
  action: () => void;
}

export async function checkWorkflows(
  projectPaths: string[],
  author: string
): Promise<void> {
  logger.section('Workflow Automation Checker');

  const { execSync } = await import('child_process');

  let totalCommits = 0;
  let bugFixCount = 0;
  let featureCount = 0;

  for (const rootPath of projectPaths) {
    try {
      const command = `dir /s /b /ad "${rootPath}\\.git"`;
      const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
      const gitDirs = output.split('\n').filter(line => line.trim());

      for (const gitDir of gitDirs) {
        const projectPath = gitDir.replace(/\\.git$/, '');

        try {
          process.chdir(projectPath);
          const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%s"`;
          const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

          if (commitsOutput.trim()) {
            const messages = commitsOutput.split('\n').filter(line => line.trim());
            totalCommits += messages.length;

            messages.forEach(msg => {
              const lower = msg.toLowerCase();
              if (lower.includes('fix') || lower.includes('修复')) bugFixCount++;
              if (lower.includes('feat') || lower.includes('新增')) featureCount++;
            });
          }
        } catch (error) {}
      }
    } catch (error) {}
  }

  logger.section('Workflow Suggestions:');

  if (bugFixCount > featureCount * 2) {
    logger.warn('  ⚠️ High bug fix ratio detected');
    logger.info('  Suggestion: Consider writing more tests');
  }

  if (totalCommits > 0 && totalCommits < 10) {
    logger.warn('  ⚠️ Low commit activity');
    logger.info('  Suggestion: Commit smaller changes more frequently');
  }

  logger.success(`Total commits analyzed: ${totalCommits}`);
  logger.info(`Bug fixes: ${bugFixCount}, Features: ${featureCount}`);
}
