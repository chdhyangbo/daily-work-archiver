import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';
/**
 * 提交分类规则
 */
const ClassificationRules = {
    FEATURE: {
        patterns: [/^feat(\(.+\))?[\:\-]/i, /新增/, /添加/, /实现/, /支持/, /添加功能/],
        keywords: ['add', 'implement', 'support', 'introduce', 'create'],
        icon: '✨',
        color: 'green'
    },
    FIX: {
        patterns: [/^fix(\(.+\))?[\:\-]/i, /修复/, /解决/, /修正/, /处理/, /bug/],
        keywords: ['fix', 'repair', 'resolve', 'correct', 'handle'],
        icon: '🐛',
        color: 'red'
    },
    REFACTOR: {
        patterns: [/^refactor(\(.+\))?[\:\-]/i, /^ref[\:\-]/i, /重构/, /优化/, /改进/, /简化/, /清理/],
        keywords: ['refactor', 'optimize', 'improve', 'simplify', 'clean', 'restructure'],
        icon: '♻️',
        color: 'yellow'
    },
    DOCS: {
        patterns: [/^docs(\(.+\))?[\:\-]/i, /^doc[\:\-]/i, /文档/, /注释/, /readme/i, /说明/],
        keywords: ['doc', 'document', 'comment', 'readme', 'guide'],
        icon: '📝',
        color: 'blue'
    },
    TEST: {
        patterns: [/^test(\(.+\))?[\:\-]/i, /^tests(\(.+\))?[\:\-]/i, /测试/, /单元测试/, /测试用例/],
        keywords: ['test', 'spec', 'unit', 'e2e', 'coverage'],
        icon: '🧪',
        color: 'cyan'
    },
    STYLE: {
        patterns: [/^style(\(.+\))?[\:\-]/i, /格式/, /样式/, /缩进/, /空格/],
        keywords: ['style', 'format', 'indent', 'whitespace', 'lint'],
        icon: '🎨',
        color: 'magenta'
    },
    CHORE: {
        patterns: [/^chore(\(.+\))?[\:\-]/i, /^build(\(.+\))?[\:\-]/i, /^ci(\(.+\))?[\:\-]/i, /构建/, /配置/, /依赖/],
        keywords: ['chore', 'build', 'ci', 'config', 'dependency', 'setup'],
        icon: '🔧',
        color: 'gray'
    }
};
/**
 * 分类单个提交信息
 */
export function classifyCommit(subject) {
    const lowerSubject = subject.toLowerCase();
    for (const [type, rule] of Object.entries(ClassificationRules)) {
        // 检查正则模式
        for (const pattern of rule.patterns) {
            if (pattern.test(subject)) {
                return { type, icon: rule.icon, color: rule.color };
            }
        }
        // 检查关键词
        for (const keyword of rule.keywords) {
            if (lowerSubject.includes(keyword.toLowerCase())) {
                return { type, icon: rule.icon, color: rule.color };
            }
        }
    }
    return { type: 'OTHER', icon: '📦', color: 'gray' };
}
/**
 * 分析项目的提交分类
 */
export async function analyzeCommits(projectPath, author, days = 7) {
    logger.section(`Analyzing commits for ${projectPath}...`);
    const since = new Date();
    since.setDate(since.getDate() - days);
    const sinceStr = since.toISOString().split('T')[0];
    try {
        process.chdir(projectPath);
        const command = `git -c core.quotepath=false log --since="${sinceStr}" --author="${author}" --pretty=format:"%s" --no-merges`;
        const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
        if (!output.trim()) {
            logger.warn('No commits found');
            return {};
        }
        const subjects = output.split('\n').filter(line => line.trim());
        const classification = {};
        subjects.forEach(subject => {
            const result = classifyCommit(subject);
            if (!classification[result.type]) {
                classification[result.type] = 0;
            }
            classification[result.type]++;
        });
        // 显示结果
        logger.success(`Total commits: ${subjects.length}`);
        logger.info('\nClassification:');
        const sorted = Object.entries(classification).sort((a, b) => b[1] - a[1]);
        sorted.forEach(([type, count]) => {
            const rule = ClassificationRules[type];
            const icon = rule?.icon || '📦';
            const percent = Math.round((count / subjects.length) * 100);
            logger.info(`  ${icon} ${type}: ${count} (${percent}%)`);
        });
        return classification;
    }
    catch (error) {
        logger.error(`Error analyzing commits: ${error.message}`);
        return {};
    }
}
/**
 * 为提交信息提供改进建议
 */
export function suggestCommitMessage(subject) {
    const classification = classifyCommit(subject);
    // 如果已经是好的格式，不需要改进
    if (/^(feat|fix|docs|style|refactor|test|chore|build|ci)(\(.+\))?[\:\-]/.test(subject)) {
        return null;
    }
    // 提供改进建议
    const type = classification.type.toLowerCase();
    let suggestion = `${type}: ${subject}`;
    // 检查是否有明显的范围信息
    if (subject.includes('登录') || subject.includes('login')) {
        suggestion = `${type}(auth): ${subject}`;
    }
    else if (subject.includes('订单') || subject.includes('order')) {
        suggestion = `${type}(order): ${subject}`;
    }
    else if (subject.includes('用户') || subject.includes('user')) {
        suggestion = `${type}(user): ${subject}`;
    }
    return suggestion;
}
//# sourceMappingURL=commit-classifier.js.map