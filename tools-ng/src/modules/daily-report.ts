import { getTimeStatsByDay } from './weekly-report.js';
import { formatDate } from '../utils/date.js';
import { logger } from '../utils/logger.js';
import { getGitStatsByDay } from './weekly-report.js';
import { loadGitActivities } from '../core/git-data-loader.js';
import path from 'path';
import fs from 'fs';

/**
 * 生成日报
 */
export async function generateDailyReport(
  date: string,
  projectPaths: string[],
  author: string,
  outputBaseDir: string
): Promise<string> {
  logger.section(`Generating Daily Report for ${date}...`);

  // 优先从git数据集读取
  const dataDir = path.join(outputBaseDir, 'data', 'git-activities');
  const activities = await loadGitActivities(dataDir, date, date);

  let gitStats: { 
    commits: number; 
    insertions: number; 
    deletions: number; 
    projects: Record<string, number>;
    commitDetails?: Array<{
      time: string;
      project: string;
      type: string;
      message: string;
      insertions: number;
      deletions: number;
    }>;
  };

  if (activities.length > 0) {
    // 从数据集汇总
    logger.info('Reading from Git activity dataset...');
    const activity = activities[0];
    gitStats = {
      commits: activity.totalCommits,
      insertions: 0,
      deletions: 0,
      projects: {},
      commitDetails: []
    };

    for (const commit of activity.commits) {
      gitStats.insertions += commit.insertions;
      gitStats.deletions += commit.deletions;

      if (!gitStats.projects[commit.project]) {
        gitStats.projects[commit.project] = 0;
      }
      gitStats.projects[commit.project]++;
      
      // 添加提交详情
      if (gitStats.commitDetails) {
        gitStats.commitDetails.push({
          time: commit.time || commit.dateTime.split(' ')[1] || '',
          project: commit.project,
          type: commit.type,
          message: commit.subject || commit.message,
          insertions: commit.insertions,
          deletions: commit.deletions
        });
      }
    }
    
    // 按时间排序
    if (gitStats.commitDetails) {
      gitStats.commitDetails.sort((a, b) => b.time.localeCompare(a.time));
    }
  } else {
    // 数据集没有，查询git
    logger.info('Collecting Git statistics...');
    gitStats = await getGitStatsByDay(date, projectPaths, author);
  }

  // 获取时间追踪
  logger.info('Collecting time tracking data...');
  const timeTrackingDir = path.join(outputBaseDir, 'data', 'time-tracking');
  const timeStats = await getTimeStatsByDay(date, timeTrackingDir);

  // 生成日报
  const report = generateDailyReportContent(date, gitStats, timeStats);

  // 保存报告
  const outputDir = path.join(outputBaseDir, 'reports', 'daily', date.substring(0, 7));
  const reportFile = path.join(outputDir, `${date}.md`);

  const { writeFile, ensureDir } = await import('../core/fs.js');
  await ensureDir(outputDir);
  await writeFile(reportFile, report);

  logger.success(`Daily report saved to: ${reportFile}`);
  logger.info('\n' + report);

  return report;
}

/**
 * 生成日报内容
 */
function generateDailyReportContent(
  date: string,
  gitStats: { 
    commits: number; 
    insertions: number; 
    deletions: number; 
    projects: Record<string, number>;
    commitDetails?: Array<{
      time: string;
      project: string;
      type: string;
      message: string;
      insertions: number;
      deletions: number;
    }>;
  },
  timeStats: { hours: number; types: Record<string, number>; projects: Record<string, number> }
): string {
  const dateObj = new Date(date);
  const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  const weekDay = weekDays[dateObj.getDay()];
  const formattedDate = `${dateObj.getFullYear()}年${dateObj.getMonth() + 1}月${dateObj.getDate()}日`;

  // 获取主要项目名称
  const mainProjects = Object.keys(gitStats.projects).join('、');
  const taskCount = gitStats.commits;
  const workHours = timeStats.hours > 0 ? timeStats.hours : 8;

  let report = `# 工作日报 - ${date}（${weekDay}）

## 📊 今日概览
- **日期**: ${formattedDate}
- **工作时长**: ${workHours} 小时
- **完成任务**: ${taskCount} 个
- **主要项目**: ${mainProjects || '无'}

---

## ✅ 已完成任务

`;

  // 按项目分组提交
  const commitsByProject = new Map<string, any[]>();
  if (gitStats.commitDetails) {
    for (const commit of gitStats.commitDetails) {
      if (!commitsByProject.has(commit.project)) {
        commitsByProject.set(commit.project, []);
      }
      commitsByProject.get(commit.project)!.push(commit);
    }
  }

  // 生成已完成任务
  let taskIndex = 1;
  for (const [project, commits] of commitsByProject) {
    // 提取任务单号
    const ticketMatch = commits[0].message.match(/(BK-\d+)/);
    const ticketNumber = ticketMatch ? ticketMatch[1] : '';
    
    report += `### 项目: ${project}\n`;
    if (ticketNumber) {
      report += `**任务单号**: ${ticketNumber}\n\n`;
    }
    
    // 按任务分组（提取【】中的内容作为任务名）
    const taskGroups = new Map<string, any[]>();
    for (const commit of commits) {
      const taskMatch = commit.message.match(/【([^】]+)】/);
      const taskName = taskMatch ? taskMatch[1] : commit.message.substring(0, 30);
      
      if (!taskGroups.has(taskName)) {
        taskGroups.set(taskName, []);
      }
      taskGroups.get(taskName)!.push(commit);
    }
    
    for (const [taskName, taskCommits] of taskGroups) {
      // 生成任务标题
      let taskTitle = taskName;
      if (taskCommits.length > 0) {
        const firstCommit = taskCommits[0];
        const typeText = firstCommit.type === 'FEATURE' ? '功能开发' : 
                        firstCommit.type === 'FIX' ? 'Bug修复' : '优化';
        // 提取【】后的描述
        const descMatch = firstCommit.message.match(/】(.+)/);
        if (descMatch) {
          taskTitle = `${taskName} - ${descMatch[1].trim()}`;
        }
      }
      
      report += `${taskIndex}. **【${taskTitle}】**\n`;
      report += `   - 完成情况：✅ 已完成\n`;
      report += `   - 修改内容：\n`;
      
      // 列出所有修改内容
      for (const commit of taskCommits) {
        const descMatch = commit.message.match(/】(.+)/);
        const desc = descMatch ? descMatch[1].trim() : commit.message;
        report += `     - ${desc}\n`;
      }
      
      // 统计总变更
      const totalInsertions = taskCommits.reduce((sum, c) => sum + c.insertions, 0);
      const totalDeletions = taskCommits.reduce((sum, c) => sum + c.deletions, 0);
      const totalFiles = Math.ceil((totalInsertions + totalDeletions) / 50);
      
      // 合并提交时间
      const times = taskCommits.map(c => c.time.split(':').slice(0, 2).join(':')).join(', ');
      
      report += `   - 代码变更: +${totalInsertions}/-${totalDeletions} 行\n`;
      report += `   - 涉及文件: ${totalFiles} 个文件\n`;
      report += `   - 技术栈: Vue.js\n`;
      report += `   - 提交时间: ${times}\n`;
      
      // 添加标签
      const typeTag = taskCommits[0].type === 'FEATURE' ? '[FEATURE]' : 
                      taskCommits[0].type === 'FIX' ? '[BUGFIX]' : 
                      taskCommits[0].type === 'REFACTOR' ? '[REFACTOR]' : '[OTHER]';
      report += `   - 标签: \`${typeTag}\`\n\n`;
      taskIndex++;
    }
  }

  if (gitStats.commits === 0) {
    report += `今日暂无完成任务。\n\n`;
  }

  report += `---

## 🔄 进行中任务

### 待确认
- **状态**: 进行中
- **当前进度**: 待更新
- **今日进展**: 根据实际工作内容更新
- **预计完成**: 待确认

---

## 📊 Git 代码统计

| 指标 | 数值 |
|------|------|
| 今日提交次数 | ${gitStats.commits} 次 |
| 活跃项目数 | ${Object.keys(gitStats.projects).length} 个 |
| 新增代码 | +${gitStats.insertions} 行 |
| 删除代码 | -${gitStats.deletions} 行 |
| 变更文件数 | ${Math.ceil((gitStats.insertions + gitStats.deletions) / 50)} 个 |

### 提交详情
| 时间 | 项目 | 类型 | 提交信息 |
|------|------|------|----------|\n`;

  if (gitStats.commitDetails && gitStats.commitDetails.length > 0) {
    for (const commit of gitStats.commitDetails) {
      report += `| ${commit.time} | ${commit.project} | ${commit.type} | ${commit.message} |\n`;
    }
  } else {
    report += `| - | - | - | 暂无提交 |\n`;
  }

  report += `
---

## 📅 今日工作计划回顾（基于昨日计划）

根据昨日计划，今日主要工作：
1. 待确认具体任务完成情况
2. 跟进项目进展
3. 处理Bug修复和功能开发

---

## 📅 下周计划

| 任务 | 工期 | 计划时间 | 优先级 |
|------|------|----------|--------|
| 待补充 | - | - | P0 |

---

## 💡 今日反思
- 今日完成了 ${gitStats.commits} 个提交，涉及 ${Object.keys(gitStats.projects).length} 个项目
- 代码变更：新增 ${gitStats.insertions} 行，删除 ${gitStats.deletions} 行
- 需要继续跟进当前项目进展，确保按时交付

---

> 📁 归档路径: \`work-archive/reports/daily/${date.substring(0, 7)}/${date}.md\`
> 🕐 创建时间: ${date}
`;

  return report;
}
