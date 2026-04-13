# 定时自动生成日报 - 使用指南

> 🎉 **自动日报功能已启用！**

---

## ✅ 已配置完成

**定时任务名称**: `Auto Daily Report Generator`  
**运行时间**: 每周一至周五 下午 6:00  
**执行内容**: 自动扫描所有 Git 项目并生成日报

---

## 📋 工作原理

### 自动化流程

```
每天下午 6:00
    ↓
Windows 任务计划程序触发
    ↓
运行 git-work-tracker.ps1
    ↓
扫描 D:\work\code和 D:\work\codepos
    ↓
收集今日所有 Git提交（91 个项目）
    ↓
分析提交内容、代码变更、技术栈
    ↓
生成 Markdown 格式日报
    ↓
保存到 work-archive/daily-reports/
    ↓
完成！📊
```

---

## ⏰ 下次运行时间

**预计下次运行**: 2026-04-03 18:00:00（如果今天是工作日且已过 18:00，则是下一个工作日）

---

## 🔧 管理定时任务

### 查看已配置的定时任务

```powershell
# 方法 1: 查看所有任务
Get-ScheduledTask -TaskName "Auto Daily Report Generator"

# 方法 2: 查看任务详细信息
Get-ScheduledTask -TaskName "Auto Daily Report Generator" | Get-ScheduledTaskInfo
```

### 手动立即生成日报

不需要等到下午 6 点，随时可以手动生成：

```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\git-work-tracker.ps1 -TodayOnly
```

### 修改运行时间

如果想改为其他时间（例如下午 5:30）：

```powershell
# 1. 删除现有任务
.\setup-scheduled-task.ps1 -Uninstall

# 2. 编辑 setup-scheduled-task.ps1，找到这行：
#    -At 6pm
# 改为：
#    -At 5:30pm

# 3. 重新运行安装
.\setup-scheduled-task.ps1
```

### 禁用定时任务

#### 临时禁用（推荐）
```powershell
Disable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

#### 永久删除
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\setup-scheduled-task.ps1 -Uninstall
```

#### 重新启用
```powershell
Enable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

---

## 📂 生成的文件位置

### 日报存储位置
```
d:\work\ai\lingma\.lingma\skills\work-archive\daily-reports\2026-04\
├── 2026-04-02.md
├── 2026-04-03.md
└── ...
```

### Git 活动详情
```
d:\work\ai\lingma\.lingma\skills\work-archive\archive-db\git-activities\
├── 2026-04-02.md
├── 2026-04-03.md
└── ...
```

---

## 💡 使用场景

### 场景 1: 正常使用（完全自动）

**什么都不用做**，系统会：
- ✅ 每个工作日下午 6 点自动运行
- ✅ 扫描所有 91 个项目的 Git提交
- ✅ 生成详细日报
- ✅ 保存到归档目录

您只需要：
- 正常工作，记得 Git提交
- 需要时查看生成的日报

### 场景 2: 提前查看今日报告

下班前想看看今天的报告：

```powershell
.\git-work-tracker.ps1 -TodayOnly
```

会显示今日统计并保存报告。

### 场景 3: 补生成之前的报告

如果某天忘记运行，可以补生成：

```powershell
# 生成昨天的报告
.\git-work-tracker.ps1 -SinceDate "2026-04-01" -UntilDate "2026-04-01"
```

---

## 🎯 自定义配置

### 选项 A: 改为每天中午 12 点生成

```powershell
# 删除当前任务
.\setup-scheduled-task.ps1 -Uninstall

# 修改脚本中的时间，然后重新安装
.\setup-scheduled-task.ps1
```

### 选项 B: 只在工作日生成（已配置）✅

当前配置就是周一到周五，跳过周末。

### 选项 C: 每小时生成一次（不推荐）

```powershell
# 需要手动创建不同的触发器
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
```

---

## 📊 日报示例

自动生成的日报包含：

```markdown
# 工作日报 - 2026-04-03

## 📊 今日概览
- Git提交：8 次
- 活跃项目：3 个
- 代码变更：+528, -234

## ✅ 完成的工作

### alliance-admin-web (4 次提交)
✨ feat: 重构权限管理模块，添加 RBAC 角色控制
   代码量：+328, -156
   
🐛 fix: 修复用户列表页面内存泄漏问题  
   代码量：+45, -28

### b2b-lottrey-web (3 次提交)
...

## 📈 工作统计
- 新功能：2 个
- Bug 修复：1 个
- 文档更新：1 次

## 💡 明日计划
[自动生成建议]
```

---

## ❓ 常见问题

### Q: 如果电脑关机了怎么办？
**A**: 
- 任务计划程序会在下次开机时自动运行（如果设置了 `-StartWhenAvailable`）
- 或者手动运行一次即可

### Q: 会影响性能吗？
**A**: 
- 完全不会！脚本运行只需 5-10 秒
- 后台静默运行，无窗口弹出
- CPU 占用极低

### Q: 可以生成周报吗？
**A**: 
- 目前只有日报
- 告诉我，我可以添加周报定时任务（每周五下午生成）

### Q: 如何查看历史日报？
**A**: 
```powershell
# 打开日报目录
explorer "d:\work\ai\lingma\.lingma\skills\work-archive\daily-reports"
```

### Q: 能否发送到邮箱？
**A**: 
- 可以添加邮件发送功能
- 需要配置 SMTP 服务器
- 告诉我，我帮您实现

---

## 🔍 故障排查

### 问题 1: 任务没有运行

**检查方法**:
```powershell
Get-ScheduledTask -TaskName "Auto Daily Report Generator" | Select-Object State, LastRunTime, NextRunTime
```

**解决方法**:
```powershell
# 手动运行一次测试
.\git-work-tracker.ps1 -TodayOnly

# 重新安装任务
.\setup-scheduled-task.ps1 -Uninstall
.\setup-scheduled-task.ps1
```

### 问题 2: 找不到 Git提交

**原因**: 可能项目还没有 Git提交

**解决**: 
- 确保工作时进行 Git提交
- 提交格式：`feat: description` 或 `fix: description`

### 问题 3: 权限错误

**症状**: "Access denied" 或 "拒绝访问"

**解决**:
```powershell
# 以管理员身份运行 PowerShell
# 右键点击 PowerShell -> 以管理员身份运行
.\setup-scheduled-task.ps1
```

---

## 📝 更新日志

### v1.0.0 - 2026-04-03
- ✅ 初始版本发布
- ✅ 定时任务配置完成
- ✅ 支持 91 个项目自动扫描
- ✅ 自动生成日报

---

## 🎉 总结

**现在您拥有了一个完全自动化的日报系统！**

### 您需要做的：
1. ✅ 正常工作，记得 Git提交
2. ✅ 其他的全部交给系统

### 系统会自动：
1. ✅ 每个工作日下午 6 点扫描
2. ✅ 收集所有 91 个项目的提交
3. ✅ 生成详细的日报
4. ✅ 保存到归档目录

### 完全无需担心！🚀

---

**技术支持**: 如有任何问题，随时询问我。
