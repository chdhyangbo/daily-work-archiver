import { GitCommit, GitLogOptions } from '../types.js';
export declare function findGitDirs(rootPath: string, maxDepth?: number): Promise<string[]>;
export declare function getGitLog(projectPath: string, options: GitLogOptions): Promise<GitCommit[]>;
export declare function getCommitStats(hash: string, projectPath?: string): Promise<{
    insertions: number;
    deletions: number;
}>;
//# sourceMappingURL=git.d.ts.map