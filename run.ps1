# run.ps1 - start backend + frontend
# Uses the password from .env when present; otherwise prompts for it at runtime
# (the password is then passed in memory only, never written to disk).
# Run from the repo root in PowerShell:  .\run.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Read-Password {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

if (-not (Test-Path "$root\.env")) {
    Write-Host "No .env file found. Enter the MySQL password for this run." -ForegroundColor Yellow
    $pw = Read-Password "MySQL root password"
    if (-not $pw) { Write-Host "No password entered. Aborted." -ForegroundColor Red; exit 1 }
    $pwEnc = [uri]::EscapeDataString($pw)
    $env:DATABASE_URL = "mysql+pymysql://root:$pwEnc@127.0.0.1:3306/unimeal_planner?charset=utf8mb4"
} else {
    Write-Host "Using database config from .env" -ForegroundColor DarkGray
}

Write-Host "========== Starting UniMeal ==========" -ForegroundColor Cyan

Write-Host "Opening backend window..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit","-File","$root\unimeal_backend\run_backend.ps1"

Write-Host "Opening frontend window..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit","-File","$root\unimeal_frontend\run_frontend.ps1"

Write-Host ""
Write-Host "Two windows opened:"
Write-Host "  frontend  http://127.0.0.1:5173" -ForegroundColor Yellow
Write-Host "  backend   http://127.0.0.1:8000  (Swagger: /docs, health: /api/health)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening your browser to the website..." -ForegroundColor Green
Start-Sleep -Seconds 5
Start-Process "http://127.0.0.1:5173"
Write-Host "Stop: press Ctrl+C in each window, or just close them." -ForegroundColor DarkGray
