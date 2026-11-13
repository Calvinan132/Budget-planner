@echo off
title Visual Flow & Health Monitor Runner
color 0b

echo ========================================================
echo    BUDGET PLANNER - VISUAL FLOW & HEALTH MONITOR
echo ========================================================
echo.

echo [1/2] Kiem tra Node.js environment...
set "PATH=C:\nvm4w\nodejs;%PATH%"

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Khong tim thay Node.js tai C:\nvm4w\nodejs!
    pause
    exit /b 1
)

echo [2/2] Khoi chay Web Dashboard tai http://localhost:3000 ...
cd /d "%~dp0flow-monitor-web"

if not exist node_modules (
    echo [INFO] Dang cai dat dependencies lan dau...
    call npm install
)

start http://localhost:3000
npm run dev

pause

