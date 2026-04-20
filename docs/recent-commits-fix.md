# 最近提交排序问题修复

## 问题描述

仪表板的"最近提交"显示顺序不正确：
- 3月6日的提交排在前面
- 4月的提交排在后面
- 应该按时间倒序显示（最新的在前）

---

## 根本原因

**原问题**：
1. Git命令没有排除merge提交，导致混乱
2. 多个项目的提交分别加入列表，没有做全局排序
3. 只取前20条，但顺序是按项目而非按时间

---

## 已修复内容

### 修复1：添加 `--no-merges` 参数
```powershell
# 修改前
git log --since="$since" --author="yangbo" ... -n 500

# 修改后
git log --since="$since" --author="yangbo" ... --no-merges -n 500
```

### 修复2：收集所有提交后统一排序
```powershell
# 修改前：每个项目内部取前20条
if ($stats.recentCommits.Count -lt 20) {
    $stats.recentCommits += @{ ... }
}

# 修改后：收集所有提交，全局排序后取前20
$allCommits += @{ ... }
$sorted = $allCommits | Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending
$stats.recentCommits += $sorted | Select-Object -First 20
```

### 修复3：最终全局排序
```powershell
# 对所有项目的提交做最终排序
if ($stats.recentCommits.Count -gt 20) {
    $stats.recentCommits = $stats.recentCommits | 
        Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending | 
        Select-Object -First 20
}
```

---

## 验证步骤

### 1. 重新生成数据

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
.\generate-dashboard-data.ps1
```

### 2. 检查数据顺序

```powershell
$data = Get-Content ..\docs-server\public\dashboard-data.json -Raw | ConvertFrom-Json
$data.recentCommits | Select-Object -First 10 date, message, project
```

**期望输出**（按时间倒序）：
```
2026-04-03 - BK-24837: 修复oaUrl
2026-04-03 - BK-24837: 修复oaUrl  
2026-04-02 - BK-24837: 增加审批通过逻辑
2026-04-01 - BK-24837: 修复问题
2026-03-26 - BK-24837: 修复问题
2026-03-25 - BK-24837: 选择优化2.4
...
```

### 3. 刷新仪表板

访问 `http://localhost:3456/dashboard`

**期望结果**：
- 最近提交按时间倒序显示
- 4月的提交在最前面
- 3月的提交在后面

---

## 技术细节

### 排序逻辑

```powershell
# 1. 收集所有提交（包含dateTime字段用于排序）
$allCommits += @{
    hash = $hash.Substring(0, 7)
    date = $date
    dateTime = $dateTime        # 完整日期时间，用于精确排序
    message = $message
    project = $projectName
}

# 2. 按dateTime倒序排序
$sorted = $allCommits | Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending

# 3. 取最新的20条
$stats.recentCommits += $sorted | Select-Object -First 20

# 4. 最终排序（多项目合并后）
$stats.recentCommits = $stats.recentCommits | 
    Sort-Object { [DateTime]::Parse($_.dateTime) } -Descending | 
    Select-Object -First 20

# 5. 移除dateTime字段（输出时不需要）
$stats.recentCommits = $stats.recentCommits | ForEach-Object {
    @{
        hash = $_.hash
        date = $_.date
        message = $_.message
        project = $_.project
    }
}
```

---

## 修复记录

### 2026-04-14
- ✅ 添加 `--no-merges` 参数排除merge提交
- ✅ 改进排序逻辑：收集所有提交后统一排序
- ✅ 添加最终全局排序
- ✅ 移除多余的dateTime字段
- ✅ 确保多项目提交正确混合排序

---

## 注意事项

1. **数据更新频率**：每次运行 `generate-dashboard-data.ps1` 会重新扫描所有Git历史
2. **运行时间**：首次运行可能需要1-3分钟
3. **排序依据**：使用完整的dateTime（包括时分秒），确保精确排序
4. **项目数量**：支持多项目混合，统一按时间排序

---

*修复后，仪表板的"最近提交"将正确按时间倒序显示！*
