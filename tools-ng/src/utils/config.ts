import { AppConfig } from '../types.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function loadConfig(): AppConfig {
  // 默认配置 - 统一使用 skills/work-archive 目录
  return {
    projectPaths: ['D:\\work\\code', 'D:\\work\\codepos'],
    author: 'yangbo',
    outputBaseDir: path.resolve(__dirname, '../../../work-archive'),
    daysBack: 365
  };
}
