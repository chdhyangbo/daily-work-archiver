import { logger } from '../utils/logger.js';
import { readFile, writeFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import path from 'path';
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const INFJ_REMINDER_MESSAGES = {
    upcoming: (goal, days) => `「${goal}」对你很重要，还有 ${days} 天，今天可以为它做些什么？`,
    today: (goal) => `今天是推进「${goal}」的好时机，需要我帮你拆解第一步吗？`,
    overdue: (goal) => `「${goal}」暂时被搁置了，这很正常。什么时候重新拾起它？`,
    completed: (goal) => `🎉 太棒了！「${goal}」完成了！这对你意味着什么？`,
    inspiration: (goal) => `想想「${goal}」实现后的样子，那会是多么美好的改变？`
};
const EMOTIONAL_VALUE_LABELS = {
    growth: '个人成长',
    impact: '影响力',
    mastery: '技能精通',
    connection: '连接与贡献'
};
export async function initGoalTracker(dataDir) {
    const goalDir = path.join(dataDir, 'goals');
    await ensureDir(goalDir);
    await ensureDir(path.join(goalDir, 'yearly'));
    await ensureDir(path.join(goalDir, 'quarterly'));
    await ensureDir(path.join(goalDir, 'monthly'));
    await ensureDir(path.join(goalDir, 'weekly'));
    await ensureDir(path.join(goalDir, 'daily'));
    const indexFile = path.join(goalDir, 'index.json');
    const goalData = {
        goals: [],
        lastReview: new Date().toISOString()
    };
    try {
        await readFile(indexFile);
    }
    catch {
        await writeFile(indexFile, JSON.stringify(goalData, null, 2));
        logger.success('目标追踪系统已初始化');
    }
    return goalDir;
}
export async function addGoal(dataDir, goal) {
    const goalDir = await initGoalTracker(dataDir);
    const indexFile = path.join(goalDir, 'index.json');
    const data = await readJsonFile(indexFile) || { goals: [], lastReview: new Date().toISOString() };
    const newGoal = {
        ...goal,
        id: `goal_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        progress: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        status: 'active'
    };
    data.goals.push(newGoal);
    await writeJsonFile(indexFile, data);
    logger.section('✨ 新目标已创建');
    logger.info(`标题: ${newGoal.title}`);
    logger.info(`层级: ${newGoal.level}`);
    logger.info(`意义: ${newGoal.why}`);
    logger.info(`情感价值: ${EMOTIONAL_VALUE_LABELS[newGoal.emotionalValue]}`);
    logger.info(`截止日期: ${newGoal.deadline}`);
    return newGoal;
}
export async function updateGoalProgress(dataDir, goalId, progress, keyResultUpdates) {
    const goalDir = path.join(dataDir, 'goals');
    const indexFile = path.join(goalDir, 'index.json');
    const data = await readJsonFile(indexFile);
    if (!data) {
        throw new Error('目标数据未初始化');
    }
    const goalIndex = data.goals.findIndex(g => g.id === goalId);
    if (goalIndex === -1) {
        throw new Error(`目标未找到: ${goalId}`);
    }
    const goal = data.goals[goalIndex];
    goal.progress = Math.min(100, Math.max(0, progress));
    goal.updatedAt = new Date().toISOString();
    if (keyResultUpdates) {
        for (const update of keyResultUpdates) {
            const krIndex = goal.keyResults.findIndex(kr => kr.id === update.keyResultId);
            if (krIndex !== -1) {
                goal.keyResults[krIndex].progress = Math.min(100, Math.max(0, update.progress));
            }
        }
    }
    if (goal.progress === 100 && goal.status === 'active') {
        goal.status = 'completed';
        logger.success(INFJ_REMINDER_MESSAGES.completed(goal.title));
    }
    await writeJsonFile(indexFile, data);
    return goal;
}
export async function getActiveGoals(dataDir, level) {
    const goalDir = path.join(dataDir, 'goals');
    const indexFile = path.join(goalDir, 'index.json');
    const data = await readJsonFile(indexFile);
    if (!data) {
        return [];
    }
    let goals = data.goals.filter(g => g.status === 'active');
    if (level) {
        goals = goals.filter(g => g.level === level);
    }
    return goals.sort((a, b) => new Date(a.deadline).getTime() - new Date(b.deadline).getTime());
}
export async function getGoalsDueSoon(dataDir, days = 7) {
    const goals = await getActiveGoals(dataDir);
    const now = new Date();
    const future = new Date();
    future.setDate(future.getDate() + days);
    return goals.filter(goal => {
        const deadline = new Date(goal.deadline);
        return deadline >= now && deadline <= future;
    });
}
export async function getOverdueGoals(dataDir) {
    const goals = await getActiveGoals(dataDir);
    const now = new Date();
    return goals.filter(goal => new Date(goal.deadline) < now);
}
export async function generateGoalReport(dataDir, level) {
    const goals = await getActiveGoals(dataDir, level);
    const overdueGoals = await getOverdueGoals(dataDir);
    const dueSoonGoals = await getGoalsDueSoon(dataDir);
    let report = '## 🎯 目标追踪报告\n\n';
    if (goals.length === 0 && overdueGoals.length === 0) {
        report += '当前没有活跃目标。是时候设定一些对你有意义的目标了！\n';
        return report;
    }
    // 即将到期
    if (dueSoonGoals.length > 0) {
        report += '### ⏰ 即将到期（7天内）\n\n';
        for (const goal of dueSoonGoals) {
            const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
            report += `- **${goal.title}** (${goal.progress}%) - ${daysLeft}天后到期\n`;
            report += `  - 意义: ${goal.why}\n`;
        }
        report += '\n';
    }
    // 逾期目标（温和提醒）
    if (overdueGoals.length > 0) {
        report += '### 💭 需要关注\n\n';
        for (const goal of overdueGoals) {
            const daysOverdue = Math.ceil((Date.now() - new Date(goal.deadline).getTime()) / (1000 * 60 * 60 * 24));
            report += `- **${goal.title}** (${goal.progress}%) - 已过期 ${daysOverdue} 天\n`;
            report += `  - ${INFJ_REMINDER_MESSAGES.overdue(goal.title)}\n`;
        }
        report += '\n';
    }
    // 按层级分组
    if (goals.length > 0) {
        const levels = ['quarterly', 'monthly', 'weekly', 'daily'];
        for (const level of levels) {
            const levelGoals = goals.filter(g => g.level === level);
            if (levelGoals.length > 0) {
                const levelLabels = {
                    yearly: '年度目标',
                    quarterly: '季度目标',
                    monthly: '月度目标',
                    weekly: '周度目标',
                    daily: '每日目标'
                };
                report += `### ${levelLabels[level]}\n\n`;
                for (const goal of levelGoals) {
                    const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
                    const progressBar = createProgressBar(goal.progress);
                    report += `- **${goal.title}** ${progressBar} ${goal.progress}%\n`;
                    report += `  - 情感价值: ${EMOTIONAL_VALUE_LABELS[goal.emotionalValue]}\n`;
                    report += `  - 截止: ${goal.deadline} (${daysLeft > 0 ? daysLeft + '天' : '已过期'})\n`;
                    if (goal.keyResults.length > 0) {
                        report += '  - 关键结果:\n';
                        for (const kr of goal.keyResults) {
                            report += `    - ${kr.title}: ${kr.progress}%\n`;
                        }
                    }
                }
                report += '\n';
            }
        }
    }
    // 统计信息
    const avgProgress = goals.length > 0
        ? Math.round(goals.reduce((sum, g) => sum + g.progress, 0) / goals.length)
        : 0;
    report += '### 📊 统计\n\n';
    report += `- 活跃目标: ${goals.length} 个\n`;
    report += `- 平均进度: ${avgProgress}%\n`;
    report += `- 需要关注: ${overdueGoals.length} 个\n`;
    return report;
}
export async function reviewGoals(dataDir) {
    const goalDir = path.join(dataDir, 'goals');
    const indexFile = path.join(goalDir, 'index.json');
    const data = await readJsonFile(indexFile);
    if (!data) {
        return '目标数据未初始化';
    }
    data.lastReview = new Date().toISOString();
    await writeJsonFile(indexFile, data);
    let review = '## 🌟 目标回顾与反思\n\n';
    review += '### 反思引导问题\n\n';
    review += '1. **意义对齐**: 这些目标仍然对你重要吗？为什么？\n';
    review += '2. **进度评估**: 什么在帮助你前进？什么在阻碍你？\n';
    review += '3. **能量检查**: 哪些目标让你充满能量？哪些消耗你的能量？\n';
    review += '4. **调整需求**: 需要调整目标或时间线吗？\n';
    review += '5. **下一步行动**: 本周/月最重要的行动是什么？\n\n';
    const activeGoals = data.goals.filter(g => g.status === 'active');
    if (activeGoals.length > 0) {
        review += '### 当前目标状态\n\n';
        for (const goal of activeGoals) {
            review += `- **${goal.title}** (${goal.progress}%)\n`;
            review += `  - 为什么重要: ${goal.why}\n`;
            review += `  - 当前感受: [记录你对这个目标的感受]\n`;
        }
    }
    return review;
}
function createProgressBar(progress) {
    const filled = Math.round(progress / 10);
    const empty = 10 - filled;
    return '█'.repeat(filled) + '░'.repeat(empty);
}
//# sourceMappingURL=goal-tracker.js.map