import { execSync } from 'child_process';
import { GitCommit, GitLogOptions } from '../types.js';
import { logger } from '../utils/logger.js';

/**
 * 获取指定日期的 Git 统计数据
 */
export async function getGitStatsByDay(
  date: string,
  projectPaths: string[],
  author: string
): Promise<{
  commits: number;
  insertions: number;
  deletions: number;
  projects: Record<string, number>;
}> {
  const stats = {
    commits: 0,
    insertions: 0,
    deletions: 0,
    projects: {} as Record<string, number>
  };

  for (const rootPath of projectPaths) {
    try {
      // 优化：只扫描一层目录，避免过深的递归
      let gitDirs: string[] = [];
      try {
        // 先检查 rootPath 本身是否是 git 仓库
        const rootGitCheck = execSync(`dir /b /ad "${rootPath}\\.git" 2>nul`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
        if (rootGitCheck.trim()) {
          gitDirs.push(`${rootPath}\\.git`);
        }
      } catch (e) {
        // rootPath 本身不是 git 仓库，继续扫描子目录
      }

      // 扫描一级子目录
      const command = `dir /b /ad "${rootPath}"`;
      const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
      const subDirs = output.split('\n').filter(line => line.trim());

      for (const subDir of subDirs) {
        const gitPath = `${rootPath}\\${subDir.trim()}\\.git`;
        try {
          execSync(`dir /b /ad "${gitPath}" 2>nul`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
          gitDirs.push(gitPath);
        } catch (e) {
          // 不是 git 仓库，跳过
        }
      }

      for (const gitDir of gitDirs) {
        const projectPath = gitDir.replace(/\\.git$/, '');
        const projectName = projectPath.split(/[\/\\]/).pop() || '';

        try {
          process.chdir(projectPath);

          const since = `${date} 00:00:00`;
          const until = `${date} 23:59:59`;

          const logCommand = `git -c core.quotepath=false log --since="${since}" --until="${until}" --author="${author}" --pretty=format:"%H|%s" --date=format:"%Y-%m-%d"`;
          const commitsOutput = execSync(logCommand, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });

          if (commitsOutput.trim()) {
            const commitList = commitsOutput.split('\n').filter(line => line.trim());
            stats.commits += commitList.length;

            if (!stats.projects[projectName]) {
              stats.projects[projectName] = 0;
            }
            stats.projects[projectName] += commitList.length;

            // 统计代码变更
            for (const commit of commitList) {
              const hash = commit.split('|')[0];
              const statInfo = execSync(`git show --stat --format="" ${hash}`, {
                encoding: 'utf-8',
                stdio: ['pipe', 'pipe', 'ignore']
              });

              const lastLine = statInfo.trim().split('\n').pop() || '';
              const insertionMatch = lastLine.match(/(\d+) insertion/);
              if (insertionMatch) {
                stats.insertions += parseInt(insertionMatch[1]);
              }
              const deletionMatch = lastLine.match(/(\d+) deletion/);
              if (deletionMatch) {
                stats.deletions += parseInt(deletionMatch[1]);
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

  return stats;
}

/**
 * 生成ASCII燃尽图
 */
export function generateBurndownChart(
  gitStats: Record<string, { commits: number }>,
  dates: string[]
): string {
  let chart = '```\n本周提交趋势:\n\n';

  const commitCounts = dates.map(d => gitStats[d]?.commits || 0);
  const maxCommits = Math.max(...commitCounts, 1);

  // 表头
  chart += '提交数  ';
  dates.forEach(date => {
    const day = new Date(date).toLocaleDateString('en-US', { weekday: 'short' }).substring(0, 3);
    chart += `${day} `;
  });
  chart += '\n';

  // 柱状图
  for (let level = 10; level >= 1; level--) {
    const threshold = maxCommits * level / 10;
    chart += '       ';
    
    dates.forEach(date => {
      const commits = gitStats[date]?.commits || 0;
      if (commits >= threshold) {
        chart += '██ ';
      } else if (commits >= threshold * 0.5) {
        chart += '▓▓ ';
      } else if (commits >= threshold * 0.25) {
        chart += '▒▒ ';
      } else {
        chart += '░░ ';
      }
    });
    chart += '\n';
  }

  // 底部日期
  chart += '       ';
  dates.forEach(date => {
    const dayNum = new Date(date).getDate().toString().padStart(2, ' ');
    chart += `${dayNum} `;
  });
  chart += '\n```';

  return chart;
}

/**
 * 生成项目时间分配图（ASCII）
 */
export function generateTimePieChart(
  timeStats: Record<string, { projects: Record<string, number> }>,
  dates: string[]
): string {
  // 汇总一周的项目时间
  const projectTotals: Record<string, number> = {};
  let totalHours = 0;

  dates.forEach(date => {
    const stats = timeStats[date];
    if (stats && stats.projects) {
      Object.entries(stats.projects).forEach(([proj, minutes]) => {
        if (!projectTotals[proj]) {
          projectTotals[proj] = 0;
        }
        const hours = minutes / 60;
        projectTotals[proj] += hours;
        totalHours += hours;
      });
    }
  });

  if (totalHours === 0) {
    return '本周暂无时间记录';
  }

  const chart = `\`\`\`\n本周时间分配 (${Math.round(totalHours * 10) / 10} 小时):\n\n`;

  // 按时间排序
  const sorted = Object.entries(projectTotals).sort((a, b) => b[1] - a[1]);
  const colors = ['🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '⬜'];
  
  let result = chart;
  sorted.forEach(([proj, hours], idx) => {
    const percent = Math.round((hours / totalHours) * 100);
    const barLength = Math.round(percent / 2);
    const bar = '█'.repeat(barLength);
    const color = colors[idx % colors.length];
    result += `${color} ${proj.padEnd(20)} ${bar} ${percent}% (${Math.round(hours * 10) / 10}h)\n`;
  });

  result += '```';
  return result;
}

/**
 * 生成完整的周报
 */
export function generateWeeklyReport(
  weekStart: string,
  dates: string[],
  gitStats: Record<string, { commits: number; insertions: number; deletions: number; projects: Record<string, number>; commitDetails?: any[] }>,
  timeStats: Record<string, { hours: number; types: Record<string, number>; projects: Record<string, number> }>
): string {
  const weekEnd = dates[dates.length - 1];
  const startDate = new Date(weekStart);
  const endDate = new Date(weekEnd);
  
  // 计算周数
  const oneJan = new Date(startDate.getFullYear(), 0, 1);
  const numberOfDays = Math.floor((startDate.getTime() - oneJan.getTime()) / (24 * 60 * 60 * 1000));
  const weekNum = Math.ceil((startDate.getDay() + 1 + numberOfDays) / 7);
  const weekNumStr = `${startDate.getFullYear()}-W${weekNum.toString().padStart(2, '0')}`;
  
  // 格式化日期范围
  const startMonth = (startDate.getMonth() + 1).toString().padStart(2, '0');
  const startDay = startDate.getDate().toString().padStart(2, '0');
  const endMonth = (endDate.getMonth() + 1).toString().padStart(2, '0');
  const endDay = endDate.getDate().toString().padStart(2, '0');
  const dateRange = `${startMonth}.${startDay} - ${endMonth}.${endDay}`;
  
  // 汇总统计
  let totalCommits = 0;
  let totalInsertions = 0;
  let totalDeletions = 0;
  const allProjects: Record<string, number> = {};
  const activeDays: string[] = [];
  const allCommitDetails: any[] = [];

  dates.forEach(date => {
    const stats = gitStats[date];
    if (stats && stats.commits > 0) {
      totalCommits += stats.commits;
      totalInsertions += stats.insertions;
      totalDeletions += stats.deletions;
      activeDays.push(date);
      
      if (stats.commitDetails) {
        allCommitDetails.push(...stats.commitDetails);
      }

      Object.entries(stats.projects).forEach(([proj, count]) => {
        if (!allProjects[proj]) {
          allProjects[proj] = 0;
        }
        allProjects[proj] += count;
      });
    }
  });
  
  const netCode = totalInsertions - totalDeletions;
  const activeDayCount = activeDays.length;

  // 构建报告
  let report = `# 周报 - ${startDate.getFullYear()} 年第 ${weekNum} 周 (${dateRange})

> **日期范围**: ${startDate.getFullYear()} 年 ${startMonth} 月 ${startDay} 日 - ${endMonth} 月 ${endDay}日  
> **生成时间**: ${new Date().toISOString().split('T')[0]}  
> **数据来源**: Git 活动数据自动生成  
> **说明**: 基于实际 Git 提交记录生成

---

## 本周核心目标

1. 待补充本周核心目标
2. 根据实际工作内容更新
3. 关注重点项目进展

---

## 本周成果总结

`;

  // 按项目分组提交，生成关键成果
  const commitsByProject = new Map<string, any[]>();
  for (const commit of allCommitDetails) {
    if (!commitsByProject.has(commit.project)) {
      commitsByProject.set(commit.project, []);
    }
    commitsByProject.get(commit.project)!.push(commit);
  }
  
  let achievementIndex = 1;
  for (const [project, commits] of commitsByProject) {
    // 按任务分组
    const taskGroups = new Map<string, any[]>();
    for (const commit of commits) {
      const taskMatch = commit.message.match(/【([^】]+)】/);
      const taskName = taskMatch ? taskMatch[1] : '其他';
      
      if (!taskGroups.has(taskName)) {
        taskGroups.set(taskName, []);
      }
      taskGroups.get(taskName)!.push(commit);
    }
    
    for (const [taskName, taskCommits] of taskGroups) {
      const totalInsert = taskCommits.reduce((sum, c) => sum + c.insertions, 0);
      const totalDelete = taskCommits.reduce((sum, c) => sum + c.deletions, 0);
      const dates_str = [...new Set(taskCommits.map(c => {
        const d = new Date(c.dateTime || c.date);
        return `${d.getMonth() + 1}月${d.getDate()}日`;
      }))].join('、');
      
      // 提取描述
      const descMatch = taskCommits[0].message.match(/】(.+)/);
      const desc = descMatch ? descMatch[1].trim() : taskCommits[0].message;
      
      report += `### 关键成果 ${achievementIndex}: ${taskName}\n`;
      report += `- **描述**: ${desc}\n`;
      report += `- **代码变更**: +${totalInsert} 行, -${totalDelete} 行\n`;
      report += `- **时间**: ${dates_str}\n`;
      report += `- **影响力**: 提升项目质量和用户体验\n\n`;
      achievementIndex++;
    }
  }
  
  if (totalCommits === 0) {
    report += `本周暂无提交记录。\n\n`;
  }

  report += `---

## 工作统计

| 指标 | 数值 |
|------|------|
| **已记录工作日** | ${activeDayCount} 天 (${dateRange}) |
| **Git 提交** | ${totalCommits} 次 |
| **活跃项目** | ${Object.keys(allProjects).length} 个 (${Object.keys(allProjects).join(', ')}) |
| **代码变更** | +${totalInsertions} 行, -${totalDeletions} 行 |
| **净增代码** | +${netCode} 行 |

### 每日工作明细

| 日期 | 工作内容 | 提交数 | 代码变更 | 备注 |
|------|----------|--------|----------|------|\n`;

  dates.forEach(date => {
    const stats = gitStats[date];
    const dateObj = new Date(date);
    const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    const weekDay = weekDays[dateObj.getDay()];
    const month = dateObj.getMonth() + 1;
    const day = dateObj.getDate();
    const dateStr = `${month}月${day}日 (${weekDay})`;
    
    if (stats && stats.commits > 0) {
      // 提取主要工作内容
      const projects = Object.keys(stats.projects).join(', ');
      report += `| ${dateStr} | ${projects} | ${stats.commits} | +${stats.insertions}, -${stats.deletions} | 待补充备注 |\n`;
    } else {
      report += `| ${dateStr} | - | - | - | 待记录 |\n`;
    }
  });

  report += `
---

## 项目进展

`;

  for (const [project, commitCount] of Object.entries(allProjects)) {
    const projectCommits = allCommitDetails.filter(c => c.project === project);
    const ticketMatch = projectCommits[0]?.message.match(/(BK-\d+)/);
    const ticketNumber = ticketMatch ? ticketMatch[1] : '';
    
    report += `### 项目: ${project}\n`;
    if (ticketNumber) {
      report += `- **任务单号**: ${ticketNumber}\n`;
    }
    report += `- **当前状态**: 开发中\n`;
    report += `- **本周完成**: \n`;
    
    // 列出完成的任务
    const taskGroups = new Map<string, any[]>();
    for (const commit of projectCommits) {
      const taskMatch = commit.message.match(/【([^】]+)】/);
      const taskName = taskMatch ? taskMatch[1] : commit.message.substring(0, 30);
      
      if (!taskGroups.has(taskName)) {
        taskGroups.set(taskName, []);
      }
      taskGroups.get(taskName)!.push(commit);
    }
    
    for (const [taskName] of taskGroups) {
      report += `  - ✅ ${taskName}\n`;
    }
    
    report += `- **整体进度**: 待更新\n`;
    report += `- **下周重点**: \n`;
    report += `  - 继续推进当前任务\n`;
    report += `  - 跟进测试反馈\n\n`;
    report += `---\n\n`;
  }

  report += `## 重点问题攻克

`;

  let problemIndex = 1;
  for (const commit of allCommitDetails.filter(c => c.type === 'FIX')) {
    const descMatch = commit.message.match(/】(.+)/);
    const desc = descMatch ? descMatch[1].trim() : commit.message;
    
    report += `### 问题 ${problemIndex}: ${commit.subject || commit.message}\n`;
    report += `- **背景**: 待补充问题背景\n`;
    report += `- **解决方案**: ${desc}\n`;
    report += `- **状态**: 已解决\n\n`;
    problemIndex++;
    
    if (problemIndex > 6) break; // 最多显示6个问题
  }

  if (problemIndex === 1) {
    report += `本周无重大问题需要攻克。\n\n`;
  }

  report += `---

## 下周计划

### 优先级 P0（必须完成）
1. 待补充 P0 任务
2. 关注重点项目交付
3. 及时修复测试反馈问题

### 优先级 P1（应该完成）
1. 待补充 P1 任务
2. 优化代码质量和性能

---

## 周反思

### 收获
- 待补充本周收获
- 保持高效的工作节奏
- 及时响应和解决问题

### 改进方向
- 提前预估可能出现的问题，减少返工
- 加强沟通，提前了解需求和测试场景
- 注意代码质量，避免小问题积累

---

**文档版本**: v2.0  
**生成方式**: 基于 Git 活动数据自动生成  
**保存位置**: \`work-archive/reports/weekly/${weekNumStr}.md\`  
**数据源**: \`work-archive/data/git-activities/\`
`;

  return report;
}

/**
 * 获取时间追踪数据（按天）
 */
export async function getTimeStatsByDay(
  date: string,
  dataDir: string
): Promise<{
  hours: number;
  types: Record<string, number>;
  projects: Record<string, number>;
}> {
  const fs = await import('fs');
  const path = await import('path');

  const file = path.join(dataDir, `${date}.json`);
  
  if (!fs.existsSync(file)) {
    return {
      hours: 0,
      types: {},
      projects: {}
    };
  }

  try {
    const content = fs.readFileSync(file, 'utf-8');
    const data = JSON.parse(content);
    
    let totalMinutes = 0;
    const typeSummary: Record<string, number> = {};
    const projectSummary: Record<string, number> = {};

    for (const session of data.sessions || []) {
      totalMinutes += session.duration;

      if (!typeSummary[session.type]) {
        typeSummary[session.type] = 0;
      }
      typeSummary[session.type] += session.duration;

      if (!projectSummary[session.project]) {
        projectSummary[session.project] = 0;
      }
      projectSummary[session.project] += session.duration;
    }

    return {
      hours: Math.round((totalMinutes / 60) * 10) / 10,
      types: typeSummary,
      projects: projectSummary
    };
  } catch (error) {
    logger.warn(`Error reading time tracking for ${date}: ${(error as Error).message}`);
    return {
      hours: 0,
      types: {},
      projects: {}
    };
  }
}
