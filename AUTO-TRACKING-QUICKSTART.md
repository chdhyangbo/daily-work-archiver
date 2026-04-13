# 自动记录系统 - 快速启动指南

> 🚀 **5 分钟实现完全自动化的工作记录！**

---

## 📋 三种自动化方案对比

| 方案 | 优点 | 推荐度 | 配置时间 |
|------|------|--------|----------|
| **Git 监控** | 零干扰、信息准确、无需额外工具 | ⭐⭐⭐⭐⭐ | 1 分钟 |
| **文件监控** | 记录完整、包含未提交代码 | ⭐⭐⭐⭐ | 2 分钟 |
| **混合模式** | 最全面、最智能 | ⭐⭐⭐⭐⭐ | 3 分钟 |

---

## 🎯 方案 A: Git 监控（最简单，强烈推荐）

### ✨ 特点
- ✅ **零配置** - 安装即用
- ✅ **完全无感** - 正常写代码即可
- ✅ **信息准确** - commit message 就是工作总结
- ✅ **自动生成日报** - 下班前一键生成

### 🚀 立即启用

#### 步骤 1: 运行 Git 扫描（每天下班前执行）

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\git-work-tracker.ps1 -TodayOnly
```

**或者创建桌面快捷方式**:
```powershell
# 一键扫描今日 Git 活动
.\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport
```

#### 步骤 2: 查看结果

扫描完成后会自动显示：
```
========================================
  今日 Git 活动统计
========================================

今日提交总数：8
活跃项目数：3

📁 alliance-admin-web
   提交数：4
   代码变更：+328 -156
   ✨ feat: 重构权限管理模块，添加 RBAC 角色控制
      (+328 -156)
   🐛 fix: 修复用户列表页面内存泄漏问题
      (+45 -28)

📁 b2b-lottrey-web
   提交数：3
   ...
```

#### 步骤 3: 生成日报

```powershell
# 自动生成 Markdown 格式的日报
.\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport
```

日报会自动保存到：
```
d:\work\ai\lingma\.lingma\skills\work-archive\daily-reports\2026-04\2026-04-02.md
```

### 💡 最佳实践

#### Commit Message 规范（推荐）
```bash
# 新功能
git commit -m "feat: 实现用户登录功能"

# Bug 修复
git commit -m "fix: 修复购物车计算错误"

# 文档更新
git commit -m "docs: 更新 API 文档"

# 性能优化
git commit -m "perf: 优化列表渲染性能"

# 代码重构
git commit -m "refactor: 重构订单处理逻辑"
```

#### 自动化工具（可选）
使用 [Commitizen](https://github.com/commitizen/cz-cli) 等工具规范化提交：
```bash
npm install -g commitizen
cz
```

---

## 🎯 方案 B: 文件监控（增强版）

### ✨ 特点
- ✅ **实时监控** - 记录所有文件变化
- ✅ **包含未提交代码** - 不怕忘记 Git 提交
- ✅ **时间统计** - 了解时间分配
- ✅ **后台静默** - 几乎不占用资源

### 🚀 立即启用

#### 步骤 1: 启动监控

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\work-activity-monitor.ps1 Start
```

**输出示例**:
```
========================================
  启动工作活动监控
========================================

✅ 监控已启动

监控范围:
  • D:\work\code
  • D:\work\codepos

数据保存位置:
  d:\work\ai\lingma\.lingma\skills\work-archive\archive-db\file-monitor

停止监控命令:
  .\work-activity-monitor.ps1 Stop

查看报告命令:
  .\work-activity-monitor.ps1 Report

💡 提示：
• 监控会在后台静默运行，几乎不占用资源
• 下班前运行 '.\work-activity-monitor.ps1 Report' 查看今日活动
• 离开公司时记得运行 '.\work-activity-monitor.ps1 Stop' 停止监控
```

#### 步骤 2: 正常工作

不需要任何操作，系统会自动记录：
- 修改了哪些文件
- 在哪个项目上工作
- 工作了多长时间
- 使用了哪些技术

#### 步骤 3: 查看报告

下班前运行：
```powershell
.\work-activity-monitor.ps1 Report
```

**报告示例**:
```
========================================
  今日工作活动报告
========================================

📊 今日概览
  • 总活动数：328 次
  • 涉及文件：86 个
  • 活跃项目：5 个

📁 活跃项目 TOP 5
  1. alliance-admin-web: 156 次 (47.6%)
  2. b2b-lottrey-web: 89 次 (27.1%)
  3. dataease: 45 次 (13.7%)
  4. operation: 23 次 (7.0%)
  5. store-info: 15 次 (4.6%)

📄 文件类型分布
  • .vue: 156 次
  • .js: 89 次
  • .ts: 45 次
  • .scss: 23 次
  • .json: 15 次
```

#### 步骤 4: 停止监控（离开公司时）

```powershell
.\work-activity-monitor.ps1 Stop
```

### 💡 日常使用流程

**早上到公司**:
```powershell
.\work-activity-monitor.ps1 Start
```

**正常工作**:
- 写代码、改文件、调试...
- 完全不需要管监控系统

**下班前**:
```powershell
.\work-activity-monitor.ps1 Report
```

**离开公司**:
```powershell
.\work-activity-monitor.ps1 Stop
```

---

## 🎯 方案 C: 混合模式（最强大）

### ✨ 特点
- ✅ **双重保障** - Git + 文件监控互补
- ✅ **最完整记录** - 不遗漏任何工作
- ✅ **智能分析** - 多维度数据交叉验证
- ✅ **自动生成完整日报**

### 🚀 立即启用

#### 步骤 1: 启动文件监控（早上）

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\work-activity-monitor.ps1 Start
```

#### 步骤 2: 正常工作

- 正常写代码
- 正常 Git 提交
- 完全无感

#### 步骤 3: 生成综合报告（下班前）

```powershell
# 1. 扫描 Git 活动
.\git-work-tracker.ps1 -TodayOnly

# 2. 查看文件监控报告
.\work-activity-monitor.ps1 Report

# 3. 整合两份数据生成完整日报
# （告诉我："生成今日日报"，我会自动整合）
```

#### 步骤 4: 停止监控（离开公司）

```powershell
.\work-activity-monitor.ps1 Stop
```

---

## 📊 生成的日报示例

### 基于 Git 活动的日报

```markdown
# 工作日报 - 2026-04-02

## 📊 今日概览
- **Git 提交**: 8 次
- **活跃项目**: 3 个
- **代码变更**: +528, -234
- **工作时长**: ~6.5 小时

## ✅ 完成的工作

### alliance-admin-web (4 次提交)

#### ✨ feat: 重构权限管理模块，添加 RBAC 角色控制
- **时间**: 2026-04-02 14:30
- **代码变更**: +328, -156
- **修改文件**: 8 个
- **技术栈**: Vue.js, Vuex, Permission Control

#### 🐛 fix: 修复用户列表页面内存泄漏问题
- **时间**: 2026-04-02 16:30
- **代码变更**: +45, -28
- **修改文件**: 3 个
- **技术栈**: Vue.js, JavaScript

### b2b-lottrey-web (3 次提交)

#### ✨ feat: 购物车批量结算功能实现
- **时间**: 2026-04-02 09:30
- **代码变更**: +456, -189
- **修改文件**: 12 个
- **技术栈**: Vue.js, Vuex, TypeScript

## 📈 工作统计
- **新功能**: 2 个
- **Bug 修复**: 1 个
- **文档更新**: 1 次

## 💡 明日计划
1. 继续完善权限管理模块的单元测试
2. 购物车功能联调测试
```

### 基于文件监控的日报

```markdown
# 工作活动报告 - 2026-04-02

## 📊 今日概览
- **总活动**: 328 次
- **涉及文件**: 86 个
- **活跃项目**: 5 个

## 📁 项目时间分配

### 1. alliance-admin-web (47.6%)
- **活动次数**: 156 次
- **主要文件**: 
  - src/views/permission/index.vue
  - src/store/modules/user.js
  - src/utils/auth.ts
- **推测工作**: 权限管理模块开发

### 2. b2b-lottrey-web (27.1%)
- **活动次数**: 89 次
- **主要文件**:
  - src/components/Cart/index.vue
  - src/api/order.js
- **推测工作**: 购物车功能开发

## 🕐 工作时间线
- **09:00-12:00**: b2b-lottrey-web (购物车功能)
- **14:00-16:30**: alliance-admin-web (权限管理)
- **16:30-17:00**: 修复 bug
- **17:00-18:00**: 文档整理
```

---

## 🔧 高级配置

### 定时任务（可选）

#### Windows 任务计划程序

**自动启动监控（每天早上 9 点）**:
```powershell
# 创建任务计划
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-NoProfile -WindowStyle Hidden -File `"d:\work\ai\lingma\.lingma\skills\tools\work-activity-monitor.ps1`" Start"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName "WorkMonitor-Start" -Action $action -Trigger $trigger
```

**自动生成日报（每天下午 6 点）**:
```powershell
# 创建任务计划
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-NoProfile -WindowStyle Hidden -File `"d:\work\ai\lingma\.lingma\skills\tools\git-work-tracker.ps1`" -TodayOnly -AutoGenerateReport"
$trigger = New-ScheduledTaskTrigger -Daily -At 6pm
Register-ScheduledTask -TaskName "WorkMonitor-Report" -Action $action -Trigger $trigger
```

**查看任务**:
```powershell
Get-ScheduledTask -TaskName "WorkMonitor-*"
```

**删除任务**:
```powershell
Unregister-ScheduledTask -TaskName "WorkMonitor-Start" -Confirm:$false
Unregister-ScheduledTask -TaskName "WorkMonitor-Report" -Confirm:$false
```

---

## 📋 常用命令速查

### Git 监控
```powershell
# 扫描今日 Git 活动
.\git-work-tracker.ps1 -TodayOnly

# 扫描最近 7 天活动
.\git-work-tracker.ps1

# 扫描并生成日报
.\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport

# 指定项目路径
.\git-work-tracker.ps1 -ProjectPath "D:\work\code"
```

### 文件监控
```powershell
# 启动监控
.\work-activity-monitor.ps1 Start

# 查看状态
.\work-activity-monitor.ps1 Status

# 查看报告
.\work-activity-monitor.ps1 Report

# 停止监控
.\work-activity-monitor.ps1 Stop
```

---

## ❓ 常见问题

### Q: 需要一直运行吗？
**A**: 
- **Git 监控**: 不需要，只需下班前运行一次扫描
- **文件监控**: 工作时运行，离开时停止

### Q: 会很卡吗？
**A**: 
- 完全不会！两个脚本都经过优化
- Git 监控：瞬间完成，零资源占用
- 文件监控：<1% CPU，极低内存

### Q: 隐私安全吗？
**A**: 
- ✅ 只记录元数据（文件名、时间、项目名）
- ❌ 不记录具体内容（代码、文档等）
- ✅ 所有数据本地存储
- ✅ 可随时关闭监控

### Q: 如果忘记运行怎么办？
**A**: 
- **Git 监控**: 随时可以补运行，会扫描所有提交
- **文件监控**: 忘记启动也不影响 Git 记录
- 两种方案互补，确保不遗漏

### Q: 可以临时关闭吗？
**A**: 
- ✅ 随时可以说："暂停监控"
- ✅ 也可以指定时间段
- ✅ 完全由您控制

---

## 🎯 推荐配置

### 最简配置（懒人首选）
```powershell
# 只在下班前运行一次
.\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport
```

### 标准配置（推荐）
```powershell
# 早上到公司
.\work-activity-monitor.ps1 Start

# 下班前
.\work-activity-monitor.ps1 Report
.\git-work-tracker.ps1 -TodayOnly -AutoGenerateReport

# 离开公司
.\work-activity-monitor.ps1 Stop
```

### 完全自动化（极客模式）
```powershell
# 设置定时任务后，完全不需要手动操作
# 每天早上 9 点自动启动
# 每天下午 6 点自动生成日报
# 每天下午 6 点半自动停止
```

---

## 🚀 立即开始

### 现在就试试最简单的 Git 监控！

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\git-work-tracker.ps1 -TodayOnly
```

**看看今天有没有 Git 提交？**

如果有，会立即显示统计结果！  
如果没有，会提示您今天还没有提交。

---

## 💡 下一步

1. **今天先试试 Git 监控** - 最简单，零门槛
2. **明天加上文件监控** - 更完整，双保险
3. **后天设置定时任务** - 完全自动化
4. **每天自动生成日报** - 享受自动化带来的便利

---

**准备好了吗？选择一个方案开始吧！** 🎉

- 方案 A（简单）: `.\git-work-tracker.ps1 -TodayOnly`
- 方案 B（完整）: `.\work-activity-monitor.ps1 Start`
- 方案 C（自动）: 设置定时任务
