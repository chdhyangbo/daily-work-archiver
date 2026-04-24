export interface ActivityPattern {
    hourDistribution: Record<number, number>;
    dayDistribution: Record<string, number>;
    peakHour: number;
    peakDay: string;
    averageCommitsPerDay: number;
    streakDays: number;
}
export declare function analyzeWorkPattern(projectPaths: string[], author: string, days?: number): Promise<void>;
//# sourceMappingURL=work-pattern-analyzer.d.ts.map