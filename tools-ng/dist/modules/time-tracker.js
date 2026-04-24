import { logger } from '../utils/logger.js';
import { ensureDir, writeJsonFile } from '../core/fs.js';
import path from 'path';
export async function startTimeTracking(project, task, type, dataDir) {
    const today = new Date().toISOString().split('T')[0];
    const now = new Date().toLocaleTimeString('en-US', { hour12: false });
    const file = path.join(dataDir, `${today}.json`);
    let data = null;
    try {
        const fs = await import('fs');
        if (fs.existsSync(file)) {
            const content = fs.readFileSync(file, 'utf-8');
            data = JSON.parse(content);
        }
    }
    catch (e) {
        // File doesn't exist or is invalid
    }
    if (!data) {
        data = {
            date: today,
            sessions: [],
            summary: { total_hours: 0 }
        };
    }
    data.sessions.push({
        project,
        task,
        start: now,
        duration: 0,
        type
    });
    await ensureDir(dataDir);
    await writeJsonFile(file, data);
    logger.success(`Started tracking: ${project} - ${task}`);
    logger.info(`Start time: ${now}`);
}
export async function stopTimeTracking(dataDir) {
    const today = new Date().toISOString().split('T')[0];
    const now = new Date().toLocaleTimeString('en-US', { hour12: false });
    const file = path.join(dataDir, `${today}.json`);
    try {
        const fs = await import('fs');
        if (!fs.existsSync(file)) {
            logger.warn('No active session found');
            return;
        }
        const content = fs.readFileSync(file, 'utf-8');
        const data = JSON.parse(content);
        const activeSession = data.sessions.find(s => !s.end);
        if (!activeSession) {
            logger.warn('No active session found');
            return;
        }
        activeSession.end = now;
        const startMinutes = parseTime(activeSession.start);
        const endMinutes = parseTime(now);
        activeSession.duration = endMinutes - startMinutes;
        const totalMinutes = data.sessions.reduce((sum, s) => sum + s.duration, 0);
        data.summary.total_hours = Math.round((totalMinutes / 60) * 10) / 10;
        await writeJsonFile(file, data);
        logger.success(`Stopped tracking: ${activeSession.project} - ${activeSession.task}`);
        logger.info(`Duration: ${activeSession.duration} minutes`);
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
}
function parseTime(timeStr) {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
}
export async function viewTimeTracking(date, dataDir) {
    const file = path.join(dataDir, `${date}.json`);
    try {
        const fs = await import('fs');
        if (!fs.existsSync(file)) {
            logger.warn(`No data found for ${date}`);
            return;
        }
        const content = fs.readFileSync(file, 'utf-8');
        const data = JSON.parse(content);
        logger.section(`Time Tracking for ${date}`);
        logger.info(`Total Hours: ${data.summary.total_hours}`);
        logger.section('Sessions:');
        data.sessions.forEach(session => {
            logger.info(`  ${session.project} - ${session.task}`);
            logger.info(`    Time: ${session.start} - ${session.end || 'ongoing'}`);
            logger.info(`    Duration: ${session.duration} minutes`);
        });
    }
    catch (error) {
        logger.error(`Error: ${error.message}`);
    }
}
//# sourceMappingURL=time-tracker.js.map