#!/bin/bash
echo "🚀 Starting Flutter EBook App with AI..."

echo "📦 Installing Python dependencies..."
pip3 install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

echo "🤖 Starting AI Server in background..."
python3 assistant.py &

echo "⏳ Waiting for AI Server to start..."
sleep 8

echo "📱 Starting Flutter App..."
echo "💡 AI Server will be automatically managed by Flutter"
flutter run

echo "✅ App started successfully!"