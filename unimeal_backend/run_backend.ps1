# run_backend.ps1 - start the FastAPI backend
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir

$python = Join-Path $dir "..\.venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $python)) {
    throw "Python virtual environment not found: $python"
}

Write-Host "Starting UniMeal backend at http://127.0.0.1:8000 ..." -ForegroundColor Cyan
& $python -m uvicorn app.main:app --reload --port 8000