import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
import { readJsonFile, writeJsonFile, ensureDir } from '../core/fs.js';
import path from 'path';

export interface ProjectConfig {
  project: string;
  milestones: Array<{
    name: string;
    estimated: number;
    completed: number;
    status: string;
  }>;
}

export async function initProject(
  projectPath: string,
  projectName: string
): Promise<void> {
  const configFile = path.join(projectPath, '.project-config.json');
  
  const config: ProjectConfig = {
    project: projectName,
    milestones: []
  };

  await writeJsonFile(configFile, config);
  logger.success(`Project config created: ${configFile}`);
}

export async function updateProjectProgress(
  projectPath: string,
  milestoneName: string,
  progress: number
): Promise<void> {
  const configFile = path.join(projectPath, '.project-config.json');
  const config = await readJsonFile<ProjectConfig>(configFile);

  if (!config) {
    logger.warn('No project config found. Run init first.');
    return;
  }

  const milestone = config.milestones.find(m => m.name === milestoneName);
  if (milestone) {
    milestone.completed = progress;
    milestone.status = progress >= milestone.estimated ? 'done' : 'in_progress';
  } else {
    config.milestones.push({
      name: milestoneName,
      estimated: 100,
      completed: progress,
      status: 'in_progress'
    });
  }

  await writeJsonFile(configFile, config);
  logger.success(`Milestone "${milestoneName}" updated to ${progress}%`);
}

export async function showProjectStatus(projectPath: string): Promise<void> {
  const configFile = path.join(projectPath, '.project-config.json');
  const config = await readJsonFile<ProjectConfig>(configFile);

  if (!config) {
    logger.warn('No project config found');
    return;
  }

  logger.section(`Project: ${config.project}`);

  let totalEstimated = 0;
  let totalCompleted = 0;

  config.milestones.forEach(m => {
    totalEstimated += m.estimated;
    totalCompleted += Math.min(m.completed, m.estimated);

    const status = m.status === 'done' ? '✅' : '⏳';
    logger.info(`${status} ${m.name}: ${m.completed}/${m.estimated}`);
  });

  const progress = totalEstimated > 0 ? Math.round((totalCompleted / totalEstimated) * 100) : 0;
  logger.section(`Overall Progress: ${progress}%`);
}
