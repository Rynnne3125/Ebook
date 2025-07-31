@echo off
echo 🚀 Starting Complete EBook System...

echo 📦 Installing Python dependencies for backend...
cd backend
pip install -r requirements.txt
cd ..

echo 📦 Installing Python dependencies for AI assistant...
pip install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

echo 🤖 Starting Backend API Server...
start /B python backend/app.py

echo 🤖 Starting AI Assistant Server...
start /B python assistant.py

echo ⏳ Waiting for servers to start...
timeout /t 10 /nobreak > nul

echo 📱 Installing Flutter dependencies...
flutter pub get

echo 📱 Starting Flutter App...
echo 💡 Backend API: http://localhost:5001
echo 💡 AI Assistant: http://localhost:5000
echo 💡 Flutter App will start shortly...
flutter run

echo ✅ Complete system started successfully!
pause
