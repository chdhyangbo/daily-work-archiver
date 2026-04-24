export interface SkillNode {
    id: string;
    name: string;
    category: string;
    level: number;
    startedAt: string;
    lastPracticed: string;
    milestones: string[];
}
export interface Milestone {
    id: string;
    title: string;
    date: string;
    description: string;
    category: 'technical' | 'soft' | 'leadership' | 'learning';
}
export interface CapabilityRadar {
    technical: number;
    problemSolving: number;
    communication: number;
    leadership: number;
    creativity: number;
    learning: number;
}
export interface GrowthData {
    skills: SkillNode[];
    milestones: Milestone[];
    capabilities: CapabilityRadar;
    lastUpdated: string;
}
export declare function initGrowthJourney(dataDir: string): Promise<string>;
export declare function addSkill(dataDir: string, name: string, category: string, level?: number): Promise<SkillNode>;
export declare function updateSkillLevel(dataDir: string, skillId: string, newLevel: number, milestone?: string): Promise<SkillNode>;
export declare function addMilestone(dataDir: string, title: string, description: string, category?: Milestone['category']): Promise<Milestone>;
export declare function updateCapabilities(dataDir: string, capabilities: Partial<CapabilityRadar>): Promise<CapabilityRadar>;
export declare function generateGrowthReport(dataDir: string): Promise<string>;
export declare function getGrowthTimeline(dataDir: string, months?: number): Promise<Milestone[]>;
//# sourceMappingURL=growth-journey.d.ts.map