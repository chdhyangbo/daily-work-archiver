# Phase 7: Security & Privacy - Data Encryption Tool

param(
    [string]$Action = "encrypt",  # encrypt, decrypt
    [string]$InputPath = "",
    [string]$OutputPath = "",
    [string]$Password = ""
)

function Protect-SensitiveData($content) {
    # Pattern matching for sensitive data
    $patterns = @(
        @{ pattern = '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'; replacement = '[EMAIL_REDACTED]' },
        @{ pattern = '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'; replacement = '[CARD_REDACTED]' },
        @{ pattern = 'password\s*[:=]\s*\S+'; replacement = 'password: [REDACTED]' },
        @{ pattern = 'token\s*[:=]\s*\S+'; replacement = 'token: [REDACTED]' },
        @{ pattern = 'secret\s*[:=]\s*\S+'; replacement = 'secret: [REDACTED]' },
        @{ pattern = 'api[_-]?key\s*[:=]\s*\S+'; replacement = 'api_key: [REDACTED]' }
    )
    
    $sanitized = $content
    foreach ($pattern in $patterns) {
        $sanitized = $sanitized -replace $pattern.pattern, $pattern.replacement
    }
    
    return $sanitized
}

function Encrypt-File($inputPath, $outputPath, $password) {
    try {
        $content = Get-Content $inputPath -Raw -Encoding UTF8
        
        # Protect sensitive data first
        $sanitized = Protect-SensitiveData $content
        
        # Simple XOR encryption (for demonstration)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($sanitized)
        $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
        
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            $bytes[$i] = $bytes[$i] -bxor $keyBytes[$i % $keyBytes.Length]
        }
        
        [System.IO.File]::WriteAllBytes($outputPath, $bytes)
        Write-Host "File encrypted: $outputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Encryption failed: $_" -ForegroundColor Red
        return $false
    }
}

function Decrypt-File($inputPath, $outputPath, $password) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($inputPath)
        $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
        
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            $bytes[$i] = $bytes[$i] -bxor $keyBytes[$i % $keyBytes.Length]
        }
        
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        $content | Out-File $outputPath -Encoding UTF8
        Write-Host "File decrypted: $outputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Decryption failed: $_" -ForegroundColor Red
        return $false
    }
}

# Main logic
Write-Host "Data Security Tool" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

if ($Action -eq "encrypt") {
    if (-not $InputPath -or -not $OutputPath -or -not $Password) {
        Write-Host "Usage for encryption:" -ForegroundColor Yellow
        Write-Host "  .\security-tool.ps1 -Action encrypt -InputPath 'file.txt' -OutputPath 'file.enc' -Password 'yourpassword'" -ForegroundColor White
        exit
    }
    
    Encrypt-File $InputPath $OutputPath $Password
    
} elseif ($Action -eq "decrypt") {
    if (-not $InputPath -or -not $OutputPath -or -not $Password) {
        Write-Host "Usage for decryption:" -ForegroundColor Yellow
        Write-Host "  .\security-tool.ps1 -Action decrypt -InputPath 'file.enc' -OutputPath 'file.txt' -Password 'yourpassword'" -ForegroundColor White
        exit
    }
    
    Decrypt-File $InputPath $OutputPath $Password
    
} else {
    Write-Host "Unknown action: $Action" -ForegroundColor Red
    Write-Host "Use 'encrypt' or 'decrypt'" -ForegroundColor Yellow
}
