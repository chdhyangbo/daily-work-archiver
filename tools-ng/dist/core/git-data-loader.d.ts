/**
 * Git活动记录接口
 */
export interface GitActivityRecord {
    date: string;
    totalCommits: number;
    types: Record<string, number>;
    projects: string;
    commits: Array<{
        hash: string;
        shortHash: string;
        dateTime: string;
        date: string;
        time: string;
        hour: number;
        author: string;
        project: string;
        subject: string;
        message: string;
        type: string;
        insertions: number;
        deletions: number;
        changed: number;
    }>;
}
/**
 * 从git数据集加载指定日期范围的git活动
 */
export declare function loadGitActivities(dataDir: string, startDate: string, endDate: string): Promise<GitActivityRecord[]>;
/**
 * 从数据集获取周报数据
 */
export declare function getWeeklyReportData(dataDir: string, weekStart: string): Promise<{
    dates: string[];
    gitStats: Record<string, {
        commits: number;
        insertions: number;
        deletions: number;
        projects: Record<string, number>;
        commitDetails?: any[];
    }>;
}>;
/**
 * 从数据集获取月报数据
 */
export declare function getMonthlyReportData(dataDir: string, month: string): Promise<{
    totalCommits: number;
    totalInsertions: number;
    totalDeletions: number;
    projectStats: Record<string, {
        commits: number;
        insertions: number;
        deletions: number;
    }>;
    typeStats: Record<string, number>;
    dailyStats: Record<string, {
        commits: number;
        insertions: number;
        deletions: number;
    }>;
}>;
/**
 * 从数据集获取简历数据（指定日期范围）
 */
export declare function getResumeData(dataDir: string, startDate: string, endDate: string): Promise<{
    totalCommits: number;
    totalInsertions: number;
    totalDeletions: number;
    projects: Array<{
        name: string;
        commits: number;
        insertions: number;
        deletions: number;
        highlights: string[];
    }>;
    achievements: string[];
}>;
/**
 * 确保当日git数据已归档（如果不存在则提示）
 */
export declare function ensureTodayDataExists(dataDir: string): Promise<boolean>;
//# sourceMappingURL=git-data-loader.d.ts.map