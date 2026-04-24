import { AppConfig } from '../types.js';
/**
 * 获取时间追踪数据（按月）
 */
export declare function getTimeStatsForMonth(dates: string[], dataDir: string): Promise<{
    totalHours: number;
    dailyHours: Record<string, number>;
    projectHours: Record<string, number>;
    typeHours: Record<string, number>;
}>;
/**
 * 生成月度报告
 */
export declare function generateMonthlyReport(month: string, config: AppConfig): Promise<string>;
//# sourceMappingURL=monthly-report.d.ts.map