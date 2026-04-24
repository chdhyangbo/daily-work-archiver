/**
 * 获取指定日期的 Git 统计数据
 */
export declare function getGitStatsByDay(date: string, projectPaths: string[], author: string): Promise<{
    commits: number;
    insertions: number;
    deletions: number;
    projects: Record<string, number>;
}>;
/**
 * 生成ASCII燃尽图
 */
export declare function generateBurndownChart(gitStats: Record<string, {
    commits: number;
}>, dates: string[]): string;
/**
 * 生成项目时间分配图（ASCII）
 */
export declare function generateTimePieChart(timeStats: Record<string, {
    projects: Record<string, number>;
}>, dates: string[]): string;
/**
 * 生成完整的周报
 */
export declare function generateWeeklyReport(weekStart: string, dates: string[], gitStats: Record<string, {
    commits: number;
    insertions: number;
    deletions: number;
    projects: Record<string, number>;
    commitDetails?: any[];
}>, timeStats: Record<string, {
    hours: number;
    types: Record<string, number>;
    projects: Record<string, number>;
}>): string;
/**
 * 获取时间追踪数据（按天）
 */
export declare function getTimeStatsByDay(date: string, dataDir: string): Promise<{
    hours: number;
    types: Record<string, number>;
    projects: Record<string, number>;
}>;
//# sourceMappingURL=weekly-report.d.ts.map