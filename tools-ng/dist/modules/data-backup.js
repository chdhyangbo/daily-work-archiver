import { logger } from '../utils/logger.js';
import { ensureDir } from '../core/fs.js';
import path from 'path';
export async function backupData(dataDir, backupDir, action) {
    if (action === 'backup') {
        logger.section('Backing Up Data...');
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupPath = path.join(backupDir, `backup-${timestamp}`);
        await ensureDir(backupPath);
        const fs = await import('fs');
        const { cp } = await import('fs/promises');
        try {
            await cp(dataDir, backupPath, { recursive: true });
            logger.success(`Backup created: ${backupPath}`);
        }
        catch (error) {
            logger.error(`Backup failed: ${error.message}`);
        }
    }
    else if (action === 'restore') {
        logger.warn('Restore functionality coming soon');
    }
    else {
        logger.warn('Usage: npm start -- backup -a backup|restore');
    }
}
//# sourceMappingURL=data-backup.js.map