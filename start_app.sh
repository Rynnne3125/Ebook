#!/bin/bash
echo "🚀 Starting Flutter EBook App with AI..."

echo "📦 Installing Python dependencies..."
pip3 install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

echo "🤖 Starting AI Server..."
python3 assistant.py &

echo "⏳ Waiting for AI Server to start..."
sleep 5

echo "📱 Starting Flutter App..."
flutter run

echo "✅ App started successfully!"