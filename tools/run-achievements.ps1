# UTF-8 Wrapper Script for Achievement System
# This script ensures proper UTF-8 encoding

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Set code page to UTF-8
chcp 65001 > $null

# Run the actual script
& "$PSScriptRoot\achievement-system-core.ps1" @args
