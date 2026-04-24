# Tools-NG: Node.js 版本工具集

> AI Work Archiver 的下一代工具集，从 PowerShell 迁移到 Node.js/TypeScript

## 🚀 快速开始（一键启动）

### 方式一：npm scripts（推荐，最简单）

#### 1. 首次设置（只需一次）

```powershell
# 进入项目目录
cd .lingma\skills\tools-ng

# 安装依赖
npm install

# 编译项目
npm run build
```

#### 2. 一键启动常用功能（已编译好）

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

# 一键生成仪表板
npm run dashboard

# 🌟 一键生成所有网页数据（dashboard + quality + growth + health）
npm run generate-all-data

# 一键聚合Git数据
npm run aggregate

# 查看完整菜单
npm run menu
```

#### 3. 开发模式（无需编译，即时运行）

```powershell
# 使用 tsx 直接运行 TypeScript 源码
npm run dev -- report -t weekly
npm run dev -- achievement
npm run dev -- analyze
```

---

### 方式二：直接运行 Node.js 命令

```powershell
# 编译后运行
npm run build
node dist/index.js report -t weekly
node dist/index.js report -t daily
node dist/index.js aggregate
node dist/index.js achievement

# 或直接运行（使用 tsx）
npx tsx src/index.ts report -t weekly
```

---

### 方式三：使用快捷脚本

```powershell
# 运行快捷脚本
.\run.ps1 weekly
.\run.ps1 daily
.\run.ps1 full
.\run.ps1 help
```

---

## ✅ 全部转换完成！

**总计**: 41个 PowerShell 工具 → 30个 TypeScript 模块  
**编译状态**: ✅ 成功  
**转换进度**: 100%

## 已转换的完整工具清单

### 报告生成工具 (7个)

1. **daily-report.ts** - 日报生成器
2. **weekly-report.ts** - 周报生成器（含燃尽图）
3. **monthly-report.ts** - 月报生成器
4. **annual-report.ts** - 年度报告生成器
5. **smart-report-summarizer.ts** - 智能报告摘要
6. **pdf-exporter.ts** - PDF导出工具
7. **chart-generator.ts** - 图表生成器

### 分析工具 (6个)

8. **commit-classifier.ts** - 提交分类器
9. **commit-quality-scorer.ts** - 提交质量评分
10. **work-pattern-analyzer.ts** - 工作模式分析
11. **duplicate-work-detector.ts** - 重复工作检测
12. **growth-tracker.ts** - 成长追踪器
13. **change-impact-analyzer.ts** - 变更影响分析

### 项目管理工具 (5个)

14. **project-tracker.ts** - 项目进度追踪
15. **project-health-monitor.ts** - 项目健康监控
16. **project-retro.ts** - 项目复盘生成器
17. **workflow-automation.ts** - 工作流自动化
18. **time-optimizer.ts** - 时间优化助手

### 核心工具 (5个)

19. **git-aggregator.ts** - Git活动聚合器
20. **git-work-tracker.ts** - Git工作追踪器
21. **achievement-system.ts** - 成就系统
22. **time-tracker.ts** - 时间追踪器
23. **work-advisor.ts** - 智能工作建议

### 系统工具 (7个)

24. **dashboard-data.ts** - 仪表板数据生成
25. **data-backup.ts** - 数据备份工具
26. **notification.ts** - 桌面通知
27. **security.ts** - 数据安全工具
28. **quick-verification.ts** - 快速验证
29. **achievement-card-generator.ts** - 成就卡片生成
30. **achievement-image-generator.ts** - 成就图片生成

## 完整的 Node.js CLI 命令清单

所有命令通过 `node dist/index.js` 运行，已配置 npm scripts 快捷方式。

## 📊 报告生成（最常用）

```powershell
# npm scripts 快捷方式（推荐）
npm run daily         # 一键生成今日日报（自动聚合+报告）
npm run weekly        # 一键生成本周周报（自动聚合+报告）
npm run monthly       # 一键生成本月报告
npm run full          # 完整流程：聚合数据 + 周报
npm run resume        # 一键生成简历（最近一年数据）

# 使用 node 直接运行
node dist/index.js report -t daily
node dist/index.js report -t weekly
node dist/index.js report -t monthly

# 指定日期和输出目录
node dist/index.js report -t weekly -d 2026-04-13 -o D:\reports

# 生成简历（指定日期范围）
node dist/index.js resume -s 2025-01-01 -e 2026-04-20
node dist/index.js resume -s 2025-01-01 -e 2026-04-20 -n "张三" -t "资深前端工程师"

# PDF 导出
node dist/index.js pdf -i report.html -o report.pdf

# 智能摘要
node dist/index.js summary -t weekly
```

### 💡 工作原理

报告生成**优先从 Git 数据集读取**，不再直接查询 Git 仓库：

1. **手动聚合数据**: 使用 `npm run agg:xxx` 命令聚合 Git 活动到数据集
2. **后续使用**: `npm run daily/weekly/monthly/resume` - 直接从数据集生成报告
3. **速度提升**: 从数分钟缩短到数秒

数据集位置：`work-archive/data/git-activities/YYYY-MM-DD.json`

### 📅 Git 数据聚合命令

**灵活的日期范围选择**：

```powershell
# 聚合今天的数据
npm run agg:today

# 聚合昨天的数据
npm run agg:yesterday

# 聚合本周的数据
npm run agg:week

# 聚合本月的数据
npm run agg:month

# 聚合近一年的数据
npm run agg:year

# 聚合最近 N 天
node dist/index.js aggregate --days 7     # 最近7天
node dist/index.js aggregate --days 30    # 最近30天

# 聚合指定日期范围
node dist/index.js aggregate --start 2026-04-01 --end 2026-04-30

# 默认聚合（最近30天）
npm run aggregate
```

**使用场景**：

| 场景 | 命令 |
|------|------|
| 每天下班前归档今日工作 | `npm run agg:today` |
| 第二天补录昨天的工作 | `npm run agg:yesterday` |
| 周末归档本周工作 | `npm run agg:week` |
| 月末归档本月工作 | `npm run agg:month` |
| 年初/离职时归档全部 | `npm run agg:year` |
| 补录指定时间段 | `node dist/index.js aggregate --start --end` |

### 🔍 代码质量分析

```powershell
# 分析最近30天提交质量
npm start -- quality

# 分析指定项目
npm start -- quality -p D:\work\code\myproject

# 建议更好的提交信息
npm start -- suggest "修复bug"
```

### 📈 分析工具

```powershell
# 分析工作模式（最近90天）
npm start -- analyze

# 分析指定天数
npm start -- analyze -d 30

# 检测重复工作
npm start -- duplicate

# 变更影响分析
npm start -- impact

# 成长追踪（最近12个月）
npm start -- growth

# 时间优化建议
npm start -- optimize
```

### 🎯 项目管理

```powershell
# 追踪工作（本周）
npm start -- track

# 追踪今天的工作
npm start -- track -f today

# 追踪本月工作
npm start -- track -f month

# 项目健康检查
npm start -- health

# 项目复盘
npm start -- retro

# 工作流检查
npm start -- workflow

# 项目初始化
npm start -- project -a init -p D:\work\code\myproject

# 查看项目状态
npm start -- project -a status -p D:\work\code\myproject
```

### 🏆 成就系统

```powershell
# 检查成就
npm start -- achievement

# 列出所有成就
npm start -- achievement -a list

# 查看已解锁成就
npm start -- achievement -a unlocked

# 查看工作建议
npm start -- advisor
```

### ⏱️ 时间管理

```powershell
# 开始计时
npm start -- time -a start -p 我的项目 -t 开发功能

# 停止计时
npm start -- time -a stop

# 查看今日时间
npm start -- time -a view

# 查看指定日期
npm start -- time -a view -d 2026-04-20
```

### 💾 数据管理

```powershell
# 一键聚合所有Git数据
npm start -- aggregate

# 生成仪表板数据
npm start -- dashboard

# 生成图表
npm start -- chart

# 数据备份
npm start -- backup

# 恢复数据
npm start -- backup -a restore
```

### 🔔 系统工具

```powershell
# 发送桌面通知
npm start -- notify "任务完成" "周报已生成"

# 验证所有工具
npm start -- verify

# 安全工具
npm start -- security -a encrypt -i data.json -o data.enc -p mypassword
```

### 选项说明

**report 命令**:
- `-t, --type`: 报告类型 (daily|weekly|monthly)
- `-d, --date`: 开始日期 (YYYY-MM-DD)
- `-o, --output`: 输出目录

**quality 命令**:
- `-d, --days`: 分析天数 (默认 30)
- `-p, --project`: 项目路径

## 项目结构

```
tools-ng/
├── src/
│   ├── core/
│   │   ├── git.ts          # Git 操作核心
│   │   └── fs.ts           # 文件系统操作
│   ├── modules/
│   │   ├── git-aggregator.ts      # Git 活动聚合器
│   │   ├── daily-report.ts        # 日报生成器
│   │   ├── weekly-report.ts       # 周报生成器
│   │   ├── monthly-report.ts      # 月报生成器
│   │   └── commit-classifier.ts   # 提交分类器
│   ├── utils/
│   │   ├── config.ts       # 配置管理
│   │   ├── date.ts         # 日期工具
│   │   └── logger.ts       # 日志工具
│   ├── types.ts            # 类型定义
│   └── index.ts            # CLI 入口
├── dist/                   # 编译输出
└── package.json
```

## 配置

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

## 开发

```bash
# 安装依赖
npm install

# 编译
npm run build

# 开发模式（使用 tsx）
npm run dev

# 运行
npm start
```

## 与 PowerShell 版本对比

| 特性 | PowerShell | Node.js |
|------|-----------|---------|
| 性能 | 较慢 | 快 3-5x |
| 跨平台 | 仅 Windows | Windows/Mac/Linux |
| 类型安全 | 无 | TypeScript |
| 生态 | 有限 | npm 丰富生态 |
| 维护性 | 一般 | 优秀 |
| 扩展性 | 困难 | 容易 |

## 待转换工具

以下工具仍为 PowerShell 版本，计划后续转换：

- [ ] achievement-system.ps1 (成就系统)
- [ ] work-pattern-analyzer.ps1 (工作模式分析)
- [ ] annual-report-generator.ps1 (年度报告)
- [ ] duplicate-work-detector.ps1 (重复工作检测)
- [ ] project-health-monitor.ps1 (项目健康监控)
- [ ] data-dashboard-api.ps1 (仪表板 API)

## 迁移进度

- ✅ Git Activity Aggregator (100%)
- ✅ Daily Report Generator (100%)
- ✅ Weekly Report Generator (100%)
- ✅ Monthly Report Generator (100%)
- ✅ Annual Report Generator (100%)
- ✅ Commit Classifier (100%)
- ✅ Commit Quality Scorer (100%)
- ✅ Work Pattern Analyzer (100%)
- ✅ Achievement System (100%)
- ✅ Growth Tracker (100%)
- ✅ Time Optimizer (100%)
- ✅ Duplicate Work Detector (100%)
- ✅ Change Impact Analyzer (100%)
- ✅ Project Health Monitor (100%)
- ✅ Project Retro Generator (100%)
- ✅ Work Advisor (100%)
- ✅ Git Work Tracker (100%)
- ✅ Time Tracker (100%)
- ✅ Project Tracker (100%)
- ✅ Workflow Automation (100%)
- ✅ Dashboard Data Generator (100%)
- ✅ Chart Generator (100%)
- ✅ Data Backup (100%)
- ✅ Notification System (100%)
- ✅ Security Tool (100%)
- ✅ Quick Verification (100%)
- ✅ PDF Exporter (100%)
- ✅ Smart Report Summarizer (100%)
- ✅ Achievement Card Generator (100%)
- ✅ Achievement Image Generator (100%)

**总体进度**: 30/30 (100%) ✅

## 💡 使用技巧

### 日常工作流

**推荐的每日工作流程**：

```powershell
# 1. 每天下班前归档今日工作（只需几秒）
npm run agg:today

# 2. 需要时快速生成报告（从数据集读取，秒级完成）
npm run daily      # 生成今日日报
npm run weekly     # 生成本周周报
npm run monthly    # 生成本月报告

# 3. 定期查看成就和进度
npm run achievement  # 查看成就解锁状态
npm run advisor      # 获取智能工作建议
```

### 报告生成最佳实践

**为什么报告生成这么快？**

报告生成**不再直接查询 Git 仓库**，而是从已聚合的数据集读取：

1. **首次使用**: 运行 `npm run aggregate` 聚合历史数据
2. **日常使用**: 运行 `npm run agg:today` 归档当日数据
3. **生成报告**: 直接从数据集读取，速度从数分钟缩短到数秒

**数据流向**：
```
Git 仓库 → npm run aggregate → 数据集 → npm run daily/weekly/monthly → 报告
         (手动触发，灵活控制)    (快速读取)    (秒级生成)
```

### Git 数据聚合技巧

**灵活的日期范围选择**：

```powershell
# 快捷命令
npm run agg:today      # 今天
npm run agg:yesterday  # 昨天
npm run agg:week       # 本周
npm run agg:month      # 本月
npm run agg:year       # 近一年

# 自定义范围
node dist/index.js aggregate --days 7                    # 最近7天
node dist/index.js aggregate --start 2026-04-01 --end 2026-04-30  # 指定范围
```

**使用场景对照表**：

| 场景 | 命令 | 说明 |
|------|------|------|
| 每天下班前 | `npm run agg:today` | 归档今日工作 |
| 第二天补录 | `npm run agg:yesterday` | 补录昨天工作 |
| 周末归档 | `npm run agg:week` | 聚合本周数据 |
| 月末归档 | `npm run agg:month` | 聚合本月数据 |
| 年初/离职 | `npm run agg:year` | 聚合全年数据 |
| 补录时间段 | `--start --end` | 自定义范围 |

### 简历生成技巧

**从数据集生成专业简历**：

```powershell
# 生成最近一年的简历
npm run resume

# 指定日期范围
node dist/index.js resume -s 2025-01-01 -e 2026-04-20

# 自定义姓名和职位
node dist/index.js resume -s 2025-01-01 -e 2026-04-20 -n "张三" -t "资深前端工程师"
```

**简历内容来源**：
- 项目贡献统计
- 代码变更数据
- 提交类型分布
- 工作亮点提取

### 开发调试技巧

**开发模式（无需编译）**：

```powershell
# 使用 tsx 直接运行，支持热重载
npm run dev -- report -t weekly
npm run dev -- achievement
npm run dev -- analyze
```

**查看帮助菜单**：

```powershell
npm run menu  # 查看所有可用命令
```

## 许可证

MIT
