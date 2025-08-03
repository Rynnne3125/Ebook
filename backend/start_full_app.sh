#!/bin/bash
echo "🚀 Starting Complete EBook System..."

echo "📦 Installing Python dependencies for backend..."
cd backend
pip3 install -r requirements.txt
cd ..

echo "📦 Installing Python dependencies for AI assistant..."
pip3 install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

echo "🤖 Starting Backend API Server..."
python3 backend/app.py &

echo "🤖 Starting AI Assistant Server..."
python3 assistant.py &

echo "⏳ Waiting for servers to start..."
sleep 10

echo "📱 Installing Flutter dependencies..."
flutter pub get

echo "📱 Starting Flutter App..."
echo "💡 Backend API: http://localhost:5001"
echo "💡 AI Assistant: http://localhost:5000"
echo "💡 Flutter App will start shortly..."
flutter run

echo "✅ Complete system started successfully!"
