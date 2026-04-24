# 定时任务使用指南

## 📋 目录

1. [功能说明](#功能说明)
2. [快速开始](#快速开始)
3. [手动执行](#手动执行)
4. [设置 Windows 定时任务](#设置-windows-定时任务)
5. [常见问题](#常见问题)

---

## 功能说明

定时任务系统会自动检查并发送目标提醒，帮助您追踪工作进度。

### 主要功能

- ⏰ **定时提醒** - 每天 3 个时间点自动检查（09:00, 14:00, 17:00）
- 🎯 **目标追踪** - 根据目标截止日期提前提醒（3天、1天、当天）
- 💬 **INFJ 友好** - 温和的提醒文案，不制造焦虑
- 🔔 **多渠道通知** - 桌面通知 + 终端输出

---

## 快速开始

### 步骤 1: 启用提醒系统

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
node enable-reminder-system.js
```

**输出示例:**
```
✅ 提醒系统已启用

配置信息:
  状态: 已启用
  风格: 温和模式 (INFJ友好)
  检查时间: 09:00, 14:00, 17:00
  通知渠道: 桌面通知 + 终端
  提前提醒: 3天、1天、当天
```

### 步骤 2: 生成提醒计划

```bash
npm run reminder -- -a schedule
```

这会检查所有活跃目标，并生成提醒时间表。

### 步骤 3: 测试提醒

```bash
npm run reminder -- -a check
```

如果有到期的提醒，会立即发送。

---

## 手动执行

### 检查提醒

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run reminder -- -a check
```

**功能**: 检查当前时间是否有需要发送的提醒

### 生成提醒计划

```bash
npm run reminder -- -a schedule
```

**功能**: 根据目标截止日期生成提醒时间表

### 查看提醒报告

```bash
npm run reminder -- -a report
```

**功能**: 显示提醒历史和即将触发的提醒

---

## 设置 Windows 定时任务

### 方式 1: 使用设置脚本（推荐）

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools-ng
.\setup-scheduled-task.ps1
```

**脚本会自动完成:**
1. ✅ 创建提醒检查脚本 (`check-reminders.ps1`)
2. ✅ 检查是否已存在同名任务
3. ✅ 创建 Windows 定时任务（每日 09:00, 14:00, 17:00）
4. ✅ 验证任务是否创建成功

### 方式 2: 手动创建

#### 1. 创建检查脚本

文件: `d:\work\ai\lingma\.lingma\skills\tools-ng\check-reminders.ps1`

```powershell
# 定时检查并发送提醒
$toolsNgDir = "d:\work\ai\lingma\.lingma\skills\tools-ng"
Set-Location $toolsNgDir

# 检查并发送提醒
npm run reminder -- -a check

# 生成提醒计划（如果有新目标）
npm run reminder -- -a schedule
```

#### 2. 创建 Windows 任务

打开 PowerShell（管理员权限）:

```powershell
# 创建触发器（每天 3 个时间点）
$triggers = @(
    (New-ScheduledTaskTrigger -Daily -At "09:00"),
    (New-ScheduledTaskTrigger -Daily -At "14:00"),
    (New-ScheduledTaskTrigger -Daily -At "17:00")
)

# 创建动作
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"d:\work\ai\lingma\.lingma\skills\tools-ng\check-reminders.ps1`""

# 创建设置
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

# 注册任务
Register-ScheduledTask `
    -TaskName "LingmaWorkArchiver" `
    -Action $action `
    -Trigger $triggers[0] `
    -Settings $settings `
    -Description "AI Work Archiver - 定时检查和发送目标提醒"
```

---

## 管理定时任务

### 查看任务状态

```powershell
schtasks /Query /TN "LingmaWorkArchiver" /V /FO LIST
```

### 手动触发任务

```powershell
schtasks /Run /TN "LingmaWorkArchiver"
```

### 禁用任务

```powershell
schtasks /Change /TN "LingmaWorkArchiver" /Disable
```

### 启用任务

```powershell
schtasks /Change /TN "LingmaWorkArchiver" /Enable
```

### 删除任务

```powershell
schtasks /Delete /TN "LingmaWorkArchiver" /F
```

---

## 配置说明

### 提醒配置文件

位置: `work-archive/data/reminders/config.json`

```json
{
  "enabled": true,
  "style": "gentle",
  "times": ["09:00", "14:00", "17:00"],
  "channels": ["notification", "terminal"],
  "advanceDays": [3, 1, 0]
}
```

### 配置项说明

| 配置项 | 说明 | 可选值 |
|--------|------|--------|
| `enabled` | 是否启用提醒系统 | `true` / `false` |
| `style` | 提醒文案风格 | `gentle`（温和）/ `direct`（直接）/ `motivational`（激励） |
| `times` | 每日检查时间 | 时间数组，格式 `HH:mm` |
| `channels` | 通知渠道 | `notification`（桌面）/ `terminal`（终端）/ `report`（报告） |
| `advanceDays` | 提前几天提醒 | 数字数组，如 `[3, 1, 0]` |

### 修改配置

直接编辑 `config.json` 文件，然后重新生成提醒计划：

```bash
npm run reminder -- -a schedule
```

---

## 常见问题

### Q1: 定时任务不执行？

**检查清单:**

1. **确认任务已启用**
   ```powershell
   schtasks /Query /TN "LingmaWorkArchiver"
   ```
   查看状态是否为 "Ready" 或 "Running"

2. **手动测试脚本**
   ```powershell
   cd d:\work\ai\lingma\.lingma\skills\tools-ng
   .\check-reminders.ps1
   ```

3. **检查提醒系统是否启用**
   ```bash
   cat work-archive/data/reminders/config.json
   ```
   确认 `"enabled": true`

4. **查看 Windows 事件日志**
   - 打开"事件查看器"
   - 导航到: 应用程序和服务日志 > Microsoft > Windows > TaskScheduler

### Q2: 没有收到提醒？

**可能原因:**

1. **没有活跃目标** - 先创建目标：
   ```bash
   npm run goal -- -a setup
   ```

2. **提醒计划未生成** - 重新生成：
   ```bash
   npm run reminder -- -a schedule
   ```

3. **提醒已过期** - 检查目标截止日期是否已过

4. **通知被禁用** - 检查 config.json 中的 `channels` 配置

### Q3: 如何自定义提醒时间？

编辑 `config.json` 中的 `times` 数组：

```json
{
  "times": ["08:00", "12:00", "18:00"]
}
```

然后更新 Windows 任务的触发器时间。

### Q4: 如何禁用某个目标的提醒？

在目标设置中将进度设为 100% 或删除目标：

```bash
# 完成目标
npm run goal -- -a update -i <goal_id> -p 100

# 或删除目标（需要手动编辑 goals/index.json）
```

### Q5: 提醒文案可以自定义吗？

可以修改 `config.json` 中的 `style`：

- `gentle` - 温和模式（默认，INFJ 友好）
- `direct` - 直接模式
- `motivational` - 激励模式

如果要完全自定义文案，需要修改源码：
`tools-ng/src/modules/reminder-engine.ts` 中的 `MESSAGE_TEMPLATES`

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `tools-ng/enable-reminder-system.js` | 启用提醒系统脚本 |
| `tools-ng/setup-scheduled-task.ps1` | Windows 定时任务设置脚本 |
| `tools-ng/check-reminders.ps1` | 提醒检查脚本（自动生成） |
| `tools-ng/src/modules/reminder-engine.ts` | 提醒引擎源码 |
| `work-archive/data/reminders/config.json` | 提醒配置文件 |
| `work-archive/data/reminders/schedule.json` | 提醒时间表 |
| `work-archive/data/reminders/history/` | 提醒历史记录 |

---

## 使用示例

### 日常工作流

**早上 9:00** - 自动触发
```
🎯 目标提醒
想想「学习 TypeScript」实现后的样子，还有 3 天，今天可以为它做些什么？
```

**下午 14:00** - 自动触发
```
（如果没有到期的提醒，则不显示）
```

**傍晚 17:00** - 自动触发
```
🎯 目标提醒
今天是推进「完成项目文档」的好时机，需要我帮你拆解第一步吗？
```

### 手动检查

随时可以手动检查：

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run reminder -- -a check
```

---

## 技术支持

如果遇到问题，可以：

1. 查看日志输出
2. 检查配置文件
3. 查看 Windows 事件日志
4. 手动执行脚本测试

**手动测试完整流程:**

```bash
# 1. 启用提醒系统
node enable-reminder-system.js

# 2. 生成提醒计划
npm run reminder -- -a schedule

# 3. 检查提醒
npm run reminder -- -a check

# 4. 查看报告
npm run reminder -- -a report
```
