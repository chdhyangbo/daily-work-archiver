# Commit Message Enhancer
# 提交信息增强建议器

param(
    [string]$ProjectPath = ".",
    [string]$Message = "",
    [string[]]$Files = @(),
    [switch]$Interactive,  # 交互模式
    [switch]$CheckLast     # 检查最后一次提交
)

# 提交信息模板
$Templates = @{
    FEATURE = @{
        template = "feat(scope): 添加/实现 [功能描述]

- 详细说明1
- 详细说明2

Closes #Issue号"
        examples = @(
            "feat(auth): 实现JWT用户认证

- 添加Token生成和验证逻辑
- 实现刷新令牌机制
- 集成Redis缓存

Closes #123",
            "feat(order): 添加订单导出功能

- 支持Excel和CSV格式导出
- 添加导出进度显示
- 实现异步导出任务"
        )
    }
    FIX = @{
        template = "fix(scope): 修复 [问题描述]

- 问题原因: [根因分析]
- 解决方案: [修复方法]
- 影响范围: [影响说明]

Fixes #Bug号"
        examples = @(
            "fix(payment): 修复支付金额计算错误

- 问题原因: 浮点数精度丢失
- 解决方案: 使用整数分代替元
- 影响范围: 所有支付相关接口

Fixes #456",
            "fix(ui): 修复移动端页面错位

- 问题原因: 缺少viewport设置
- 解决方案: 添加meta viewport标签
- 影响范围: 所有移动端页面"
        )
    }
    REFACTOR = @{
        template = "refactor(scope): 重构 [重构内容]

- 重构前: [原代码问题]
- 重构后: [改进方案]
- 收益: [性能/可维护性提升]"
        examples = @(
            "refactor(api): 重构用户服务层

- 重构前: 业务逻辑分散在Controller
- 重构后: 提取Service层，统一错误处理
- 收益: 代码复用率提升40%，单测覆盖率+25%",
            "refactor(db): 优化订单查询SQL

- 重构前: 全表扫描，查询慢
- 重构后: 添加复合索引，分页优化
- 收益: 查询速度提升10倍"
        )
    }
    DOCS = @{
        template = "docs(scope): 更新 [文档内容]

- 更新内容1
- 更新内容2"
        examples = @(
            "docs(api): 更新API接口文档

- 添加新的认证接口说明
- 更新错误码列表
- 补充请求示例",
            "docs(readme): 完善项目README

- 添加快速开始指南
- 补充环境配置说明
- 添加贡献者规范"
        )
    }
    TEST = @{
        template = "test(scope): 添加/更新 [测试内容]

- 测试场景1
- 测试场景2
- 覆盖率变化: [提升百分比]"
        examples = @(
            "test(auth): 添加认证模块单元测试

- 测试Token生成逻辑
- 测试Token验证边界条件
- 测试刷新机制
- 覆盖率: 65% -> 92%",
            "test(e2e): 添加订单流程端到端测试

- 测试创建订单流程
- 测试支付回调流程
- 测试订单状态流转"
        )
    }
}

# 分析提交信息质量
function Analyze-MessageQuality($message, $files) {
    $issues = @()
    $suggestions = @()
    $score = 100
    
    # 1. 长度检查
    if ($message.Length -lt 10) {
        $issues += "提交信息过短（少于10个字符）"
        $suggestions += "添加更详细的描述，至少说明做了什么"
        $score -= 20
    } elseif ($message.Length -gt 72) {
        $issues += "标题过长（超过72个字符）"
        $suggestions += "标题保持在72字符以内，详细说明放在正文"
        $score -= 10
    }
    
    # 2. 检查是否包含类型前缀
    $hasType = $message -match "^(feat|fix|refactor|docs|test|style|chore|perf)(\(.+\))?:"
    if (-not $hasType) {
        $issues += "缺少类型前缀"
        $suggestions += "使用类型前缀，如 'feat:', 'fix:', 'refactor:' 等"
        $score -= 15
    }
    
    # 3. 检查是否使用动词开头
    $verbs = @("add", "update", "remove", "fix", "refactor", "implement", "optimize", "create", "delete", "改进", "修复", "添加", "删除", "更新")
    $hasVerb = $false
    $messageLower = $message.ToLower()
    foreach ($verb in $verbs) {
        if ($messageLower -match "^$verb\b" -or $messageLower -match ":\s*$verb\b") {
            $hasVerb = $true
            break
        }
    }
    if (-not $hasVerb) {
        $issues += "缺少动词开头"
        $suggestions += "使用动词开头，如 '添加', '修复', '更新', '重构' 等"
        $score -= 10
    }
    
    # 4. 检查是否包含具体信息
    $vagueWords = @("修改", "更新", "调整", "优化", "改", "update", "modify", "change")
    $isVague = $false
    foreach ($word in $vagueWords) {
        if ($messageLower -eq $word -or $messageLower -match "^$word\s*$" -or $messageLower -match ":\s*$word\s*$") {
            $isVague = $true
            break
        }
    }
    if ($isVague) {
        $issues += "描述过于模糊"
        $suggestions += "避免使用'修改'、'更新'等模糊词汇，具体说明修改了什么"
        $score -= 15
    }
    
    # 5. 检查文件关联
    if ($files.Count -gt 0) {
        # 检查是否混合了不同类型的修改
        $hasCode = $files | Where-Object { $_ -match "\.(js|ts|java|py|go|cpp|c|h)$" }
        $hasTest = $files | Where-Object { $_ -match "(test|spec)\.(js|ts|java|py)$" }
        $hasDoc = $files | Where-Object { $_ -match "\.(md|txt|rst)$" }
        $hasConfig = $files | Where-Object { $_ -match "(package\.json|\.yml|\.yaml|\.config\.)$" }
        
        $types = 0
        if ($hasCode) { $types++ }
        if ($hasTest) { $types++ }
        if ($hasDoc) { $types++ }
        if ($hasConfig) { $types++ }
        
        if ($types -gt 2) {
            $issues += "混合了多种类型的修改（代码、测试、文档、配置）"
            $suggestions += "建议将不同类型的修改分开提交"
            $score -= 10
        }
        
        # 检查文件数量
        if ($files.Count -gt 15) {
            $issues += "修改文件过多（$($files.Count)个）"
            $suggestions += "考虑将大提交拆分为多个逻辑独立的小提交"
            $score -= 5
        }
    }
    
    # 6. 检查是否包含Issue号
    if (-not ($message -match "#\d+" -or $message -match "(closes|fixes|resolves)\s+#?\d+")) {
        $suggestions += "如有相关Issue，请在提交信息中引用，如 'Closes #123'"
    }
    
    return @{
        score = [Math]::Max(0, $score)
        issues = $issues
        suggestions = $suggestions
        grade = if ($score -ge 90) { "A" } elseif ($score -ge 80) { "B" } elseif ($score -ge 60) { "C" } else { "D" }
    }
}

# 猜测提交类型
function Guess-CommitType($message, $files) {
    $messageLower = $message.ToLower()
    
    # 根据关键词判断
    if ($messageLower -match "fix|修复|解决|bug") { return "FIX" }
    if ($messageLower -match "feat|feature|功能|新增|添加") { return "FEATURE" }
    if ($messageLower -match "refactor|重构|优化.*代码|改进.*结构") { return "REFACTOR" }
    if ($messageLower -match "doc|文档|注释|readme") { return "DOCS" }
    if ($messageLower -match "test|测试|spec|用例") { return "TEST" }
    if ($messageLower -match "style|格式|样式|缩进|空格") { return "STYLE" }
    if ($messageLower -match "perf|性能|优化.*速度|缓存") { return "PERF" }
    
    # 根据文件判断
    if ($files) {
        $testFiles = $files | Where-Object { $_ -match "(test|spec)" }
        $docFiles = $files | Where-Object { $_ -match "\.(md|txt|rst)$" }
        
        if ($testFiles.Count -eq $files.Count) { return "TEST" }
        if ($docFiles.Count -eq $files.Count) { return "DOCS" }
    }
    
    return "OTHER"
}

# 生成改进建议
function Get-ImprovementSuggestion($message, $type, $files) {
    $suggestions = @()
    
    # 根据类型提供模板
    if ($Templates.ContainsKey($type)) {
        $template = $Templates[$type]
        
        # 提取scope
        $scope = ""
        if ($files.Count -gt 0) {
            # 从文件路径推断scope
            $firstFile = $files[0]
            $parts = $firstFile -split "[/\\]"
            if ($parts.Count -gt 1) {
                $scope = $parts[0]
            }
        }
        
        # 生成建议
        $example = $template.examples[0]
        $suggestions += "## 建议格式`n`n$example"
        
        # 生成具体建议
        $suggestions += "`n`n## 改进建议`n"
        
        # 尝试改进当前信息
        $improved = $message
        
        # 添加类型前缀
        if (-not ($improved -match "^(feat|fix|refactor|docs|test|style|chore|perf)(\(.+\))?:")) {
            $typePrefix = $type.ToLower()
            if ($scope) {
                $improved = "$typePrefix($scope): $improved"
            } else {
                $improved = "$typePrefix: $improved"
            }
        }
        
        $suggestions += "`n**改进后的提交信息:**`n"`
$improved

- [补充详细说明]
- [补充影响范围]
"`"
    }
    
    return $suggestions -join "`n"
}

# 交互模式
function Run-InteractiveMode($projectPath) {
    Write-Host "`n🤖 提交信息增强助手" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # 获取待提交的文件
    Set-Location $projectPath
    $status = git status --porcelain 2>$null
    
    if (-not $status) {
        Write-Host "`n✅ 没有待提交的更改" -ForegroundColor Green
        return
    }
    
    $stagedFiles = $status | Where-Object { $_ -match "^[AMRD]" } | ForEach-Object { $_.Substring(3) }
    $unstagedFiles = $status | Where-Object { $_ -match "^.[MD]" } | ForEach-Object { $_.Substring(3) }
    
    Write-Host "`n📁 待提交文件:" -ForegroundColor Yellow
    foreach ($file in $stagedFiles) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    }
    foreach ($file in $unstagedFiles) {
        Write-Host "  ⏳ $file (未暂存)" -ForegroundColor Gray
    }
    
    # 获取用户输入
    Write-Host "`n请输入提交信息 (直接回车查看建议): " -ForegroundColor Cyan -NoNewline
    $message = Read-Host
    
    if (-not $message) {
        # 自动分析文件生成建议
        $allFiles = $stagedFiles + $unstagedFiles
        $guessedType = Guess-CommitType "" $allFiles
        
        Write-Host "`n🤔 根据文件类型推测: [$guessedType]" -ForegroundColor Yellow
        
        $suggestion = Get-ImprovementSuggestion "" $guessedType $allFiles
        Write-Host $suggestion
        
        Write-Host "`n💡 提示: 复制上面的模板，填入具体内容后再次运行" -ForegroundColor Gray
    } else {
        # 分析用户输入
        $allFiles = $stagedFiles + $unstagedFiles
        $analysis = Analyze-MessageQuality $message $allFiles
        $type = Guess-CommitType $message $allFiles
        
        Write-Host "`n📊 质量评分: $($analysis.score)/100 (等级: $($analysis.grade))" -ForegroundColor $(
            if ($analysis.grade -eq "A") { "Green" } elseif ($analysis.grade -eq "B") { "Yellow" } else { "Red" }
        )
        
        if ($analysis.issues.Count -gt 0) {
            Write-Host "`n⚠️ 发现的问题:" -ForegroundColor Red
            foreach ($issue in $analysis.issues) {
                Write-Host "  - $issue" -ForegroundColor Red
            }
        }
        
        if ($analysis.suggestions.Count -gt 0) {
            Write-Host "`n💡 改进建议:" -ForegroundColor Yellow
            foreach ($suggestion in $analysis.suggestions) {
                Write-Host "  • $suggestion" -ForegroundColor Yellow
            }
        }
        
        if ($analysis.grade -ne "A") {
            Write-Host "`n📝 参考模板:" -ForegroundColor Cyan
            $improvement = Get-ImprovementSuggestion $message $type $allFiles
            Write-Host $improvement
        } else {
            Write-Host "`n✅ 提交信息质量优秀！" -ForegroundColor Green
        }
    }
}

# 检查最后一次提交
function Check-LastCommit($projectPath) {
    Set-Location $projectPath
    
    $lastCommit = git log -1 --pretty=format:"%H|%s|%b" 2>$null
    if (-not $lastCommit) {
        Write-Host "❌ 无法获取最后一次提交" -ForegroundColor Red
        return
    }
    
    $parts = $lastCommit.Split('|')
    $hash = $parts[0]
    $subject = $parts[1]
    $body = $parts[2]
    
    $files = git diff-tree --no-commit-id --name-only -r $hash 2>$null
    
    Write-Host "`n📋 最后一次提交分析" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "提交: $subject" -ForegroundColor White
    
    $analysis = Analyze-MessageQuality $subject $files
    $type = Guess-CommitType $subject $files
    
    Write-Host "`n推测类型: [$type]" -ForegroundColor Yellow
    Write-Host "质量评分: $($analysis.score)/100 (等级: $($analysis.grade))" -ForegroundColor $(
        if ($analysis.grade -eq "A") { "Green" } elseif ($analysis.grade -eq "B") { "Yellow" } else { "Red" }
    )
    
    if ($analysis.issues.Count -gt 0) {
        Write-Host "`n问题:" -ForegroundColor Red
        foreach ($issue in $analysis.issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    if ($analysis.suggestions.Count -gt 0) {
        Write-Host "`n建议:" -ForegroundColor Yellow
        foreach ($suggestion in $analysis.suggestions) {
            Write-Host "  • $suggestion" -ForegroundColor Yellow
        }
    }
}

# 主逻辑
if ($Interactive) {
    Run-InteractiveMode $ProjectPath
} elseif ($CheckLast) {
    Check-LastCommit $ProjectPath
} elseif ($Message) {
    # 分析提供的消息
    $analysis = Analyze-MessageQuality $Message $Files
    $type = Guess-CommitType $Message $Files
    
    Write-Host "`n📊 提交信息分析" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "原始信息: $Message" -ForegroundColor White
    Write-Host "推测类型: [$type]" -ForegroundColor Yellow
    Write-Host "质量评分: $($analysis.score)/100 (等级: $($analysis.grade))" -ForegroundColor $(
        if ($analysis.grade -eq "A") { "Green" } elseif ($analysis.grade -eq "B") { "Yellow" } else { "Red" }
    )
    
    if ($analysis.issues.Count -gt 0) {
        Write-Host "`n⚠️ 问题:" -ForegroundColor Red
        foreach ($issue in $analysis.issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    if ($analysis.suggestions.Count -gt 0) {
        Write-Host "`n💡 建议:" -ForegroundColor Yellow
        foreach ($suggestion in $analysis.suggestions) {
            Write-Host "  • $suggestion" -ForegroundColor Yellow
        }
    }
    
    $improvement = Get-ImprovementSuggestion $Message $type $Files
    Write-Host $improvement
} else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  .\commit-message-enhancer.ps1 -Interactive                    # 交互模式" -ForegroundColor White
    Write-Host "  .\commit-message-enhancer.ps1 -CheckLast                     # 检查最后一次提交" -ForegroundColor White
    Write-Host "  .\commit-message-enhancer.ps1 -Message '你的提交信息'          # 分析指定消息" -ForegroundColor White
}
