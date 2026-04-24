# AI Work Archiver

> 全功能自动化工作追踪和报告系统

## ⚡ 快速启动

### 1. 安装依赖

```bash
cd tools-ng
npm install
npm run build
```

### 2. 一键生成报告

```bash
# 生成本周周报（最常用）
npm run weekly

# 生成今日日报
npm run daily

# 生成本月报告
npm run monthly

# 完整流程（聚合数据 + 生成周报）
npm run full

# 查看成就
npm run achievement

# 生成仪表板数据
npm run dashboard

# 查看帮助菜单
npm run menu
```

### 3. 启动可视化面板

```bash
# 生成所有数据
npm run generate-all-data

# 启动文档服务器
cd ../docs-server
node server.js
```

访问: http://localhost:3456/overview

## 🛠 常用命令

### 报告生成

```bash
npm run report -- -t weekly          # 周报
npm run report -- -t daily           # 日报
npm run report -- -t monthly         # 月报
npm run report -- -t annual          # 年报
```

### 数据分析

```bash
npm run aggregate                    # 聚合Git数据
npm run quality                      # 代码质量分析
npm run analyze                      # 工作模式分析
npm run growth                       # 成长追踪
npm run impact                       # 变更影响分析
```

### 项目管理

```bash
npm run track                        # 项目进度追踪
npm run health                       # 项目健康监控
npm run retro                        # 项目复盘
```

### 开发模式（无需编译）

```bash
npm run dev -- report -t weekly
npm run dev -- achievement
npm run dev -- analyze
```

## 📦 工具清单

### 报告生成 (7个)
- daily-report - 日报生成器
- weekly-report - 周报生成器（含燃尽图）
- monthly-report - 月报生成器
- annual-report - 年度报告生成器
- smart-report-summarizer - 智能报告摘要
- pdf-exporter - PDF导出工具
- chart-generator - 图表生成器

### 分析工具 (6个)
- commit-classifier - 提交分类器
- commit-quality-scorer - 提交质量评分
- work-pattern-analyzer - 工作模式分析
- duplicate-work-detector - 重复工作检测
- growth-tracker - 成长追踪器
- change-impact-analyzer - 变更影响分析

### 项目管理 (5个)
- project-tracker - 项目进度追踪
- project-health-monitor - 项目健康监控
- project-retro - 项目复盘生成器
- workflow-automation - 工作流自动化
- time-optimizer - 时间优化助手

### 核心工具 (5个)
- git-aggregator - Git活动聚合器
- git-work-tracker - Git工作追踪器
- achievement-system - 成就系统
- time-tracker - 时间追踪器
- work-advisor - 智能工作建议

### 系统工具 (7个)
- dashboard-data - 仪表板数据生成
- data-backup - 数据备份工具
- notification - 桌面通知
- security - 数据安全工具
- quick-verification - 快速验证
- achievement-card-generator - 成就卡片生成
- achievement-image-generator - 成就图片生成

## ⚙️ 配置说明

编辑 `tools-ng/src/utils/config.ts`:

```typescript
export function loadConfig(): AppConfig {
  return {
    projectPaths: ['D:\\work\\code', 'D:\\work\\codepos'],  // 修改为您的项目路径
    author: 'yangbo',                                       // 修改为您的Git用户名
    outputBaseDir: path.resolve(__dirname, '../../work-archive'),
    daysBack: 365
  };
}
```

## 📁 数据目录结构

```
work-archive/
├── reports/                # 报告目录
│   ├── daily/              # 日报 (YYYY-MM/DD.md)
│   ├── weekly/             # 周报 (YYYY-WWW.md)
│   └── monthly/            # 月报 (YYYY-MM.md)
├── annual-reports/         # 年报
├── data/
│   ├── achievements/       # 成就数据
│   ├── git-activities/     # Git活动数据
│   └── dashboard-data.json # 仪表板数据
├── backups/                # 数据备份
└── visualizations/         # 可视化图表
```

## ❓ 常见问题

### Q: 命令找不到？
**A**: 确保在 `tools-ng` 目录下执行：
```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
```

### Q: 如何修改扫描的项目目录？
**A**: 编辑 `tools-ng/src/utils/config.ts` 中的 `projectPaths` 配置

### Q: Web面板无法访问？
**A**: 
1. 先生成数据：`npm run generate-all-data`
2. 启动服务器：`cd ../docs-server && node server.js`
3. 访问：http://localhost:3456/overview

### Q: 如何查看帮助？
**A**: 运行 `npm run menu` 查看所有可用命令

## 📚 更多文档

- [tools-ng 详细文档](tools-ng/README.md)
- [定时任务设置指南](tools-ng/SCHEDULED-TASK-GUIDE.md)
- [项目文档](docs/)

---

**版本**: 2.0.0 | **更新日期**: 2026-04-24
**技术栈**: TypeScript 5.3+ | Node.js 18+ | Express.js
