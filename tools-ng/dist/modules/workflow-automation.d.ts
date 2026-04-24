export interface WorkflowRule {
    name: string;
    condition: (stats: any) => boolean;
    action: () => void;
}
export declare function checkWorkflows(projectPaths: string[], author: string): Promise<void>;
//# sourceMappingURL=workflow-automation.d.ts.map