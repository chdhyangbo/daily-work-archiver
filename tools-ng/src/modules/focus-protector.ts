import { logger } from '../utils/logger.js';
import { readFile, writeFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import path from 'path';

export interface FocusSession {
  id: string;
  date: string;
  startTime: string;
  endTime?: string;
  duration?: number; // minutes
  task: string;
  interruptions: Interruption[];
  quality: number; // 1-10
  notes?: string;
}

export interface Interruption {
  time: string;
  type: 'notification' | 'meeting' | 'colleague' | 'self' | 'other';
  duration: number; // minutes
  recovered: boolean;
}

export interface FocusStats {
  totalSessions: number;
  totalFocusTime: number; // minutes
  averageSessionDuration: number;
  averageInterruptions: number;
  bestTimeOfDay: string;
  qualityTrend: 'improving' | 'stable' | 'declining';
}

export async function initFocusProtector(dataDir: string): Promise<string> {
  const focusDir = path.join(dataDir, 'focus');
  await ensureDir(focusDir);

  const indexFile = path.join(focusDir, 'index.json');
  try {
    await readFile(indexFile);
  } catch {
    await writeJsonFile(indexFile, { sessions: [] });
    logger.success('专注力保护系统已初始化');
  }

  return focusDir;
}

export async function startFocusSession(
  dataDir: string,
  task: string
): Promise<FocusSession> {
  const focusDir = await initFocusProtector(dataDir);
  const indexFile = path.join(focusDir, 'index.json');

  const data = await readJsonFile<{ sessions: FocusSession[] }>(indexFile) || { sessions: [] };

  const now = new Date();
  const session: FocusSession = {
    id: `focus_${Date.now()}`,
    date: now.toISOString().split('T')[0],
    startTime: now.toTimeString().slice(0, 5),
    task,
    interruptions: [],
    quality: 0
  };

  data.sessions.push(session);
  await writeJsonFile(indexFile, data);

  logger.section('🎯 专注时段已开始');
  logger.info(`任务: ${task}`);
  logger.info(`时间: ${session.startTime}`);
  logger.info('');
  logger.info('💡 INFJ 专注提示:');
  logger.info('- 关闭不必要的通知');
  logger.info('- 准备好水和必需品');
  logger.info('- 如果被打断，深呼吸，慢慢回到状态');
  logger.info('- 记住：质量比时长更重要');

  return session;
}

export async function endFocusSession(
  dataDir: string,
  sessionId: string,
  quality: number,
  notes?: string
): Promise<FocusSession> {
  const focusDir = await initFocusProtector(dataDir);
  const indexFile = path.join(focusDir, 'index.json');

  const data = await readJsonFile<{ sessions: FocusSession[] }>(indexFile);
  if (!data) {
    throw new Error('专注数据未初始化');
  }

  const sessionIndex = data.sessions.findIndex(s => s.id === sessionId);
  if (sessionIndex === -1) {
    throw new Error('专注时段未找到');
  }

  const session = data.sessions[sessionIndex];
  session.endTime = new Date().toTimeString().slice(0, 5);
  session.quality = Math.min(10, Math.max(1, quality));
  session.notes = notes;

  // Calculate duration
  const start = new Date(`${session.date}T${session.startTime}`);
  const end = new Date(`${session.date}T${session.endTime}`);
  session.duration = Math.round((end.getTime() - start.getTime()) / (1000 * 60));

  await writeJsonFile(indexFile, data);

  logger.section('✅ 专注时段已结束');
  logger.info(`任务: ${session.task}`);
  logger.info(`时长: ${session.duration} 分钟`);
  logger.info(`质量: ${session.quality}/10`);
  logger.info(`中断次数: ${session.interruptions.length}`);

  return session;
}

export async function logInterruption(
  dataDir: string,
  sessionId: string,
  type: Interruption['type'],
  duration: number
): Promise<FocusSession> {
  const focusDir = await initFocusProtector(dataDir);
  const indexFile = path.join(focusDir, 'index.json');

  const data = await readJsonFile<{ sessions: FocusSession[] }>(indexFile);
  if (!data) {
    throw new Error('专注数据未初始化');
  }

  const sessionIndex = data.sessions.findIndex(s => s.id === sessionId);
  if (sessionIndex === -1) {
    throw new Error('专注时段未找到');
  }

  const interruption: Interruption = {
    time: new Date().toTimeString().slice(0, 5),
    type,
    duration,
    recovered: false
  };

  data.sessions[sessionIndex].interruptions.push(interruption);
  await writeJsonFile(indexFile, data);

  logger.info(`⚠️ 记录中断: ${type} (${duration}分钟)`);
  logger.info('深呼吸，慢慢回到状态。没关系，继续就好。');

  return data.sessions[sessionIndex];
}

export async function analyzeFocusPattern(dataDir: string, days: number = 30): Promise<FocusStats> {
  const focusDir = await initFocusProtector(dataDir);
  const indexFile = path.join(focusDir, 'index.json');

  const data = await readJsonFile<{ sessions: FocusSession[] }>(indexFile);
  if (!data || data.sessions.length === 0) {
    return {
      totalSessions: 0,
      totalFocusTime: 0,
      averageSessionDuration: 0,
      averageInterruptions: 0,
      bestTimeOfDay: 'N/A',
      qualityTrend: 'stable'
    };
  }

  // Filter recent sessions
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);
  const recentSessions = data.sessions.filter(s => new Date(s.date) >= cutoffDate);

  const totalSessions = recentSessions.length;
  const totalFocusTime = recentSessions.reduce((sum, s) => sum + (s.duration || 0), 0);
  const averageSessionDuration = totalSessions > 0 ? Math.round(totalFocusTime / totalSessions) : 0;
  const averageInterruptions = totalSessions > 0 
    ? Math.round(recentSessions.reduce((sum, s) => sum + s.interruptions.length, 0) / totalSessions * 10) / 10
    : 0;

  // Find best time of day
  const hourQuality: Record<string, number[]> = {};
  for (const session of recentSessions) {
    const hour = session.startTime.split(':')[0];
    if (!hourQuality[hour]) hourQuality[hour] = [];
    hourQuality[hour].push(session.quality);
  }

  const hourAverages = Object.entries(hourQuality).map(([hour, qualities]) => ({
    hour,
    average: qualities.reduce((sum, q) => sum + q, 0) / qualities.length
  }));

  hourAverages.sort((a, b) => b.average - a.average);
  const bestTimeOfDay = hourAverages.length > 0 ? `${hourAverages[0].hour}:00` : 'N/A';

  // Calculate quality trend
  const midpoint = Math.floor(recentSessions.length / 2);
  const firstHalf = recentSessions.slice(0, midpoint);
  const secondHalf = recentSessions.slice(midpoint);

  const firstAvg = firstHalf.reduce((sum, s) => sum + s.quality, 0) / firstHalf.length;
  const secondAvg = secondHalf.reduce((sum, s) => sum + s.quality, 0) / secondHalf.length;

  let qualityTrend: FocusStats['qualityTrend'] = 'stable';
  if (secondAvg > firstAvg + 0.5) qualityTrend = 'improving';
  else if (secondAvg < firstAvg - 0.5) qualityTrend = 'declining';

  return {
    totalSessions,
    totalFocusTime,
    averageSessionDuration,
    averageInterruptions,
    bestTimeOfDay,
    qualityTrend
  };
}

export async function generateFocusReport(dataDir: string, days: number = 7): Promise<string> {
  let report = '## 🎯 专注力报告\n\n';

  const stats = await analyzeFocusPattern(dataDir, days);
  
  report += '### 📊 专注统计\n\n';
  report += `- 总专注时段: ${stats.totalSessions}\n`;
  report += `- 总专注时长: ${Math.round(stats.totalFocusTime / 60 * 10) / 10} 小时\n`;
  report += `- 平均时长: ${stats.averageSessionDuration} 分钟\n`;
  report += `- 平均中断: ${stats.averageInterruptions} 次/时段\n`;
  report += `- 最佳时段: ${stats.bestTimeOfDay}\n`;
  report += `- 质量趋势: ${stats.qualityTrend === 'improving' ? '📈 提升中' : stats.qualityTrend === 'declining' ? '📉 下降中' : '➡️ 稳定'}\n\n`;

  report += '### 💡 INFJ 专注建议\n\n';
  report += '- 在你的最佳时段安排深度工作\n';
  report += '- 接受中断是正常的，关键是快速恢复\n';
  report += '- 质量比时长更重要\n';
  report += '- 每次专注后给自己恢复的时间\n';
  report += '- 保护你的专注时间，学会说"不"\n\n';

  return report;
}
