@echo off
echo Starting Python AI Servers...

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed or not in PATH
    echo Please install Python and add it to PATH
    pause
    exit /b 1
)

REM Install Python dependencies if needed
echo Installing Python dependencies...
pip install flask flask-cors edge-tts google-generativeai python-dotenv requests

REM Start assistant.py in background
echo Starting assistant.py server...
start "AI Assistant Server" cmd /k "cd /d %~dp0 && python assistant.py"

REM Wait a moment for assistant.py to start
timeout /t 3 /nobreak >nul

REM Start app.py in background  
echo Starting app.py server...
start "AI App Server" cmd /k "cd /d %~dp0 && python app.py"

REM Wait a moment for servers to start
timeout /t 5 /nobreak >nul

echo Python servers started successfully!
echo You can now run: flutter run -d chrome --web-port=3000
echo.
echo Press any key to continue with Flutter...
pause >nul

REM Start Flutter
echo Starting Flutter app...
flutter run -d chrome --web-port=3000
