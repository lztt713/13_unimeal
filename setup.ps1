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

# Locate a working Python interpreter. Set UNIMEAL_PYTHON_EXE when Python is
# installed outside PATH.
$pythonExe = $null
$pythonArgs = @()
if ($env:UNIMEAL_PYTHON_EXE -and (Test-Path -LiteralPath $env:UNIMEAL_PYTHON_EXE)) {
    $pythonExe = $env:UNIMEAL_PYTHON_EXE
}
else {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        try {
            & $pythonCommand.Source -c "import sys" 2>$null
            if ($LASTEXITCODE -eq 0) { $pythonExe = $pythonCommand.Source }
        }
        catch {}
    }
    if (-not $pythonExe) {
        $pyCommand = Get-Command py -ErrorAction SilentlyContinue
        if ($pyCommand) {
            try {
                & $pyCommand.Source -3 -c "import sys" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $pythonExe = $pyCommand.Source
                    $pythonArgs = @("-3")
                }
            }
            catch {}
        }
    }
}
if (-not $pythonExe) {
    throw "A working Python 3 installation was not found. Install Python or set UNIMEAL_PYTHON_EXE."
}

# 1. Locate the mysql client. Set UNIMEAL_MYSQL_EXE when MySQL is installed elsewhere.
$mysql = $null
if ($env:UNIMEAL_MYSQL_EXE -and (Test-Path $env:UNIMEAL_MYSQL_EXE)) {
    $mysql = $env:UNIMEAL_MYSQL_EXE
}
elseif (Get-Command mysql -ErrorAction SilentlyContinue) {
    $mysql = "mysql"
}
else {
    $mysqlCandidates = @(
        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
        "D:\MYSQL\MySQL Server 8.0\bin\mysql.exe"
    )
    $mysql = $mysqlCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $mysql) {
    throw "MySQL client not found. Install MySQL 8, add mysql to PATH, or set UNIMEAL_MYSQL_EXE."
}

Write-Host "[1/3] Apply database scripts (schema + sample + current migrations)" -ForegroundColor Green
$pw = Read-Password "MySQL root password"
if (-not $pw) { Write-Host "No password entered. Aborted." -ForegroundColor Red; exit 1 }

$sqlFiles = @(
    "$root\database\master_schema.sql",
    "$root\database\sample_data.sql",
    "$root\database\migrations\20260823_frontend_alignment.sql",
    "$root\database\migrations\20260908_complete_recipe_details.sql",
    "$root\database\migrations\20260919_profile_and_notifications.sql",
    "$root\database\migrations\20260920_cooking_skill_recipe_matches.sql",
    "$root\database\migrations\20260920_demo_recipe_data.sql",
    "$root\database\migrations\20260920_recipe_images.sql",
    "$root\database\migrations\20260920_remove_comment_demo_prefix.sql",
    "$root\database\migrations\20260923_frontend_equipment_and_allergens.sql",
    "$root\database\migrations\20260927_allergy_warning_data.sql",
    "$root\database\migrations\20260929_add_15_student_recipes.sql",
    "$root\database\migrations\20260929_recipe_image_and_comment_completion.sql",
    "$root\database\migrations\20260930_distinct_student_recipes.sql"
)
foreach ($sql in $sqlFiles) {
    Get-Content -Raw $sql | & $mysql "-uroot" "-p$pw"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "DATABASE ERROR while applying: $sql" -ForegroundColor Red
        Write-Host "Check that MySQL is running and that the root password is correct." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "      database ready" -ForegroundColor Green

# 2. Backend virtual environment and dependencies
# run_backend.ps1 starts the backend from this root-level environment, so setup
# must create it instead of installing packages into the user's system Python.
Write-Host "[2/3] Create backend virtual environment and install dependencies" -ForegroundColor Green
$venvDir = Join-Path $root ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host "      creating .venv ..." -ForegroundColor DarkGray
    & $pythonExe @pythonArgs -m venv $venvDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $venvPython)) {
        throw "Could not create Python virtual environment: $venvDir"
    }
}
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r "$root\unimeal_backend\requirements.txt"
if ($LASTEXITCODE -ne 0) {
    throw "Backend dependency installation failed. Check your Python installation and internet connection."
}

# 3. Frontend dependencies
Write-Host "[3/3] Install frontend deps (npm)" -ForegroundColor Green
Set-Location "$root\unimeal_frontend"
npm ci

Set-Location $root
Write-Host "========== Setup done. Run .\run.ps1 to start. ==========" -ForegroundColor Cyan
