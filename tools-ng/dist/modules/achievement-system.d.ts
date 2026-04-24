/**
 * 成就定义接口
 */
export interface Achievement {
    id: string;
    name: string;
    description: string;
    requirement: string;
    icon: string;
    category: string;
    points: number;
    condition: (stats: AchievementStats) => boolean;
}
export interface AchievementStats {
    totalCommits: number;
    projectCount: number;
    maxStreak: number;
    maxDailyCommits: number;
    vueCommits: number;
    reactCommits: number;
    tsCommits: number;
    frontendCommits: number;
    backendCommits: number;
    componentCount: number;
    uiPageCount: number;
    responsivePageCount: number;
    aiIntegrationCount: number;
    promptCount: number;
    modelTrainingCount: number;
    aiPipelineCount: number;
    ragSystemCount: number;
    agentCount: number;
    apiCount: number;
    databaseTableCount: number;
    codeReviewCount: number;
    bugFixCount: number;
    testCaseCount: number;
    perfOptimizationCount: number;
    docCount: number;
}
export interface AchievementLevel {
    name: string;
    minPoints: number;
    icon: string;
}
export interface AchievementResult {
    unlocked: number;
    totalPoints: number;
    totalPossible: number;
    list: Array<{
        id: string;
        name: string;
        description: string;
        requirement: string;
        icon: string;
        category: string;
        points: number;
        unlocked: boolean;
        progress: number;
    }>;
}
/**
 * 等级系统
 */
export declare const Levels: AchievementLevel[];
/**
 * 成就定义
 */
export declare const Achievements: Achievement[];
/**
 * 获取Git统计数据
 */
export declare function getGitStatistics(projectPaths: string[], author: string): Promise<AchievementStats>;
/**
 * 检查成就
 */
export declare function checkAchievements(stats: AchievementStats): AchievementResult;
/**
 * 获取当前等级
 */
export declare function getCurrentLevel(points: number): {
    current: AchievementLevel;
    next: AchievementLevel | null;
    progress: number;
};
/**
 * 主函数：检查成就
 */
export declare function runAchievementSystem(action: string, projectPaths: string[], author: string, outputPath: string): Promise<void>;
//# sourceMappingURL=achievement-system.d.ts.map