import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import path from 'path';

export interface QualityScore {
  hash: string;
  subject: string;
  score: number;
  grade: string;
  details: string[];
}

export async function scoreCommitQuality(
  projectPath: string,
  author: string,
  days: number = 30,
  outputDir: string
): Promise<void> {
  logger.section('Commit Quality Scorer');

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
    const scores: QualityScore[] = [];

    for (const commit of commits) {
      const [hash, subject] = commit.split('|');
      const score = calculateQualityScore(subject);
      scores.push(score);
    }

    // 统计分析
    const avgScore = scores.reduce((sum, s) => sum + s.score, 0) / scores.length;
    const gradeDistribution: Record<string, number> = {};
    scores.forEach(s => {
      gradeDistribution[s.grade] = (gradeDistribution[s.grade] || 0) + 1;
    });

    logger.success(`Total commits: ${scores.length}`);
    logger.info(`Average score: ${avgScore.toFixed(1)}`);
    logger.section('Grade Distribution:');
    Object.entries(gradeDistribution)
      .sort((a, b) => b[1] - a[1])
      .forEach(([grade, count]) => {
        logger.info(`  ${grade}: ${count} commits`);
      });

    // 保存报告
    await ensureDir(outputDir);
    const reportFile = path.join(outputDir, `quality-report-${new Date().toISOString().split('T')[0]}.md`);
    
    let report = `# Commit Quality Report\n\n`;
    report += `**Date**: ${new Date().toISOString().split('T')[0]}\n`;
    report += `**Total Commits**: ${scores.length}\n`;
    report += `**Average Score**: ${avgScore.toFixed(1)}\n\n`;

    report += '## Low Quality Commits (Need Improvement)\n\n';
    const lowQuality = scores.filter(s => s.score < 60);
    if (lowQuality.length > 0) {
      report += '| Hash | Subject | Score | Grade |\n|------|---------|-------|-------|\n';
      lowQuality.forEach(s => {
        report += `| ${s.hash.substring(0, 7)} | ${s.subject} | ${s.score} | ${s.grade} |\n`;
      });
    } else {
      report += 'All commits have good quality!\n';
    }

    await writeFile(reportFile, report);
    logger.success(`Report saved to: ${reportFile}`);
  } catch (error) {
    logger.error(`Error: ${(error as Error).message}`);
  }
}

function calculateQualityScore(subject: string): QualityScore {
  let score = 50;
  const details: string[] = [];

  // 长度检查
  if (subject.length >= 10 && subject.length <= 100) {
    score += 15;
    details.push('Length OK');
  } else if (subject.length >= 5) {
    score += 5;
    details.push('Short');
  } else {
    details.push('Too short');
  }

  // 格式检查
  const typeWords = ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf', '新增', '修复', '优化', '重构', '文档'];
  const hasType = typeWords.some(word => subject.toLowerCase().includes(word.toLowerCase()));
  if (hasType) {
    score += 20;
    details.push('Has type');
  } else {
    details.push('No type');
  }

  // Ticket检查
  const hasTicket = subject.includes('#') || (subject.includes('-') && /\d/.test(subject));
  if (hasTicket) {
    score += 15;
    details.push('Has ticket');
  } else {
    details.push('No ticket');
  }

  // 确定等级
  let grade = 'D';
  if (score >= 90) grade = 'A';
  else if (score >= 75) grade = 'B';
  else if (score >= 60) grade = 'C';

  return {
    hash: '',
    subject,
    score: Math.min(score, 100),
    grade,
    details
  };
}
