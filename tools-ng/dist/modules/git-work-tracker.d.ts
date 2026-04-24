export interface GitWorkStats {
    totalCommits: number;
    projects: Record<string, {
        commits: number;
        insertions: number;
        deletions: number;
    }>;
    dailySummary: Record<string, number>;
    weeklySummary: Record<string, number>;
    monthlySummary: Record<string, number>;
}
export declare function trackGitWork(projectPaths: string[], author: string, filter: 'today' | 'week' | 'month' | 'all', outputBaseDir: string): Promise<void>;
//# sourceMappingURL=git-work-tracker.d.ts.map