export interface ProjectConfig {
    project: string;
    milestones: Array<{
        name: string;
        estimated: number;
        completed: number;
        status: string;
    }>;
}
export declare function initProject(projectPath: string, projectName: string): Promise<void>;
export declare function updateProjectProgress(projectPath: string, milestoneName: string, progress: number): Promise<void>;
export declare function showProjectStatus(projectPath: string): Promise<void>;
//# sourceMappingURL=project-tracker.d.ts.map