# AI 工作归档助手 - 使用说明

> 🎉 **恭喜！您的个人工作归档系统已安装完成！**

## ✅ 已安装组件

- ✅ **daily-work-archiver** - 自动工作归档和报告生成
- ✅ **work-archive/** - 工作数据存储目录
- ✅ **交接文档** - 项目交接文档（已初始化）

## 🚀 立即开始使用

### 方式 1: 直接开始工作对话（最简单）

**您只需要像平常一样和我对话，我就会自动归档！**

例如：
```
你：今天上午优化了登录模块，用 JWT 替代 Session，性能提升 30%
我：✅ 已归档今日工作对话
    - [FEATURE] [PERFORMANCE] 登录模块优化
    - 成果：性能提升 30%
    - 技术：JWT, Session
```

### 方式 2: 使用命令生成报告

#### 日报命令
```
/today-report
或
生成今天的日报
或
今天的工作总结
```

#### 周报命令
```
/week-report
或
生成本周的周报
或
这周的工作总结
```

#### 交接文档命令
```
/update-handover    # 更新交接文档
/view-handover      # 查看交接文档
```

#### 简历命令
```
/generate-resume    # 生成简历素材
或
更新我的简历
```

## 📁 文件存储位置

所有数据都存储在本地：

```
d:\work\ai\lingma\.lingma\skills\
├── daily-work-archiver/      # 技能主程序
│   └── SKILL.md
└── work-archive/              # 您的工作数据
    ├── daily-reports/         # 日报存档
    │   └── 2026-04/
    │       └── [日期].md
    ├── weekly-reports/        # 周报存档
    │   └── [年份-W 周数].md
    ├── handover/              # 交接文档
    │   └── project-handover.md  ← 随时查阅
    ├── resume-builder/        # 简历素材
    │   └── projects.md
    └── archive-db/            # 归档数据库
```

## 🤖 自动任务管理

### 定时日报任务（推荐）

系统已配置 Windows 定时任务，每周一至周五 **下午 6:00** 自动扫描 Git 提交并生成日报。

#### 启用/安装定时任务
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\setup-scheduled-task.ps1
```

#### 禁用/卸载定时任务
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\setup-scheduled-task.ps1 -Uninstall
```

#### 临时暂停定时任务
```powershell
Disable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

#### 恢复定时任务
```powershell
Enable-ScheduledTask -TaskName "Auto Daily Report Generator"
```

#### 查看任务状态
```powershell
Get-ScheduledTask -TaskName "Auto Daily Report Generator" | Get-ScheduledTaskInfo
```

#### 手动立即生成日报
```powershell
cd d:\work\ai\lingma\.lingma\skills\tools
.\git-work-tracker.ps1 -TodayOnly
```

---

## ⚙️ 配置与查看

### 如何更改 Git 爬取目录

系统默认扫描 `D:\work\code` 和 `D:\work\codepos` 下的所有 Git 仓库。如果您需要更改扫描目录，请按以下步骤操作：

1. 打开脚本文件：`tools\git-work-tracker.ps1`
2. 找到第 25-28 行左右的 `$projectDirs` 配置项：
```powershell
# Project root directories
$projectDirs = @(
    "D:\work\code",
    "D:\work\codepos"
)
```
3. 将其修改为您自己的项目根目录（支持多个目录）：
```powershell
$projectDirs = @(
    "C:\Your\Project\Path\1",
    "D:\Your\Project\Path\2"
)
```
4. 保存文件后，重新运行自动任务即可生效。

### 日报和周报查看位置

生成的报告文件均保存在本地 `work-archive` 目录下，您可以随时通过文件管理器或编辑器打开查看：

#### 📅 日报位置
```
work-archive/daily-reports/YYYY-MM/YYYY-MM-DD.md
```
- **打开方式**：在文件管理器中导航至 `work-archive\daily-reports\`，按月份进入对应文件夹即可查看当日报告。

#### 📆 周报位置
```
work-archive/weekly-reports/YYYY-WWW.md
```
- **打开方式**：在文件管理器中导航至 `work-archive\weekly-reports\`，文件名格式为 `年份-W周数.md`。

---

## 💡 使用技巧

### 1. 自动归档最佳实践

**高质量输入 = 高质量报告**

✅ **好的描述**:
```
"今天上午花了 3 个小时优化用户登录模块，使用 JWT 替代了原来的 
Session 机制，接口响应时间从 500ms 降至 50ms，性能提升约 90%"
```

❌ **不够好的描述**:
```
"做了点优化"
```

### 2. 定期生成报告

**推荐节奏**:
- 📅 **每天下班前**: `/today-report` 生成日报
- 📆 **每周五下午**: `/week-report` 生成周报  
- 📄 **每月最后一天**: 查看月度总结
- 🔄 **项目完成后**: `/update-handover` 更新交接文档
- 💼 **准备跳槽时**: `/generate-resume` 生成简历

### 3. 善用搜索

```
/search-archive JWT           # 搜索所有 JWT 相关内容
/search-archive [FEATURE]     # 搜索所有新功能开发
/search-archive 本周 优化     # 搜索本周的优化工作
```

## 🎯 典型使用场景

### 场景 1: 日常工作记录

**早上开始工作**:
```
你：早，今天计划完成登录模块的 JWT 改造
我：✅ 已记录今日计划
    - [PLANNING] [HIGH] 登录模块 JWT 改造
    - 状态：TODO
```

**工作中**:
```
你：刚完成了 JWT 工具类的实现，遇到了 token 刷新的问题，
   通过滑动过期机制解决了，性能提升很明显
我：✅ 已归档工作进展
    - [FEATURE] [DONE] JWT 工具类实现
    - [BUGFIX] [DONE] Token 刷新问题
    - 关键技术：滑动过期机制
    - 成果：性能显著提升
```

**下班前**:
```
你：/today-report
我：📊 正在生成今日日报...
   [自动生成详细日报]
   📄 已保存至：daily-reports/2026-04/2026-04-02.md
```

### 场景 2: 项目进度追踪

**项目讨论**:
```
你：Auth System 项目整体进度已经 85% 了，
   还剩双重验证功能没完成，预计下周上线
我：✅ 已更新项目进度
    - 项目：Auth System
    - 进度：70% → 85%
    - 待完成：双重验证
    - 预计：下周上线
```

**查看进度**:
```
你：Auth System 项目进展如何？
我：根据归档记录，Auth System 项目当前进度 85%
   
   已完成:
   ✅ JWT 改造 (100%)
   ✅ Token 管理 (100%)
   ✅ 短信验证码 (100%)
   
   进行中:
   🔄 双重验证 (60%)
   
   详细信息请查看：handover/project-handover.md
```

### 场景 3: 问题解决记录

**遇到问题**:
```
你：线上出现 token 频繁失效的问题，用户反馈很多
我：✅ 已记录生产问题
    - [BUG] [HIGH] [ONLINE] Token 频繁失效
    - 影响：用户体验
    - 优先级：高
```

**解决问题**:
```
你：token 失效问题定位到了，是 Redis 缓存策略问题，
   已经调整为双层缓存，问题解决了
我：✅ 已记录问题解决方案
    - 根因：Redis 缓存策略不当
    - 方案：双层缓存架构
    - 状态：✅ 已解决
    - 经验：已添加到 FAQ
```

### 场景 4: 技术学习记录

**学习新技术**:
```
你：最近在研究 JWT 的最佳实践，看了几篇不错的文章
我：✅ 已记录学习内容
    - [LEARNING] JWT 最佳实践
    - 类型：技术研究
    - 应用：Auth System 项目
```

**分享学习心得**:
```
你：JWT 的滑动过期机制设计很巧妙，既保证安全又兼顾体验
我：✅ 已记录技术洞察
    - 知识点：JWT 滑动过期
    - 理解：安全与体验的平衡
    - 应用：已用于登录模块
```

## 📊 自动化功能说明

### 自动识别的工作内容

当您提到以下内容时，我会自动归档：

1. **任务执行**
   - "开发了 XXX"、"实现了 XXX"
   - "修复了 XXX"、"优化了 XXX"
   - "完成了 XXX"、"测试了 XXX"

2. **成果展示**
   - "性能提升了 X%"
   - "效率提高了"
   - "减少了/降低了 XXX"

3. **问题记录**
   - "遇到一个问题..."
   - "发现一个 bug..."
   - "原因是..."、"解决方案是..."

4. **计划安排**
   - "明天要..."
   - "接下来计划..."
   - "准备做..."

### 自动提取的信息

- ⏰ **时间戳**: 自动记录对话时间
- 🏷️ **标签**: 自动分类（功能/修复/文档等）
- 📊 **数据**: 自动提取量化成果（性能提升 X%）
- 🔧 **技术**: 自动识别使用的技术栈
- 📁 **项目**: 自动关联相关项目

## 🔒 数据安全

### 本地存储
- ✅ 所有数据存储在本地
- ✅ 不会上传到外部服务器
- ✅ 完全由您控制

### 敏感信息处理
- ✅ 自动识别密码、密钥等敏感信息
- ✅ 支持手动标记私密内容
- ✅ 可选择性包含在报告中

### 备份建议
```powershell
# 定期备份工作数据
cd d:\work\ai\lingma\.lingma\skills
Copy-Item -Path work-archive -Destination D:\Backup\work-archive -Recurse
```

## ❓ 常见问题

### Q: 如何确保归档准确性？
**A**: 
1. 详细描述工作内容（包含具体数据和成果）
2. 及时检查生成的报告
3. 发现错误立即纠正

### Q: 可以同时在多个项目工作吗？
**A**: 可以！系统会自动识别和分类不同项目的对话。

### Q: 如何导出归档数据？
**A**: 使用命令 `/export-archive [日期范围]`

### Q: 数据会保存多久？
**A**: 默认永久保存，您可以手动清理或删除。

### Q: 如何查看历史归档？
**A**: 
```
/search-archive 上个月的项目    # 搜索上月内容
/search-archive [FEATURE]      # 搜索所有功能开发
/view-handover                 # 查看交接文档
```

## 🎯 下一步行动

### 现在开始您的第一次工作归档吧！

**选项 1: 告诉我您当前的工作**
```
"我正在负责 XXX 项目，主要做 XXX 开发"
```

**选项 2: 记录今天已完成的工作**
```
"今天上午我做了 XXX，下午做了 XXX"
```

**选项 3: 直接生成今天的日报**
```
"/today-report"
```

### 推荐的首次使用流程

1. **介绍您的工作背景**（可选）
   ```
   "我是一名 Java 开发工程师，主要负责 Auth System 项目开发"
   ```

2. **记录当前的工作内容**
   ```
   "今天主要完成了 XXX 功能的开发，遇到了 XXX 问题并解决了"
   ```

3. **生成第一份日报**
   ```
   "/today-report"
   ```

4. **查看交接文档**
   ```
   "/view-handover"
   ```

5. **养成习惯**
   - 每天工作对话 → 自动归档
   - 下班前生成日报
   - 周五生成周报
   - 随时查看交接文档

---

## 🎉 让我们开始吧！

**现在，请告诉我：**

您当前正在做什么工作？或者今天完成了什么任务？

我会立即开始自动归档，并为您生成第一份工作日报！💪

---

**技术支持**: 如有任何问题，随时询问我。这个系统会随着您的使用越来越智能！🚀
