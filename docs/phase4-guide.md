# 第四阶段：可视化与游戏化 - 完整使用指南

## 快速开始

### 一键启动（推荐）

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools

# 启动所有功能
.\run-phase4.ps1 -All

# 只启动仪表板
.\run-phase4.ps1 -Dashboard

# 只检查成就
.\run-phase4.ps1 -Achievements

# 查看状态
.\run-phase4.ps1 -Action status
```

---

## 功能1：成就徽章系统

### 功能说明
- 追踪你的Git提交成就
- 积分等级系统
- 游戏化激励机制

### 使用方法

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools

# 检查成就（扫描Git历史）
.\achievement-system.ps1 -Action check

# 列出所有成就
.\achievement-system.ps1 -Action list
```

### 成就列表（8个）

| 图标 | 成就名称 | 条件 | 积分 |
|------|---------|------|------|
| SEED | Initial Commit | 第一次提交 | +10 |
| SEEDLING | Getting Started | 10次提交 | +20 |
| TREE | Code Craftsman | 100次提交 | +50 |
| TROPHY | Code Master | 1000次提交 | +200 |
| FIRE | 3-Day Streak | 连续3天提交 | +15 |
| LIGHTNING | Week Warrior | 连续7天提交 | +30 |
| TARGET | Multi-tasker | 3个项目贡献 | +30 |

### 等级系统

| 等级 | 所需积分 |
|------|---------|
| Code Rookie | 0+ |
| Junior Dev | 100+ |
| Mid Dev | 300+ |
| Senior Dev | 600+ |
| Expert | 1000+ |
| Legend | 2000+ |

---

## 功能2：个人仪表板

### 功能说明
- 可视化展示Git提交统计
- GitHub风格贡献热力图
- 时段和项目分布图表
- 成就和等级显示

### 使用方法

```powershell
# 方式1：使用快速启动脚本
.\run-phase4.ps1 -Dashboard

# 方式2：手动启动
# 1. 生成数据
.\generate-dashboard-data.ps1

# 2. 启动服务器
cd ..\docs-server
node server.js
```

### 访问地址
```
http://localhost:3456/dashboard
```

### 仪表板包含
1. **统计卡片**
   - 总提交数
   - 今日提交
   - 连续天数
   - 本周提交

2. **等级信息**
   - 当前等级
   - 积分进度条
   - 成就解锁数

3. **贡献热力图**
   - 最近90天提交分布
   - 类似GitHub贡献图

4. **图表分析**
   - 24小时时段分布
   - 项目提交分布

5. **最近提交列表**
   - 最近20次提交
   - 提交信息、项目、日期

---

## 故障排除

### 问题1：PowerShell解析错误
**症状**: 脚本报"ParserError"或"UnexpectedToken"
**原因**: 文件编码问题
**解决**: 文件已修复，使用ASCII兼容的图标代码

### 问题2：仪表板数据不更新
**解决**:
```powershell
# 重新生成数据
.\generate-dashboard-data.ps1

# 刷新浏览器页面
```

### 问题3：成就检查很慢
**原因**: 需要扫描所有Git仓库历史
**建议**: 首次运行需要1-3分钟，后续会更快

### 问题4：端口3456被占用
**解决**:
```powershell
# 停止旧服务器
.\run-phase4.ps1 -Action stop

# 重新启动
.\run-phase4.ps1 -Dashboard
```

---

## 文件说明

### 工具脚本
```
.lingma/skills/tools/
├── achievement-system.ps1          # 成就系统
├── generate-dashboard-data.ps1     # 仪表板数据生成
└── run-phase4.ps1                  # 快速启动脚本
```

### Web文件
```
.lingma/skills/docs-server/
├── server.js                       # 服务器（已更新）
└── public/
    └── dashboard.html              # 仪表板页面
```

### 数据文件
```
.lingma/skills/work-archive/data/
├── achievements/
│   └── achievements.json          # 成就数据
└── docs-server/public/
    └── dashboard-data.json         # 仪表板数据
```

---

## 高级用法

### 自定义成就
编辑 `achievement-system.ps1` 文件，在 `$Achievements` 哈希表中添加新成就：

```powershell
NEW_ACHIEVEMENT = @{
    id = "NEW_ACHIEVEMENT"
    name = "My Achievement"
    description = "Description here"
    icon = "ICON_NAME"
    category = "category_name"
    condition = { param($s) $s.totalCommits -ge 100 }
    points = 50
}
```

### 定时更新数据
使用Windows任务计划程序每天自动更新：

```powershell
# 创建计划任务（每天上午9点）
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File d:\work\ai\lingma\.lingma\skills\tools\generate-dashboard-data.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName "UpdateDashboard" -Action $action -Trigger $trigger
```

---

## 下一步

### 第五阶段计划
- 团队排行榜
- 成就分享功能（生成图片）
- 自定义成就创建界面
- 里程碑庆祝动画
- PDF报告导出

### 反馈和建议
如果有任何问题或建议，请告诉我！

---

*第四阶段由 AI Work Archiver 自动开发*
