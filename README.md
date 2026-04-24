# AI Work Archiver - 完整使用手册

> 🎉 **恭喜！您的全功能工作归档系统已安装完成！**
> 
> **开发完成**: 2026-04-17 | **总阶段**: 4/4 (100%) | **总工具**: 70+个 (41 PowerShell + 30 TypeScript)

---

## ⚡ 快速启动（推荐工具）

### 🚀 方式1：使用 tools-ng（Node.js版，最推荐）

新一代工具集，性能更快、跨平台支持、类型安全：

```powershell
# 1. 进入 tools-ng 目录
cd d:\work\ai\lingma\.lingma\skills\tools-ng

# 2. 安装依赖（只需一次）
npm install

# 3. 编译项目（只需一次）
npm run build
```

**一键生成报告（编译后）：**

```powershell
# 一键生成本周周报（最常用）
npm run weekly

# 一键生成今日日报
npm run daily

# 一键生成本月报告
npm run monthly

# 一键完成完整流程（聚合数据 + 生成周报）
npm run full

# 一键查看成就
npm run achievement

# 一键聚合Git数据
npm run aggregate

# 查看完整菜单
npm run menu
```

**开发模式（无需编译）：**

```powershell
# 使用 tsx 直接运行 TypeScript 源码
npm run dev -- report -t weekly
npm run dev -- achievement
npm run dev -- analyze
```

**详细文档**: 查看 [tools-ng/README.md](tools-ng/README.md)

---

### 📊 方式2：使用 PowerShell 工具（传统方式）

### 🚀 方式1：交互式控制台（最推荐）

启动可视化菜单，一键运行所有功能：

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
.\main-console.ps1
```

**功能菜单**:
- 选项1: 运行所有工具（完整流程）
- 选项2: 快速运行（跳过Git扫描）
- 选项3: 运行指定阶段
- 选项4: 查看数据总览
- 选项5: 打开统一展示中心
- 选项6: 验证所有功能
- 选项7: 备份数据

---

### 📊 方式2：命令行一键运行

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 运行所有工具
.\run-all-tools.ps1 -All

# 快速运行（跳过Git扫描）
.\run-all-tools.ps1 -Phase1 -Phase2 -Phase3 -Phase4 -Reports -Dashboard
```

---

### 🌐 方式3：统一展示中心

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 运行所有工具并启动Web服务
.\run-all-tools.ps1 -All
.\run-phase4.ps1 -All
```

**访问地址**:
- 统一展示中心: http://localhost:3456/overview ⭐
- 主仪表板: http://localhost:3456/dashboard
- 文档中心: http://localhost:3456/

---

### 📊 方式2：只生成报告

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 日报
.\daily-report-enhanced.ps1

# 周报
.\weekly-report-enhanced.ps1

# 月报
.\monthly-dashboard.ps1

# 年报
.\annual-report-generator.ps1
```

---

### 🏆 方式3：查看成就

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 检查成就
.\achievement-system-core.ps1 -Action check

# 列出所有成就
.\achievement-system-core.ps1 -Action list
```

---

### ⚙️ 方式4：备份数据

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 备份并压缩
.\data-backup-restore.ps1 -Action backup -Compress
```

---

### 🔧 常用命令速查表

| 功能 | 命令 |
|------|------|
| **启动交互式控制台** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\main-console.ps1` |
| **运行所有工具** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\run-all-tools.ps1 -All` |
| **统一展示中心** | `http://localhost:3456/overview` |
| **启动仪表板** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\run-phase4.ps1 -All` |
| **验证所有功能** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\quick-verification.ps1` |
| **生成日报** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\daily-report-enhanced.ps1` |
| **生成周报** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\weekly-report-enhanced.ps1` |
| **查看成就** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\achievement-system-core.ps1 -Action check` |
| **备份数据** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\data-backup-restore.ps1 -Action backup -Compress` |
| **生成交互图表** | `cd d:\work\ai\lingma\.lingma\skills\tools; .\chart-generator.ps1 -Type overview` |
| **停止服务** | 在运行服务器的终端按 `Ctrl+C` |

---

### ❗ 常见错误解决

**错误**: 无法将"run-phase4.ps1"项识别为 cmdlet

**解决方法**: 
```powershell
# 1. 先切换到 tools 目录
cd d:\work\ai\lingma\.lingma\skills\tools

# 2. 然后执行（注意前面有 .\）
.\run-phase4.ps1 -All
```

**错误**: 中文乱码

**解决方法**: 
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

---

## 📋 目录

1. [⚡ 快速启动](#-快速启动推荐工具)
   - [使用 tools-ng（推荐）](#-方式1使用-tools-ngnodejs版最推荐)
   - [使用 PowerShell 工具](#-方式2使用-powershell-工具传统方式)
2. [系统概览](#系统概览)
3. [快速开始](#快速开始)
4. [功能总览](#功能总览)
5. [tools-ng 工具集](#tools-ng-工具集)
6. [PowerShell 工具集](#powershell-工具集)
7. [统一展示中心](#统一展示中心)
8. [定时任务管理](#定时任务管理)
9. [配置说明](#配置说明)
10. [常见问题](#常见问题)

---

## 系统概览

AI Work Archiver 是一个全功能的自动化工作追踪和报告系统，帮助您：

- 📊 **自动追踪** Git 提交和工作活动
- 📝 **智能生成** 日报/周报/月报/年报
- 🤖 **AI分析** 工作模式和效率
- 🏆 **游戏化** 成就徽章系统
- 📈 **可视化** 数据图表和仪表板
- 💾 **安全备份** 数据保护和隐私

### 技术栈

**tools-ng (新一代)**:
- **语言**: TypeScript 5.3+
- **运行时**: Node.js 18+
- **CLI**: Commander.js
- **优势**: 跨平台、类型安全、高性能

**PowerShell (传统)**:
- **脚本**: PowerShell 5.1+
- **Web**: Node.js + Express
- **图表**: Chart.js
- **数据**: JSON + Markdown

---

## 快速开始

### 环境准备

**重要：所有命令都需要在 tools 目录下执行！**

```powershell
# 1. 进入工具目录（这是必须的）
cd d:\work\ai\lingma\.lingma\skills\tools

# 2. 设置UTF-8编码（避免中文乱码）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

**目录说明**:
- 📁 **tools/**: 所有PowerShell脚本都在这里执行
- 📁 **docs/**: 文档目录
- 📁 **docs-server/**: Web服务器目录
- 📁 **work-archive/**: 数据存储目录

### 方式 1: 启动Web仪表板（推荐）

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 启动仪表板和相关服务
.\run-phase4.ps1 -All

# 浏览器访问
# http://localhost:3456/dashboard
```

**用途**: 查看个人工作数据、贡献热力图、成就徽章、统计图表

**停止服务**: 在运行服务器的终端按 `Ctrl+C`

### 方式 2: 生成报告

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 生成日报
.\daily-report-enhanced.ps1

# 生成周报
.\weekly-report-enhanced.ps1

# 生成月报
.\monthly-dashboard.ps1

# 生成年报
.\annual-report-generator.ps1
```

**用途**: 自动生成工作摘要和绩效报告

**输出位置**: 
- 日报: `work-archive/reports/daily/YYYY-MM/`
- 周报: `work-archive/reports/weekly/`
- 月报: `work-archive/reports/monthly/`
- 年报: `work-archive/annual-reports/`

### 方式 3: 日常对话自动归档

像平常一样和我对话，我会自动归档您的工作内容：

```
你：今天上午优化了登录模块，性能提升30%
我：✅ 已归档今日工作
    - [FEATURE] [PERFORMANCE] 登录模块优化
    - 成果：性能提升30%
```

---

## tools-ng 工具集

> **推荐使用**：新一代 Node.js/TypeScript 工具集，性能更快、跨平台支持

### 快速开始

```powershell
# 1. 进入 tools-ng 目录
cd d:\work\ai\lingma\.lingma\skills\tools-ng

# 2. 安装依赖（只需一次）
npm install

# 3. 编译项目（只需一次）
npm run build
```

### npm Scripts 快捷命令

| 命令 | 功能 | 说明 |
|------|------|------|
| `npm run weekly` | 生成本周周报 | 最常用 |
| `npm run daily` | 生成今日日报 | 日常使用 |
| `npm run monthly` | 生成本月报告 | 月末使用 |
| `npm run full` | 完整流程 | 聚合数据 + 生成周报 |
| `npm run achievement` | 查看成就 | 成就系统 |
| `npm run aggregate` | 聚合Git数据 | 数据采集 |
| `npm run dashboard` | 生成仪表板数据 | 可视化 |
| `npm run menu` | 查看帮助菜单 | 命令清单 |

### 开发模式（无需编译）

```powershell
# 直接使用 tsx 运行 TypeScript 源码
npm run dev -- report -t weekly
npm run dev -- achievement
npm run dev -- analyze
```

### CLI 命令详解

所有命令格式：`node dist/index.js <command> [options]`

```powershell
# 报告生成
node dist/index.js report -t weekly
node dist/index.js report -t daily -d 2026-04-20
node dist/index.js report -t monthly

# 代码质量
node dist/index.js quality
node dist/index.js quality -d 30 -p D:\work\code\myproject

# 分析工具
node dist/index.js analyze
node dist/index.js analyze -d 30
node dist/index.js growth
node dist/index.js impact

# 项目管理
node dist/index.js track
node dist/index.js track -f today
node dist/index.js health
node dist/index.js retro

# 成就与建议
node dist/index.js achievement
node dist/index.js achievement -a list
node dist/index.js advisor

# 数据管理
node dist/index.js aggregate
node dist/index.js dashboard
node dist/index.js backup
```

### 完整工具清单 (30个)

**报告生成 (7个)**:
- daily-report.ts - 日报生成器
- weekly-report.ts - 周报生成器（含燃尽图）
- monthly-report.ts - 月报生成器
- annual-report.ts - 年度报告生成器
- smart-report-summarizer.ts - 智能报告摘要
- pdf-exporter.ts - PDF导出工具
- chart-generator.ts - 图表生成器

**分析工具 (6个)**:
- commit-classifier.ts - 提交分类器
- commit-quality-scorer.ts - 提交质量评分
- work-pattern-analyzer.ts - 工作模式分析
- duplicate-work-detector.ts - 重复工作检测
- growth-tracker.ts - 成长追踪器
- change-impact-analyzer.ts - 变更影响分析

**项目管理 (5个)**:
- project-tracker.ts - 项目进度追踪
- project-health-monitor.ts - 项目健康监控
- project-retro.ts - 项目复盘生成器
- workflow-automation.ts - 工作流自动化
- time-optimizer.ts - 时间优化助手

**核心工具 (5个)**:
- git-aggregator.ts - Git活动聚合器
- git-work-tracker.ts - Git工作追踪器
- achievement-system.ts - 成就系统
- time-tracker.ts - 时间追踪器
- work-advisor.ts - 智能工作建议

**系统工具 (7个)**:
- dashboard-data.ts - 仪表板数据生成
- data-backup.ts - 数据备份工具
- notification.ts - 桌面通知
- security.ts - 数据安全工具
- quick-verification.ts - 快速验证
- achievement-card-generator.ts - 成就卡片生成
- achievement-image-generator.ts - 成就图片生成

### 与 PowerShell 版本对比

| 特性 | PowerShell | tools-ng (Node.js) |
|------|-----------|-------------------|
| 性能 | 较慢 | 快 3-5x ✅ |
| 跨平台 | 仅 Windows | Windows/Mac/Linux ✅ |
| 类型安全 | 无 | TypeScript ✅ |
| 生态 | 有限 | npm 丰富生态 ✅ |
| 维护性 | 一般 | 优秀 ✅ |
| 扩展性 | 困难 | 容易 ✅ |
| 安装 | 无需安装 | 需要 Node.js 18+ |
| 使用 | 直接使用 | 需要 npm install + build |

### 配置修改

编辑 `src/utils/config.ts` 修改配置：

```typescript
export function loadConfig(): AppConfig {
  return {
    projectPaths: ['D:\\work\\code', 'D:\\work\\codepos'],
    author: 'yangbo',
    outputBaseDir: path.resolve(__dirname, '../../work-archive'),
    daysBack: 365
  };
}
```

**详细文档**: 查看 [tools-ng/README.md](tools-ng/README.md)

---

## PowerShell 工具集

> **传统方式**：所有 PowerShell 工具仍然可用，兼容 Windows 系统

### 快速启动

### 完整工具清单（28+个脚本）

#### 新增工具（2026-04-17）

| 阶段 | 工具 | 用途 | 启动命令 |
|------|------|------|----------|
| **Phase 1** | commit-quality-scorer.ps1 | 提交质量评分 | `.\commit-quality-scorer.ps1` |
| | workflow-automation.ps1 | 工作流自动化 | `.\workflow-automation.ps1 -Action check` |
| **Phase 2** | work-advisor.ps1 | 智能工作建议 | `.\work-advisor.ps1` |
| | growth-tracker.ps1 | 个人成长追踪 | `.\growth-tracker.ps1` |
| | time-optimizer.ps1 | 时间优化助手 | `.\time-optimizer.ps1` |
| **Phase 3** | change-impact-analyzer.ps1 | 变更影响分析 | `.\change-impact-analyzer.ps1` |
| | project-health-monitor.ps1 | 项目健康监控 | `.\project-health-monitor.ps1` |
| | project-retro-generator.ps1 | 项目复盘生成 | `.\project-retro-generator.ps1` |
| **Phase 4** | smart-report-summarizer.ps1 | 智能报告摘要 | `.\smart-report-summarizer.ps1 -ReportType weekly` |
| | achievement-card-generator.ps1 | 成就卡片生成 | `.\achievement-card-generator.ps1` |
| | data-dashboard-api.ps1 | API数据生成 | `.\data-dashboard-api.ps1` |
| **管理工具** | main-console.ps1 | 交互式控制台 | `.\main-console.ps1` ⭐ |
| | run-all-tools.ps1 | 一键运行器 | `.\run-all-tools.ps1 -All` |
| | quick-verification.ps1 | 快速验证 | `.\quick-verification.ps1` |

---

### 原有工具清单

| 阶段 | 工具 | 用途 | 启动命令 |
|------|------|------|----------|
| **Phase 1** | project-tracker.ps1 | 项目进度追踪 | `.\project-tracker.ps1` |
| | time-tracker.ps1 | 时间记录 | `.	ime-tracker.ps1` |
| | daily-report-enhanced.ps1 | 日报生成 | `.\daily-report-enhanced.ps1` |
| | git-work-tracker.ps1 | Git活动追踪 | `.\git-work-tracker.ps1 -TodayOnly` |
| **Phase 2** | weekly-report-enhanced.ps1 | 周报生成 | `.\weekly-report-enhanced.ps1` |
| | monthly-dashboard.ps1 | 月报仪表板 | `.\monthly-dashboard.ps1` |
| | commit-classifier.ps1 | 提交分类 | `.\commit-classifier.ps1` |
| **Phase 3** | work-pattern-analyzer.ps1 | 工作模式分析 | `.\work-pattern-analyzer.ps1` |
| | commit-message-enhancer.ps1 | 提交质量检测 | `.\commit-message-enhancer.ps1` |
| | duplicate-work-detector.ps1 | 重复代码检测 | `.\duplicate-work-detector.ps1` |
| **Phase 4** | achievement-system-core.ps1 | 成就系统 | `.chievement-system-core.ps1 -Action check` |
| | generate-dashboard-data.ps1 | 仪表板数据 | `.\generate-dashboard-data.ps1` |
| | run-phase4.ps1 | 阶段4启动器 | `.
un-phase4.ps1 -All` |
| **Phase 5** | pdf-exporter.ps1 | PDF导出 | `.\pdf-exporter.ps1 -ExportAllDaily` |
| | achievement-image-generator.ps1 | 成就卡片 | `.chievement-image-generator.ps1` |
| | notification-sender.ps1 | 桌面通知 | `.
otification-sender.ps1 -TestNotification` |
| | data-backup-restore.ps1 | 数据备份 | `.\data-backup-restore.ps1 -Action backup` |
| | annual-report-generator.ps1 | 年度报告 | `.nnual-report-generator.ps1` |
| | run-phase5.ps1 | 阶段5启动器 | `.
un-phase5.ps1 -All` |
| **Phase 6** | chart-generator.ps1 | 交互式图表 | `.\chart-generator.ps1 -Type overview` |
| **Phase 7** | security-tool.ps1 | 数据加密 | `.\security-tool.ps1 -Action encrypt` |

---

## 新增工具详细用法

### 🌟 交互式控制台 (main-console.ps1) ⭐ 最推荐

**用途**: 提供可视化菜单，一键运行所有功能

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
.\main-console.ps1
```

**功能菜单**:
- 选项1: 运行所有工具（完整流程）
- 选项2: 快速运行（跳过Git扫描）
- 选项3: 运行指定阶段
- 选项4: 查看数据总览
- 选项5: 打开统一展示中心
- 选项6: 验证所有功能
- 选项7: 备份数据

### 📊 一键运行器 (run-all-tools.ps1)

**用途**: 命令行一键运行所有或指定阶段工具

```powershell
# 运行所有工具
.\run-all-tools.ps1 -All

# 运行指定阶段
.\run-all-tools.ps1 -Phase1
.\run-all-tools.ps1 -Phase2
.\run-all-tools.ps1 -Phase3
.\run-all-tools.ps1 -Phase4

# 只生成报告
.\run-all-tools.ps1 -Reports

# 只更新仪表板
.\run-all-tools.ps1 -Dashboard
```

### ✅ 快速验证 (quick-verification.ps1)

**用途**: 测试所有功能是否正常运行

```powershell
.\quick-verification.ps1
```

### 🌐 统一展示中心

**用途**: 一站式查看所有分析数据

**访问**: http://localhost:3456/overview

**显示内容**:
- 核心指标卡片
- 质量分析
- 成长追踪
- 项目健康
- 智能报告链接

---

## 统一展示中心

### 访问地址

1. **统一展示中心**: http://localhost:3456/overview ⭐
2. **主仪表板**: http://localhost:3456/dashboard
3. **文档中心**: http://localhost:3456/

### 启动方式

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools

# 运行所有工具并启动Web服务
.\run-all-tools.ps1 -All
.\run-phase4.ps1 -All
```

### 功能特色

- 📊 核心指标实时显示
- 🎨 精美卡片式设计
- 🔄 自动刷新（60秒）
- 📱 响应式布局
- 🔗 快速跳转链接

---

## 原有工具详细用法

## 第一阶段：核心功能

### 1.1 Git工作追踪器 (git-work-tracker.ps1)

**用途**: 扫描所有Git仓库，统计提交活动，生成工作记录

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 扫描指定目录下的所有Git仓库
- 按作者过滤提交记录
- 统计提交次数、代码变更量
- 生成今日/本周/本月工作摘要

**使用方法**:

```powershell
# 查看今日提交
.\git-work-tracker.ps1 -TodayOnly

# 查看本周提交
.\git-work-tracker.ps1 -WeekOnly

# 查看本月提交
.\git-work-tracker.ps1 -MonthOnly

# 查看所有提交
.\git-work-tracker.ps1
```

**配置**:
- 编辑脚本第25-28行修改扫描目录
- 修改作者名称过滤器

**输出位置**: `work-archive/reports/daily/YYYY-MM/DD.md`

---

### 1.2 项目进度追踪器 (project-tracker.ps1)

**用途**: 跟踪项目里程碑、工时、完成进度

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 创建 `.project-config.yml` 配置文件
- 记录项目里程碑和预估工时
- 自动计算完成百分比
- 生成项目进度报告

**使用方法**:

```powershell
# 初始化项目配置
.\project-tracker.ps1 -Action init -ProjectPath "D:\work\code\my-project"

# 更新进度
.\project-tracker.ps1 -Action update -ProjectPath "D:\work\code\my-project" -Milestone "API开发" -Progress 80

# 查看项目状态
.\project-tracker.ps1 -Action status -ProjectPath "D:\work\code\my-project"

# 列出所有项目
.\project-tracker.ps1 -Action list
```

**输出**: 项目配置文件保存在项目根目录

---

### 1.3 时间追踪器 (time-tracker.ps1)

**用途**: 记录工作时间段、项目时间分配

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 开始/结束工作会话
- 记录项目时间分配
- 生成时间统计报告
- 计算总工作时长

**使用方法**:

```powershell
# 开始工作会话
.\time-tracker.ps1 -Action start -Project "my-project" -Task "API开发"

# 结束工作会话
.\time-tracker.ps1 -Action stop

# 查看今日时间记录
.\time-tracker.ps1 -Action view -Date "2026-04-14"

# 查看本周时间统计
.\time-tracker.ps1 -Action summary -Week

# 查看本月时间统计
.\time-tracker.ps1 -Action summary -Month
```

**输出位置**: `work-archive/data/time-tracking/YYYY-MM-DD.json`

---

### 1.4 日报生成器 (daily-report-enhanced.ps1)

**用途**: 自动生成详细的每日工作总结

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 汇总今日Git提交
- 整合时间追踪数据
- 提取项目进度更新
- 生成格式化的日报Markdown

**使用方法**:

```powershell
# 生成今日日报
.\daily-report-enhanced.ps1

# 生成指定日期日报
.\daily-report-enhanced.ps1 -Date "2026-04-14"
```

**输出位置**: `work-archive/reports/daily/YYYY-MM/YYYY-MM-DD.md`

---

## 第二阶段：报告系统

### 2.1 周报生成器 (weekly-report-enhanced.ps1)

**用途**: 生成本周工作总结，包含燃尽图和时间分配

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 汇总本周所有Git提交
- 生成ASCII燃尽图
- 时间分配饼图
- 项目进度汇总
- 下周计划建议

**使用方法**:

```powershell
# 生成本周周报
.\weekly-report-enhanced.ps1

# 生成指定周周报
.\weekly-report-enhanced.ps1 -WeekNumber 16 -Year 2026
```

**输出位置**: `work-archive/reports/weekly/YYYY-WWW.md`

---

### 2.2 月度仪表板 (monthly-dashboard.ps1)

**用途**: 生成月度绩效报告和关键指标

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 月度提交统计
- 项目贡献分布
- 工作类型分析
- 绩效评分
- 趋势对比

**使用方法**:

```powershell
# 生成本月月报
.\monthly-dashboard.ps1

# 生成指定月份月报
.\monthly-dashboard.ps1 -Month 4 -Year 2026
```

**输出位置**: `work-archive/reports/monthly/YYYY-MM.md`

---

### 2.3 提交分类器 (commit-classifier.ps1)

**用途**: 自动识别和分类Git提交类型

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 识别提交类型（FEATURE/BUGFIX/REFACTOR等）
- 统计各类型提交比例
- 生成分类报告

**使用方法**:

```powershell
# 分类今日提交
.\commit-classifier.ps1 -Today

# 分类本周提交
.\commit-classifier.ps1 -Week

# 分类指定日期范围
.\commit-classifier.ps1 -StartDate "2026-04-01" -EndDate "2026-04-14"
```

---

## 第三阶段：AI驱动功能

### 3.1 工作模式分析器 (work-pattern-analyzer.ps1)

**用途**: 分析工作习惯，识别高效时段

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 24小时工作分布分析
- 高效时段识别
- 专注时间统计
- 上下文切换检测
- 工作习惯建议

**使用方法**:

```powershell
# 分析工作模式
.\work-pattern-analyzer.ps1

# 分析指定月份
.\work-pattern-analyzer.ps1 -Month 4 -Year 2026
```

**输出**: 控制台显示分析报告和建议

---

### 3.2 提交信息增强器 (commit-message-enhancer.ps1)

**用途**: 检测和评分Git提交信息质量

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 提交信息质量评分（A-D级）
- 提供改进建议
- 检查命名规范
- 生成质量报告

**使用方法**:

```powershell
# 检查今日提交质量
.\commit-message-enhancer.ps1 -Today

# 检查本周提交质量
.\commit-message-enhancer.ps1 -Week

# 检查历史提交
.\commit-message-enhancer.ps1 -Days 30
```

---

### 3.3 重复工作检测器 (duplicate-work-detector.ps1)

**用途**: 检测代码库中的重复代码和工作

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- SimHash算法检测代码相似度
- 识别重复功能实现
- 生成重复代码报告
- 提供重构建议

**使用方法**:

```powershell
# 扫描重复代码
.\duplicate-work-detector.ps1 -ProjectPath "D:\work\code\my-project"

# 设置相似度阈值
.\duplicate-work-detector.ps1 -ProjectPath "D:\work\code\my-project" -Threshold 0.85
```

**输出**: 重复代码检测报告

---

## 第四阶段：可视化与游戏化

### 4.1 成就系统 (achievement-system-core.ps1)

**用途**: 追踪工作成就，解锁徽章和等级

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 7个成就徽章（提交里程碑、连续打卡等）
- 6级等级系统（Rookie → Legend）
- 积分激励机制
- 成就历史记录

**成就列表**:
| 徽章 | 名称 | 条件 | 积分 |
|------|------|------|------|
| SEED | Initial Commit | 首次提交 | +10 |
| SEEDLING | Getting Started | 10次提交 | +20 |
| TREE | Code Craftsman | 100次提交 | +50 |
| TROPHY | Code Master | 1000次提交 | +200 |
| FIRE | 3-Day Streak | 连续3天 | +15 |
| LIGHTNING | Week Warrior | 连续7天 | +30 |
| TARGET | Multi-tasker | 3个项目 | +30 |

**等级系统**:
| 等级 | 积分要求 | 图标 |
|------|----------|------|
| Code Rookie | 0+ | BRONZE |
| Junior Dev | 100+ | SILVER |
| Mid Dev | 300+ | GOLD |
| Senior Dev | 600+ | DIAMOND |
| Expert | 1000+ | CROWN |
| Legend | 2000+ | LEGEND |

**使用方法**:

```powershell
# 检查成就状态
.\achievement-system-core.ps1 -Action check

# 列出所有成就
.\achievement-system-core.ps1 -Action list

# 列出已解锁成就
.\achievement-system-core.ps1 -Action unlocked

# 重置成就数据
.\achievement-system-core.ps1 -Action reset
```

**输出位置**: `work-archive/data/achievements/achievements.json`

---

### 4.2 仪表板数据生成器 (generate-dashboard-data.ps1)

**用途**: 收集所有工作数据，生成仪表板所需的JSON

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 汇总Git统计数据
- 计算成就积分
- 生成时间分布数据
- 准备可视化数据

**使用方法**:

```powershell
# 生成仪表板数据
.\generate-dashboard-data.ps1
```

**输出位置**: `work-archive/data/dashboard-data.json`

---

### 4.3 Web仪表板 (run-phase4.ps1)

**用途**: 启动个人工作数据可视化仪表板

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 贡献热力图（GitHub风格）
- 统计卡片展示
- 项目分布图表
- 成就徽章墙
- 实时数据刷新

**使用方法**:

```powershell
# 启动所有Phase 4功能
.\run-phase4.ps1 -All

# 只启动Web服务器
.\run-phase4.ps1 -ServerOnly

# 生成数据但不启动服务器
.\run-phase4.ps1 -GenerateOnly

# 查看服务器状态
.\run-phase4.ps1 -Status
```

**访问地址**: http://localhost:3456/dashboard

**停止服务器**: 在终端按 `Ctrl+C`

---

## 第五阶段：高级集成

### 5.1 PDF导出器 (pdf-exporter.ps1)

**用途**: 将Markdown报告导出为可打印的HTML/PDF

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- Markdown转HTML
- 专业打印样式
- 支持日报/周报批量导出
- 表格和代码高亮

**使用方法**:

```powershell
# 导出所有日报
.\pdf-exporter.ps1 -ExportAllDaily

# 导出所有周报
.\pdf-exporter.ps1 -ExportAllWeekly

# 导出指定文件
.\pdf-exporter.ps1 -InputFile "path\to\report.md"
```

**输出位置**: `work-archive/exports/`

**转换为PDF**: 在浏览器中打开HTML文件，按Ctrl+P，选择"另存为PDF"

---

### 5.2 成就卡片生成器 (achievement-image-generator.ps1)

**用途**: 生成精美的成就分享卡片

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 渐变背景设计
- 专业排版布局
- 支持单个/批量生成
- 适合社交媒体分享

**使用方法**:

```powershell
# 生成所有成就卡片
.\achievement-image-generator.ps1

# 生成指定成就卡片
.\achievement-image-generator.ps1 -AchievementId FIRE
.\achievement-image-generator.ps1 -AchievementId LIGHTNING
```

**输出位置**: `work-archive/exports/`

**分享**: 在浏览器打开HTML，截图或打印为PDF

---

### 5.3 桌面通知器 (notification-sender.ps1)

**用途**: 发送Windows桌面通知（成就解锁、提醒等）

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- Windows气球通知
- Toast通知（Win10/11）
- 支持BurntToast模块
- 自定义通知类型

**使用方法**:

```powershell
# 测试通知
.\notification-sender.ps1 -TestNotification

# 发送自定义通知
.\notification-sender.ps1 -Title "成就解锁" -Message "你获得了：连续7天打卡" -Type achievement

# 发送提醒通知
.\notification-sender.ps1 -Title "提醒" -Message "该生成周报了" -Type warning
```

**安装BurntToast（可选，用于更好的通知）**:
```powershell
Install-Module -Name BurntToast -Scope CurrentUser
```

---

### 5.4 数据备份工具 (data-backup-restore.ps1)

**用途**: 备份和恢复所有工作数据

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 自动时间戳备份
- ZIP压缩支持
- 完整数据恢复
- 备份清单管理

**使用方法**:

```powershell
# 创建备份
.\data-backup-restore.ps1 -Action backup

# 创建压缩备份
.\data-backup-restore.ps1 -Action backup -Compress

# 列出所有备份
.\data-backup-restore.ps1 -Action list

# 恢复备份
.\data-backup-restore.ps1 -Action restore -BackupDir "path\to\backup"
```

**备份内容**: 日报、周报、月报、数据库、所有数据文件

**备份位置**: `work-archive/backups/`

---

### 5.5 年度报告生成器 (annual-report-generator.ps1)

**用途**: 生成年度的综合工作总结

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 年度提交统计
- 月度活动图表
- 项目分布分析
- 工作类型统计
- 代码变更汇总
- 关键指标展示

**使用方法**:

```powershell
# 生成当前年份年报
.\annual-report-generator.ps1

# 生成指定年份年报
.\annual-report-generator.ps1 -Year 2026
```

**输出位置**: `work-archive/annual-reports/YYYY-annual-report.md`

---

### 5.6 阶段5启动器 (run-phase5.ps1)

**用途**: 一键运行所有Phase 5功能

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**使用方法**:

```powershell
# 运行所有功能
.\run-phase5.ps1 -All

# 只导出PDF
.\run-phase5.ps1 -ExportPDF -ExportAllDaily

# 只生成成就卡片
.\run-phase5.ps1 -GenerateCards

# 只测试通知
.\run-phase5.ps1 -TestNotify

# 只备份数据
.\run-phase5.ps1 -Backup -Compress

# 只生成年报
.\run-phase5.ps1 -AnnualReport -Year 2026
```

---

## 第六阶段：数据可视化

### 6.1 交互式图表生成器 (chart-generator.ps1)

**用途**: 生成基于Chart.js的交互式数据可视化

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 月度提交柱状图
- 工作类型环形图
- 项目分布饼图
- 时段活动折线图
- 响应式布局设计

**使用方法**:

```powershell
# 生成总览图表
.\chart-generator.ps1 -Type overview

# 生成指定年份图表
.\chart-generator.ps1 -Type overview -Year 2026
```

**输出位置**: `work-archive/visualizations/YYYY-overview.html`

**查看**: 在浏览器中打开HTML文件，图表支持交互和动画

---

## 第七阶段：安全与隐私

### 7.1 数据安全工具 (security-tool.ps1)

**用途**: 加密敏感数据，保护隐私信息

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**功能**:
- 敏感信息自动检测（邮箱、卡号、密码、token等）
- 文件加密/解密
- 数据脱敏处理
- XOR加密算法

**使用方法**:

```powershell
# 加密文件
.\security-tool.ps1 -Action encrypt -InputFile "report.md" -OutputFile "report.enc" -Password "yourpassword"

# 解密文件
.\security-tool.ps1 -Action decrypt -InputFile "report.enc" -OutputFile "report.md" -Password "yourpassword"
```

**检测模式**:
- 邮箱地址 → `[EMAIL_REDACTED]`
- 信用卡号 → `[CARD_REDACTED]`
- 密码 → `password: [REDACTED]`
- Token → `token: [REDACTED]`
- API密钥 → `api_key: [REDACTED]`

---

## 定时任务管理

### 自动日报生成任务

系统可配置Windows定时任务，自动扫描Git并提交生成日报。

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

**安装/启用定时任务**:
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\setup-scheduled-task.ps1
```

**卸载/禁用定时任务**:
```powershell
.\setup-scheduled-task.ps1 -Uninstall
```

**临时暂停**:
```powershell
Disable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

**恢复运行**:
```powershell
Enable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

**查看状态**:
```powershell
Get-ScheduledTask -TaskName "Auto Daily Report Generator" | Get-ScheduledTaskInfo
```

**手动执行**:
```powershell
.\git-work-tracker.ps1 -TodayOnly
```

**默认时间**: 周一至周五 下午6:00

---

## 配置说明

### 修改Git扫描目录

**文件位置**: `d:\work\ai\lingma\.lingma\skills\tools\git-work-tracker.ps1`

1. 打开文件: `tools\git-work-tracker.ps1`
2. 找到第25-28行的 `$projectDirs` 配置:
```powershell
$projectDirs = @(
    "D:\work\code",
    "D:\work\codepos"
)
```
3. 修改为您的项目目录:
```powershell
$projectDirs = @(
    "C:\Your\Project\Path\1",
    "D:\Your\Project\Path\2"
)
```
4. 保存并重新运行

### 修改作者过滤器

**文件位置**: 所有PowerShell脚本中搜索 `yangbo` 并替换为您的Git用户名。

**涉及文件**: `tools/` 目录下的所有.ps1脚本

---

## 数据目录结构

```
work-archive/
├── reports/                # 统一报告目录
│   ├── daily/              # 日报
│   │   └── YYYY-MM/
│   │       └── YYYY-MM-DD.md
│   ├── weekly/             # 周报
│   │   └── YYYY-WWW.md
│   └── monthly/            # 月报
│       └── YYYY-MM.md
├── annual-reports/         # 年报
│   └── YYYY-annual-report.md
├── archive-db/             # 归档数据库
├── data/
│   ├── achievements/       # 成就数据
│   │   └── achievements.json
│   ├── time-tracking/      # 时间记录
│   │   └── YYYY-MM-DD.json
│   └── dashboard-data.json # 仪表板数据
├── exports/                # 导出文件
│   ├── PDF/HTML报告
│   └── 成就卡片
├── backups/                # 数据备份
│   └── backup_YYYYMMDD_HHMMSS/
└── visualizations/         # 可视化图表
    └── YYYY-overview.html
```

---

## 常见问题

### Q: 应该在哪里执行命令？
**A**: **所有PowerShell命令都需要在 tools 目录下执行！**
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
# 然后执行命令
```

### Q: 为什么命令找不到文件？
**A**: 请确认当前目录是否正确：
```powershell
# 检查当前目录
pwd
# 应该显示: D:\work\ai\lingma\.lingma\skills\tools

# 如果不在正确目录，请切换
Set-Location d:\work\ai\lingma\.lingma\skills\tools
```

### Q: 如何确保没有中文乱码？
**A**: 每次运行脚本前执行:
```powershell
# 在 tools 目录下执行
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

### Q: Web仪表板无法访问？
**A**: 
```powershell
# 1. 进入 tools 目录
cd d:\work\ai\lingma\.lingma\skills\tools

# 2. 启动服务
.\run-phase4.ps1 -All

# 3. 检查端口3456是否被占用
netstat -ano | findstr :3456

# 4. 访问 http://localhost:3456/dashboard
```

### Q: 成就系统没有数据？
**A**: 
```powershell
# 在 tools 目录下执行
cd d:\work\ai\lingma\.lingma\skills\tools

# 先运行数据生成器
.\generate-dashboard-data.ps1

# 再检查成就
.\achievement-system-core.ps1 -Action check
```

### Q: 如何备份所有数据？
**A**:
```powershell
# 在 tools 目录下执行
cd d:\work\ai\lingma\.lingma\skills\tools
.\data-backup-restore.ps1 -Action backup -Compress
```

### Q: 如何查看所有成就？
**A**:
```powershell
# 在 tools 目录下执行
cd d:\work\ai\lingma\.lingma\skills\tools
.\achievement-system-core.ps1 -Action list
```

### Q: 定时任务不执行？
**A**:
```powershell
# 在 tools 目录下执行
cd d:\work\ai\lingma\.lingma\skills\tools

# 1. 检查任务状态
Get-ScheduledTask -TaskName "Auto Daily Report Generator"

# 2. 手动执行测试
.\git-work-tracker.ps1 -TodayOnly

# 3. 重新安装任务
.\setup-scheduled-task.ps1 -Uninstall
.\setup-scheduled-task.ps1
```

### Q: 如何自定义报告内容？
**A**: 
```powershell
# 在 tools 目录下找到对应脚本
cd d:\work\ai\lingma\.lingma\skills\tools

# 用文本编辑器打开
notepad daily-report-enhanced.ps1

# 修改模板部分后保存
```

---

## 快速参考卡

### 每日工作流

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 早上
cd d:\work\ai\lingma\.lingma\skills\tools
.\run-phase4.ps1 -Status

# 工作中 - 自动归档对话

# 下班前
.\daily-report-enhanced.ps1
.\achievement-system-core.ps1 -Action check
```

### 每周工作流

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 周五
cd d:\work\ai\lingma\.lingma\skills\tools
.\weekly-report-enhanced.ps1
.\data-backup-restore.ps1 -Action backup
```

### 每月工作流

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 月末
cd d:\work\ai\lingma\.lingma\skills\tools
.\monthly-dashboard.ps1
.\pdf-exporter.ps1 -ExportAllDaily -ExportAllWeekly
```

### 每年工作流

**执行目录**: `d:\work\ai\lingma\.lingma\skills\tools`

```powershell
# 年末
cd d:\work\ai\lingma\.lingma\skills\tools
.\annual-report-generator.ps1
.\chart-generator.ps1 -Type overview
```

---

## 技术支持

- **文档**: 查看 `docs/` 目录下的详细文档
- **ROADMAP**: `ROADMAP.md` - 项目路线图
- **进度报告**: `docs/progress-report.md`
- **完成总结**: `docs/project-complete-summary.md`

---

**开发完成**: 2026-04-14  
**总工具数**: 28个PowerShell脚本  
**总阶段**: 7/7 (100%)  
**代码行数**: ~5,000+ 行

**🎉 开始使用吧！如有任何问题，随时询问！**
