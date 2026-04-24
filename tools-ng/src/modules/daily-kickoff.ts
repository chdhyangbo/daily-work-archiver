import { logger } from '../utils/logger.js';
import { readFile, writeFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import { getActiveGoals, getGoalsDueSoon, getOverdueGoals, generateGoalReport } from './goal-tracker.js';
import path from 'path';

export interface DailyKickoff {
  date: string;
  yesterdayCompleted: string[];
  todayMITs: string[]; // Most Important Tasks
  goalsDueSoon: string[];
  emotionalState: 'energized' | 'calm' | 'tired' | 'stressed' | 'excited';
  focusPlan: string;
  createdAt: string;
}

export interface KickoffData {
  kickoffs: DailyKickoff[];
}

const EMOTIONAL_STATE_LABELS = {
  energized: '精力充沛',
  calm: '平静专注',
  tired: '有些疲惫',
  stressed: '压力较大',
  excited: '兴奋期待'
};

export async function runDailyKickoff(dataDir: string): Promise<string> {
  const kickoffDir = path.join(dataDir, 'kickoffs');
  await ensureDir(kickoffDir);

  const today = new Date().toISOString().split('T')[0];
  
  logger.section('🌅 今日启动检查');
  logger.info(`日期: ${today}`);
  logger.info('');

  // Step 1: Review yesterday
  logger.info('📋 步骤 1: 回顾昨日完成情况');
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];
  
  // Try to load yesterday's report
  const yesterdayReport = path.join(dataDir, 'reports', 'daily', yesterdayStr.substring(0, 7), `${yesterdayStr}.md`);
  const yesterdayData = await readJsonFile<any>(yesterdayReport);
  
  logger.info('昨天完成了什么？（记录 1-3 项成就）');
  // In interactive mode, this would prompt user
  // For now, we'll generate a template

  // Step 2: Check goals
  logger.info('');
  logger.info('🎯 步骤 2: 检查目标状态');
  
  const dueSoonGoals = await getGoalsDueSoon(dataDir);
  const overdueGoals = await getOverdueGoals(dataDir);

  if (dueSoonGoals.length > 0) {
    logger.info('即将到期的目标:');
    for (const goal of dueSoonGoals) {
      const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      logger.info(`  - ${goal.title} (${goal.progress}%) - ${daysLeft}天后到期`);
    }
  }

  if (overdueGoals.length > 0) {
    logger.warn('需要关注的目标:');
    for (const goal of overdueGoals) {
      logger.warn(`  - ${goal.title} - 需要重新计划`);
    }
  }

  // Step 3: Set MITs (Most Important Tasks)
  logger.info('');
  logger.info('⭐ 步骤 3: 确认今日最重要的 3 件事 (MIT)');
  logger.info('1. [待填写]');
  logger.info('2. [待填写]');
  logger.info('3. [待填写]');

  // Step 4: Emotional check-in
  logger.info('');
  logger.info('💭 步骤 4: 情绪状态记录');
  logger.info('你现在感觉如何？');
  logger.info('  1. 精力充沛 - 准备好迎接挑战');
  logger.info('  2. 平静专注 - 适合深度工作');
  logger.info('  3. 有些疲惫 - 需要合理安排');
  logger.info('  4. 压力较大 - 先做简单的热身');
  logger.info('  5. 兴奋期待 - 保持这个状态！');

  // Step 5: Generate focus plan
  logger.info('');
  logger.info('🎯 步骤 5: 今日专注计划');
  generateFocusPlan(dataDir);

  // Generate kickoff template
  const kickoffTemplate = generateKickoffTemplate(today, dueSoonGoals, overdueGoals);
  
  // Save kickoff data
  const kickoffFile = path.join(kickoffDir, `${today}.json`);
  const kickoffData: DailyKickoff = {
    date: today,
    yesterdayCompleted: [],
    todayMITs: [],
    goalsDueSoon: dueSoonGoals.map(g => g.title),
    emotionalState: 'calm',
    focusPlan: '根据能量状态安排工作',
    createdAt: new Date().toISOString()
  };

  // Load or create kickoff data
  const allKickoffsFile = path.join(kickoffDir, 'index.json');
  const kickoffIndex = await readJsonFile<KickoffData>(allKickoffsFile) || { kickoffs: [] };
  kickoffIndex.kickoffs.push(kickoffData);
  await writeJsonFile(allKickoffsFile, kickoffIndex);

  logger.info('');
  logger.success('启动检查完成！开始高效的一天吧！');
  
  return kickoffTemplate;
}

function generateFocusPlan(dataDir: string): void {
  const now = new Date();
  const hour = now.getHours();
  
  logger.info('');
  logger.info('📅 建议的专注时段:');
  
  // INFJ-friendly focus suggestions
  if (hour < 10) {
    logger.info('  🌅 上午 (9:00-12:00): 深度工作时段');
    logger.info('     适合：复杂问题解决、创意设计、重要开发');
    logger.info('     建议：关闭通知，专注 MIT #1');
  } else if (hour < 14) {
    logger.info('  ☀️ 中午 (14:00-17:00): 协作与沟通时段');
    logger.info('     适合：会议、代码审查、文档编写');
    logger.info('     建议：处理需要交互的任务');
  } else {
    logger.info('  🌆 下午 (17:00-18:00): 总结与规划时段');
    logger.info('     适合：日报、复盘、明日计划');
    logger.info('     建议：整理今日成果，准备明天');
  }
  
  logger.info('');
  logger.info('💡 专注提示:');
  logger.info('  - 使用番茄工作法 (25分钟专注 + 5分钟休息)');
  logger.info('  - 每完成一个 MIT，给自己一个小奖励');
  logger.info('  - 如果被打断，深呼吸，慢慢回到状态');
}

function generateKickoffTemplate(
  today: string,
  dueSoonGoals: any[],
  overdueGoals: any[]
): string {
  let template = `# 每日启动检查 - ${today}\n\n`;
  
  template += '## 🌅 今日概览\n\n';
  template += '- **日期**: ' + today + '\n';
  template += '- **情绪状态**: [记录你的感受]\n';
  template += '- **能量水平**: [高/中/低]\n\n';
  
  template += '## ✅ 昨日成就\n\n';
  template += '1. [昨天完成了什么？]\n';
  template += '2. [有什么值得庆祝的？]\n';
  template += '3. [学到了什么？]\n\n';
  
  template += '## ⭐ 今日 MIT (最重要的 3 件事)\n\n';
  template += '1. [ ] \n';
  template += '2. [ ] \n';
  template += '3. [ ] \n\n';
  
  if (dueSoonGoals.length > 0) {
    template += '## ⏰ 即将到期的目标\n\n';
    for (const goal of dueSoonGoals) {
      const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      template += `- **${goal.title}** (${goal.progress}%) - ${daysLeft}天后\n`;
    }
    template += '\n';
  }
  
  if (overdueGoals.length > 0) {
    template += '## 💭 需要关注\n\n';
    for (const goal of overdueGoals) {
      template += `- **${goal.title}** - 需要重新计划\n`;
    }
    template += '\n';
  }
  
  template += '## 🎯 今日专注计划\n\n';
  template += '### 上午 (9:00-12:00)\n';
  template += '- 任务: [安排深度工作]\n';
  template += '- 环境: 关闭通知，专注模式\n\n';
  
  template += '### 下午 (14:00-17:00)\n';
  template += '- 任务: [安排协作任务]\n';
  template += '- 环境: 开放沟通\n\n';
  
  template += '### 傍晚 (17:00-18:00)\n';
  template += '- 任务: 日报、复盘、明日计划\n';
  template += '- 环境: 总结反思\n\n';
  
  template += '## 💭 今日反思\n\n';
  template += '- 什么让我充满能量？\n';
  template += '- 什么消耗了我的能量？\n';
  template += '- 今天我为长期目标做了什么？\n';
  template += '- 我对自己满意吗？为什么？\n';
  
  return template;
}

export async function getKickoffHistory(dataDir: string, days: number = 7): Promise<DailyKickoff[]> {
  const kickoffDir = path.join(dataDir, 'kickoffs');
  const allKickoffsFile = path.join(kickoffDir, 'index.json');
  
  const data = await readJsonFile<KickoffData>(allKickoffsFile);
  if (!data || data.kickoffs.length === 0) {
    return [];
  }
  
  // Return last N days
  return data.kickoffs.slice(-days);
}
