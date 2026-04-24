import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';

export async function generateProjectRetro(
  projectPath: string,
  author: string,
  outputDir: string
): Promise<void> {
  logger.section('Project Retrospective Generator');

  const { readJsonFile } = await import('../core/fs.js');

  try {
    process.chdir(projectPath);
    const projectName = projectPath.split(/[\/\\]/).pop() || '';

    // 获取项目统计
    const totalCommitsOutput = execSync(`git -c core.quotepath=false log --author="${author}" --oneline`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    const totalCommits = totalCommitsOutput.trim().split('\n').filter(l => l.trim()).length;

    const firstCommit = execSync(`git -c core.quotepath=false log --author="${author}" --reverse --pretty=format:"%ad" --date=format:"%Y-%m-%d" | head -1`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    const lastCommit = execSync(`git -c core.quotepath=false log --author="${author}" -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d"`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

    // 获取文件变更统计
    const filesChangedOutput = execSync(`git -c core.quotepath=false log --author="${author}" --name-only --pretty=format:"" | sort | uniq | wc -l`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    const filesChanged = parseInt(filesChangedOutput.trim());

    // 生成回顾报告
    const retroContent = `# Project Retrospective: ${projectName}

## Project Overview
- **Start Date**: ${firstCommit.trim()}
- **End Date**: ${lastCommit.trim()}
- **Total Commits**: ${totalCommits}
- **Files Changed**: ${filesChanged}

## What Went Well
- Consistent development activity
- Multiple features implemented
- Regular code commits

## What Could Be Improved
- Consider adding more tests
- Improve commit message quality
- Add more documentation

## Action Items
- [ ] Review and refactor complex code
- [ ] Update project documentation
- [ ] Add unit tests for critical paths
- [ ] Optimize performance bottlenecks

## Lessons Learned
- Document key decisions
- Keep commits focused and atomic
- Regular code reviews help maintain quality
`;

    await ensureDir(outputDir);
    const outputFile = path.join(outputDir, `retro-${projectName}-${new Date().toISOString().split('T')[0]}.md`);
    await writeFile(outputFile, retroContent);

    logger.success(`Retrospective saved to: ${outputFile}`);
  } catch (error) {
    logger.error(`Error: ${(error as Error).message}`);
  }
}
