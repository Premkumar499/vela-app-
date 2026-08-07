@echo off
REM ERP Billing System - Start Script (Windows)
REM This script starts both backend and frontend servers

echo ==========================================
echo   Starting ERP Billing System
echo ==========================================
echo.

REM Start Backend (Flask)
echo Starting Backend (Flask) on port 5000...
start "Backend-Flask" cmd /k "cd billing_system\backend && python app.py"

REM Wait a moment for backend to start
timeout /t 2 /nobreak >nul

REM Start Frontend (Flutter)
echo Starting Frontend (Flutter)...
start "Frontend-Flutter" cmd /k "cd billing_system\frontend\flutter_application && flutter run -d chrome"

echo.
echo ==========================================
echo   Both servers started!
echo ==========================================
echo Backend: http://localhost:5000
echo Frontend: Will open in Chrome
echo.
echo Close the terminal windows to stop servers
echo ==========================================
