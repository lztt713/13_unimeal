param([int]$Port = 8000, [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$env:PYTHONUTF8 = '1'
if (!(Test-Path -LiteralPath '.env')) {
    Copy-Item -LiteralPath '.env.example' -Destination '.env'
    throw 'Fill in DB_PASSWORD in the project .env, then run this script again.'
}
$projectPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (!(Test-Path -LiteralPath $projectPython)) {
    $systemPython = Get-Command python -ErrorAction SilentlyContinue
    if ($systemPython) { & $systemPython.Source -m venv .venv }
    else {
        $bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
        if (!(Test-Path -LiteralPath $bundledPython)) { throw 'Install Python 3.12 or newer, then try again.' }
        & $bundledPython -m venv .venv
    }
    if ($LASTEXITCODE -ne 0) { throw 'Could not create Python environment.' }
}
& $projectPython -m pip install -r unimeal_backend/requirements.txt --disable-pip-version-check
if ($LASTEXITCODE -ne 0) { throw 'Backend dependency installation failed.' }
& $projectPython -c "from pathlib import Path; from dotenv import dotenv_values; import secrets; p=Path('.env'); values=dotenv_values(p); p.open('a',encoding='utf-8').write('\nSESSION_SECRET='+secrets.token_urlsafe(48)+'\n') if not values.get('SESSION_SECRET') else None"
& $projectPython unimeal_backend/check_database.py
if ($LASTEXITCODE -ne 0) { throw 'Database check failed. Check MySQL and the project .env.' }
if (!$SkipBuild) {
    Push-Location unimeal_frontend
    try {
        if (!(Test-Path node_modules)) {
            & npm.cmd ci --no-audit --no-fund
            if ($LASTEXITCODE -ne 0) { throw 'Frontend dependency installation failed.' }
        }
        & npm.cmd run build
        if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
    } finally { Pop-Location }
}
if (!(Test-Path 'unimeal_frontend/dist/index.html')) { throw 'No frontend build. Run without -SkipBuild.' }
Write-Host "UniMeal: http://127.0.0.1:$Port  (Ctrl+C to stop)"
& $projectPython -m uvicorn app.main:app --app-dir unimeal_backend --host 127.0.0.1 --port $Port
