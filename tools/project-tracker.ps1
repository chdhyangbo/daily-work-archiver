# Project Progress Tracker
# 项目进度追踪脚本

param(
    [string]$ProjectPath = ".",
    [string]$Action = "status",  # init, update, status, report
    [string]$MilestoneName = "",
    [int]$Progress = -1,
    [string]$Blocker = "",
    [string]$Risk = ""
)

# 配置文件路径
$configFile = Join-Path $ProjectPath ".project-config.yml"

# 初始化项目配置
function Initialize-Project {
    $projectName = Split-Path $ProjectPath -Leaf
    
    $config = @{
        project = $projectName
        created = (Get-Date -Format "yyyy-MM-dd")
        estimated_hours = 0
        actual_hours = 0
        status = "planning"
        milestones = @()
        blockers = @()
        risks = @()
    }
    
    Save-Config $config
    Write-Host "✅ 项目 '$projectName' 初始化完成" -ForegroundColor Green
    Write-Host "请编辑 $configFile 添加里程碑计划" -ForegroundColor Yellow
}

# 保存配置
function Save-Config($config) {
    $yaml = ConvertTo-Yaml $config
    $yaml | Out-File -FilePath $configFile -Encoding UTF8
}

# 读取配置
function Load-Config {
    if (-not (Test-Path $configFile)) {
        return $null
    }
    
    $content = Get-Content $configFile -Raw
    return ConvertFrom-Yaml $content
}

# 简单的YAML转换
function ConvertTo-Yaml($obj, $indent = 0) {
    $spaces = " " * $indent
    $yaml = ""
    
    foreach ($key in $obj.Keys) {
        $value = $obj[$key]
        
        if ($value -is [System.Collections.ArrayList] -or $value -is [Array]) {
            $yaml += "${spaces}${key}:`n"
            foreach ($item in $value) {
                if ($item -is [Hashtable] -or $item -is [System.Collections.Specialized.OrderedDictionary]) {
                    $yaml += "${spaces}-`n"
                    $yaml += ConvertTo-Yaml $item ($indent + 2)
                } else {
                    $yaml += "${spaces}- $item`n"
                }
            }
        } elseif ($value -is [Hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary]) {
            $yaml += "${spaces}${key}:`n"
            $yaml += ConvertTo-Yaml $value ($indent + 2)
        } else {
            $yaml += "${spaces}${key}: $value`n"
        }
    }
    
    return $yaml
}

# 简单的YAML解析
function ConvertFrom-Yaml($content) {
    $result = @{}
    $lines = $content -split "`n"
    $currentArray = $null
    $currentKey = $null
    $inArrayItem = $false
    $arrayItemData = @{}
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
            continue
        }
        
        # 检测数组项开始
        if ($trimmed -eq "-") {
            if ($inArrayItem -and $arrayItemData.Count -gt 0) {
                $currentArray += $arrayItemData
                $arrayItemData = @{}
            }
            $inArrayItem = $true
            continue
        }
        
        # 解析键值对
        if ($trimmed -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2]
            
            if ($inArrayItem) {
                $arrayItemData[$key] = $value
            } else {
                if ($value -eq "") {
                    # 可能是数组开始
                    $currentKey = $key
                    $currentArray = @()
                    $result[$key] = $currentArray
                } else {
                    $result[$key] = $value
                    $currentArray = $null
                }
            }
        }
    }
    
    # 处理最后一个数组项
    if ($inArrayItem -and $arrayItemData.Count -gt 0 -and $currentArray -ne $null) {
        $currentArray += $arrayItemData
    }
    
    return $result
}

# 计算项目进度
function Get-ProjectProgress($config) {
    if (-not $config.milestones -or $config.milestones.Count -eq 0) {
        return 0
    }
    
    $totalEstimated = 0
    $totalCompleted = 0
    
    foreach ($milestone in $config.milestones) {
        $estimated = [int]$milestone.estimated
        $completed = [int]$milestone.completed
        $totalEstimated += $estimated
        $totalCompleted += [Math]::Min($completed, $estimated)
    }
    
    if ($totalEstimated -eq 0) {
        return 0
    }
    
    return [Math]::Round(($totalCompleted / $totalEstimated) * 100)
}

# 显示项目状态
function Show-ProjectStatus($config) {
    if (-not $config) {
        Write-Host "❌ 未找到项目配置，请先运行: .\project-tracker.ps1 -Action init" -ForegroundColor Red
        return
    }
    
    $progress = Get-ProjectProgress $config
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  项目: $($config.project)" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "整体进度: $progress%" -ForegroundColor $(if ($progress -ge 80) { "Green" } elseif ($progress -ge 50) { "Yellow" } else { "Red" })
    Write-Host "状态: $($config.status)" -ForegroundColor Gray
    Write-Host ""
    
    if ($config.milestones -and $config.milestones.Count -gt 0) {
        Write-Host "里程碑:" -ForegroundColor Yellow
        foreach ($milestone in $config.milestones) {
            $mProgress = if ($milestone.estimated -gt 0) { 
                [Math]::Min(100, [Math]::Round(([int]$milestone.completed / [int]$milestone.estimated) * 100))
            } else { 0 }
            
            $statusIcon = switch ($milestone.status) {
                "done" { "✅" }
                "in_progress" { "🔄" }
                "blocked" { "⚠️" }
                default { "⏳" }
            }
            
            Write-Host "  $statusIcon $($milestone.name) - $mProgress% ($($milestone.completed)/$($milestone.estimated)h)" -ForegroundColor White
        }
    }
    
    if ($config.blockers -and $config.blockers.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️ 阻塞事项:" -ForegroundColor Red
        foreach ($blocker in $config.blockers) {
            Write-Host "  - $blocker" -ForegroundColor Red
        }
    }
    
    if ($config.risks -and $config.risks.Count -gt 0) {
        Write-Host ""
        Write-Host "🚨 风险:" -ForegroundColor Yellow
        foreach ($risk in $config.risks) {
            Write-Host "  - $risk" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
}

# 更新里程碑进度
function Update-Milestone($config, $name, $progress) {
    $found = $false
    
    for ($i = 0; $i -lt $config.milestones.Count; $i++) {
        if ($config.milestones[$i].name -eq $name) {
            $config.milestones[$i].completed = $progress
            $config.milestones[$i].status = if ($progress -ge $config.milestones[$i].estimated) { "done" } else { "in_progress" }
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "❌ 未找到里程碑: $name" -ForegroundColor Red
        return $false
    }
    
    Save-Config $config
    Write-Host "✅ 里程碑 '$name' 进度更新为 $progress" -ForegroundColor Green
    return $true
}

# 添加阻塞
function Add-Blocker($config, $description) {
    if (-not $config.blockers) {
        $config.blockers = @()
    }
    $config.blockers += $description
    Save-Config $config
    Write-Host "⚠️ 已添加阻塞: $description" -ForegroundColor Yellow
}

# 添加风险
function Add-Risk($config, $description) {
    if (-not $config.risks) {
        $config.risks = @()
    }
    $config.risks += $description
    Save-Config $config
    Write-Host "🚨 已添加风险: $description" -ForegroundColor Yellow
}

# 主逻辑
switch ($Action) {
    "init" {
        Initialize-Project
    }
    "status" {
        $config = Load-Config
        Show-ProjectStatus $config
    }
    "update" {
        $config = Load-Config
        if ($MilestoneName -and $Progress -ge 0) {
            Update-Milestone $config $MilestoneName $Progress
        }
        if ($Blocker) {
            Add-Blocker $config $Blocker
        }
        if ($Risk) {
            Add-Risk $config $Risk
        }
        Show-ProjectStatus $config
    }
    "report" {
        $config = Load-Config
        # 生成日报片段
        $progress = Get-ProjectProgress $config
        $report = @"
### 项目进度：$($config.project)
- **整体进度**: $progress%
- **状态**: $($config.status)
"@
        
        if ($config.milestones) {
            $currentMilestone = $config.milestones | Where-Object { $_.status -eq "in_progress" } | Select-Object -First 1
            if ($currentMilestone) {
                $mProgress = [Math]::Min(100, [Math]::Round(([int]$currentMilestone.completed / [int]$currentMilestone.estimated) * 100))
                $report += "
- **当前里程碑**: $($currentMilestone.name) ($mProgress%)"
            }
        }
        
        if ($config.blockers -and $config.blockers.Count -gt 0) {
            $report += "
- **阻塞**: $($config.blockers -join ', ')"
        }
        
        Write-Host $report
    }
    default {
        Write-Host "用法: .\project-tracker.ps1 -Action [init|status|update|report]" -ForegroundColor Yellow
    }
}
