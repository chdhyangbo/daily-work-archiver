# 两步工作流：先汇总，后展示

## 新的数据架构

```
Git仓库 → 汇总脚本 → git-activities/ → 仪表板生成器 → dashboard-data.json → Web界面
```

### 优势

1. **数据复用**：汇总一次，多次使用
2. **性能提升**：仪表板生成不需要重复扫描Git
3. **数据一致性**：所有工具使用同一份数据源
4. **易于扩展**：其他工具也可以读取汇总数据

---

## 使用步骤

### 第一步：汇总Git活动数据

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 运行汇总脚本
.\git-activity-aggregator.ps1
```

**默认参数**：
- 扫描目录：`D:\work\code`, `D:\work\codepos`
- 作者：`yangbo`
- 时间范围：最近365天

**自定义参数**：
```powershell
.\git-activity-aggregator.ps1 `
  -ProjectPaths @("C:\your\path1", "D:\your\path2") `
  -Author "yourname" `
  -DaysBack 180
```

**输出**：
```
work-archive/data/git-activities/
├── 2026-04-15.json    # 该日期的所有提交
├── 2026-04-14.json
├── ...
└── activity-index.json  # 索引文件
```

---

### 第二步：生成仪表板数据

```powershell
# 运行仪表板数据生成器
.\generate-dashboard-data.ps1
```

**功能**：
- 从 `git-activities/` 读取所有活动文件
- 统计、排序、汇总
- 生成 `dashboard-data.json`

**输出**：
```
docs-server/public/dashboard-data.json
```

---

### 第三步：启动仪表板

```powershell
# 启动Web服务
.\run-phase4.ps1 -All

# 访问
http://localhost:3456/dashboard
```

---

## 完整工作流

### 日常更新（推荐频率：每周一次）

```powershell
# 1. 汇总最新的Git活动
.\git-activity-aggregator.ps1

# 2. 生成仪表板数据
.\generate-dashboard-data.ps1

# 3. 刷新浏览器查看
# http://localhost:3456/dashboard
```

### 首次使用

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 第一步：汇总（可能需要1-3分钟）
.\git-activity-aggregator.ps1

# 第二步：生成仪表板（几秒钟）
.\generate-dashboard-data.ps1

# 第三步：启动服务
.\run-phase4.ps1 -All
```

---

## 数据文件说明

### activity-index.json
索引文件，包含总体统计：

```json
{
  "totalCommits": 500,
  "dateRange": {
    "from": "2026-01-01",
    "to": "2026-04-15"
  },
  "projects": {
    "project-a": 300,
    "project-b": 200
  },
  "types": {
    "FEATURE": 150,
    "FIX": 200,
    ...
  },
  "totalInsertions": 50000,
  "totalDeletions": 20000
}
```

### YYYY-MM-DD.json
每日活动文件：

```json
{
  "date": "2026-04-15",
  "totalCommits": 10,
  "projects": "project-a, project-b",
  "types": {
    "FEATURE": 5,
    "FIX": 3,
    ...
  },
  "commits": [
    {
      "hash": "abc1234",
      "shortHash": "abc1234",
      "dateTime": "2026-04-15 10:30:00",
      "date": "2026-04-15",
      "time": "10:30:00",
      "hour": 10,
      "author": "yangbo",
      "project": "project-a",
      "projectPath": "D:\\work\\code\\project-a",
      "subject": "feat: 添加新功能",
      "message": "feat: 添加新功能\n详细描述...",
      "type": "FEATURE",
      "insertions": 100,
      "deletions": 50,
      "changed": 150
    }
  ]
}
```

---

## 常见问题

### Q1: 什么时候需要重新汇总？
**A**: 
- 每周定期更新
- 提交了大量新代码后
- 添加了新的Git仓库后

### Q2: 汇总脚本运行很慢？
**A**: 正常！首次扫描所有Git历史需要时间。后续只扫描新增部分会快很多。

### Q3: 可以只汇总特定项目吗？
**A**: 可以，使用 `-ProjectPaths` 参数：
```powershell
.\git-activity-aggregator.ps1 -ProjectPaths @("D:\work\code\specific-project")
```

### Q4: 数据文件会很大吗？
**A**: 
- 每个日期文件约10-100KB
- 一年约5-10MB
- 可定期清理旧数据

### Q5: 仪表板数据不更新？
**A**: 需要重新运行两个脚本：
```powershell
.\git-activity-aggregator.ps1
.\generate-dashboard-data.ps1
```

---

## 高级用法

### 定时自动汇总（每周）

创建Windows计划任务：
```powershell
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File D:\work\ai\lingma\.lingma\skills\tools\git-activity-aggregator.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 10am
Register-ScheduledTask -TaskName "Git Activity Aggregator" -Action $action -Trigger $trigger
```

### 查看汇总统计

```powershell
# 查看索引
Get-Content work-archive\data\git-activities\activity-index.json | ConvertFrom-Json | ConvertTo-Json -Depth 3

# 查看某天的提交
Get-Content work-archive\data\git-activities\2026-04-15.json | ConvertFrom-Json
```

### 清理旧数据

```powershell
# 删除30天前的数据
$cutoffDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
Get-ChildItem work-archive\data\git-activities\*.json | 
  Where-Object { $_.BaseName -lt $cutoffDate } | 
  Remove-Item
```

---

## 架构对比

### 旧架构
```
仪表板生成器 → 扫描所有Git仓库 → 生成数据
              (每次都要扫描，慢)
```

### 新架构
```
汇总脚本 → 扫描Git仓库 → 保存为JSON
仪表板生成器 → 读取JSON → 生成数据 (快！)
```

**性能提升**：
- 旧方案：每次1-3分钟
- 新方案：首次1-3分钟，后续几秒钟

---

*新架构让数据管理更高效、更可扩展！*
