import { logger } from './utils/logger.js';
import { loadConfig } from './utils/config.js';

export interface AppConfig {
  projectPaths: string[];
  author: string;
  outputBaseDir: string;
  daysBack: number;
}

export interface GitCommit {
  hash: string;
  shortHash: string;
  dateTime: string;
  date: string;
  time: string;
  hour: number;
  author: string;
  project: string;
  subject: string;
  message: string;
  type: 'FEATURE' | 'FIX' | 'REFACTOR' | 'DOCS' | 'TEST' | 'OTHER';
  insertions: number;
  deletions: number;
  changed: number;
}

export interface GitLogOptions {
  since: string;
  until?: string;
  author: string;
  noMerges?: boolean;
}

export { logger, loadConfig };
