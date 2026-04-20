# 仪表板加载失败解决方案

## 问题描述

打开 `http://localhost:3456/dashboard` 时显示：
```
加载失败: Unexpected token '<'
请确保已运行 generate-dashboard-data.ps1 生成数据
```

---

## 根本原因

**路径错误**：`dashboard.html` 尝试从 `/dashboard-data.json` 加载数据，但服务器配置的静态文件路径是 `/static/`。

**已修复**：将请求路径改为 `/static/dashboard-data.json`

---

## 解决步骤

### 步骤1：生成仪表板数据

```powershell
# 1. 进入 tools 目录
cd d:\work\ai\lingma\.lingma\skills\tools

# 2. 设置编码（避免中文乱码）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 3. 生成数据
.\generate-dashboard-data.ps1

# 等待扫描完成（可能需要1-3分钟）
```

**成功标志**：
```
✅ 仪表板数据已生成
   输出: docs-server/public/dashboard-data.json
```

---

### 步骤2：启动服务器

```powershell
# 在 tools 目录下
.\run-phase4.ps1 -All
```

或者手动启动：
```powershell
cd d:\work\ai\lingma\.lingma\skills\docs-server
node server.js
```

**成功标志**：
```
📚 Work Archive Docs Server running at http://localhost:3456
📁 Serving documents from:
   - 工作归档: ...
```

---

### 步骤3：访问仪表板

打开浏览器访问：`http://localhost:3456/dashboard`

**如果仍然报错**：
1. 按 `F12` 打开开发者工具
2. 切换到 **Console** 标签
3. 查看具体错误信息
4. 检查 Network 标签，确认 `/static/dashboard-data.json` 返回 200

---

## 常见问题

### Q1: generate-dashboard-data.ps1 运行很慢？
**A**: 正常！脚本需要扫描所有Git仓库历史，第一次运行可能需要1-3分钟。

**优化**：后续运行会更快，因为有缓存。

### Q2: 服务器无法启动？
**A**: 检查端口3456是否被占用：
```powershell
netstat -ano | findstr :3456
```
如果被占用，杀掉进程或改用其他端口。

### Q3: 数据生成后仍然加载失败？
**A**: 
1. 确认文件存在：`Test-Path ..\docs-server\public\dashboard-data.json`
2. 清除浏览器缓存（Ctrl+Shift+Delete）
3. 硬刷新页面（Ctrl+F5）

### Q4: 如何查看生成的数据？
**A**: 
```powershell
# 查看文件大小
Get-Item ..\docs-server\public\dashboard-data.json | Select-Object Name, Length

# 查看部分内容
Get-Content ..\docs-server\public\dashboard-data.json | Select-Object -First 10
```

---

## 验证清单

- [ ] 已运行 `generate-dashboard-data.ps1`
- [ ] 文件存在：`docs-server/public/dashboard-data.json`
- [ ] 服务器正在运行：`http://localhost:3456`
- [ ] 浏览器访问：`http://localhost:3456/dashboard`
- [ ] 开发者工具无错误

---

## 修复记录

### 2026-04-14
- ✅ 修复 `dashboard.html` 中的数据请求路径
- ✅ 从 `/dashboard-data.json` 改为 `/static/dashboard-data.json`
- ✅ 改进错误提示，显示详细的解决步骤
- ✅ 添加一键刷新按钮

---

*问题解决后，仪表板将正常显示您的工作数据！*
