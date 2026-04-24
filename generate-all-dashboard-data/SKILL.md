---
name: generate-all-dashboard-data
description: 一键生成所有网页数据，包括 overview 页面所需的全部数据文件。执行后会生成 dashboard-data.json、quality-report.json、growth-report.json、health-report.json 等所有数据。
version: 1.0.0
license: MIT
---

# 一键生成所有网页数据 - Generate All Dashboard Data

这个技能用于一键生成 `http://localhost:3456/overview` 统一展示中心所需的所有数据文件。

## 🎯 核心功能

一次性生成以下所有数据文件：

| 数据文件 | 生成命令 | 说明 |
|---------|---------|------|
| `dashboard-data.json` | `npm run dashboard` | 主仪表板数据（提交统计、质量评分、成就等） |
| `api/quality-report.json` | `npm run quality` | 质量分析报告 |
| `api/growth-report.json` | `npm run growth` | 成长追踪报告 |
| `api/health-report.json` | `npm run health` | 项目健康报告 |

## 🚀 使用方法

### 方式一：对话中直接生成（推荐）

当用户提到以下关键词时，自动执行：
- "生成所有数据"
- "一键生成数据"
- "刷新所有数据"
- "更新 dashboard 数据"
- "generate all data"
- "refresh dashboard"

### 方式二：手动执行命令

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run generate-all-data
```

或者直接运行 Node.js 脚本：

```bash
node d:\work\ai\lingma\.lingma\skills\generate-all-dashboard-data\generate-all-data.js
```

## 📋 执行流程

### 步骤 1: 生成仪表板数据

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run dashboard
```

**生成内容**：
- 提交统计（总提交数、今日提交、本周提交、连续天数）
- 质量评分
- 成就系统数据
- 保存到：`docs-server/public/dashboard-data.json`

### 步骤 2: 生成质量报告

```bash
npm run quality
```

**生成内容**：
- 提交质量评分
- 等级分布（S/A/B/C/D）
- 项目质量排名
- 保存到：`docs-server/public/api/quality-report.json`

### 步骤 3: 生成成长报告

```bash
npm run growth
```

**生成内容**：
- 参与项目统计
- 里程碑记录
- 技能成长轨迹
- 保存到：`docs-server/public/api/growth-report.json`

### 步骤 4: 生成健康报告

```bash
npm run health
```

**生成内容**：
- 项目健康评分
- 风险项目识别
- 健康趋势分析
- 保存到：`docs-server/public/api/health-report.json`

## 💡 AI 执行示例

### 示例 1: 用户请求生成所有数据

**用户**: 生成所有网页数据

**AI**:
```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run dashboard
```

📊 **步骤 1/4: 生成仪表板数据...**
- 正在分析 Git 提交记录...
- 正在计算质量评分...
- 正在更新成就状态...

✅ 仪表板数据已生成：`dashboard-data.json`

```bash
npm run quality
```

📊 **步骤 2/4: 生成质量报告...**
- 正在评估提交质量...
- 正在统计等级分布...

✅ 质量报告已生成：`api/quality-report.json`

```bash
npm run growth
```

📈 **步骤 3/4: 生成成长报告...**
- 正在分析成长轨迹...
- 正在计算里程碑...

✅ 成长报告已生成：`api/growth-report.json`

```bash
npm run health
```

💚 **步骤 4/4: 生成健康报告...**
- 正在评估项目健康度...
- 正在识别风险项目...

✅ 健康报告已生成：`api/health-report.json`

---

🎉 **所有数据生成完成！**

您可以访问以下页面查看数据：
- 统一展示中心：http://localhost:3456/overview
- 工作仪表板：http://localhost:3456/dashboard
- 成就系统：http://localhost:3456/achievements

如果服务器未启动，请先运行：
```bash
cd d:\work\ai\lingma\.lingma\skills\docs-server
node server.js
```

## 🔍 数据文件位置

所有生成的数据文件位于：

```
d:\work\ai\lingma\.lingma\skills\docs-server\public\
├── dashboard-data.json          # 主仪表板数据
└── api\
    ├── quality-report.json      # 质量报告
    ├── growth-report.json       # 成长报告
    └── health-report.json       # 健康报告
```

## ⚠️ 注意事项

1. **Git 仓库要求**：需要在工作区根目录有 Git 仓库
2. **数据依赖**：某些报告依赖聚合数据，建议先运行 `npm run aggregate`
3. **服务器状态**：生成数据后，如果服务器正在运行，页面会自动刷新
4. **执行时间**：完整生成所有数据通常需要 10-30 秒

## 🔄 完整工作流

### 推荐执行顺序

```bash
# 1. 聚合 Git 数据（可选，但推荐）
npm run aggregate

# 2. 生成所有网页数据
npm run dashboard && npm run quality && npm run growth && npm run health

# 3. 启动可视化面板（如果未启动）
cd d:\work\ai\lingma\.lingma\skills\docs-server
node server.js
```

### 一键执行脚本

可以创建一个 npm script 或直接运行 Node.js 脚本：

**方式 1: 使用 npm script（推荐）**

```bash
cd d:\work\ai\lingma\.lingma\skills\tools-ng
npm run generate-all-data
```

**方式 2: 直接运行 Node.js 脚本**

```bash
node d:\work\ai\lingma\.lingma\skills\generate-all-dashboard-data\generate-all-data.js
```

**方式 3: 添加全局命令（可选）**

在 `generate-all-dashboard-data` 目录执行：

```bash
npm link
```

然后可以在任何地方运行：

```bash
generate-all-data
```

## 📊 数据验证

生成完成后，可以检查文件是否存在：

**方式 1: 使用 Node.js 脚本（自动验证）**

```bash
node d:\work\ai\lingma\.lingma\skills\generate-all-dashboard-data\generate-all-data.js
```

脚本会自动验证所有文件并显示文件大小。

**方式 2: 手动检查**

```javascript
// 使用 Node.js 检查
const fs = require('fs');
const path = require('path');

const dataDir = 'd:\\work\\ai\\lingma\\.lingma\\skills\\docs-server\\public';
const files = [
  'dashboard-data.json',
  'api/quality-report.json',
  'api/growth-report.json',
  'api/health-report.json'
];

files.forEach(file => {
  const filePath = path.join(dataDir, file);
  const exists = fs.existsSync(filePath);
  console.log(`${exists ? '✅' : '❌'} ${file}`);
});
```

## 🎯 触发关键词

以下关键词会触发此技能：

| 中文 | 英文 |
|------|------|
| 生成所有数据 | generate all data |
| 一键生成数据 | one-click generate data |
| 刷新所有数据 | refresh all data |
| 更新 dashboard 数据 | update dashboard data |
| 生成网页数据 | generate web data |
| 更新 overview 数据 | update overview data |

## 💡 最佳实践

1. **定期更新**：建议每天工作结束时生成一次
2. **汇报前更新**：在向领导汇报工作前，先生成最新数据
3. **周报/月报生成后**：生成周报或月报后，同步更新网页数据
4. **启动面板前**：在打开可视化面板前，确保数据是最新的

---

**让我们开始生成数据吧！** 🚀
