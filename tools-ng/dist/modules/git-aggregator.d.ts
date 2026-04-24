import { AppConfig, GitCommit } from '../types.js';
export interface ActivitySummary {
    totalCommits: number;
    dateRange: {
        from: string;
        to: string;
    };
    projects: Record<string, number>;
    types: Record<string, number>;
    totalInsertions: number;
    totalDeletions: number;
    generatedAt: string;
}
export declare function aggregateGitActivities(config: AppConfig, options?: {
    daysBack?: number;
    startDate?: string;
    endDate?: string;
}): Promise<GitCommit[]>;
export declare function saveActivitiesByDate(activities: GitCommit[], outputDir: string, archiveDbDir: string): Promise<void>;
export declare function createActivityIndex(activities: GitCommit[], outputDir: string): Promise<void>;
//# sourceMappingURL=git-aggregator.d.ts.map