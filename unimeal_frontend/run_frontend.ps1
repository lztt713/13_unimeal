# run_frontend.ps1 - start the Vite frontend (opened by ..\run.ps1)
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir
Write-Host "Starting UniMeal frontend at http://127.0.0.1:5173 ..." -ForegroundColor Cyan
npm run dev
