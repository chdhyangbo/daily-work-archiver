export interface MetricIssue {
    severity: 'high' | 'medium' | 'low';
    description: string;
    examples: string[];
    improvement: string;
}
export interface QualityMetrics {
    commitMessageQuality: {
        score: number;
        issues: MetricIssue[];
        trend: 'improving' | 'declining' | 'stable';
        totalAnalyzed: number;
        compliantCount: number;
    };
    bugFixFrequency: {
        score: number;
        fixRatio: number;
        totalFixes: number;
        totalCommits: number;
        hotspots: Array<{
            project: string;
            fixCount: number;
        }>;
        issues: MetricIssue[];
    };
    commitSizeDistribution: {
        score: number;
        averageSize: number;
        tooLarge: number;
        tooSmall: number;
        optimalCount: number;
        issues: MetricIssue[];
    };
    workConsistency: {
        score: number;
        currentStreak: number;
        maxStreak: number;
        gaps: Array<{
            start: string;
            end: string;
            days: number;
        }>;
        issues: MetricIssue[];
    };
}
/**
 * Analyze quality metrics from git activity data
 */
export declare function analyzeQualityMetrics(gitActivitiesDir: string, daysToAnalyze?: number): Promise<QualityMetrics>;
//# sourceMappingURL=quality-metrics.d.ts.map