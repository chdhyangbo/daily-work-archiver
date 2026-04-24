import { AppConfig, GitCommit } from '../types.js';
import { findGitDirs, getGitLog } from '../core/git.js';
import { writeJsonFile, writeFile, ensureDir } from '../core/fs.js';
import { logger } from '../utils/logger.js';
import path from 'path';

export interface ActivitySummary {
  totalCommits: number;
  dateRange: { from: string; to: string };
  projects: Record<string, number>;
  types: Record<string, number>;
  totalInsertions: number;
  totalDeletions: number;
  generatedAt: string;
}

export async function aggregateGitActivities(
  config: AppConfig,
  options?: {
    daysBack?: number;      // 最近N天
    startDate?: string;     // 开始日期 YYYY-MM-DD
    endDate?: string;       // 结束日期 YYYY-MM-DD
  }
): Promise<GitCommit[]> {
  logger.section('[1/3] Collecting Git activities...');
  
  const allActivities: GitCommit[] = [];
  
  // 计算日期范围
  let sinceDate: string;
  let untilDate: string | undefined;
  
  if (options?.startDate && options?.endDate) {
    // 自定义日期范围
    sinceDate = options.startDate;
    untilDate = options.endDate;
    logger.info(`Date range: ${sinceDate} ~ ${untilDate}`);
  } else if (options?.daysBack !== undefined) {
    // 最近N天
    const since = new Date();
    since.setDate(since.getDate() - options.daysBack);
    sinceDate = since.toISOString().split('T')[0];
    logger.info(`Scanning last ${options.daysBack} days (since ${sinceDate})`);
  } else {
    // 默认使用配置的daysBack
    const since = new Date();
    since.setDate(since.getDate() - config.daysBack);
    sinceDate = since.toISOString().split('T')[0];
    logger.info(`Scanning last ${config.daysBack} days (since ${sinceDate})`);
  }
  
  for (const rootPath of config.projectPaths) {
    try {
      logger.cyan(`Scanning: ${rootPath}`);
      
      const projectPaths = await findGitDirs(rootPath);
      
      for (const projectPath of projectPaths) {
        const projectName = projectPath.split(/[\/\\]/).pop() || '';
        logger.gray(`  Project: ${projectName}`);
        
        try {
          const commits = await getGitLog(projectPath, {
            since: sinceDate,
            author: config.author,
            noMerges: true,
            until: untilDate
          });
          
          allActivities.push(...commits);
        } catch (error) {
          logger.error(`    Error: ${(error as Error).message}`);
        }
      }
    } catch (error) {
      logger.error(`Error scanning ${rootPath}: ${(error as Error).message}`);
    }
  }
  
  logger.success(`  Collected ${allActivities.length} commits`);
  return allActivities;
}

export async function saveActivitiesByDate(
  activities: GitCommit[],
  outputDir: string,
  archiveDbDir: string
): Promise<void> {
  logger.section('[2/3] Saving activities by date...');
  
  await ensureDir(outputDir);
  await ensureDir(archiveDbDir);
  
  // Group by date
  const groupedByDate = new Map<string, GitCommit[]>();
  for (const activity of activities) {
    if (!groupedByDate.has(activity.date)) {
      groupedByDate.set(activity.date, []);
    }
    groupedByDate.get(activity.date)!.push(activity);
  }
  
  let savedFiles = 0;
  
  for (const [date, dateActivities] of groupedByDate) {
    // Sort by dateTime descending
    dateActivities.sort((a, b) => b.dateTime.localeCompare(a.dateTime));
    
    // Count types
    const typeCounts = {
      FEATURE: dateActivities.filter(a => a.type === 'FEATURE').length,
      FIX: dateActivities.filter(a => a.type === 'FIX').length,
      REFACTOR: dateActivities.filter(a => a.type === 'REFACTOR').length,
      DOCS: dateActivities.filter(a => a.type === 'DOCS').length,
      TEST: dateActivities.filter(a => a.type === 'TEST').length,
      OTHER: dateActivities.filter(a => a.type === 'OTHER').length
    };
    
    const uniqueProjects = [...new Set(dateActivities.map(a => a.project))].join(', ');
    
    // Save JSON
    const jsonData = {
      date,
      totalCommits: dateActivities.length,
      projects: uniqueProjects,
      types: typeCounts,
      commits: dateActivities
    };
    
    const jsonFile = path.join(outputDir, `${date}.json`);
    await writeJsonFile(jsonFile, jsonData);
    
    // Save Markdown
    const mdContent = generateMarkdown(date, dateActivities);
    const mdFile = path.join(archiveDbDir, `${date}.md`);
    await writeFile(mdFile, mdContent);
    
    savedFiles++;
  }
  
  logger.success(`Saved ${savedFiles} files to ${outputDir}`);
  logger.success(`Saved ${savedFiles} markdown files to ${archiveDbDir}`);
}

export async function createActivityIndex(
  activities: GitCommit[],
  outputDir: string
): Promise<void> {
  logger.section('[3/3] Creating activity index...');
  
  if (activities.length === 0) {
    logger.warn('No activities to index');
    return;
  }
  
  const sortedByDate = [...activities].sort((a, b) => a.date.localeCompare(b.date));
  
  const stats: ActivitySummary = {
    totalCommits: activities.length,
    dateRange: {
      from: sortedByDate[0].date,
      to: sortedByDate[sortedByDate.length - 1].date
    },
    projects: {},
    types: {
      FEATURE: 0,
      FIX: 0,
      REFACTOR: 0,
      DOCS: 0,
      TEST: 0,
      OTHER: 0
    },
    totalInsertions: 0,
    totalDeletions: 0,
    generatedAt: new Date().toISOString()
  };
  
  for (const activity of activities) {
    if (!stats.projects[activity.project]) {
      stats.projects[activity.project] = 0;
    }
    stats.projects[activity.project]++;
    stats.types[activity.type]++;
    stats.totalInsertions += activity.insertions;
    stats.totalDeletions += activity.deletions;
  }
  
  const indexFile = path.join(outputDir, 'activity-index.json');
  await writeJsonFile(indexFile, stats);
  
  logger.success(`Index saved: ${indexFile}`);
  logger.cyan(`  Total commits: ${stats.totalCommits}`);
  logger.cyan(`  Date range: ${stats.dateRange.from} to ${stats.dateRange.to}`);
  logger.cyan(`  Projects: ${Object.keys(stats.projects).length}`);
}

function generateMarkdown(date: string, activities: GitCommit[]): string {
  const totalCommits = activities.length;
  const totalInsertions = activities.reduce((sum, a) => sum + a.insertions, 0);
  const totalDeletions = activities.reduce((sum, a) => sum + a.deletions, 0);
  const activeProjects = [...new Set(activities.map(a => a.project))];
  
  let mdContent = `## Git Activity Statistics for Today

**Total Commits**: ${totalCommits}  
**Active Projects**: ${activeProjects.length}  
**Code Changes**: +${totalInsertions} -${totalDeletions}

---

`;
  
  // Group by project
  const groupedByProject = new Map<string, GitCommit[]>();
  for (const activity of activities) {
    if (!groupedByProject.has(activity.project)) {
      groupedByProject.set(activity.project, []);
    }
    groupedByProject.get(activity.project)!.push(activity);
  }
  
  for (const [projectName, projActivities] of groupedByProject) {
    const projCommits = projActivities.length;
    const projInsertions = projActivities.reduce((sum, a) => sum + a.insertions, 0);
    const projDeletions = projActivities.reduce((sum, a) => sum + a.deletions, 0);
    
    mdContent += `### Project: ${projectName}

**Commits**: ${projCommits}  
**Code**: +${projInsertions} -${projDeletions}

`;
    
    for (const act of projActivities) {
      mdContent += `#### [${act.type}] ${act.subject}
- **Time**: ${act.dateTime}
- **Changes**: +${act.insertions} -${act.deletions}
- **Files**: 0
- **Tech**: 

`;
    }
  }
  
  return mdContent;
}
