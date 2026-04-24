// Logger utility - replaces PowerShell's Write-Host -ForegroundColor
export const logger = {
    info: (msg) => console.log(`\x1b[34m${msg}\x1b[0m`),
    success: (msg) => console.log(`\x1b[32m${msg}\x1b[0m`),
    warn: (msg) => console.log(`\x1b[33m${msg}\x1b[0m`),
    error: (msg) => console.log(`\x1b[31m${msg}\x1b[0m`),
    cyan: (msg) => console.log(`\x1b[36m${msg}\x1b[0m`),
    gray: (msg) => console.log(`\x1b[90m${msg}\x1b[0m`),
    yellow: (msg) => console.log(`\x1b[33m${msg}\x1b[0m`),
    section: (title) => {
        console.log(`\n\x1b[36m${title}\x1b[0m`);
        console.log('\x1b[36m' + '='.repeat(50) + '\x1b[0m');
        console.log('');
    },
    divider: () => {
        console.log('\x1b[36m' + '-'.repeat(60) + '\x1b[0m');
    }
};
//# sourceMappingURL=logger.js.map