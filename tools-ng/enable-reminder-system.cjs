// 启用提醒系统脚本
// enable-reminder-system.js

const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'work-archive', 'data');
const reminderDir = path.join(dataDir, 'reminders');
const configFile = path.join(reminderDir, 'config.json');

// 确保目录存在
if (!fs.existsSync(reminderDir)) {
  fs.mkdirSync(reminderDir, { recursive: true });
  fs.mkdirSync(path.join(reminderDir, 'history'), { recursive: true });
}

// 创建或更新配置
const config = {
  enabled: true,
  style: 'gentle',
  times: ['09:00', '14:00', '17:00'],
  channels: ['notification', 'terminal'],
  advanceDays: [3, 1, 0]
};

fs.writeFileSync(configFile, JSON.stringify(config, null, 2), 'utf8');

console.log('✅ 提醒系统已启用');
console.log('');
console.log('配置信息:');
console.log('  状态: 已启用');
console.log('  风格: 温和模式 (INFJ友好)');
console.log('  检查时间: 09:00, 14:00, 17:00');
console.log('  通知渠道: 桌面通知 + 终端');
console.log('  提前提醒: 3天、1天、当天');
console.log('');
console.log('下一步:');
console.log('  1. 运行定时任务设置: .\\setup-scheduled-task.ps1');
console.log('  2. 手动测试提醒: npm run reminder -- -a check');
console.log('  3. 生成提醒计划: npm run reminder -- -a schedule');
