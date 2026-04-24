import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { ensureDir, writeJsonFile, readJsonFile } from '../core/fs.js';
import path from 'path';

/**
 * 成就定义接口
 */
export interface Achievement {
  id: string;
  name: string;
  description: string;
  requirement: string;
  icon: string;
  category: string;
  points: number;
  condition: (stats: AchievementStats) => boolean;
}

export interface AchievementStats {
  totalCommits: number;
  projectCount: number;
  maxStreak: number;
  maxDailyCommits: number;
  vueCommits: number;
  reactCommits: number;
  tsCommits: number;
  frontendCommits: number;
  backendCommits: number;
  componentCount: number;
  uiPageCount: number;
  responsivePageCount: number;
  aiIntegrationCount: number;
  promptCount: number;
  modelTrainingCount: number;
  aiPipelineCount: number;
  ragSystemCount: number;
  agentCount: number;
  apiCount: number;
  databaseTableCount: number;
  codeReviewCount: number;
  bugFixCount: number;
  testCaseCount: number;
  perfOptimizationCount: number;
  docCount: number;
}

export interface AchievementLevel {
  name: string;
  minPoints: number;
  icon: string;
}

export interface AchievementResult {
  unlocked: number;
  totalPoints: number;
  totalPossible: number;
  list: Array<{
    id: string;
    name: string;
    description: string;
    requirement: string;
    icon: string;
    category: string;
    points: number;
    unlocked: boolean;
    progress: number;
  }>;
}

/**
 * 等级系统
 */
export const Levels: AchievementLevel[] = [
  { name: '代码新人', minPoints: 0, icon: '🥉' },
  { name: '初级开发', minPoints: 100, icon: '🥈' },
  { name: '中级开发', minPoints: 300, icon: '🥇' },
  { name: '高级开发', minPoints: 600, icon: '💎' },
  { name: '专家', minPoints: 1000, icon: '👑' },
  { name: '大师', minPoints: 1500, icon: '🌟' },
  { name: '传奇', minPoints: 2000, icon: '🔥' },
  { name: '神话', minPoints: 3000, icon: '🚀' }
];

/**
 * 成就定义
 */
export const Achievements: Achievement[] = [
  // 基础里程碑成就
  {
    id: 'FIRST_COMMIT',
    name: '初次提交',
    description: '完成第一次代码提交',
    requirement: '提交次数 >= 1',
    icon: '🌱',
    category: 'milestone',
    points: 10,
    condition: (stats) => stats.totalCommits >= 1
  },
  {
    id: 'COMMIT_10',
    name: '初出茅庐',
    description: '累计提交10次',
    requirement: '提交次数 >= 10',
    icon: '🌿',
    category: 'milestone',
    points: 20,
    condition: (stats) => stats.totalCommits >= 10
  },
  {
    id: 'COMMIT_100',
    name: '代码工匠',
    description: '累计提交100次',
    requirement: '提交次数 >= 100',
    icon: '🌳',
    category: 'milestone',
    points: 50,
    condition: (stats) => stats.totalCommits >= 100
  },
  {
    id: 'COMMIT_1000',
    name: '代码大师',
    description: '累计提交1000次',
    requirement: '提交次数 >= 1000',
    icon: '🏆',
    category: 'milestone',
    points: 200,
    condition: (stats) => stats.totalCommits >= 1000
  },
  {
    id: 'STREAK_3',
    name: '三日连续',
    description: '连续3天有提交记录',
    requirement: '连续提交天数 >= 3',
    icon: '🔥',
    category: 'consistency',
    points: 15,
    condition: (stats) => stats.maxStreak >= 3
  },
  {
    id: 'STREAK_7',
    name: '周周不懈',
    description: '连续7天有提交记录',
    requirement: '连续提交天数 >= 7',
    icon: '⚡',
    category: 'consistency',
    points: 30,
    condition: (stats) => stats.maxStreak >= 7
  },
  {
    id: 'STREAK_30',
    name: '月度达人',
    description: '连续30天有提交记录',
    requirement: '连续提交天数 >= 30',
    icon: '🌙',
    category: 'consistency',
    points: 100,
    condition: (stats) => stats.maxStreak >= 30
  },
  {
    id: 'MULTI_PROJECT',
    name: '多面手',
    description: '参与3个以上项目',
    requirement: '参与项目数 >= 3',
    icon: '🎯',
    category: 'contribution',
    points: 30,
    condition: (stats) => stats.projectCount >= 3
  },
  {
    id: 'PROJECT_10',
    name: '项目专家',
    description: '参与10个以上项目',
    requirement: '参与项目数 >= 10',
    icon: '🚀',
    category: 'contribution',
    points: 80,
    condition: (stats) => stats.projectCount >= 10
  },
  {
    id: 'FULLSTACK_DEV',
    name: '全栈开发者',
    description: '同时在前端和后端项目中有提交',
    requirement: '前端和后端都有提交记录',
    icon: '🌐',
    category: 'fullstack',
    points: 100,
    condition: (stats) => stats.frontendCommits > 0 && stats.backendCommits > 0
  },
  {
    id: 'BUG_HUNTER',
    name: 'Bug猎手',
    description: '修复100个以上Bug',
    requirement: 'Bug修复数量 >= 100',
    icon: '🐛',
    category: 'engineering',
    points: 80,
    condition: (stats) => stats.bugFixCount >= 100
  }
];

/**
 * 获取Git统计数据
 */
export async function getGitStatistics(
  projectPaths: string[],
  author: string
): Promise<AchievementStats> {
  const stats: AchievementStats = {
    totalCommits: 0,
    projectCount: 0,
    maxStreak: 0,
    maxDailyCommits: 0,
    vueCommits: 0,
    reactCommits: 0,
    tsCommits: 0,
    frontendCommits: 0,
    backendCommits: 0,
    componentCount: 0,
    uiPageCount: 0,
    responsivePageCount: 0,
    aiIntegrationCount: 0,
    promptCount: 0,
    modelTrainingCount: 0,
    aiPipelineCount: 0,
    ragSystemCount: 0,
    agentCount: 0,
    apiCount: 0,
    databaseTableCount: 0,
    codeReviewCount: 0,
    bugFixCount: 0,
    testCaseCount: 0,
    perfOptimizationCount: 0,
    docCount: 0
  };

  const dailyCommits: Record<string, number> = {};
  const projectCommits: Record<string, number> = {};

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

          const logCommand = `git -c core.quotepath=false log --all --author="${author}" --pretty=format:"%H|%ad|%s" --date=format:"%Y-%m-%d"`;
          const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

          if (commitsOutput.trim()) {
            const commitList = commitsOutput.split('\n').filter(line => line.trim());

            if (!projectCommits[projectName]) {
              projectCommits[projectName] = 0;
            }
            projectCommits[projectName] += commitList.length;
            stats.totalCommits += commitList.length;

            for (const commit of commitList) {
              const parts = commit.split('|');
              const date = parts[1];
              const message = parts[2];

              if (!dailyCommits[date]) {
                dailyCommits[date] = 0;
              }
              dailyCommits[date]++;

              // 分类统计（简化版）
              if (message.toLowerCase().includes('fix') || message.toLowerCase().includes('修复')) {
                stats.bugFixCount++;
              }
              if (message.toLowerCase().includes('test') || message.toLowerCase().includes('测试')) {
                stats.testCaseCount++;
              }
              if (message.toLowerCase().includes('docs') || message.toLowerCase().includes('文档')) {
                stats.docCount++;
              }
            }
          }
        } catch (error) {
          logger.warn(`    Error in project ${projectName}: ${(error as Error).message}`);
        }
      }
    } catch (error) {
      logger.warn(`Error scanning ${rootPath}: ${(error as Error).message}`);
    }
  }

  stats.projectCount = Object.keys(projectCommits).length;

  // 计算最大连续提交天数
  const sortedDates = Object.keys(dailyCommits).sort();
  let currentStreak = 0;
  let maxStreak = 0;
  let lastDate: Date | null = null;

  for (const date of sortedDates) {
    const currentDate = new Date(date);
    if (lastDate) {
      const diff = (currentDate.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24);
      if (diff === 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > maxStreak) {
      maxStreak = currentStreak;
    }
    lastDate = currentDate;
  }

  stats.maxStreak = maxStreak;
  stats.maxDailyCommits = Math.max(...Object.values(dailyCommits), 0);

  return stats;
}

/**
 * 检查成就
 */
export function checkAchievements(stats: AchievementStats): AchievementResult {
  const unlocked: Achievement[] = [];
  let totalPoints = 0;
  const list: AchievementResult['list'] = [];

  for (const achievement of Achievements) {
    const result = achievement.condition(stats);

    list.push({
      id: achievement.id,
      name: achievement.name,
      description: achievement.description,
      requirement: achievement.requirement,
      icon: achievement.icon,
      category: achievement.category,
      points: achievement.points,
      unlocked: result,
      progress: result ? 100 : 0
    });

    if (result) {
      unlocked.push(achievement);
      totalPoints += achievement.points;
    }
  }

  return {
    unlocked: unlocked.length,
    totalPoints,
    totalPossible: Achievements.reduce((sum, a) => sum + a.points, 0),
    list
  };
}

/**
 * 获取当前等级
 */
export function getCurrentLevel(points: number): {
  current: AchievementLevel;
  next: AchievementLevel | null;
  progress: number;
} {
  let currentLevel = Levels[0];
  let nextLevel: AchievementLevel | null = null;
  let progress = 100;

  for (let i = 0; i < Levels.length; i++) {
    if (points >= Levels[i].minPoints) {
      currentLevel = Levels[i];
    }
    if (Levels[i].minPoints > points && !nextLevel) {
      nextLevel = Levels[i];
      const prevLevel = Levels[i - 1];
      const range = Levels[i].minPoints - prevLevel.minPoints;
      const earned = points - prevLevel.minPoints;
      progress = Math.round((earned / range) * 100);
      break;
    }
  }

  return { current: currentLevel, next: nextLevel, progress };
}

/**
 * 主函数：检查成就
 */
export async function runAchievementSystem(
  action: string,
  projectPaths: string[],
  author: string,
  outputPath: string
): Promise<void> {
  await ensureDir(outputPath);

  if (action === 'check') {
    logger.section('Checking Achievements...');

    const stats = await getGitStatistics(projectPaths, author);
    const achievements = checkAchievements(stats);
    const level = getCurrentLevel(achievements.totalPoints);

    const dataFile = path.join(outputPath, 'achievements.json');
    await writeJsonFile(dataFile, {
      lastCheck: new Date().toISOString(),
      stats: {
        totalCommits: stats.totalCommits,
        projectCount: stats.projectCount,
        maxStreak: stats.maxStreak
      },
      achievements: {
        unlocked: achievements.unlocked,
        totalPoints: achievements.totalPoints,
        totalPossible: achievements.totalPossible,
        list: achievements.list
      },
      level: {
        current: level.current,
        next: level.next,
        progress: level.progress
      }
    });

    logger.success(`Level: ${level.current.icon} ${level.current.name}`);
    logger.info(`Points: ${achievements.totalPoints} / ${achievements.totalPossible}`);
    logger.info(`Progress: ${level.progress}%`);
    logger.success(`Unlocked: ${achievements.unlocked} / ${Achievements.length}`);

    logger.section('Unlocked Achievements:');
    achievements.list
      .filter(a => a.unlocked)
      .forEach(a => {
        logger.info(`  ${a.icon} ${a.name} - ${a.description} (+${a.points}pts)`);
      });

    logger.info(`\nData saved to: ${dataFile}`);
  } else if (action === 'list') {
    const dataFile = path.join(outputPath, 'achievements.json');
    const data = await readJsonFile<any>(dataFile);

    if (data) {
      logger.section('Current Status');
      logger.info(`Level: ${data.level.current.name}`);
      logger.info(`Points: ${data.achievements.totalPoints}`);
      logger.success(`Unlocked: ${data.achievements.unlocked} / ${Achievements.length}`);

      logger.section('All Achievements:');
      data.achievements.list.forEach((ach: any) => {
        if (ach.unlocked) {
          logger.success(`  ${ach.icon} ${ach.name}`);
        } else {
          logger.info(`  ${ach.icon} ${ach.name} (locked)`);
        }
      });
    } else {
      logger.warn('No data found. Run with action=check first.');
    }
  } else {
    logger.warn('Usage: npm start -- achievement -a check|list');
  }
}
