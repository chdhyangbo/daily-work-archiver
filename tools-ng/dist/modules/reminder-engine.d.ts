import { Goal } from './goal-tracker.js';
export interface ReminderSchedule {
    id: string;
    goalId: string;
    goalTitle: string;
    scheduledTime: string;
    reminderType: 'inspiration' | 'preparation' | 'action' | 'followup' | 'completed';
    message: string;
    sent: boolean;
    sentAt?: string;
    createdAt: string;
}
export interface ReminderConfig {
    enabled: boolean;
    style: 'gentle' | 'direct' | 'motivational';
    times: string[];
    channels: ('notification' | 'terminal' | 'report')[];
    advanceDays: number[];
}
export declare function initReminderSystem(dataDir: string): Promise<string>;
export declare function generateReminderSchedules(dataDir: string, goals?: Goal[]): Promise<ReminderSchedule[]>;
export declare function checkAndSendReminders(dataDir: string): Promise<number>;
export declare function checkOverdueGoals(dataDir: string): Promise<string[]>;
export declare function generateReminderReport(dataDir: string): Promise<string>;
//# sourceMappingURL=reminder-engine.d.ts.map