export interface GrowthMetric {
    month: string;
    commits: number;
    projects: number;
    streakDays: number;
}
export declare function trackGrowth(projectPaths: string[], author: string, months?: number): Promise<void>;
//# sourceMappingURL=growth-tracker.d.ts.map