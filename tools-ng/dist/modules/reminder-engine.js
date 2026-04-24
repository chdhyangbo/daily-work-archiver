import { logger } from '../utils/logger.js';
import { notifyUser } from './notification.js';
import { readFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import { getActiveGoals, getGoalsDueSoon, getOverdueGoals } from './goal-tracker.js';
import path from 'path';
const DEFAULT_CONFIG = {
    enabled: true,
    style: 'gentle',
    times: ['09:00', '14:00', '17:00'],
    channels: ['notification', 'terminal'],
    advanceDays: [3, 1, 0]
};
// INFJ-friendly message templates
const MESSAGE_TEMPLATES = {
    gentle: {
        inspiration: (goal, days) => `想想「${goal}」实现后的样子，还有 ${days} 天，今天可以为它做些什么？`,
        preparation: (goal) => `明天就是推进「${goal}」的时候了，今晚可以准备些什么？`,
        action: (goal) => `今天是推进「${goal}」的好时机，需要我帮你拆解第一步吗？`,
        followup: (goal) => `「${goal}」暂时被搁置了，这很正常。什么时候重新拾起它？`,
        completed: (goal) => `🎉 太棒了！「${goal}」完成了！这对你意味着什么？花点时间庆祝一下吧。`
    },
    direct: {
        inspiration: (goal, days) => `「${goal}」还有 ${days} 天到期，开始行动吧！`,
        preparation: (goal) => `明天需要推进「${goal}」，做好准备。`,
        action: (goal) => `今天是完成「${goal}」的关键日，立即行动！`,
        followup: (goal) => `「${goal}」已过期，需要重新计划。`,
        completed: (goal) => `✅ 「${goal}」已完成！`
    },
    motivational: {
        inspiration: (goal, days) => `你离「${goal}」的实现只有 ${days} 天了！每一次努力都在让你变得更好！`,
        preparation: (goal) => `「${goal}」就在明天！你已经准备好了，相信自己！`,
        action: (goal) => `今天就是改变的一天！推进「${goal}」，你可以的！`,
        followup: (goal) => `挫折是成长的一部分。「${goal}」等你重新出发！`,
        completed: (goal) => `🌟 你做到了！「${goal}」完成！你的努力证明了你的能力！`
    }
};
export async function initReminderSystem(dataDir) {
    const reminderDir = path.join(dataDir, 'reminders');
    await ensureDir(reminderDir);
    await ensureDir(path.join(reminderDir, 'history'));
    const configFile = path.join(reminderDir, 'config.json');
    const scheduleFile = path.join(reminderDir, 'schedule.json');
    try {
        await readFile(configFile);
    }
    catch {
        await writeJsonFile(configFile, DEFAULT_CONFIG);
        logger.success('提醒系统已初始化（INFJ 温和模式）');
    }
    try {
        await readFile(scheduleFile);
    }
    catch {
        await writeJsonFile(scheduleFile, { schedules: [] });
    }
    return reminderDir;
}
export async function generateReminderSchedules(dataDir, goals) {
    const reminderDir = await initReminderSystem(dataDir);
    const scheduleFile = path.join(reminderDir, 'schedule.json');
    const configFile = await readJsonFile(path.join(reminderDir, 'config.json'));
    if (!configFile?.enabled) {
        logger.info('提醒系统已禁用');
        return [];
    }
    const activeGoals = goals || await getActiveGoals(dataDir);
    const schedules = [];
    const now = new Date();
    for (const goal of activeGoals) {
        const deadline = new Date(goal.deadline);
        const daysUntilDeadline = Math.ceil((deadline.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        // Generate reminders based on advance days
        for (const advanceDay of configFile.advanceDays) {
            const reminderDate = new Date(deadline);
            reminderDate.setDate(reminderDate.getDate() - advanceDay);
            // Only schedule future reminders
            if (reminderDate >= now) {
                let reminderType;
                let message;
                if (advanceDay >= 3) {
                    reminderType = 'inspiration';
                    message = MESSAGE_TEMPLATES[configFile.style].inspiration(goal.title, advanceDay);
                }
                else if (advanceDay === 1) {
                    reminderType = 'preparation';
                    message = MESSAGE_TEMPLATES[configFile.style].preparation(goal.title);
                }
                else {
                    reminderType = 'action';
                    message = MESSAGE_TEMPLATES[configFile.style].action(goal.title);
                }
                schedules.push({
                    id: `reminder_${goal.id}_${advanceDay}d`,
                    goalId: goal.id,
                    goalTitle: goal.title,
                    scheduledTime: reminderDate.toISOString(),
                    reminderType,
                    message,
                    sent: false,
                    createdAt: now.toISOString()
                });
            }
        }
    }
    // Load existing schedules and merge
    const existingData = await readJsonFile(scheduleFile);
    const existingSchedules = existingData?.schedules || [];
    // Keep unsent schedules and add new ones
    const mergedSchedules = [
        ...existingSchedules.filter(s => !s.sent),
        ...schedules.filter(s => !existingSchedules.find(es => es.id === s.id))
    ];
    await writeJsonFile(scheduleFile, { schedules: mergedSchedules });
    return schedules;
}
export async function checkAndSendReminders(dataDir) {
    const reminderDir = await initReminderSystem(dataDir);
    const scheduleFile = path.join(reminderDir, 'schedule.json');
    const configFile = await readJsonFile(path.join(reminderDir, 'config.json'));
    if (!configFile?.enabled) {
        return 0;
    }
    const data = await readJsonFile(scheduleFile);
    if (!data || data.schedules.length === 0) {
        return 0;
    }
    const now = new Date();
    let sentCount = 0;
    for (const schedule of data.schedules) {
        if (schedule.sent)
            continue;
        const scheduledTime = new Date(schedule.scheduledTime);
        // Check if it's time to send (within 1 hour window)
        const timeDiff = Math.abs(now.getTime() - scheduledTime.getTime());
        if (timeDiff <= 3600000) { // 1 hour
            // Send reminder through configured channels
            for (const channel of configFile.channels) {
                if (channel === 'notification') {
                    notifyUser('🎯 目标提醒', schedule.message);
                }
                else if (channel === 'terminal') {
                    logger.section('🎯 目标提醒');
                    logger.info(schedule.message);
                }
            }
            schedule.sent = true;
            schedule.sentAt = now.toISOString();
            sentCount++;
            // Archive to history
            const historyFile = path.join(reminderDir, 'history', `${schedule.id}.json`);
            await writeJsonFile(historyFile, schedule);
        }
    }
    // Update schedule file
    data.schedules = data.schedules.filter(s => !s.sent);
    await writeJsonFile(scheduleFile, data);
    if (sentCount > 0) {
        logger.success(`已发送 ${sentCount} 个提醒`);
    }
    return sentCount;
}
export async function checkOverdueGoals(dataDir) {
    const overdueGoals = await getOverdueGoals(dataDir);
    const configFile = await readJsonFile(path.join(dataDir, 'reminders', 'config.json'));
    const style = configFile?.style || 'gentle';
    const messages = [];
    for (const goal of overdueGoals) {
        const message = MESSAGE_TEMPLATES[style].followup(goal.title);
        messages.push(message);
    }
    return messages;
}
export async function generateReminderReport(dataDir) {
    const reminderDir = await initReminderSystem(dataDir);
    const historyDir = path.join(reminderDir, 'history');
    let report = '## 📬 提醒历史\n\n';
    // This would list reminder history - simplified for now
    report += '提醒系统正在运行中...\n\n';
    const dueSoonGoals = await getGoalsDueSoon(dataDir);
    if (dueSoonGoals.length > 0) {
        report += '### 即将触发的提醒\n\n';
        for (const goal of dueSoonGoals) {
            const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
            report += `- **${goal.title}**: ${daysLeft} 天后到期\n`;
        }
    }
    return report;
}
//# sourceMappingURL=reminder-engine.js.map