import { logger } from '../utils/logger.js';
import { readFile, ensureDir, readJsonFile, writeJsonFile } from '../core/fs.js';
import path from 'path';
const MOOD_LABELS = {
    energized: '精力充沛',
    calm: '平静专注',
    tired: '疲惫',
    stressed: '压力大',
    excited: '兴奋',
    anxious: '焦虑',
    neutral: '平静'
};
export async function initEnergyTracker(dataDir) {
    const energyDir = path.join(dataDir, 'energy-logs');
    await ensureDir(energyDir);
    const indexFile = path.join(energyDir, 'index.json');
    try {
        await readFile(indexFile);
    }
    catch {
        await writeJsonFile(indexFile, { logs: [] });
        logger.success('能量追踪系统已初始化');
    }
    return energyDir;
}
export async function logEnergy(dataDir, energyLevel, focusLevel, mood, task, notes) {
    const energyDir = await initEnergyTracker(dataDir);
    const indexFile = path.join(energyDir, 'index.json');
    const data = await readJsonFile(indexFile) || { logs: [] };
    const now = new Date();
    const log = {
        id: `energy_${Date.now()}`,
        date: now.toISOString().split('T')[0],
        time: now.toTimeString().slice(0, 5),
        energyLevel: Math.min(10, Math.max(1, energyLevel)),
        focusLevel: Math.min(10, Math.max(1, focusLevel)),
        mood,
        task,
        notes,
        createdAt: now.toISOString()
    };
    data.logs.push(log);
    await writeJsonFile(indexFile, data);
    logger.section('💫 能量记录已保存');
    logger.info(`时间: ${log.date} ${log.time}`);
    logger.info(`能量: ${log.energyLevel}/10`);
    logger.info(`专注: ${log.focusLevel}/10`);
    logger.info(`情绪: ${MOOD_LABELS[log.mood]}`);
    if (task)
        logger.info(`任务: ${task}`);
    return log;
}
export async function getDailyEnergySummary(dataDir, date) {
    const energyDir = await initEnergyTracker(dataDir);
    const indexFile = path.join(energyDir, 'index.json');
    const data = await readJsonFile(indexFile);
    if (!data || data.logs.length === 0) {
        return null;
    }
    const targetDate = date || new Date().toISOString().split('T')[0];
    const dayLogs = data.logs.filter(log => log.date === targetDate);
    if (dayLogs.length === 0) {
        return null;
    }
    const averageEnergy = Math.round(dayLogs.reduce((sum, log) => sum + log.energyLevel, 0) / dayLogs.length * 10) / 10;
    const averageFocus = Math.round(dayLogs.reduce((sum, log) => sum + log.focusLevel, 0) / dayLogs.length * 10) / 10;
    // Find dominant mood
    const moodCounts = {};
    for (const log of dayLogs) {
        moodCounts[log.mood] = (moodCounts[log.mood] || 0) + 1;
    }
    const dominantMood = Object.entries(moodCounts).sort((a, b) => b[1] - a[1])[0][0];
    // Find peak and low hours
    const hourEnergy = {};
    for (const log of dayLogs) {
        const hour = log.time.split(':')[0];
        if (!hourEnergy[hour])
            hourEnergy[hour] = [];
        hourEnergy[hour].push(log.energyLevel);
    }
    const hourAverages = Object.entries(hourEnergy).map(([hour, energies]) => ({
        hour,
        average: energies.reduce((sum, e) => sum + e, 0) / energies.length
    }));
    hourAverages.sort((a, b) => b.average - a.average);
    const peakHours = hourAverages.slice(0, 2).map(h => h.hour);
    const lowHours = hourAverages.slice(-2).map(h => h.hour);
    return {
        date: targetDate,
        logs: dayLogs,
        averageEnergy,
        averageFocus,
        dominantMood,
        peakHours,
        lowHours
    };
}
export async function analyzeEnergyPattern(dataDir, days = 30) {
    const energyDir = await initEnergyTracker(dataDir);
    const indexFile = path.join(energyDir, 'index.json');
    const data = await readJsonFile(indexFile);
    if (!data || data.logs.length === 0) {
        return {
            bestHours: [],
            worstHours: [],
            averageEnergyByHour: {},
            energyTrend: 'stable',
            recommendations: ['数据不足，继续记录以获取分析结果']
        };
    }
    // Filter logs from last N days
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    const recentLogs = data.logs.filter(log => new Date(log.date) >= cutoffDate);
    // Calculate average energy by hour
    const hourEnergy = {};
    for (const log of recentLogs) {
        const hour = log.time.split(':')[0];
        if (!hourEnergy[hour])
            hourEnergy[hour] = [];
        hourEnergy[hour].push(log.energyLevel);
    }
    const averageEnergyByHour = {};
    for (const [hour, energies] of Object.entries(hourEnergy)) {
        averageEnergyByHour[hour] = Math.round(energies.reduce((sum, e) => sum + e, 0) / energies.length * 10) / 10;
    }
    // Find best and worst hours
    const hourAverages = Object.entries(averageEnergyByHour)
        .map(([hour, avg]) => ({ hour, avg }))
        .sort((a, b) => b.avg - a.avg);
    const bestHours = hourAverages.slice(0, 3).map(h => h.hour);
    const worstHours = hourAverages.slice(-3).map(h => h.hour);
    // Calculate trend (compare first half vs second half)
    const midpoint = Math.floor(recentLogs.length / 2);
    const firstHalf = recentLogs.slice(0, midpoint);
    const secondHalf = recentLogs.slice(midpoint);
    const firstAvg = firstHalf.reduce((sum, log) => sum + log.energyLevel, 0) / firstHalf.length;
    const secondAvg = secondHalf.reduce((sum, log) => sum + log.energyLevel, 0) / secondHalf.length;
    let energyTrend = 'stable';
    if (secondAvg > firstAvg + 0.5)
        energyTrend = 'improving';
    else if (secondAvg < firstAvg - 0.5)
        energyTrend = 'declining';
    // Generate INFJ-friendly recommendations
    const recommendations = [];
    if (bestHours.length > 0) {
        recommendations.push(`你的最佳状态时段: ${bestHours.map(h => `${h}:00`).join(', ')}，安排重要工作`);
    }
    if (worstHours.length > 0) {
        recommendations.push(`能量低谷时段: ${worstHours.map(h => `${h}:00`).join(', ')}，适合休息或简单任务`);
    }
    if (energyTrend === 'improving') {
        recommendations.push('🌟 你的能量状态在提升，继续保持！');
    }
    else if (energyTrend === 'declining') {
        recommendations.push('⚠️ 注意到能量在下降，需要关注休息和恢复');
    }
    recommendations.push('记住：了解自己的节奏比勉强自己更重要');
    recommendations.push('在高效时段做重要的事，在低谷时段照顾自己');
    return {
        bestHours,
        worstHours,
        averageEnergyByHour,
        energyTrend,
        recommendations
    };
}
export async function generateEnergyReport(dataDir, days = 7) {
    let report = '## 💫 能量与情绪报告\n\n';
    const pattern = await analyzeEnergyPattern(dataDir, days);
    report += '### 能量模式分析\n\n';
    report += `- **最佳时段**: ${pattern.bestHours.map(h => `${h}:00`).join(', ')}\n`;
    report += `- **低谷时段**: ${pattern.worstHours.map(h => `${h}:00`).join(', ')}\n`;
    report += `- **能量趋势**: ${pattern.energyTrend === 'improving' ? '📈 提升中' : pattern.energyTrend === 'declining' ? '📉 下降中' : '➡️ 稳定'}\n\n`;
    report += '### 💡 INFJ 友好建议\n\n';
    for (const rec of pattern.recommendations) {
        report += `- ${rec}\n`;
    }
    report += '\n';
    // Daily summaries
    report += '### 每日摘要\n\n';
    for (let i = 0; i < days; i++) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        const dateStr = date.toISOString().split('T')[0];
        const summary = await getDailyEnergySummary(dataDir, dateStr);
        if (summary) {
            report += `**${dateStr}**\n`;
            report += `- 平均能量: ${summary.averageEnergy}/10\n`;
            report += `- 平均专注: ${summary.averageFocus}/10\n`;
            report += `- 主导情绪: ${MOOD_LABELS[summary.dominantMood]}\n`;
            report += `- 记录次数: ${summary.logs.length}\n\n`;
        }
    }
    return report;
}
//# sourceMappingURL=energy-tracker.js.map