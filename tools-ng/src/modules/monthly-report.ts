import { AppConfig } from '../types.js';
import { logger } from '../utils/logger.js';
import { ensureDir, writeFile } from '../core/fs.js';
import { getMonthlyReportData } from '../core/git-data-loader.js';
import path from 'path';

/**
 * 获取月份的日期范围
 */
function getMonthRange(month: string): string[] {
  const [year, monthStr] = month.split('-').map(Number);
  const start = new Date(year, monthStr - 1, 1);
  const end = new Date(year, monthStr, 0);
  
  const dates: string[] = [];
  const current = new Date(start);
  
  while (current <= end) {
    const year = current.getFullYear();
    const m = String(current.getMonth() + 1).padStart(2, '0');
    const d = String(current.getDate()).padStart(2, '0');
    dates.push(`${year}-${m}-${d}`);
    current.setDate(current.getDate() + 1);
  }
  
  return dates;
}

/**
 * 获取时间追踪数据（按月）
 */
export async function getTimeStatsForMonth(
  dates: string[],
  dataDir: string
): Promise<{
  totalHours: number;
  dailyHours: Record<string, number>;
  projectHours: Record<string, number>;
  typeHours: Record<string, number>;
}> {
  const fs = await import('fs');
  
  const stats = {
    totalHours: 0,
    dailyHours: {} as Record<string, number>,
    projectHours: {} as Record<string, number>,
    typeHours: {} as Record<string, number>
  };

  dates.forEach(date => {
    stats.dailyHours[date] = 0;
  });

  for (const date of dates) {
    const file = path.join(dataDir, `${date}.json`);
    
    if (!fs.existsSync(file)) {
      continue;
    }

    try {
      const content = fs.readFileSync(file, 'utf-8');
      const data = JSON.parse(content);
      
      let dayMinutes = 0;

      for (const session of data.sessions || []) {
        dayMinutes += session.duration;

        if (!stats.projectHours[session.project]) {
          stats.projectHours[session.project] = 0;
        }
        stats.projectHours[session.project] += session.duration;

        if (!stats.typeHours[session.type]) {
          stats.typeHours[session.type] = 0;
        }
        stats.typeHours[session.type] += session.duration;
      }

      stats.dailyHours[date] = dayMinutes / 60;
      stats.totalHours += dayMinutes / 60;
    } catch (error) {
      logger.warn(`Error reading time tracking for ${date}: ${(error as Error).message}`);
    }
  }

  return stats;
}

/**
 * 生成月度报告
 */
export async function generateMonthlyReport(
  month: string,
  config: AppConfig
): Promise<string> {
  logger.section(`Generating Monthly Report for ${month}...`);

  const dates = getMonthRange(month);
  logger.info(`Date range: ${dates[0]} ~ ${dates[dates.length - 1]}`);

  // 优先从数据集读取
  const dataDir = path.join(config.outputBaseDir, 'data', 'git-activities');
  const monthData = await getMonthlyReportData(dataDir, month);

  // 获取时间追踪
  logger.info('Collecting time tracking data...');
  const timeTrackingDir = path.join(config.outputBaseDir, 'data', 'time-tracking');
  const timeStats = await getTimeStatsForMonth(dates, timeTrackingDir);

  // 计算指标
  const activeDays = Object.keys(monthData.dailyStats).length;
  const avgCommitsPerDay = activeDays > 0 
    ? Math.round((monthData.totalCommits / activeDays) * 10) / 10 
    : 0;

  const avgHoursPerDay = activeDays > 0
    ? Math.round((timeStats.totalHours / activeDays) * 10) / 10
    : 0;

  // 生成报告
  let report = `# ${month} 月度绩效报告

---

## 📊 月度概览

| 指标 | 数值 |
|------|------|
| **总提交数** | ${monthData.totalCommits} |
| **活跃天数** | ${activeDays}/${dates.length} |
| **日均提交** | ${avgCommitsPerDay} |
| **代码新增** | +${monthData.totalInsertions} |
| **代码删除** | -${monthData.totalDeletions} |
`;

  if (timeStats.totalHours > 0) {
    report += `| **总工时** | ${Math.round(timeStats.totalHours * 10) / 10} 小时 |
| **日均工时** | ${avgHoursPerDay} 小时 |
`;
  }

  report += `
---

## 🚀 项目贡献

| 项目 | 提交数 | 占比 |
|------|--------|------|
`;

  const sortedProjects = Object.entries(monthData.projectStats).sort((a, b) => b[1].commits - a[1].commits);
  sortedProjects.forEach(([project, data]) => {
    const percent = monthData.totalCommits > 0 
      ? Math.round((data.commits / monthData.totalCommits) * 100) 
      : 0;
    report += `| ${project} | ${data.commits} | ${percent}% |\n`;
  });

  report += `
---

## 📈 提交类型分布

| 类型 | 数量 | 占比 |
|------|------|------|
`;

  const typeIcons: Record<string, string> = {
    FEATURE: '✨',
    FIX: '🐛',
    REFACTOR: '♻️',
    DOCS: '📝',
    TEST: '🧪',
    OTHER: '📦'
  };

  Object.entries(monthData.typeStats).forEach(([type, count]) => {
    const percent = monthData.totalCommits > 0 
      ? Math.round((count / monthData.totalCommits) * 100) 
      : 0;
    const icon = typeIcons[type] || '📦';
    report += `| ${icon} ${type} | ${count} | ${percent}% |\n`;
  });

  if (timeStats.totalHours > 0 && Object.keys(timeStats.projectHours).length > 0) {
    report += `
---

## ⏰ 时间分配

| 项目 | 时长(小时) | 占比 |
|------|-----------|------|
`;

    const sortedTimeProjects = Object.entries(timeStats.projectHours)
      .sort((a, b) => b[1] - a[1]);
    sortedTimeProjects.forEach(([project, minutes]) => {
      const hours = Math.round((minutes / 60) * 10) / 10;
      const percent = timeStats.totalHours > 0 
        ? Math.round((minutes / (timeStats.totalHours * 60)) * 100) 
        : 0;
      report += `| ${project} | ${hours} | ${percent}% |\n`;
    });
  }

  report += `
---

## 📅 每日提交趋势

`;

  // 显示有提交的日期
  const sortedDates = Object.entries(monthData.dailyStats)
    .filter(([_, data]) => data.commits > 0)
    .sort((a, b) => a[0].localeCompare(b[0]));
  
  if (sortedDates.length > 0) {
    report += '| 日期 | 提交数 | 新增 | 删除 |\n';
    report += '|------|--------|------|------|\n';
    sortedDates.forEach(([date, data]) => {
      report += `| ${date} | ${data.commits} | +${data.insertions} | -${data.deletions} |\n`;
    });
  } else {
    report += '本月暂无提交记录。\n';
  }

  report += `
---

## 🎯 下月计划

- [ ] 继续推进主要项目开发
- [ ] 提升代码质量
- [ ] 完善文档和测试
- [ ] 保持连续提交习惯

---

*报告由 AI Work Archiver 自动生成*
`;

  // 保存报告
  const outputDir = path.join(config.outputBaseDir, 'reports', 'monthly');
  await ensureDir(outputDir);
  const reportFile = path.join(outputDir, `${month}.md`);
  await writeFile(reportFile, report);

  logger.success(`Monthly report saved to: ${reportFile}`);
  logger.info('\n' + report);

  return report;
}
