# Smart Commit Classifier
# 智能提交分类器

param(
    [string]$ProjectPath = ".",
    [switch]$Analyze,      # 分析历史提交
    [switch]$Suggest,      # 建议更好的提交信息
    [string]$CommitMessage = "",
    [string[]]$ChangedFiles = @()
)

# 分类规则
$ClassificationRules = @{
    FEATURE = @{
        patterns = @(
            "^feat(
            "^feature[:\-]",
            "新增",
            "添加",
            "实现",
            "支持",
            "添加功能"
        )
        keywords = @("add", "implement", "support", "introduce", "create")
        color = "Green"
        icon = "✨"
    }
    BUGFIX = @{
        patterns = @(
            "^fix(
            "^bugfix[:\-]",
            "修复",
            "解决",
            "修正",
            "处理",
            "bug"
        )
        keywords = @("fix", "repair", "resolve", "correct", "handle")
        color = "Red"
        icon = "🐛"
    }
    REFACTOR = @{
        patterns = @(
            "^refactor(
            "^ref[:\-]",
            "重构",
            "优化",
            "改进",
            "简化",
            "清理"
        )
        keywords = @("refactor", "optimize", "improve", "simplify", "clean", "restructure")
        color = "Yellow"
        icon = "♻️"
    }
    DOCS = @{
        patterns = @(
            "^docs(
            "^doc[:\-]",
            "文档",
            "注释",
            "readme",
            "说明"
        )
        keywords = @("doc", "document", "comment", "readme", "guide")
        color = "Blue"
        icon = "📝"
    }
    TEST = @{
        patterns = @(
            "^test(
            "^tests(
            "测试",
            "单元测试",
            "测试用例"
        )
        keywords = @("test", "spec", "unit", "e2e", "coverage")
        color = "Cyan"
        icon = "🧪"
    }
    STYLE = @{
        patterns = @(
            "^style(
            "格式",
            "样式",
            "缩进",
            "空格"
        )
        keywords = @("style", "format", "indent", "whitespace", "lint")
        color = "Magenta"
        icon = "🎨"
    }
    CHORE = @{
        patterns = @(
            "^chore(
            "^build(
            "^ci(
            "构建",
            "配置",
            "依赖"
        )
        keywords = @("chore", "build", "ci", "config", "dependency", "package")
        color = "Gray"
        icon = "🔧"
    }
    PERF = @{
        patterns = @(
            "^perf(
            "^performance(
            "性能",
            "优化",
            "加速",
            "缓存"
        )
        keywords = @("perf", "performance", "speed", "fast", "cache", "optimize")
        color = "Green"
        icon = "⚡"
    }
}

# 根据提交信息分类
function Classify-Commit($message) {
    $messageLower = $message.ToLower()
    
    foreach ($category in $ClassificationRules.Keys) {
        $rules = $ClassificationRules[$category]
        
        # 检查正则模式
        foreach ($pattern in $rules.patterns) {
            if ($message -match $pattern) {
                return $category
            }
        }
        
        # 检查关键词
        foreach ($keyword in $rules.keywords) {
            if ($messageLower -contains $keyword -or $messageLower.StartsWith($keyword)) {
                return $category
            }
        }
    }
    
    return "OTHER"
}

# 根据文件类型分类
function Classify-ByFiles($files) {
    $categories = @{}
    
    foreach ($file in $files) {
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $filename = [System.IO.Path]::GetFileName($file).ToLower()
        
        # 测试文件
        if ($file -match "(test|spec|__tests__)" -or $ext -in @(".test.js", ".spec.js", ".test.ts", ".spec.ts")) {
            $categories["TEST"] = ($categories["TEST"] + 1)
        }
        # 文档文件
        elseif ($ext -in @(".md", ".txt", ".rst") -or $filename -in @("readme", "changelog", "license")) {
            $categories["DOCS"] = ($categories["DOCS"] + 1)
        }
        # 配置文件
        elseif ($ext -in @(".json", ".yml", ".yaml", ".xml", ".config.js", ".config.ts") -or 
                $filename -match "(config|setup|package|dockerfile|makefile)") {
            $categories["CHORE"] = ($categories["CHORE"] + 1)
        }
        # 样式文件
        elseif ($ext -in @(".css", ".scss", ".less", ".sass", ".styl")) {
            $categories["STYLE"] = ($categories["STYLE"] + 1)
        }
        # 源代码
        else {
            $categories["CODE"] = ($categories["CODE"] + 1)
        }
    }
    
    return $categories
}

# 分析提交质量
function Analyze-CommitQuality($message, $files) {
    $issues = @()
    $suggestions = @()
    
    # 检查提交信息长度
    if ($message.Length -lt 10) {
        $issues += "提交信息过短"
        $suggestions += "添加更详细的描述，说明做了什么以及为什么"
    }
    
    # 检查是否包含动词
    $verbs = @("add", "fix", "update", "remove", "refactor", "implement", "optimize", "create", "delete", "修改", "添加", "修复", "删除", "更新")
    $hasVerb = $verbs | Where-Object { $message.ToLower() -contains $_ }
    if (-not $hasVerb) {
        $suggestions += "使用动词开头，如 'Add', 'Fix', 'Update' 等"
    }
    
    # 检查文件数量
    if ($files.Count -gt 20) {
        $issues += "修改文件过多 ($($files.Count)个)"
        $suggestions += "考虑将大提交拆分为多个小提交"
    }
    
    # 检查是否混合了不同类型的修改
    $fileCategories = Classify-ByFiles $files
    if ($fileCategories.Count -gt 2) {
        $issues += "混合了多种类型的修改"
        $suggestions += "建议将代码、测试、文档分开提交"
    }
    
    return @{
        issues = $issues
        suggestions = $suggestions
        score = 100 - ($issues.Count * 20)
    }
}

# 建议更好的提交信息
function Suggest-BetterMessage($originalMessage, $category, $files) {
    $suggestions = @()
    
    # 根据分类建议格式
    switch ($category) {
        "FEATURE" {
            if ($originalMessage -notmatch "^feat(") {
                $suggestions += "feat: $originalMessage"
            }
        }
        "BUGFIX" {
            if ($originalMessage -notmatch "^fix(") {
                $suggestions += "fix: $originalMessage"
            }
        }
        "REFACTOR" {
            if ($originalMessage -notmatch "^refactor(") {
                $suggestions += "refactor: $originalMessage"
            }
        }
    }
    
    # 提取文件主要修改
    $mainFiles = $files | Select-Object -First 3 | ForEach-Object { 
        [System.IO.Path]::GetFileNameWithoutExtension($_