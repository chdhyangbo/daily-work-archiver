export interface EnergyLog {
    id: string;
    date: string;
    time: string;
    energyLevel: number;
    focusLevel: number;
    mood: 'energized' | 'calm' | 'tired' | 'stressed' | 'excited' | 'anxious' | 'neutral';
    task?: string;
    notes?: string;
    createdAt: string;
}
export interface DailyEnergySummary {
    date: string;
    logs: EnergyLog[];
    averageEnergy: number;
    averageFocus: number;
    dominantMood: string;
    peakHours: string[];
    lowHours: string[];
}
export interface EnergyPattern {
    bestHours: string[];
    worstHours: string[];
    averageEnergyByHour: Record<string, number>;
    energyTrend: 'improving' | 'stable' | 'declining';
    recommendations: string[];
}
export declare function initEnergyTracker(dataDir: string): Promise<string>;
export declare function logEnergy(dataDir: string, energyLevel: number, focusLevel: number, mood: EnergyLog['mood'], task?: string, notes?: string): Promise<EnergyLog>;
export declare function getDailyEnergySummary(dataDir: string, date?: string): Promise<DailyEnergySummary | null>;
export declare function analyzeEnergyPattern(dataDir: string, days?: number): Promise<EnergyPattern>;
export declare function generateEnergyReport(dataDir: string, days?: number): Promise<string>;
//# sourceMappingURL=energy-tracker.d.ts.map