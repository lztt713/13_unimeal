# run_backend.ps1 - start the FastAPI backend (opened by ..\run.ps1)
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir
Write-Host "Starting UniMeal backend at http://127.0.0.1:8000 ..." -ForegroundColor Cyan
python -m uvicorn app.main:app --reload --port 8000
