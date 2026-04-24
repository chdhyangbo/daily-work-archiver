#!/usr/bin/env node
import { Command } from 'commander';
import { loadConfig } from './utils/config.js';
import { logger } from './utils/logger.js';
import { aggregateGitActivities, saveActivitiesByDate, createActivityIndex } from './modules/git-aggregator.js';
import { getTimeStatsByDay, generateWeeklyReport } from './modules/weekly-report.js';
import { generateDailyReport } from './modules/daily-report.js';
import { generateMonthlyReport } from './modules/monthly-report.js';
import { generateResume } from './modules/resume-generator.js';
import { getWeeklyReportData } from './core/git-data-loader.js';
import { analyzeCommits, suggestCommitMessage } from './modules/commit-classifier.js';
import { analyzeWorkPattern } from './modules/work-pattern-analyzer.js';
import { trackGrowth } from './modules/growth-tracker.js';
import { suggestTimeOptimization } from './modules/time-optimizer.js';
import { detectDuplicateWork } from './modules/duplicate-work-detector.js';
import { generateChangeImpactReport } from './modules/change-impact-analyzer.js';
import { monitorProjectHealth } from './modules/project-health-monitor.js';
import { generateProjectRetro } from './modules/project-retro.js';
import { provideWorkAdvice } from './modules/work-advisor.js';
import { trackGitWork } from './modules/git-work-tracker.js';
import { runAchievementSystem } from './modules/achievement-system.js';
import { generateDashboardData } from './modules/dashboard-data.js';
import { generateChartHTML } from './modules/chart-generator.js';
import { startTimeTracking, stopTimeTracking, viewTimeTracking } from './modules/time-tracker.js';
import { initProject, updateProjectProgress, showProjectStatus } from './modules/project-tracker.js';
import { checkWorkflows } from './modules/workflow-automation.js';
import { backupData } from './modules/data-backup.js';
import { notifyUser } from './modules/notification.js';
import { securityTool } from './modules/security.js';
import { verifyAllTools } from './modules/quick-verification.js';
import { exportToPDF } from './modules/pdf-exporter.js';
import { generateSmartSummary } from './modules/smart-report-summarizer.js';
import { addGoal, updateGoalProgress, getActiveGoals, generateGoalReport, reviewGoals } from './modules/goal-tracker.js';
import { generateReminderSchedules, checkAndSendReminders, generateReminderReport } from './modules/reminder-engine.js';
import { runDailyKickoff } from './modules/daily-kickoff.js';
import { logEnergy, getDailyEnergySummary, analyzeEnergyPattern, generateEnergyReport } from './modules/energy-tracker.js';
import { addSkill, updateSkillLevel, addMilestone, generateGrowthReport, getGrowthTimeline } from './modules/growth-journey.js';
import { startFocusSession, endFocusSession, logInterruption, generateFocusReport } from './modules/focus-protector.js';
import { interactiveGoalSetup } from './modules/interactive-goal.js';
import { getCurrentWeekStart } from './utils/date.js';
import { writeFile, ensureDir } from './core/fs.js';
import path from 'path';
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const program = new Command();
program
    .name('tools-ng')
    .description('AI Work Archiver - Next Generation Tools')
    .version('1.0.0');
// aggregate command
program
    .command('aggregate')
    .description('Aggregate Git activities')
    .option('-d, --days <days>', 'Scan last N days (e.g., 1 for today, 7 for week)')
    .option('-s, --start <date>', 'Start date (YYYY-MM-DD)')
    .option('-e, --end <date>', 'End date (YYYY-MM-DD)')
    .option('-t, --today', 'Scan only today', false)
    .option('-y, --yesterday', 'Scan only yesterday', false)
    .option('-w, --this-week', 'Scan this week', false)
    .option('-m, --this-month', 'Scan this month', false)
    .option('-a, --all', 'Scan all history (last 365 days)', false)
    .action(async (options) => {
    try {
        const config = loadConfig();
        let aggregateOptions = {};
        // 处理不同的日期选项
        if (options.today) {
            // 今天
            const today = new Date().toISOString().split('T')[0];
            aggregateOptions.startDate = today;
            aggregateOptions.endDate = today;
            logger.info('Scanning: TODAY');
        }
        else if (options.yesterday) {
            // 昨天
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);
            const dateStr = yesterday.toISOString().split('T')[0];
            aggregateOptions.startDate = dateStr;
            aggregateOptions.endDate = dateStr;
            logger.info('Scanning: YESTERDAY');
        }
        else if (options.thisWeek) {
            // 本周
            const today = new Date();
            const weekStart = new Date(today);
            weekStart.setDate(today.getDate() - today.getDay() + 1);
            aggregateOptions.startDate = weekStart.toISOString().split('T')[0];
            aggregateOptions.endDate = today.toISOString().split('T')[0];
            logger.info('Scanning: THIS WEEK');
        }
        else if (options.thisMonth) {
            // 本月
            const today = new Date();
            const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
            aggregateOptions.startDate = monthStart.toISOString().split('T')[0];
            aggregateOptions.endDate = today.toISOString().split('T')[0];
            logger.info('Scanning: THIS MONTH');
        }
        else if (options.all) {
            // 全部（365天）
            aggregateOptions.daysBack = 365;
            logger.info('Scanning: ALL (last 365 days)');
        }
        else if (options.days) {
            // 最近N天
            aggregateOptions.daysBack = parseInt(options.days);
            logger.info(`Scanning: LAST ${options.days} DAYS`);
        }
        else if (options.start && options.end) {
            // 自定义日期范围
            aggregateOptions.startDate = options.start;
            aggregateOptions.endDate = options.end;
            logger.info(`Scanning: ${options.start} ~ ${options.end}`);
        }
        else {
            // 默认：最近30天
            aggregateOptions.daysBack = 30;
            logger.info('Scanning: DEFAULT (last 30 days)');
        }
        const activities = await aggregateGitActivities(config, aggregateOptions);
        const outputDir = path.join(config.outputBaseDir, 'data', 'git-activities');
        const archiveDbDir = path.join(config.outputBaseDir, 'archive-db', 'git-activities');
        await saveActivitiesByDate(activities, outputDir, archiveDbDir);
        await createActivityIndex(activities, outputDir);
        logger.section('Done!');
        logger.success(`Data saved to: ${outputDir}`);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
        process.exit(1);
    }
});
// report command - generate daily/weekly/monthly reports
program
    .command('report')
    .description('Generate report')
    .option('-t, --type <type>', 'Report type (daily|weekly|monthly)', 'weekly')
    .option('-d, --date <date>', 'Start date (YYYY-MM-DD)', getCurrentWeekStart())
    .option('-o, --output <path>', 'Output directory')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const { type, date: startDate, output } = options;
        if (type === 'daily') {
            const reportDate = startDate || new Date().toISOString().split('T')[0];
            await generateDailyReport(reportDate, config.projectPaths, config.author, config.outputBaseDir);
        }
        else if (type === 'weekly') {
            logger.section('Generating Weekly Report...');
            logger.info(`Week start: ${startDate}`);
            // 优先从数据集读取
            const dataDir = path.join(config.outputBaseDir, 'data', 'git-activities');
            const weekData = await getWeeklyReportData(dataDir, startDate);
            const { dates, gitStats } = weekData;
            logger.info(`Date range: ${dates[0]} ~ ${dates[dates.length - 1]}`);
            // Collect time tracking stats
            logger.info('Collecting time tracking data...');
            const timeTrackingDir = path.join(config.outputBaseDir, 'data', 'time-tracking');
            const timeStats = {};
            for (const date of dates) {
                timeStats[date] = await getTimeStatsByDay(date, timeTrackingDir);
            }
            // Generate report
            logger.info('Generating report...');
            const report = generateWeeklyReport(startDate, dates, gitStats, timeStats);
            // Save report
            const outputDir = output || path.join(config.outputBaseDir, 'reports', 'weekly');
            await ensureDir(outputDir);
            const startDateObj = new Date(startDate);
            const weekNum = Math.floor((startDateObj.getTime() - new Date(startDateObj.getFullYear(), 0, 1).getTime()) / (7 * 24 * 60 * 60 * 1000) + 1);
            const reportFile = path.join(outputDir, `${startDateObj.getFullYear()}-W${weekNum.toString().padStart(2, '0')}.md`);
            await writeFile(reportFile, report);
            logger.section('Done!');
            logger.success(`Weekly report saved to: ${reportFile}`);
            logger.info('\n' + report);
        }
        else if (type === 'monthly') {
            // 从日期提取月份 (YYYY-MM-DD -> YYYY-MM)
            const month = startDate.substring(0, 7);
            await generateMonthlyReport(month, config);
        }
        else {
            logger.warn(`Report generation for ${type} is not yet implemented`);
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
        process.exit(1);
    }
});
// quality command - score commit quality
program
    .command('quality')
    .description('Score commit quality')
    .option('-d, --days <days>', 'Number of days to analyze', '30')
    .option('-p, --project <path>', 'Project path')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const days = parseInt(options.days);
        const projectPath = options.project || config.projectPaths[0];
        logger.section('Commit Quality Analysis');
        logger.info(`Analyzing last ${days} days for ${projectPath}`);
        await analyzeCommits(projectPath, config.author, days);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
        process.exit(1);
    }
});
// achievement command
program
    .command('achievement')
    .description('Check achievements')
    .option('-a, --action <action>', 'Action (check|list|unlocked)', 'check')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const outputPath = path.join(config.outputBaseDir, 'data', 'achievements');
        await runAchievementSystem(options.action, config.projectPaths, config.author, outputPath);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// suggest command - suggest better commit message
program
    .command('suggest')
    .description('Suggest better commit message')
    .argument('<message>', 'Commit message to improve')
    .action((message) => {
    const suggestion = suggestCommitMessage(message);
    if (suggestion) {
        logger.section('Suggestion');
        logger.info(`Original: ${message}`);
        logger.success(`Better:   ${suggestion}`);
    }
    else {
        logger.success('Your commit message is already good!');
    }
});
// dashboard command
program
    .command('dashboard')
    .description('Generate dashboard data')
    .option('-s, --serve', 'Start web server', false)
    .action(async (options) => {
    try {
        const config = loadConfig();
        await generateDashboardData(config.projectPaths, config.author, config.outputBaseDir);
        if (options.serve) {
            logger.info('Would start web server on http://localhost:3456');
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// track command
program
    .command('track')
    .description('Track git work')
    .option('-f, --filter <filter>', 'Filter (today|week|month|all)', 'week')
    .action(async (options) => {
    try {
        const config = loadConfig();
        await trackGitWork(config.projectPaths, config.author, options.filter, config.outputBaseDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// analyze command
program
    .command('analyze')
    .description('Analyze work patterns')
    .option('-d, --days <days>', 'Number of days to analyze', '90')
    .action(async (options) => {
    try {
        const config = loadConfig();
        await analyzeWorkPattern(config.projectPaths, config.author, parseInt(options.days));
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// growth command
program
    .command('growth')
    .description('Track growth')
    .option('-m, --months <months>', 'Number of months', '12')
    .action(async (options) => {
    try {
        const config = loadConfig();
        await trackGrowth(config.projectPaths, config.author, parseInt(options.months));
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// optimize command
program
    .command('optimize')
    .description('Suggest time optimization')
    .action(async () => {
    try {
        const config = loadConfig();
        await suggestTimeOptimization(config.projectPaths, config.author);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// duplicate command
program
    .command('duplicate')
    .description('Detect duplicate work')
    .action(async () => {
    try {
        const config = loadConfig();
        await detectDuplicateWork(config.projectPaths, config.author);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// impact command
program
    .command('impact')
    .description('Analyze change impact')
    .option('-p, --project <path>', 'Project path')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const projectPath = options.project || config.projectPaths[0];
        const outputDir = path.join(config.outputBaseDir, 'data', 'impact-reports');
        await generateChangeImpactReport(projectPath, config.author, 30, outputDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// health command
program
    .command('health')
    .description('Monitor project health')
    .action(async () => {
    try {
        const config = loadConfig();
        await monitorProjectHealth(config.projectPaths, config.author, 30, config.outputBaseDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// retro command
program
    .command('retro')
    .description('Generate project retrospective')
    .option('-p, --project <path>', 'Project path')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const projectPath = options.project || config.projectPaths[0];
        const outputDir = path.join(config.outputBaseDir, 'reports', 'retrospectives');
        await generateProjectRetro(projectPath, config.author, outputDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// advisor command
program
    .command('advisor')
    .description('Get work advice')
    .action(async () => {
    try {
        const config = loadConfig();
        await provideWorkAdvice(config.projectPaths, config.author);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// workflow command
program
    .command('workflow')
    .description('Check workflows')
    .action(async () => {
    try {
        const config = loadConfig();
        await checkWorkflows(config.projectPaths, config.author);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// chart command
program
    .command('chart')
    .description('Generate charts')
    .action(async () => {
    try {
        const config = loadConfig();
        await generateChartHTML(config.projectPaths, config.author, config.outputBaseDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// project command
program
    .command('project')
    .description('Project tracking')
    .option('-a, --action <action>', 'Action (init|update|status)')
    .option('-p, --path <path>', 'Project path')
    .option('-m, --milestone <name>', 'Milestone name')
    .option('--progress <progress>', 'Progress percentage')
    .action(async (options) => {
    try {
        const { action, path: projPath, milestone, progress } = options;
        if (action === 'init') {
            await initProject(projPath, path.basename(projPath));
        }
        else if (action === 'update') {
            await updateProjectProgress(projPath, milestone, parseInt(progress));
        }
        else if (action === 'status') {
            await showProjectStatus(projPath);
        }
        else {
            logger.warn('Usage: npm start -- project -a init|update|status');
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// time command
program
    .command('time')
    .description('Time tracking')
    .option('-a, --action <action>', 'Action (start|stop|view)')
    .option('-p, --project <project>', 'Project name')
    .option('-t, --task <task>', 'Task name')
    .option('-d, --date <date>', 'Date to view')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const dataDir = path.join(config.outputBaseDir, 'data', 'time-tracking');
        const { action, project, task, date } = options;
        if (action === 'start') {
            await startTimeTracking(project || 'general', task || 'work', 'coding', dataDir);
        }
        else if (action === 'stop') {
            await stopTimeTracking(dataDir);
        }
        else if (action === 'view') {
            await viewTimeTracking(date || new Date().toISOString().split('T')[0], dataDir);
        }
        else {
            logger.warn('Usage: npm start -- time -a start|stop|view');
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// backup command
program
    .command('backup')
    .description('Backup data')
    .option('-a, --action <action>', 'Action (backup|restore)', 'backup')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const dataDir = path.join(config.outputBaseDir, 'data');
        const backupDir = path.join(config.outputBaseDir, 'backups');
        await backupData(dataDir, backupDir, options.action);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// notify command
program
    .command('notify')
    .description('Send notification')
    .argument('<title>', 'Notification title')
    .argument('<message>', 'Notification message')
    .action((title, message) => {
    notifyUser(title, message);
});
// security command
program
    .command('security')
    .description('Security tools')
    .option('-a, --action <action>', 'Action (encrypt|decrypt)')
    .option('-i, --input <file>', 'Input file')
    .option('-o, --output <file>', 'Output file')
    .option('-p, --password <password>', 'Password')
    .action((options) => {
    securityTool(options.action, options.input, options.output, options.password);
});
// verify command
program
    .command('verify')
    .description('Verify all tools')
    .action(async () => {
    await verifyAllTools();
});
// pdf command
program
    .command('pdf')
    .description('Export to PDF')
    .option('-i, --input <file>', 'Input file')
    .option('-o, --output <file>', 'Output file')
    .action((options) => {
    exportToPDF(options.input || 'report.html', options.output || 'report.pdf');
});
// summary command
program
    .command('summary')
    .description('Generate smart summary')
    .option('-t, --type <type>', 'Report type', 'weekly')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const dataDir = path.join(config.outputBaseDir, 'data');
        await generateSmartSummary(options.type, dataDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// kickoff command
program
    .command('kickoff')
    .description('Daily startup check for INFJ workflow')
    .action(async () => {
    try {
        const config = loadConfig();
        await runDailyKickoff(config.outputBaseDir);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// goal command
program
    .command('goal')
    .description('Goal tracking (INFJ-style)')
    .option('-a, --action <action>', 'Action (add|update|list|review|report|setup)')
    .option('-t, --title <title>', 'Goal title')
    .option('-l, --level <level>', 'Goal level (yearly|quarterly|monthly|weekly|daily)')
    .option('-d, --description <desc>', 'Goal description')
    .option('-w, --why <why>', 'Why this goal matters (INFJ意义感)')
    .option('--deadline <deadline>', 'Deadline (YYYY-MM-DD)')
    .option('-e, --emotional <value>', 'Emotional value (growth|impact|mastery|connection)')
    .option('-i, --id <id>', 'Goal ID (for update)')
    .option('-p, --progress <progress>', 'Progress percentage (for update)')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const { action, title, level, description, why, deadline, emotional, id, progress } = options;
        if (action === 'setup') {
            // Interactive goal setup
            await interactiveGoalSetup(config.outputBaseDir);
        }
        else if (action === 'add') {
            if (!title || !level || !why || !deadline) {
                logger.warn('需要提供: title, level, why, deadline');
                return;
            }
            await addGoal(config.outputBaseDir, {
                title,
                level,
                description: description || '',
                why,
                keyResults: [],
                deadline,
                emotionalValue: emotional || 'growth',
                reminders: [],
                status: 'active'
            });
        }
        else if (action === 'update') {
            if (!id || progress === undefined) {
                logger.warn('需要提供: id, progress');
                return;
            }
            await updateGoalProgress(config.outputBaseDir, id, parseInt(progress));
        }
        else if (action === 'list') {
            const goals = await getActiveGoals(config.outputBaseDir);
            logger.section('🎯 活跃目标');
            for (const goal of goals) {
                logger.info(`${goal.title} (${goal.progress}%) - ${goal.deadline}`);
            }
        }
        else if (action === 'review') {
            const review = await reviewGoals(config.outputBaseDir);
            logger.info(review);
        }
        else if (action === 'report') {
            const report = await generateGoalReport(config.outputBaseDir);
            logger.info(report);
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// reminder command
program
    .command('reminder')
    .description('INFJ-friendly reminder system')
    .option('-a, --action <action>', 'Action (check|schedule|report)')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const action = options.action || 'check';
        if (action === 'check') {
            const sent = await checkAndSendReminders(config.outputBaseDir);
            logger.info(`已发送 ${sent} 个提醒`);
        }
        else if (action === 'schedule') {
            await generateReminderSchedules(config.outputBaseDir);
            logger.success('提醒已生成');
        }
        else if (action === 'report') {
            const report = await generateReminderReport(config.outputBaseDir);
            logger.info(report);
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// energy command
program
    .command('energy')
    .description('Energy and mood tracking (INFJ-friendly)')
    .option('-a, --action <action>', 'Action (log|summary|pattern|report)')
    .option('-e, --energy <level>', 'Energy level (1-10)')
    .option('-f, --focus <level>', 'Focus level (1-10)')
    .option('-m, --mood <mood>', 'Mood (energized|calm|tired|stressed|excited|anxious|neutral)')
    .option('-t, --task <task>', 'Current task')
    .option('-n, --notes <notes>', 'Additional notes')
    .option('-d, --days <days>', 'Number of days to analyze')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const action = options.action || 'report';
        if (action === 'log') {
            if (!options.energy || !options.focus || !options.mood) {
                logger.warn('需要提供: energy, focus, mood');
                return;
            }
            await logEnergy(config.outputBaseDir, parseInt(options.energy), parseInt(options.focus), options.mood, options.task, options.notes);
        }
        else if (action === 'summary') {
            const summary = await getDailyEnergySummary(config.outputBaseDir);
            if (summary) {
                logger.section('💫 今日能量摘要');
                logger.info(`平均能量: ${summary.averageEnergy}/10`);
                logger.info(`平均专注: ${summary.averageFocus}/10`);
                logger.info(`主导情绪: ${summary.dominantMood}`);
            }
            else {
                logger.info('今日暂无能量记录');
            }
        }
        else if (action === 'pattern') {
            const pattern = await analyzeEnergyPattern(config.outputBaseDir, parseInt(options.days) || 30);
            logger.section('📊 能量模式分析');
            logger.info(`最佳时段: ${pattern.bestHours.map(h => `${h}:00`).join(', ')}`);
            logger.info(`能量趋势: ${pattern.energyTrend}`);
            for (const rec of pattern.recommendations) {
                logger.info(`  - ${rec}`);
            }
        }
        else if (action === 'report') {
            const report = await generateEnergyReport(config.outputBaseDir, parseInt(options.days) || 7);
            logger.info(report);
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// growth command
program
    .command('growth')
    .description('Growth journey tracking (INFJ-style)')
    .option('-a, --action <action>', 'Action (skill|milestone|report|timeline)')
    .option('-n, --name <name>', 'Skill name')
    .option('-c, --category <category>', 'Skill category')
    .option('-l, --level <level>', 'Skill level (1-10)')
    .option('-i, --id <id>', 'Skill ID (for update)')
    .option('-t, --title <title>', 'Milestone title')
    .option('-d, --description <desc>', 'Description')
    .option('-m, --months <months>', 'Number of months')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const action = options.action || 'report';
        if (action === 'skill') {
            if (options.id && options.level) {
                await updateSkillLevel(config.outputBaseDir, options.id, parseInt(options.level));
            }
            else if (options.name && options.category) {
                await addSkill(config.outputBaseDir, options.name, options.category, parseInt(options.level) || 1);
            }
            else {
                logger.warn('需要提供: name, category 或 id, level');
            }
        }
        else if (action === 'milestone') {
            if (options.title && options.description) {
                await addMilestone(config.outputBaseDir, options.title, options.description);
            }
            else {
                logger.warn('需要提供: title, description');
            }
        }
        else if (action === 'report') {
            const report = await generateGrowthReport(config.outputBaseDir);
            logger.info(report);
        }
        else if (action === 'timeline') {
            const timeline = await getGrowthTimeline(config.outputBaseDir, parseInt(options.months) || 6);
            logger.section('🏆 成长时间线');
            for (const m of timeline) {
                logger.info(`${m.date}: ${m.title}`);
            }
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// focus command
program
    .command('focus')
    .description('Focus session tracking for deep work')
    .option('-a, --action <action>', 'Action (start|end|interrupt|report)')
    .option('-t, --task <task>', 'Task name')
    .option('-i, --id <id>', 'Session ID')
    .option('-q, --quality <quality>', 'Session quality (1-10)')
    .option('-n, --notes <notes>', 'Notes')
    .option('-d, --days <days>', 'Number of days to analyze')
    .action(async (options) => {
    try {
        const config = loadConfig();
        const action = options.action || 'report';
        if (action === 'start') {
            if (!options.task) {
                logger.warn('需要提供: task');
                return;
            }
            await startFocusSession(config.outputBaseDir, options.task);
        }
        else if (action === 'end') {
            if (!options.id || !options.quality) {
                logger.warn('需要提供: id, quality');
                return;
            }
            await endFocusSession(config.outputBaseDir, options.id, parseInt(options.quality), options.notes);
        }
        else if (action === 'interrupt') {
            if (!options.id) {
                logger.warn('需要提供: id');
                return;
            }
            await logInterruption(config.outputBaseDir, options.id, 'other', 5);
        }
        else if (action === 'report') {
            const report = await generateFocusReport(config.outputBaseDir, parseInt(options.days) || 7);
            logger.info(report);
        }
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
// resume command
program
    .command('resume')
    .description('Generate resume from Git dataset')
    .option('-s, --start <date>', 'Start date (YYYY-MM-DD)')
    .option('-e, --end <date>', 'End date (YYYY-MM-DD)')
    .option('-n, --name <name>', 'Your name', '杨博')
    .option('-t, --title <title>', 'Job title', '高级前端开发工程师')
    .action(async (options) => {
    try {
        const config = loadConfig();
        await generateResume(config.outputBaseDir, options.start, options.end, options.name, options.title);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
});
program.parse();
//# sourceMappingURL=index.js.map