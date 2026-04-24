import { logger } from '../utils/logger.js';
export function exportToPDF(inputFile, outputFile) {
    logger.section('PDF Exporter');
    logger.info(`Input: ${inputFile}`);
    logger.info(`Output: ${outputFile}`);
    logger.warn('PDF export functionality requires additional dependencies (e.g., puppeteer)');
    logger.info('For now, please use browser Print to PDF:');
    logger.info('  1. Open the HTML file in browser');
    logger.info('  2. Press Ctrl+P');
    logger.info('  3. Select "Save as PDF"');
}
//# sourceMappingURL=pdf-exporter.js.map