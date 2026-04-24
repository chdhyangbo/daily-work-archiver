import { logger } from '../utils/logger.js';
import { readJsonFile, writeJsonFile } from '../core/fs.js';
import path from 'path';
export async function initProject(projectPath, projectName) {
    const configFile = path.join(projectPath, '.project-config.json');
    const config = {
        project: projectName,
        milestones: []
    };
    await writeJsonFile(configFile, config);
    logger.success(`Project config created: ${configFile}`);
}
export async function updateProjectProgress(projectPath, milestoneName, progress) {
    const configFile = path.join(projectPath, '.project-config.json');
    const config = await readJsonFile(configFile);
    if (!config) {
        logger.warn('No project config found. Run init first.');
        return;
    }
    const milestone = config.milestones.find(m => m.name === milestoneName);
    if (milestone) {
        milestone.completed = progress;
        milestone.status = progress >= milestone.estimated ? 'done' : 'in_progress';
    }
    else {
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
export async function showProjectStatus(projectPath) {
    const configFile = path.join(projectPath, '.project-config.json');
    const config = await readJsonFile(configFile);
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
//# sourceMappingURL=project-tracker.js.map