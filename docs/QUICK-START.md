# AI Work Archiver - 快速启动指南

> 3步开始使用，一键运行所有功能！

---

## 🚀 方式1：交互式控制台（推荐）

这是最简单的方式，提供可视化菜单和完整控制。

### 启动控制台

```powershell
1

```

### 控制台功能

**一键运行**
- 选项1: 运行所有工具（完整流程）
- 选项2: 快速运行（跳过Git扫描）
- 选项3: 运行指定阶段

**数据查看**
- 选项4: 查看数据总览
- 选项5-7: 查看各类报告
- 选项8: 打开统一展示中心（Web）

**工具管理**
- 选项9: 验证所有功能
- 选项10: 备份数据

---

## 🎯 方式2：一键运行脚本

适合快速执行，无需交互。

### 运行所有工具

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 完整运行（包含Git扫描）
.\run-all-tools.ps1 -All

# 快速运行（跳过Git扫描）
.\run-all-tools.ps1 -Phase1 -Phase2 -Phase3 -Phase4 -Reports -Dashboard
```

### 运行指定阶段

```powershell
# 只运行Phase 1
.\run-all-tools.ps1 -Phase1

# 只运行Phase 4
.\run-all-tools.ps1 -Phase4

# 只生成报告
.\run-all-tools.ps1 -Reports
```

---

## 📊 方式3：统一展示中心

所有数据的Web可视化入口。

### 启动服务

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 运行所有工具
.\run-all-tools.ps1 -All

# 启动Web服务
.\run-phase4.ps1 -All
```

### 访问地址

- **统一展示中心**: http://localhost:3456/overview ⭐ 推荐
- **主仪表板**: http://localhost:3456/dashboard
- **文档中心**: http://localhost:3456/

### 展示中心功能

✅ 核心指标卡片
- 提交统计
- 质量评分
- 成就系统

✅ 质量分析
- 等级分布
- 项目质量排行
- 质量趋势

✅ 成长追踪
- 里程碑列表
- 月度趋势
- 项目统计

✅ 项目健康
- 健康状态分布
- 项目健康分数
- 预警信息

✅ 快速链接
- 直接访问各类报告
- 跳转到其他功能页面

---

## 🔄 完整工作流程

### 日常使用（推荐）

```powershell
# 步骤1: 进入工具目录
cd d:\work\ai\lingma\.lingma\skills\tools

# 步骤2: 设置编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 步骤3: 启动交互式控制台
.\main-console.ps1

# 步骤4: 选择 "1. 运行所有工具"

# 步骤5: 等待完成后，选择 "8. 打开统一展示中心"

# 步骤6: 浏览器访问 http://localhost:3456/overview
```

### 快速验收

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\quick-verification.ps1
```

这会测试所有功能并生成验收报告。

---

## 📁 数据输出位置

所有生成的数据都保存在：

```
work-archive/data/
├── git-activities/           # Git活动数据库
├── commit-quality/           # 提交质量评分
├── work-advice/              # 工作建议
├── growth/                   # 成长追踪
├── time-optimization/        # 时间优化
├── change-impact/            # 变更影响分析
├── project-health/           # 项目健康监控
├── retrospectives/           # 项目复盘
├── smart-reports/            # 智能报告（Markdown）
├── achievement-cards/        # 成就卡片（HTML）
└── api/                      # API数据（JSON）
```

---

## ⚡ 常用命令速查

| 功能 | 命令 |
|------|------|
| **启动控制台** | `.\main-console.ps1` |
| **运行所有工具** | `.\run-all-tools.ps1 -All` |
| **快速运行** | `.\run-all-tools.ps1 -Phase1 -Phase2 -Phase3 -Phase4` |
| **验证功能** | `.\quick-verification.ps1` |
| **生成周报** | `.\smart-report-summarizer.ps1 -ReportType weekly` |
| **生成成就卡片** | `.\achievement-card-generator.ps1` |
| **更新仪表板** | `.\generate-dashboard-data.ps1` |
| **备份数据** | `.\data-backup-restore.ps1 -Action backup -Compress` |
| **启动Web服务** | `.\run-phase4.ps1 -All` |

---

## 🎨 统一展示中心截图说明

访问 http://localhost:3456/overview 后，你会看到：

### 1. 页面顶部
- 紫色渐变标题栏："AI Work Archiver - 统一展示中心"
- 数据状态栏：显示最后更新时间
- 刷新按钮：点击刷新所有数据

### 2. 核心指标区
三个卡片并排显示：
- 📝 **提交统计**: 总提交数、今日提交、本周提交、连续天数
- ⭐ **质量评分**: 平均分、进度条、等级分布
- 🏆 **成就系统**: 已解锁数、总积分、当前等级

### 3. 质量分析区
- 📊 质量总览卡片
- 🏅 等级分布卡片（S/A/B/C/D各级数量）
- 📈 Top 5 项目质量排行

### 4. 成长追踪区
- 📊 成长总览卡片（项目数、提交数、里程碑数）
- 🎯 里程碑列表（带日期）

### 5. 项目健康区
- 💚 健康总览卡片（健康/一般/风险项目数）
- 📋 项目状态列表（带健康分数和状态指示器）

### 6. 智能报告区
- 📝 报告链接卡片（直接点击打开JSON数据）
- 🎖️ 快速链接卡片（跳转到其他页面）

---

## ⚠️ 常见问题

### Q1: 控制台闪退？
**A**: 确保在 `tools` 目录执行，并且设置了UTF-8编码。

### Q2: Web页面无法访问？
**A**: 
1. 确保运行了 `.\run-phase4.ps1 -All` 启动服务
2. 检查端口3456是否被占用
3. 查看控制台是否有报错

### Q3: 数据未显示？
**A**: 
1. 先运行 `.\run-all-tools.ps1 -All` 生成数据
2. 点击页面上的"刷新数据"按钮
3. 检查 `work-archive/data/` 目录是否有对应文件

### Q4: 如何单独运行某个功能？
**A**: 可以直接运行对应的ps1脚本，例如：
```powershell
.\commit-quality-scorer.ps1
.\work-advisor.ps1
.\growth-tracker.ps1
```

---

## 🎯 下一步

1. **立即体验**: 运行 `.\main-console.ps1` 开始使用
2. **查看详情**: 访问 http://localhost:3456/overview 查看所有数据
3. **验收功能**: 运行 `.\quick-verification.ps1` 验证所有功能

---

**开始使用吧！** 🚀
