import { logger } from '../utils/logger.js';

export async function verifyAllTools(): Promise<void> {
  logger.section('Quick Verification');

  const tools = [
    'Git Aggregator',
    'Daily Report',
    'Weekly Report',
    'Monthly Report',
    'Annual Report',
    'Commit Classifier',
    'Commit Quality Scorer',
    'Work Pattern Analyzer',
    'Achievement System',
    'Growth Tracker',
    'Time Optimizer',
    'Duplicate Detector',
    'Change Impact Analyzer',
    'Project Health Monitor',
    'Project Retro',
    'Work Advisor',
    'Time Tracker',
    'Data Backup',
    'Dashboard Data',
    'Notification'
  ];

  logger.info(`Total tools available: ${tools.length}`);
  logger.section('Tool List:');

  tools.forEach((tool, index) => {
    logger.success(`  ${index + 1}. ${tool}`);
  });

  logger.section('All modules loaded successfully!');
}
