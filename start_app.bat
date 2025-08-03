@echo off
echo 🚀 Starting Flutter EBook App with AI...

echo 📦 Installing Python dependencies...
pip install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

echo 🤖 Starting AI Server in background...
start /B python assistant.py

echo ⏳ Waiting for AI Server to start...
timeout /t 8 /nobreak > nul

echo 📱 Starting Flutter App...
echo 💡 AI Server will be automatically managed by Flutter
flutter run

echo ✅ App started successfully!
pause