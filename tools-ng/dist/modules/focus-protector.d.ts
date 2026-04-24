export interface FocusSession {
    id: string;
    date: string;
    startTime: string;
    endTime?: string;
    duration?: number;
    task: string;
    interruptions: Interruption[];
    quality: number;
    notes?: string;
}
export interface Interruption {
    time: string;
    type: 'notification' | 'meeting' | 'colleague' | 'self' | 'other';
    duration: number;
    recovered: boolean;
}
export interface FocusStats {
    totalSessions: number;
    totalFocusTime: number;
    averageSessionDuration: number;
    averageInterruptions: number;
    bestTimeOfDay: string;
    qualityTrend: 'improving' | 'stable' | 'declining';
}
export declare function initFocusProtector(dataDir: string): Promise<string>;
export declare function startFocusSession(dataDir: string, task: string): Promise<FocusSession>;
export declare function endFocusSession(dataDir: string, sessionId: string, quality: number, notes?: string): Promise<FocusSession>;
export declare function logInterruption(dataDir: string, sessionId: string, type: Interruption['type'], duration: number): Promise<FocusSession>;
export declare function analyzeFocusPattern(dataDir: string, days?: number): Promise<FocusStats>;
export declare function generateFocusReport(dataDir: string, days?: number): Promise<string>;
//# sourceMappingURL=focus-protector.d.ts.map