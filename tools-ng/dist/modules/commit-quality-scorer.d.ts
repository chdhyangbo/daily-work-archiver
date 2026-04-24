export interface QualityScore {
    hash: string;
    subject: string;
    score: number;
    grade: string;
    details: string[];
}
export declare function scoreCommitQuality(projectPath: string, author: string, days: number | undefined, outputDir: string): Promise<void>;
//# sourceMappingURL=commit-quality-scorer.d.ts.map