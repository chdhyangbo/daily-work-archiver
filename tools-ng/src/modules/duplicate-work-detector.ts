import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';

export async function detectDuplicateWork(
  projectPaths: string[],
  author: string,
  days: number = 90
): Promise<void> {
  logger.section('Duplicate Work Detector');

  const since = new Date();
  since.setDate(since.getDate() - days);
  const sinceStr = since.toISOString().split('T')[0];

  const commitMessages: string[] = [];
  const similarityPairs: Array<{ msg1: string; msg2: string; score: number }> = [];

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
          const logCommand = `git -c core.quotepath=false log --since="${sinceStr}" --author="${author}" --pretty=format:"%s" --no-merges`;
          const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

          if (commitsOutput.trim()) {
            const messages = commitsOutput.split('\n').filter(line => line.trim());
            commitMessages.push(...messages);
          }
        } catch (error) {}
      }
    } catch (error) {}
  }

  // 简单的相似度检测
  for (let i = 0; i < commitMessages.length; i++) {
    for (let j = i + 1; j < commitMessages.length; j++) {
      const similarity = calculateSimilarity(commitMessages[i], commitMessages[j]);
      if (similarity > 0.7) {
        similarityPairs.push({
          msg1: commitMessages[i],
          msg2: commitMessages[j],
          score: similarity
        });
      }
    }
  }

  logger.section('Duplicate/Similar Commits Found:');
  if (similarityPairs.length === 0) {
    logger.success('No duplicates found!');
  } else {
    similarityPairs.slice(0, 10).forEach(pair => {
      logger.warn(`  "${pair.msg1}"`);
      logger.warn(`  "${pair.msg2}"`);
      logger.info(`  Similarity: ${(pair.score * 100).toFixed(0)}%\n`);
    });
  }
}

function calculateSimilarity(s1: string, s2: string): number {
  const words1 = s1.toLowerCase().split(/\s+/);
  const words2 = s2.toLowerCase().split(/\s+/);
  
  const set1 = new Set(words1);
  const set2 = new Set(words2);
  
  let intersection = 0;
  set1.forEach(word => {
    if (set2.has(word)) intersection++;
  });
  
  const union = new Set([...set1, ...set2]).size;
  return union > 0 ? intersection / union : 0;
}
