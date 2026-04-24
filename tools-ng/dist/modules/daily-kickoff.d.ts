export interface DailyKickoff {
    date: string;
    yesterdayCompleted: string[];
    todayMITs: string[];
    goalsDueSoon: string[];
    emotionalState: 'energized' | 'calm' | 'tired' | 'stressed' | 'excited';
    focusPlan: string;
    createdAt: string;
}
export interface KickoffData {
    kickoffs: DailyKickoff[];
}
export declare function runDailyKickoff(dataDir: string): Promise<string>;
export declare function getKickoffHistory(dataDir: string, days?: number): Promise<DailyKickoff[]>;
//# sourceMappingURL=daily-kickoff.d.ts.map