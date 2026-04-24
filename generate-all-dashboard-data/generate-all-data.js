#!/usr/bin/env node

/**
 * 一键生成所有网页数据
 * Generate All Dashboard Data
 * 
 * 生成 overview 页面所需的所有数据文件：
 * - dashboard-data.json
 * - api/quality-report.json
 * - api/growth-report.json
 * - api/health-report.json
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  white: '\x1b[37m',
  gray: '\x1b[90m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function runCommand(command, description) {
  log(`\n📊 ${description}...`, 'yellow');
  try {
    execSync(command, { 
      stdio: 'inherit',
      cwd: path.join(__dirname, '..', 'tools-ng')
    });
    return true;
  } catch (error) {
    log(`❌ ${description} 失败`, 'red');
    return false;
  }
}

async function main() {
  log('========================================', 'cyan');
  log('🚀 一键生成所有网页数据', 'green');
  log('========================================', 'cyan');
  log('');

  const tasks = [
    {
      command: 'npm run dashboard',
      description: '步骤 1/4: 生成仪表板数据',
      file: 'dashboard-data.json'
    },
    {
      command: 'npm run quality',
      description: '步骤 2/4: 生成质量报告',
      file: 'api/quality-report.json'
    },
    {
      command: 'npm run growth',
      description: '步骤 3/4: 生成成长报告',
      file: 'api/growth-report.json'
    },
    {
      command: 'npm run health',
      description: '步骤 4/4: 生成健康报告',
      file: 'api/health-report.json'
    }
  ];

  const results = [];

  // 执行所有任务
  for (const task of tasks) {
    const success = runCommand(task.command, task.description);
    results.push({ ...task, success });
  }

  // 验证文件
  log('\n========================================', 'cyan');
  log('📁 验证数据文件...', 'green');
  log('========================================', 'cyan');
  log('');

  const dataDir = path.join(__dirname, '..', 'docs-server', 'public');
  let allSuccess = true;

  for (const result of results) {
    const filePath = path.join(dataDir, result.file);
    if (fs.existsSync(filePath)) {
      const stats = fs.statSync(filePath);
      const size = (stats.size / 1024).toFixed(2);
      log(`✅ ${result.file} (${size} KB)`, 'green');
    } else {
      log(`❌ ${result.file} (未生成)`, 'red');
      allSuccess = false;
    }
  }

  log('');
  log('========================================', 'cyan');

  if (allSuccess) {
    log('🎉 所有数据生成完成！', 'green');
    log('========================================', 'cyan');
    log('');
    log('访问地址:', 'white');
    log('  - 统一展示中心: http://localhost:3456/overview', 'cyan');
    log('  - 工作仪表板: http://localhost:3456/dashboard', 'cyan');
    log('  - 成就系统: http://localhost:3456/achievements', 'cyan');
  } else {
    log('⚠️ 部分数据未生成，请检查错误信息', 'yellow');
    log('========================================', 'cyan');
  }

  log('');
  
  // 退出码
  process.exit(allSuccess ? 0 : 1);
}

// 运行
main().catch(error => {
  log(`\n❌ 发生错误: ${error.message}`, 'red');
  process.exit(1);
});
