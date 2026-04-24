import { findGitDirs } from './dist/core/git.js';

const dirs = await findGitDirs('D:\\work\\code');
console.log(dirs.filter(d => d.includes('order-reveal') || d.includes('baike-desktop-client')));
