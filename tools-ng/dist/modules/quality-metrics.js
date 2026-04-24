import { readJsonFile } from '../core/fs.js';
import path from 'path';
/**
 * Analyze quality metrics from git activity data
 */
export async function analyzeQualityMetrics(gitActivitiesDir, daysToAnalyze = 90) {
    // Load all git activity files
    const activities = await loadGitActivities(gitActivitiesDir, daysToAnalyze);
    if (activities.length === 0) {
        throw new Error('No git activity data found');
    }
    // Analyze each metric
    const commitMessageQuality = analyzeCommitMessageQuality(activities);
    const bugFixFrequency = analyzeBugFixFrequency(activities);
    const commitSizeDistribution = analyzeCommitSizeDistribution(activities);
    const workConsistency = analyzeWorkConsistency(activities);
    return {
        commitMessageQuality,
        bugFixFrequency,
        commitSizeDistribution,
        workConsistency
    };
}
/**
 * Load git activity data from JSON files
 */
async function loadGitActivities(activitiesDir, daysToAnalyze) {
    const { readdirSync, existsSync } = await import('fs');
    const activities = [];
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToAnalyze);
    const cutoffStr = cutoffDate.toISOString().split('T')[0];
    try {
        const files = readdirSync(activitiesDir);
        const jsonFiles = files.filter(f => f.endsWith('.json') && f !== 'activity-index.json');
        for (const file of jsonFiles) {
            const filePath = path.join(activitiesDir, file);
            const dateStr = file.replace('.json', '');
            // Skip if before cutoff date
            if (dateStr < cutoffStr)
                continue;
            try {
                const data = await readJsonFile(filePath);
                if (data.commits && data.commits.length > 0) {
                    activities.push(data);
                }
            }
            catch (error) {
                // Skip invalid files
                continue;
            }
        }
    }
    catch (error) {
        console.error('Error loading git activities:', error);
    }
    return activities;
}
/**
 * Analyze commit message quality
 */
function analyzeCommitMessageQuality(activities) {
    const allCommits = activities.flatMap(a => a.commits);
    const issues = [];
    let compliantCount = 0;
    const noTypePrefix = [];
    const noTicket = [];
    const tooShort = [];
    const tooLong = [];
    for (const commit of allCommits) {
        let isCompliant = true;
        const subject = commit.subject || commit.message;
        // Check type prefix
        const hasTypePrefix = /^(feat|fix|docs|style|refactor|test|chore|perf|Merge)/i.test(subject) ||
            /:(feat|fix|docs|style|refactor|test|chore|perf)/i.test(subject);
        if (!hasTypePrefix) {
            noTypePrefix.push(subject);
            isCompliant = false;
        }
        // Check ticket number
        const hasTicket = /[A-Z]+-\d+/.test(subject);
        if (!hasTicket) {
            noTicket.push(subject);
            isCompliant = false;
        }
        // Check length
        if (subject.length < 10) {
            tooShort.push(subject);
            isCompliant = false;
        }
        else if (subject.length > 100) {
            tooLong.push(subject);
            isCompliant = false;
        }
        if (isCompliant) {
            compliantCount++;
        }
    }
    const total = allCommits.length;
    const score = total > 0 ? Math.round((compliantCount / total) * 100) : 0;
    // Generate issues
    if (noTypePrefix.length > 0) {
        const percentage = Math.round((noTypePrefix.length / total) * 100);
        issues.push({
            severity: percentage > 30 ? 'high' : 'medium',
            description: `${percentage}% 的提交缺少类型前缀（feat/fix/refactor等）`,
            examples: noTypePrefix.slice(0, 5),
            improvement: '使用 Conventional Commits 规范，在提交消息开头添加类型前缀，如：feat: 新增用户登录功能'
        });
    }
    if (noTicket.length > 0) {
        const percentage = Math.round((noTicket.length / total) * 100);
        issues.push({
            severity: percentage > 20 ? 'medium' : 'low',
            description: `${percentage}% 的提交缺少任务编号（如 BK-24837）`,
            examples: noTicket.slice(0, 5),
            improvement: '在提交消息中包含任务追踪编号，格式：TICKET-123: 描述内容'
        });
    }
    if (tooShort.length > 0) {
        issues.push({
            severity: 'low',
            description: `${tooShort.length} 个提交消息过短（<10字符），描述不够清晰`,
            examples: tooShort.slice(0, 3),
            improvement: '提交消息应该清晰描述变更内容，建议至少 10 个字符'
        });
    }
    // Calculate trend (compare last 30 days vs previous 30 days)
    const trend = calculateTrend(activities, 'message');
    return {
        score,
        issues,
        trend,
        totalAnalyzed: total,
        compliantCount
    };
}
/**
 * Analyze bug fix frequency
 */
function analyzeBugFixFrequency(activities) {
    const allCommits = activities.flatMap(a => a.commits);
    const issues = [];
    const fixCommits = allCommits.filter(c => c.type === 'FIX');
    const totalCommits = allCommits.length;
    const fixRatio = totalCommits > 0 ? fixCommits.length / totalCommits : 0;
    // Find hotspots
    const projectFixCount = {};
    for (const commit of fixCommits) {
        projectFixCount[commit.project] = (projectFixCount[commit.project] || 0) + 1;
    }
    const hotspots = Object.entries(projectFixCount)
        .map(([project, count]) => ({ project, fixCount: count }))
        .sort((a, b) => b.fixCount - a.fixCount)
        .slice(0, 5);
    // Calculate score (lower fix ratio is better, but some fixes are normal)
    let score = 100;
    if (fixRatio > 0.6)
        score = 40;
    else if (fixRatio > 0.5)
        score = 50;
    else if (fixRatio > 0.4)
        score = 60;
    else if (fixRatio > 0.3)
        score = 70;
    else if (fixRatio > 0.2)
        score = 80;
    else
        score = 90;
    // Generate issues
    if (fixRatio > 0.4) {
        issues.push({
            severity: 'high',
            description: `修复类提交占比过高 (${Math.round(fixRatio * 100)}%)，代码质量可能存在问题`,
            examples: fixCommits.slice(0, 5).map(c => c.subject),
            improvement: '1. 加强代码审查和测试\n2. 在开发前先设计好方案\n3. 使用 TDD 方法减少后期修复'
        });
    }
    if (hotspots.length > 0 && hotspots[0].fixCount > 5) {
        issues.push({
            severity: 'medium',
            description: `项目 "${hotspots[0].project}" 有 ${hotspots[0].fixCount} 次修复，可能存在设计问题`,
            examples: fixCommits.filter(c => c.project === hotspots[0].project).slice(0, 3).map(c => c.subject),
            improvement: '1. 对该项目进行代码重构\n2. 增加单元测试覆盖\n3. 审查架构设计是否合理'
        });
    }
    return {
        score,
        fixRatio,
        totalFixes: fixCommits.length,
        totalCommits,
        hotspots,
        issues
    };
}
/**
 * Analyze commit size distribution
 */
function analyzeCommitSizeDistribution(activities) {
    const allCommits = activities.flatMap(a => a.commits);
    const issues = [];
    const sizes = allCommits.map(c => c.changed || (c.insertions + c.deletions));
    const averageSize = sizes.length > 0 ? sizes.reduce((sum, s) => sum + s, 0) / sizes.length : 0;
    const tooLarge = sizes.filter(s => s > 300).length;
    const tooSmall = sizes.filter(s => s > 0 && s < 5).length;
    const optimalCount = sizes.filter(s => s >= 5 && s <= 300).length;
    // Calculate score
    const total = sizes.length;
    const optimalRatio = total > 0 ? optimalCount / total : 0;
    const score = Math.round(optimalRatio * 100);
    // Generate issues
    if (tooLarge > 0) {
        const largeCommits = allCommits.filter(c => (c.changed || (c.insertions + c.deletions)) > 300);
        issues.push({
            severity: tooLarge > 5 ? 'high' : 'medium',
            description: `${tooLarge} 个提交变更过大（>300行），建议拆分`,
            examples: largeCommits.slice(0, 3).map(c => `${c.subject} (${c.changed || (c.insertions + c.deletions)} 行)`),
            improvement: '1. 将大提交拆分为多个小提交\n2. 每个提交只做一件事\n3. 按功能模块或文件分组提交'
        });
    }
    if (tooSmall > 0) {
        issues.push({
            severity: 'low',
            description: `${tooSmall} 个提交变更过小（<5行），可以考虑合并`,
            examples: [],
            improvement: '相关的微小改动可以合并为一个提交，保持提交历史的清晰'
        });
    }
    return {
        score,
        averageSize: Math.round(averageSize),
        tooLarge,
        tooSmall,
        optimalCount,
        issues
    };
}
/**
 * Analyze work consistency
 */
function analyzeWorkConsistency(activities) {
    const issues = [];
    // Get all dates with commits
    const dates = activities.map(a => a.date).sort();
    if (dates.length === 0) {
        return { score: 0, currentStreak: 0, maxStreak: 0, gaps: [], issues };
    }
    // Calculate streaks
    let currentStreak = 0;
    let maxStreak = 0;
    let tempStreak = 1;
    const gaps = [];
    const today = new Date().toISOString().split('T')[0];
    const lastDate = dates[dates.length - 1];
    // Check if there's a commit today or yesterday
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    if (lastDate === today || lastDate === yesterdayStr) {
        // Count current streak from today/yesterday backwards
        const dateSet = new Set(dates);
        let checkDate = new Date(lastDate === today ? today : yesterdayStr);
        while (dateSet.has(checkDate.toISOString().split('T')[0])) {
            currentStreak++;
            checkDate.setDate(checkDate.getDate() - 1);
        }
    }
    // Calculate max streak and gaps
    for (let i = 1; i < dates.length; i++) {
        const prevDate = new Date(dates[i - 1]);
        const currDate = new Date(dates[i]);
        const diffDays = Math.round((currDate.getTime() - prevDate.getTime()) / (1000 * 60 * 60 * 24));
        if (diffDays === 1) {
            tempStreak++;
            maxStreak = Math.max(maxStreak, tempStreak);
        }
        else if (diffDays > 3) {
            gaps.push({
                start: dates[i - 1],
                end: dates[i],
                days: diffDays
            });
            tempStreak = 1;
        }
        else {
            tempStreak = 1;
        }
    }
    maxStreak = Math.max(maxStreak, tempStreak);
    // Calculate score
    let score = 70;
    if (currentStreak >= 7)
        score += 20;
    else if (currentStreak >= 3)
        score += 10;
    if (maxStreak >= 10)
        score += 10;
    else if (maxStreak >= 5)
        score += 5;
    if (gaps.length > 3)
        score -= 20;
    else if (gaps.length > 1)
        score -= 10;
    score = Math.max(0, Math.min(100, score));
    // Generate issues
    if (gaps.length > 0) {
        const largeGaps = gaps.filter(g => g.days > 7);
        if (largeGaps.length > 0) {
            issues.push({
                severity: 'medium',
                description: `存在 ${largeGaps.length} 次较长的工作中断（>7天）`,
                examples: largeGaps.slice(0, 3).map(g => `${g.start} 至 ${g.end} (${g.days} 天)`),
                improvement: '1. 保持每日提交习惯，即使是小的进展\n2. 使用分支管理长期任务\n3. 设置每日编码目标'
            });
        }
    }
    if (currentStreak === 0) {
        issues.push({
            severity: 'low',
            description: '当前没有连续提交记录',
            examples: [],
            improvement: '从今天开始，每天都进行代码提交，建立连续工作习惯'
        });
    }
    return {
        score,
        currentStreak,
        maxStreak,
        gaps,
        issues
    };
}
/**
 * Calculate trend for a metric
 */
function calculateTrend(activities, metric) {
    if (activities.length < 2)
        return 'stable';
    const sorted = activities.sort((a, b) => a.date.localeCompare(b.date));
    const midPoint = Math.floor(sorted.length / 2);
    const recent = sorted.slice(midPoint);
    const older = sorted.slice(0, midPoint);
    let recentScore = 0;
    let olderScore = 0;
    if (metric === 'message') {
        recentScore = calculateMessageScore(recent);
        olderScore = calculateMessageScore(older);
    }
    else if (metric === 'fix') {
        recentScore = calculateFixScore(recent);
        olderScore = calculateFixScore(older);
    }
    const diff = recentScore - olderScore;
    if (diff > 5)
        return 'improving';
    if (diff < -5)
        return 'declining';
    return 'stable';
}
function calculateMessageScore(activities) {
    const commits = activities.flatMap(a => a.commits);
    if (commits.length === 0)
        return 50;
    let compliant = 0;
    for (const commit of commits) {
        const subject = commit.subject || commit.message;
        const hasType = /^(feat|fix|docs|style|refactor|test|chore|perf|Merge)/i.test(subject) ||
            /:(feat|fix|docs|style|refactor|test|chore|perf)/i.test(subject);
        const hasTicket = /[A-Z]+-\d+/.test(subject);
        if (hasType && hasTicket)
            compliant++;
    }
    return (compliant / commits.length) * 100;
}
function calculateFixScore(activities) {
    const commits = activities.flatMap(a => a.commits);
    if (commits.length === 0)
        return 50;
    const fixCount = commits.filter(c => c.type === 'FIX').length;
    const fixRatio = fixCount / commits.length;
    // Lower fix ratio is better
    return (1 - fixRatio) * 100;
}
//# sourceMappingURL=quality-metrics.js.map