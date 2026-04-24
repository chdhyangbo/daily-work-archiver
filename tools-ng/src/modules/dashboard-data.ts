import { logger } from '../utils/logger.js';
import { readJsonFile, writeJsonFile, ensureDir } from '../core/fs.js';
import path from 'path';
import { analyzeQualityMetrics } from './quality-metrics.js';

export async function generateDashboardData(
  projectPaths: string[],
  author: string,
  outputBaseDir: string
): Promise<void> {
  logger.section('Generating Dashboard Data...');

  const { execSync } = await import('child_process');
  const { readdirSync, statSync } = await import('fs');

  let totalCommits = 0;
  const projects: Record<string, number> = {};
  const dailyCommits: Record<string, number> = {};
  const contributions: Array<{ date: string; count: number }> = [];
  const recentCommits: Array<any> = [];
  const hourlyDistribution: Record<string, number> = {};
  const typeDistribution: Record<string, number> = { FEATURE: 0, FIX: 0, REFACTOR: 0, DOCS: 0, TEST: 0, OTHER: 0 };

  // Load git activity data for detailed analysis
  const gitActivitiesDir = path.join(outputBaseDir, 'data', 'git-activities');
  let qualityMetrics: any = null;

  try {
    if (readdirSync(gitActivitiesDir).length > 0) {
      logger.info('Analyzing quality metrics from git activities...');
      qualityMetrics = await analyzeQualityMetrics(gitActivitiesDir, 90);
      logger.success('Quality metrics analysis complete');
    }
  } catch (error) {
    logger.warn(`Quality metrics analysis failed: ${(error as Error).message}`);
  }

  // Process git activity data for richer dashboard
  if (qualityMetrics) {
    try {
      const activityFiles = readdirSync(gitActivitiesDir)
        .filter(f => f.endsWith('.json') && f !== 'activity-index.json')
        .sort()
        .reverse();

      // Build contributions array and calculate stats
      for (const file of activityFiles) {
        const filePath = path.join(gitActivitiesDir, file);
        const data = await readJsonFile(filePath) as any;
        if (data.date && data.totalCommits) {
          contributions.push({ date: data.date, count: data.totalCommits });
          
          // Count daily commits
          dailyCommits[data.date] = data.totalCommits;
          totalCommits += data.totalCommits;
          
          // Count projects - handle both string and array formats
          if (data.projects) {
            const projectList = Array.isArray(data.projects) ? data.projects : [data.projects];
            projectList.forEach((proj: string) => {
              // Split comma-separated projects
              const projList = proj.split(',').map(p => p.trim()).filter(p => p);
              projList.forEach((project: string) => {
                projects[project] = (projects[project] || 0) + 1;
              });
            });
          }
          
          // Also count from commits
          if (data.commits) {
            data.commits.forEach((commit: any) => {
              if (commit.project) {
                projects[commit.project] = (projects[commit.project] || 0) + 1;
              }
            });
          }
          
          // Count types
          if (data.types) {
            Object.entries(data.types).forEach(([type, count]) => {
              if (typeDistribution[type] !== undefined) {
                typeDistribution[type] += count as number;
              }
            });
          }

          // Get recent commits
          if (data.commits && recentCommits.length < 25) {
            data.commits.forEach((commit: any) => {
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
            data.commits.forEach((commit: any) => {
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
    } catch (error) {
      logger.warn(`Error processing git activities: ${(error as Error).message}`);
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
    } else {
      const prevDate = new Date(sortedDates[i - 1]);
      const currDate = new Date(sortedDates[i]);
      const diff = Math.round((currDate.getTime() - prevDate.getTime()) / (24 * 60 * 60 * 1000));
      
      if (diff === 1) {
        tempStreak++;
      } else {
        tempStreak = 1;
      }
    }
    maxStreak = Math.max(maxStreak, tempStreak);
  }

  const dashboardData: any = {
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
  const docsServerPublic = path.resolve(outputBaseDir, '../../docs-server/public');
  const docsOutputFile = path.join(docsServerPublic, 'dashboard-data.json');
  
  try {
    const { copyFile } = await import('fs/promises');
    await ensureDir(docsServerPublic);
    await copyFile(outputFile, docsOutputFile);
    logger.success(`Dashboard data copied to: ${docsOutputFile}`);
  } catch (error) {
    logger.warn(`Could not copy to docs-server: ${(error as Error).message}`);
  }
}
