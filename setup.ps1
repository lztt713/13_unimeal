# setup.ps1 - one-time setup: apply DB scripts + install deps (asks for password)
# Run from the repo root in PowerShell:  .\setup.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# Masked password prompt (shows asterisks, returns plain text)
function Read-Password {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

Write-Host "========== UniMeal one-time setup ==========" -ForegroundColor Cyan

# 1. Locate the mysql client
$mysql = $null
if (Get-Command mysql -ErrorAction SilentlyContinue) { $mysql = "mysql" }
elseif (Test-Path "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe") { $mysql = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" }

if (-not $mysql) {
    Write-Warning "mysql client not found. Apply the SQL files in database/migrations manually."
} else {
    Write-Host "[1/3] Apply database scripts (schema + sample + ZZH migration)" -ForegroundColor Green
    $pw = Read-Password "MySQL root password"
    if (-not $pw) { Write-Host "No password entered. Aborted." -ForegroundColor Red; exit 1 }

    $sqlFiles = @(
        "$root\database\master_schema.sql",
        "$root\database\sample_data.sql",
        "$root\database\migrations\20260919_profile_and_notifications.sql",
        "$root\database\migrations\20260920_demo_recipe_data.sql",
        "$root\database\migrations\20260923_frontend_equipment_and_allergens.sql",
        "$root\database\migrations\20260927_allergy_warning_data.sql"
    )
    foreach ($sql in $sqlFiles) {
        Get-Content -Raw $sql | & $mysql "-uroot" "-p$pw"
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "DATABASE ERROR: the MySQL root password is wrong (access denied)." -ForegroundColor Red
            Write-Host "Ask Qichen Hu for the correct MySQL root password, then run .\setup.ps1 again." -ForegroundColor Yellow
            exit 1
        }
    }
    Write-Host "      database ready" -ForegroundColor Green
}

# 2. Backend dependencies
Write-Host "[2/3] Install backend deps (pip)" -ForegroundColor Green
Set-Location "$root\unimeal_backend"
python -m pip install -r requirements.txt

# 3. Frontend dependencies
Write-Host "[3/3] Install frontend deps (npm)" -ForegroundColor Green
Set-Location "$root\unimeal_frontend"
npm ci

Set-Location $root
Write-Host "========== Setup done. Run .\run.ps1 to start. ==========" -ForegroundColor Cyan
