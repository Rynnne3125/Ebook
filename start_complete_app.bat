@echo off
echo 🚀 Starting Complete EBook System with AI Assistant
echo ====================================================

echo 📦 Installing Python dependencies...
pip install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition requests python-dotenv

echo 📦 Installing Flutter dependencies...
flutter pub get

echo 🤖 Starting Integrated Backend Server...
start "EBook Backend" cmd /k "cd /d %~dp0 && python backend/app.py"

echo ⏳ Waiting for backend to start...
timeout /t 8 /nobreak >nul

echo 📱 Starting Flutter App...
echo 💡 Backend API: http://localhost:5001 (with AI Assistant integrated)
echo 💡 Flutter App: http://localhost:3000
echo 💡 All features: Voice Assistant, Teaching Scripts, Heyzine Flipbook
echo.
echo ✨ The app will auto-start the backend server when needed!
echo.

flutter run -d chrome --web-port=3000

echo.
echo ✅ App started successfully!
echo 💡 If you need to restart backend manually: python backend/app.py
echo.
echo 🌐 For production deployment:
echo 1. Run: deploy_render.bat (setup Render.com - FREE)
echo 2. Run: build_flutter_render.bat https://your-render-url
echo 3. Deploy frontend to Firebase/Netlify/Vercel
pause
pause
