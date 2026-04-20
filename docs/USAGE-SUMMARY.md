# AI Work Archiver - 系统使用总结

> 完整的使用指南，包含一键调用和统一展示入口

---

## 📦 系统概览

**总计工具**: 25个  
**开发阶段**: Phase 1-4 全部完成  
**状态**: ✅ 可立即使用

---

## 🚀 一键调用方法

### 方法1：交互式控制台 ⭐ 最推荐

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

### 方法2：命令行一键运行

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 运行所有工具
.\run-all-tools.ps1 -All

# 快速运行（跳过Git扫描）
.\run-all-tools.ps1 -Phase1 -Phase2 -Phase3 -Phase4 -Reports -Dashboard

# 只运行某个Phase
.\run-all-tools.ps1 -Phase1
.\run-all-tools.ps1 -Phase4
```

---

### 方法3：单独运行某个工具

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools

# Phase 1
.\commit-quality-scorer.ps1
.\workflow-automation.ps1 -Action check

# Phase 2
.\work-advisor.ps1
.\growth-tracker.ps1
.\time-optimizer.ps1

# Phase 3
.\change-impact-analyzer.ps1
.\project-health-monitor.ps1
.\project-retro-generator.ps1

# Phase 4
.\smart-report-summarizer.ps1 -ReportType weekly
.\achievement-card-generator.ps1
.\data-dashboard-api.ps1
```

---

## 🌐 统一展示入口

### 启动Web服务

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\run-phase4.ps1 -All
```

### 访问地址

1. **统一展示中心**: http://localhost:3456/overview ⭐ 推荐
   - 一站式查看所有数据
   - 核心指标卡片
   - 质量、成长、健康分析
   - 智能报告链接
   - 自动刷新（60秒）

2. **主仪表板**: http://localhost:3456/dashboard
   - Git提交可视化
   - 贡献图
   - 项目分布
   - 最近提交列表

3. **文档中心**: http://localhost:3456/
   - Markdown文档浏览
   - 全文搜索

---

## 📊 一键验收数据

### 快速验证

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\quick-verification.ps1
```

这会：
- 测试所有工具是否正常运行
- 检查数据文件是否生成
- 显示通过/失败统计

---

### 完整验收流程

```powershell
# 步骤1：运行所有工具
.\run-all-tools.ps1 -All

# 步骤2：验证功能
.\quick-verification.ps1

# 步骤3：启动Web服务
.\run-phase4.ps1 -All

# 步骤4：浏览器访问
# http://localhost:3456/overview
# http://localhost:3456/dashboard
```

---

## 📁 数据文件位置

所有生成的数据保存在：

```
work-archive/data/
├── git-activities/           # Git活动数据库（按日期的JSON文件）
├── commit-quality/           # 提交质量评分
│   ├── quality-summary.json
│   ├── top-commits.json
│   ├── project-quality.json
│   └── quality-trend.json
├── work-advice/              # 工作建议
├── growth/                   # 成长追踪
│   └── growth-report.json
├── time-optimization/        # 时间优化
├── change-impact/            # 变更影响分析
├── project-health/           # 项目健康监控
│   └── health-report.json
├── retrospectives/           # 项目复盘
├── smart-reports/            # 智能报告（Markdown格式）
├── achievement-cards/        # 成就卡片（HTML格式）
└── api/                      # API数据（供Web展示）
    ├── quality-report.json
    ├── growth-report.json
    └── health-report.json
```

---

## 🎯 统一展示中心功能

访问 http://localhost:3456/overview 可以看到：

### 1. 核心指标区
- 📝 提交统计卡片
  - 总提交数
  - 今日提交
  - 本周提交
  - 连续天数

- ⭐ 质量评分卡片
  - 平均分数
  - 进度条显示
  - 等级分布徽章

- 🏆 成就系统卡片
  - 已解锁成就数
  - 总积分
  - 当前等级

### 2. 质量分析区
- 📊 质量总览
- 🏅 等级分布（S/A/B/C/D）
- 📈 Top 5 项目质量排行

### 3. 成长追踪区
- 📊 成长总览
  - 参与项目数
  - 总提交数
  - 里程碑数
- 🎯 里程碑时间线

### 4. 项目健康区
- 💚 健康总览
  - 健康项目数
  - 一般项目数
  - 风险项目数
- 📋 项目状态列表
  - 健康分数
  - 状态指示器（绿/黄/红）

### 5. 智能报告区
- 📝 报告链接（点击直接查看JSON数据）
- 🎖️ 快速跳转链接

### 6. 自动刷新
- 每60秒自动刷新数据
- 手动刷新按钮

---

## 📋 工具清单

### Phase 1: 基础增强 ✅
1. commit-quality-scorer.ps1 - 提交质量评分
2. workflow-automation.ps1 - 工作流自动化
3. achievement-system-core.ps1 - 成就系统

### Phase 2: 智能分析 ✅
4. work-advisor.ps1 - 工作建议引擎
5. growth-tracker.ps1 - 成长追踪
6. time-optimizer.ps1 - 时间优化

### Phase 3: 深度洞察 ✅
7. change-impact-analyzer.ps1 - 变更影响分析
8. project-health-monitor.ps1 - 项目健康监控
9. project-retro-generator.ps1 - 项目复盘

### Phase 4: AI集成 ✅
10. smart-report-summarizer.ps1 - 智能报告摘要
11. achievement-card-generator.ps1 - 成就卡片生成
12. data-dashboard-api.ps1 - API数据生成

### 已有工具 ✅
13-25. 其他13个工具（日报/周报/月报/年报等）

### 管理工具 ✅
26. main-console.ps1 - 交互式控制台 ⭐
27. run-all-tools.ps1 - 一键运行器
28. quick-verification.ps1 - 快速验证

---

## ⚡ 日常使用推荐

### 每天使用（3分钟）

```powershell
# 启动控制台
cd d:\work\ai\lingma\.lingma\skills\tools
.\main-console.ps1

# 选择选项 2（快速运行）
# 等待完成
# 选择选项 5（打开Web展示中心）
# 浏览器查看结果
```

### 每周使用（10分钟）

```powershell
# 完整运行
cd d:\work\ai\lingma\.lingma\skills\tools
.\run-all-tools.ps1 -All

# 验证功能
.\quick-verification.ps1

# 查看报告
# 浏览器访问 http://localhost:3456/overview
```

---

## 🔧 常见问题

### Q1: 如何快速启动？
**A**: 运行 `.\main-console.ps1`，选择选项1或2

### Q2: 数据在哪里看？
**A**: 运行后选择选项5，浏览器访问 http://localhost:3456/overview

### Q3: 如何验证所有功能？
**A**: 运行 `.\quick-verification.ps1`

### Q4: Web页面无法访问？
**A**: 确保运行了 `.\run-phase4.ps1 -All` 启动服务

### Q5: 如何查看原始数据？
**A**: 直接查看 `work-archive/data/` 目录下的JSON文件

---

## 🎉 总结

现在你有：

✅ **一键调用方法**: main-console.ps1 或 run-all-tools.ps1  
✅ **统一展示入口**: http://localhost:3456/overview  
✅ **一键验收工具**: quick-verification.ps1  
✅ **完整数据文件**: 12个数据目录，25+个工具  
✅ **详细文档**: QUICK-START.md, ACCEPTANCE-GUIDE.md

**立即开始使用吧！**

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\main-console.ps1
```
