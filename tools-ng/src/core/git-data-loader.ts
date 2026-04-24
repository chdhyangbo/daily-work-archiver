import fs from 'fs';
import path from 'path';
import { logger } from '../utils/logger.js';
import { ensureDir } from '../core/fs.js';

/**
 * Git活动记录接口
 */
export interface GitActivityRecord {
  date: string;
  totalCommits: number;
  types: Record<string, number>;
  projects: string;
  commits: Array<{
    hash: string;
    shortHash: string;
    dateTime: string;
    date: string;
    time: string;
    hour: number;
    author: string;
    project: string;
    subject: string;
    message: string;
    type: string;
    insertions: number;
    deletions: number;
    changed: number;
  }>;
}

/**
 * 从git数据集加载指定日期范围的git活动
 */
export async function loadGitActivities(
  dataDir: string,
  startDate: string,
  endDate: string
): Promise<GitActivityRecord[]> {
  const activities: GitActivityRecord[] = [];
  
  try {
    // 获取日期范围内的所有日期
    const start = new Date(startDate);
    const end = new Date(endDate);
    const current = new Date(start);
    
    while (current <= end) {
      const dateStr = current.toISOString().split('T')[0];
      const filePath = path.join(dataDir, `${dateStr}.json`);
      
      if (fs.existsSync(filePath)) {
        try {
          const content = fs.readFileSync(filePath, 'utf-8');
          const activity = JSON.parse(content) as GitActivityRecord;
          activities.push(activity);
        } catch (error) {
          logger.warn(`Error reading ${filePath}: ${(error as Error).message}`);
        }
      }
      
      current.setDate(current.getDate() + 1);
    }
  } catch (error) {
    logger.error(`Error loading git activities: ${(error as Error).message}`);
  }
  
  return activities;
}

/**
 * 从数据集获取周报数据
 */
export async function getWeeklyReportData(
  dataDir: string,
  weekStart: string
): Promise<{
  dates: string[];
  gitStats: Record<string, { commits: number; insertions: number; deletions: number; projects: Record<string, number>; commitDetails?: any[] }>;
}> {
  const dates = getWeekRange(weekStart);
  const activities = await loadGitActivities(dataDir, dates[0], dates[dates.length - 1]);
  
  const gitStats: Record<string, any> = {};
  
  // 初始化所有日期的统计数据
  for (const date of dates) {
    gitStats[date] = {
      commits: 0,
      insertions: 0,
      deletions: 0,
      projects: {},
      commitDetails: []
    };
  }
  
  // 从活动记录中汇总数据
  for (const activity of activities) {
    const date = activity.date;
    if (!gitStats[date]) continue;
    
    gitStats[date].commits = activity.totalCommits;
    
    let totalInsertions = 0;
    let totalDeletions = 0;
    const projectCommits: Record<string, number> = {};
    const commitDetails: any[] = [];
    
    for (const commit of activity.commits) {
      totalInsertions += commit.insertions;
      totalDeletions += commit.deletions;
      
      if (!projectCommits[commit.project]) {
        projectCommits[commit.project] = 0;
      }
      projectCommits[commit.project]++;
      
      // 收集提交详情
      commitDetails.push({
        hash: commit.hash,
        shortHash: commit.shortHash,
        dateTime: commit.dateTime,
        date: commit.date,
        time: commit.time,
        author: commit.author,
        project: commit.project,
        subject: commit.subject,
        message: commit.message,
        type: commit.type,
        insertions: commit.insertions,
        deletions: commit.deletions,
        changed: commit.changed
      });
    }
    
    gitStats[date].insertions = totalInsertions;
    gitStats[date].deletions = totalDeletions;
    gitStats[date].projects = projectCommits;
    gitStats[date].commitDetails = commitDetails;
  }
  
  return { dates, gitStats };
}

/**
 * 从数据集获取月报数据
 */
export async function getMonthlyReportData(
  dataDir: string,
  month: string  // YYYY-MM
): Promise<{
  totalCommits: number;
  totalInsertions: number;
  totalDeletions: number;
  projectStats: Record<string, { commits: number; insertions: number; deletions: number }>;
  typeStats: Record<string, number>;
  dailyStats: Record<string, { commits: number; insertions: number; deletions: number }>;
}> {
  const [year, monthNum] = month.split('-').map(Number);
  const startDate = `${year}-${monthNum.toString().padStart(2, '0')}-01`;
  const lastDay = new Date(year, monthNum, 0).getDate();
  const endDate = `${year}-${monthNum.toString().padStart(2, '0')}-${lastDay}`;
  
  const activities = await loadGitActivities(dataDir, startDate, endDate);
  
  const stats = {
    totalCommits: 0,
    totalInsertions: 0,
    totalDeletions: 0,
    projectStats: {} as Record<string, any>,
    typeStats: {} as Record<string, number>,
    dailyStats: {} as Record<string, any>
  };
  
  for (const activity of activities) {
    stats.totalCommits += activity.totalCommits;
    stats.dailyStats[activity.date] = {
      commits: activity.totalCommits,
      insertions: 0,
      deletions: 0
    };
    
    let dayInsertions = 0;
    let dayDeletions = 0;
    
    for (const commit of activity.commits) {
      stats.totalInsertions += commit.insertions;
      stats.totalDeletions += commit.deletions;
      dayInsertions += commit.insertions;
      dayDeletions += commit.deletions;
      
      // 项目统计
      if (!stats.projectStats[commit.project]) {
        stats.projectStats[commit.project] = { commits: 0, insertions: 0, deletions: 0 };
      }
      stats.projectStats[commit.project].commits++;
      stats.projectStats[commit.project].insertions += commit.insertions;
      stats.projectStats[commit.project].deletions += commit.deletions;
      
      // 类型统计
      if (!stats.typeStats[commit.type]) {
        stats.typeStats[commit.type] = 0;
      }
      stats.typeStats[commit.type]++;
    }
    
    stats.dailyStats[activity.date].insertions = dayInsertions;
    stats.dailyStats[activity.date].deletions = dayDeletions;
  }
  
  return stats;
}

/**
 * 从数据集获取简历数据（指定日期范围）
 */
export async function getResumeData(
  dataDir: string,
  startDate: string,
  endDate: string
): Promise<{
  totalCommits: number;
  totalInsertions: number;
  totalDeletions: number;
  projects: Array<{ name: string; commits: number; insertions: number; deletions: number; highlights: string[] }>;
  achievements: string[];
}> {
  const activities = await loadGitActivities(dataDir, startDate, endDate);
  
  const projectMap: Record<string, { commits: number; insertions: number; deletions: number; subjects: string[] }> = {};
  let totalCommits = 0;
  let totalInsertions = 0;
  let totalDeletions = 0;
  
  for (const activity of activities) {
    totalCommits += activity.totalCommits;
    
    for (const commit of activity.commits) {
      totalInsertions += commit.insertions;
      totalDeletions += commit.deletions;
      
      if (!projectMap[commit.project]) {
        projectMap[commit.project] = { commits: 0, insertions: 0, deletions: 0, subjects: [] };
      }
      projectMap[commit.project].commits++;
      projectMap[commit.project].insertions += commit.insertions;
      projectMap[commit.project].deletions += commit.deletions;
      projectMap[commit.project].subjects.push(commit.subject);
    }
  }
  
  const projects = Object.entries(projectMap).map(([name, data]) => ({
    name,
    commits: data.commits,
    insertions: data.insertions,
    deletions: data.deletions,
    highlights: extractHighlights(data.subjects)
  }));
  
  return {
    totalCommits,
    totalInsertions,
    totalDeletions,
    projects,
    achievements: generateAchievements(totalCommits, totalInsertions, projects)
  };
}

/**
 * 提取项目亮点（提交信息中的关键描述）
 */
function extractHighlights(subjects: string[]): string[] {
  const highlights: string[] = [];
  const seen = new Set<string>();
  
  for (const subject of subjects) {
    // 提取有意义的描述（排除简单的fix等）
    if (subject.length > 10 && !seen.has(subject)) {
      seen.add(subject);
      highlights.push(subject);
      if (highlights.length >= 5) break; // 最多保留5个亮点
    }
  }
  
  return highlights;
}

/**
 * 生成成就列表
 */
function generateAchievements(
  totalCommits: number,
  totalInsertions: number,
  projects: Array<{ name: string; commits: number }>
): string[] {
  const achievements: string[] = [];
  
  if (totalCommits >= 100) achievements.push(`累计提交 ${totalCommits} 次`);
  if (totalInsertions >= 10000) achievements.push(`新增代码 ${totalInsertions.toLocaleString()} 行`);
  if (projects.length >= 5) achievements.push(`参与 ${projects.length} 个项目开发`);
  
  const topProject = projects.sort((a, b) => b.commits - a.commits)[0];
  if (topProject) {
    achievements.push(`核心贡献：${topProject.name} (${topProject.commits} 次提交)`);
  }
  
  return achievements;
}

/**
 * 获取一周的日期范围
 */
function getWeekRange(startDate: string): string[] {
  const dates: string[] = [];
  const start = new Date(startDate);
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(start);
    date.setDate(start.getDate() + i);
    dates.push(date.toISOString().split('T')[0]);
  }
  
  return dates;
}

/**
 * 确保当日git数据已归档（如果不存在则提示）
 */
export async function ensureTodayDataExists(dataDir: string): Promise<boolean> {
  const today = new Date().toISOString().split('T')[0];
  const filePath = path.join(dataDir, `${today}.json`);
  
  if (!fs.existsSync(filePath)) {
    logger.warn(`今日数据尚未归档，请先运行: npm run aggregate`);
    return false;
  }
  
  return true;
}
