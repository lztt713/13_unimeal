# test.ps1 - run backend tests on MySQL
# Uses the password from .env when present; otherwise prompts for it at runtime.
# Run from the repo root in PowerShell:  .\test.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$root\unimeal_backend"
$python = Join-Path $root ".venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $python)) {
    throw "Python virtual environment not found: $python. Run .\setup.ps1 once from the project root first."
}

function Read-Password {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$hasTestDatabaseUrl = $false
if (Test-Path "$root\.env") {
    $hasTestDatabaseUrl = Select-String -Path "$root\.env" -Pattern '^\s*TEST_DATABASE_URL\s*=\s*\S+' -Quiet
}

if (-not $hasTestDatabaseUrl) {
    Write-Host "No TEST_DATABASE_URL found in .env. Enter the MySQL password for this run." -ForegroundColor Yellow
    $pw = Read-Password "MySQL root password"
    if (-not $pw) { Write-Host "No password entered. Aborted." -ForegroundColor Red; exit 1 }
    $pwEnc = [uri]::EscapeDataString($pw)
    $env:TEST_DATABASE_URL = "mysql+pymysql://root:$pwEnc@127.0.0.1:3306/unimeal_test?charset=utf8mb4"
} else {
    Write-Host "Using test database config from .env" -ForegroundColor DarkGray
}

Write-Host "Running tests against MySQL (unimeal_test) ..." -ForegroundColor Cyan
& $python -m unittest discover -s tests -v
exit $LASTEXITCODE
