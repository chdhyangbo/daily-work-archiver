export interface TimeSession {
    project: string;
    task: string;
    start: string;
    end?: string;
    duration: number;
    type: string;
}
export interface TimeTrackingData {
    date: string;
    sessions: TimeSession[];
    summary: {
        total_hours: number;
        [key: string]: any;
    };
}
export declare function startTimeTracking(project: string, task: string, type: string, dataDir: string): Promise<void>;
export declare function stopTimeTracking(dataDir: string): Promise<void>;
export declare function viewTimeTracking(date: string, dataDir: string): Promise<void>;
//# sourceMappingURL=time-tracker.d.ts.map