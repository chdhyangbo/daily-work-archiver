/**
 * 提交类型定义
 */
export interface CommitClassification {
    type: string;
    scope?: string;
    icon: string;
    color: string;
}
/**
 * 分类单个提交信息
 */
export declare function classifyCommit(subject: string): CommitClassification;
/**
 * 分析项目的提交分类
 */
export declare function analyzeCommits(projectPath: string, author: string, days?: number): Promise<Record<string, number>>;
/**
 * 为提交信息提供改进建议
 */
export declare function suggestCommitMessage(subject: string): string | null;
//# sourceMappingURL=commit-classifier.d.ts.map