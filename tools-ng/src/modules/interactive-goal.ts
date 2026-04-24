import { logger } from '../utils/logger.js';
import { addGoal, Goal } from './goal-tracker.js';
import { createInterface } from 'readline';

export async function interactiveGoalSetup(dataDir: string): Promise<void> {
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout
  });

  const question = (query: string): Promise<string> => {
    return new Promise((resolve) => {
      rl.question(query, (answer) => {
        resolve(answer.trim());
      });
    });
  };

  try {
    logger.section('🎯 INFJ 目标设定向导');
    logger.info('让我们一步步设定对你有意义的目标\n');

    // Step 1: Goal title
    logger.info('步骤 1/6: 目标标题');
    const title = await question('请输入目标名称: ');
    if (!title) {
      logger.warn('目标名称不能为空');
      rl.close();
      return;
    }

    // Step 2: Goal level
    logger.info('\n步骤 2/6: 目标层级');
    logger.info('1. yearly   - 年度目标');
    logger.info('2. quarterly - 季度目标');
    logger.info('3. monthly  - 月度目标');
    logger.info('4. weekly   - 周度目标');
    logger.info('5. daily    - 每日目标');
    
    const levelChoice = await question('\n请选择 (1-5，默认 3): ');
    const levelMap: Record<string, Goal['level']> = {
      '1': 'yearly',
      '2': 'quarterly',
      '3': 'monthly',
      '4': 'weekly',
      '5': 'daily'
    };
    const level = levelMap[levelChoice] || 'monthly';

    // Step 3: Why (INFJ 最重要的部分)
    logger.info('\n步骤 3/6: 这个目标为什么对你重要？');
    logger.info('(这是 INFJ 最需要的意义感连接)');
    const why = await question('请输入原因: ');
    if (!why) {
      logger.warn('建议填写原因，这能帮助你保持动力');
    }

    // Step 4: Deadline
    logger.info('\n步骤 4/6: 截止日期');
    const defaultDeadline = getDefaultDeadline(level);
    const deadlineInput = await question(`请输入截止日期 (YYYY-MM-DD，默认 ${defaultDeadline}): `);
    const deadline = deadlineInput || defaultDeadline;

    // Validate date format
    if (!validateDate(deadline)) {
      logger.error('日期格式错误，请使用 YYYY-MM-DD 格式');
      rl.close();
      return;
    }

    // Step 5: Emotional value
    logger.info('\n步骤 5/6: 这个目标的情感价值');
    logger.info('1. growth     - 个人成长');
    logger.info('2. impact     - 影响力');
    logger.info('3. mastery    - 技能精通');
    logger.info('4. connection - 连接与贡献');
    
    const emotionalChoice = await question('\n请选择 (1-4，默认 1): ');
    const emotionalMap: Record<string, Goal['emotionalValue']> = {
      '1': 'growth',
      '2': 'impact',
      '3': 'mastery',
      '4': 'connection'
    };
    const emotionalValue = emotionalMap[emotionalChoice] || 'growth';

    // Step 6: Description (optional)
    logger.info('\n步骤 6/6: 目标描述（可选）');
    const description = await question('请输入详细描述（可跳过）: ');

    // Create goal
    logger.info('\n✨ 正在创建目标...\n');
    
    const goal = await addGoal(dataDir, {
      title,
      level,
      description: description || '',
      why: why || '未填写',
      keyResults: [],
      deadline,
      emotionalValue,
      reminders: [],
      status: 'active'
    });

    // Show summary
    logger.section('🎉 目标创建成功！');
    logger.info(`标题: ${goal.title}`);
    logger.info(`层级: ${goal.level}`);
    logger.info(`意义: ${goal.why}`);
    logger.info(`截止日期: ${goal.deadline}`);
    logger.info(`情感价值: ${goal.emotionalValue}`);
    logger.info('');
    logger.info('💡 提示:');
    logger.info('- 使用 npm run goal -- -a report 查看所有目标');
    logger.info('- 使用 npm run reminder -- -a schedule 生成提醒');
    logger.info('- 记得每天更新进度哦！');

  } catch (error) {
    logger.error(`创建目标时出错: ${(error as Error).message}`);
  } finally {
    rl.close();
  }
}

function getDefaultDeadline(level: Goal['level']): string {
  const now = new Date();
  
  switch (level) {
    case 'yearly':
      now.setFullYear(now.getFullYear() + 1);
      now.setMonth(11, 31);
      break;
    case 'quarterly':
      now.setMonth(now.getMonth() + 3);
      break;
    case 'monthly':
      now.setMonth(now.getMonth() + 1);
      break;
    case 'weekly':
      now.setDate(now.getDate() + 7);
      break;
    case 'daily':
      now.setDate(now.getDate() + 1);
      break;
  }
  
  return now.toISOString().split('T')[0];
}

function validateDate(dateStr: string): boolean {
  const regex = /^\d{4}-\d{2}-\d{2}$/;
  if (!regex.test(dateStr)) return false;
  
  const date = new Date(dateStr);
  return date instanceof Date && !isNaN(date.getTime());
}
