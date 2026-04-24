export interface KeyResult {
    id: string;
    title: string;
    progress: number;
    deadline: string;
}
export interface ReminderConfig {
    daysBefore: number;
    message: string;
}
export interface Goal {
    id: string;
    title: string;
    level: 'yearly' | 'quarterly' | 'monthly' | 'weekly' | 'daily';
    description: string;
    why: string;
    keyResults: KeyResult[];
    progress: number;
    deadline: string;
    emotionalValue: 'growth' | 'impact' | 'mastery' | 'connection';
    reminders: ReminderConfig[];
    createdAt: string;
    updatedAt: string;
    status: 'active' | 'completed' | 'paused' | 'archived';
}
export interface GoalData {
    goals: Goal[];
    lastReview: string;
}
export declare function initGoalTracker(dataDir: string): Promise<string>;
export declare function addGoal(dataDir: string, goal: Omit<Goal, 'id' | 'createdAt' | 'updatedAt' | 'progress'>): Promise<Goal>;
export declare function updateGoalProgress(dataDir: string, goalId: string, progress: number, keyResultUpdates?: {
    keyResultId: string;
    progress: number;
}[]): Promise<Goal>;
export declare function getActiveGoals(dataDir: string, level?: Goal['level']): Promise<Goal[]>;
export declare function getGoalsDueSoon(dataDir: string, days?: number): Promise<Goal[]>;
export declare function getOverdueGoals(dataDir: string): Promise<Goal[]>;
export declare function generateGoalReport(dataDir: string, level?: Goal['level']): Promise<string>;
export declare function reviewGoals(dataDir: string): Promise<string>;
//# sourceMappingURL=goal-tracker.d.ts.map