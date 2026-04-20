# Duplicate Work Detector
# 重复工作检测器 - 检测是否写过类似代码或解决过类似问题

param(
    [string]$ProjectPath = ".",
    [string]$SearchPattern = "",
    [string]$FileExtension = "",
    [switch]$CheckCurrentChanges,  # 检查当前修改
    [switch]$BuildIndex            # 构建代码索引
)

# 索引文件路径
$indexDir = Join-Path $PSScriptRoot ".." "work-archive" "data" "code-index"
$indexFile = Join-Path $indexDir "code-index.json"

# 确保索引目录存在
if (-not (Test-Path $indexDir)) {
    New-Item -ItemType Directory -Path $indexDir -Force | Out-Null
}

# 代码片段结构
class CodeSnippet {
    [string]$hash
    [string]$content
    [string]$filePath
    [string]$project
    [string]$commitHash
    [DateTime]$commitDate
    [string]$commitMessage
    [int]$lineStart
    [int]$lineEnd
}

# 计算代码指纹（简化版SimHash）
function Get-CodeFingerprint($content) {
    # 规范化代码
    $normalized = $content.ToLower()
    # 移除多余空白
    $normalized = $normalized -replace "\s+", " "
    # 移除注释（简化处理）
    $normalized = $normalized -replace "//.*?($|\r|\n)", ""
    $normalized = $normalized -replace "/\*.*?\*/", ""
    
    # 计算简单哈希
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes))
    return $hash.Replace("-", "").Substring(0, 16)
}

# 计算相似度（简化版）
function Get-Similarity($content1, $content2) {
    # 规范化
    $norm1 = ($content1.ToLower() -replace "\s+", " ").Trim()
    $norm2 = ($content2.ToLower() -replace "\s+", " ").Trim()
    
    # 如果完全相同
    if ($norm1 -eq $norm2) {
        return 100
    }
    
    # 计算Levenshtein距离（简化版）
    $len1 = $norm1.Length
    $len2 = $norm2.Length
    
    if ($len1 -eq 0 -or $len2 -eq 0) {
        return 0
    }
    
    # 使用简单的字符匹配率
    $matches = 0
    $minLen = [Math]::Min($len1, $len2)
    $maxLen = [Math]::Max($len1, $len2)
    
    for ($i = 0; $i -lt $minLen; $i++) {
        if ($norm1[$i] -eq $norm2[$i]) {
            $matches++
        }
    }
    
    return [Math]::Round(($matches / $maxLen) * 100)
}

# 从Git历史中提取代码片段
function Extract-CodeSnippets($projectPath) {
    $snippets = @()
    
    Set-Location $projectPath
    
    # 获取所有提交
    $commits = git log --all --author="yangbo" --pretty=format:"%H|%ad|%s" --date=format:"%Y-%m-%d" 2>$null
    
    if (-not $commits) {
        return $snippets
    }
    
    $commitList = $commits -split "`n" | Where-Object { $_ } | Select-Object -First 50  # 限制最近50个提交
    
    foreach ($commitInfo in $commitList) {
        $parts = $commitInfo.Split('|')
        $commitHash = $parts[0]
        $commitDate = $parts[1]
        $commitMessage = $parts[2]
        
        # 获取修改的文件
        $files = git diff-tree --no-commit-id --name-only -r $commitHash 2>$null
        
        foreach ($file in $files) {
            # 只处理代码文件
            if ($file -notmatch "\.(js|ts|java|py|go|cpp|c|h|vue|jsx|tsx)$") {
                continue
            }
            
            # 获取文件内容
            $content = git show "$commitHash:$file" 2>$null
            if (-not $content) { continue }
            
            # 提取函数/类级别的代码块
            $lines = $content -split "`n"
            $currentBlock = @()
            $inBlock = $false
            $blockStart = 0
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                
                # 检测函数/类/方法开始（简化检测）
                if ($line -match "^(function|class|def|const|let|var|public|private|protected)\s+\w+" -or
                    $line -match "^\s*(async\s+)?function\s*\w*\s*\(" -or
                    $line -match "^\s*\w+\s*[=:]\s*function\s*\(" -or
                    $line -match "^\s*\w+\s*\([^)]*\)\s*[{=]" -or
                    $line -match "^\s*(methods?|computed|watch|mounted|created)\s*\(\)") {
                    
                    # 保存之前的代码块
                    if ($currentBlock.Count -gt 5) {
                        $snippet = @{
                            hash = Get-CodeFingerprint ($currentBlock -join "`n")
                            content = $currentBlock -join "`n"
                            filePath = $file
                            project = Split-Path $projectPath -Leaf
                            commitHash = $commitHash
                            commitDate = $commitDate
                            commitMessage = $commitMessage
                            lineStart = $blockStart
                            lineEnd = $i - 1
                        }
                        $snippets += $snippet
                    }
                    
                    # 开始新代码块
                    $currentBlock = @($line)
                    $inBlock = $true
                    $blockStart = $i
                } elseif ($inBlock) {
                    $currentBlock += $line
                    
                    # 检测代码块结束（简化：遇到空行且缩进减少）
                    if ($line -match "^\}" -and $currentBlock.Count -gt 10) {
                        $snippet = @{
                            hash = Get-CodeFingerprint ($currentBlock -join "`n")
                            content = $currentBlock -join "`n"
                            filePath = $file
                            project = Split-Path $projectPath -Leaf
                            commitHash = $commitHash
                            commitDate = $commitDate
                            commitMessage = $commitMessage
                            lineStart = $blockStart
                            lineEnd = $i
                        }
                        $snippets += $snippet
                        
                        $currentBlock = @()
                        $inBlock = $false
                    }
                }
            }
        }
    }
    
    return $snippets
}

# 构建代码索引
function Build-CodeIndex($projectPaths) {
    Write-Host "正在构建代码索引..." -ForegroundColor Yellow
    
    $allSnippets = @()
    
    foreach ($path in $projectPaths) {
        if (-not (Test-Path $path)) { continue }
        
        Write-Host "  扫描: $path" -ForegroundColor Gray
        
        # 获取所有Git仓库
        $gitDirs = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                   Where-Object { $_.PSIsContainer -and $_.Name -eq '.git' }
        
        foreach ($gitDir in $gitDirs) {
            $projectPath = $gitDir.Parent.FullName
            $snippets = Extract-CodeSnippets $projectPath
            $allSnippets += $snippets
            Write-Host "    找到 $($snippets.Count) 个代码片段" -ForegroundColor Gray
        }
    }
    
    # 保存索引
    $index = @{
        lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        totalSnippets = $allSnippets.Count
        snippets = $allSnippets
    }
    
    $index | ConvertTo-Json -Depth 10 | Out-File $indexFile -Encoding UTF8
    
    Write-Host "✅ 索引构建完成: $($allSnippets.Count) 个代码片段" -ForegroundColor Green
}

# 搜索相似代码
function Search-SimilarCode($pattern, $threshold = 70) {
    if (-not (Test-Path $indexFile)) {
        Write-Host "❌ 代码索引不存在，请先运行 -BuildIndex" -ForegroundColor Red
        return @()
    }
    
    $index = Get-Content $indexFile | ConvertFrom-Json
    $patternHash = Get-CodeFingerprint $pattern
    $patternNorm = ($pattern.ToLower() -replace "\s+", " ").Trim()
    
    $matches = @()
    
    foreach ($snippet in $index.snippets) {
        # 快速过滤：哈希前缀匹配
        if ($snippet.hash.Substring(0, 8) -eq $patternHash.Substring(0, 8)) {
            $similarity = 100
        } else {
            # 计算相似度
            $similarity = Get-Similarity $pattern $snippet.content
        }
        
        if ($similarity -ge $threshold) {
            $matches += @{
                snippet = $snippet
                similarity = $similarity
            }
        }
    }
    
    # 按相似度排序
    return $matches | Sort-Object similarity -Descending
}

# 检查当前修改
function Check-CurrentChanges($projectPath) {
    Set-Location $projectPath
    
    $diff = git diff --cached 2>$null
    if (-not $diff) {
        $diff = git diff 2>$null
    }
    
    if (-not $diff) {
        Write-Host "✅ 没有待检测的修改" -ForegroundColor Green
        return
    }
    
    Write-Host "`n🔍 检查当前修改中的重复代码..." -ForegroundColor Yellow
    
    # 解析diff，提取新增代码
    $lines = $diff -split "`n"
    $currentBlock = @()
    $inAddition = $false
    $currentFile = ""
    
    $potentialDuplicates = @()
    
    foreach ($line in $lines) {
        if ($line -match "^\+\+\+ b/(.+)$") {
            $currentFile = $matches[1]
        } elseif ($line -match "^@@") {
            # 检查之前的代码块
            if ($currentBlock.Count -gt 5) {
                $blockContent = ($currentBlock -join "`n").Substring(1)  # 移除开头的+
                $similar = Search-SimilarCode $blockContent 60
                
                if ($similar.Count -gt 0) {
                    $potentialDuplicates += @{
                        file = $currentFile
                        content = $blockContent
                        matches = $similar | Select-Object -First 3
                    }
                }
            }
            
            $currentBlock = @()
        } elseif ($line -match "^(\+[^+]|\+.+)") {
            $currentBlock += $line
        }
    }
    
    # 显示结果
    if ($potentialDuplicates.Count -eq 0) {
        Write-Host "✅ 未发现明显的重复代码" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ 发现 $($potentialDuplicates.Count) 处潜在重复:" -ForegroundColor Yellow
        
        foreach ($dup in $potentialDuplicates) {
            Write-Host "`n📁 文件: $($dup.file)" -ForegroundColor Cyan
            Write-Host "📝 新代码:" -ForegroundColor White
            Write-Host ($dup.content.Split("`n") | Select-Object -First 5 | ForEach-Object { "  $_" }) -ForegroundColor Gray
            
            Write-Host "`n🔍 相似代码:" -ForegroundColor Yellow
            foreach ($match in $dup.matches) {
                Write-Host "  相似度: $($match.similarity)%" -ForegroundColor $(
                    if ($match.similarity -ge 90) { "Red" } else { "Yellow" }
                )
                Write-Host "  项目: $($match.snippet.project)" -ForegroundColor Gray
                Write-Host "  文件: $($match.snippet.filePath)" -ForegroundColor Gray
                Write-Host "  提交: $($match.snippet.commitMessage)" -ForegroundColor Gray
                Write-Host "  日期: $($match.snippet.commitDate)" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
}

# 主逻辑
if ($BuildIndex) {
    $projectPaths = @("D:\work\code", "D:\work\codepos")
    Build-CodeIndex $projectPaths
} elseif ($CheckCurrentChanges) {
    Check-CurrentChanges $ProjectPath
} elseif ($SearchPattern) {
    Write-Host "`n🔍 搜索相似代码..." -ForegroundColor Yellow
    Write-Host "搜索内容: $SearchPattern`n" -ForegroundColor Gray
    
    $matches = Search-SimilarCode $SearchPattern
    
    if ($matches.Count -eq 0) {
        Write-Host "未找到相似代码" -ForegroundColor Gray
    } else {
        Write-Host "找到 $($matches.Count) 个相似代码:`n" -ForegroundColor Green
        
        foreach ($match in $matches | Select-Object -First 5) {
            Write-Host "相似度: $($match.similarity)%" -ForegroundColor $(
                if ($match.similarity -ge 90) { "Red" } elseif ($match.similarity -ge 70) { "Yellow" } else { "Gray" }
            )
            Write-Host "项目: $($match.snippet.project)" -ForegroundColor Cyan
            Write-Host "文件: $($match.snippet.filePath)" -ForegroundColor White
            Write-Host "提交: $($match.snippet.commitMessage)" -ForegroundColor Gray
            Write-Host "日期: $($match.snippet.commitDate)" -ForegroundColor Gray
            Write-Host "代码片段:" -ForegroundColor Gray
            Write-Host ($match.snippet.content.Split("`n") | Select-Object -First 10 | ForEach-Object { "  $_" }) -ForegroundColor DarkGray
            Write-Host "---`n"
        }
    }
} else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  .\duplicate-work-detector.ps1 -BuildIndex                    # 构建代码索引" -ForegroundColor White
    Write-Host "  .\duplicate-work-detector.ps1 -CheckCurrentChanges           # 检查当前修改" -ForegroundColor White
    Write-Host "  .\duplicate-work-detector.ps1 -SearchPattern '代码内容'       # 搜索相似代码" -ForegroundColor White
}
