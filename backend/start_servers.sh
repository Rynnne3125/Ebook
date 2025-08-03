#!/bin/bash

echo "Starting Python AI Servers..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed or not in PATH"
    echo "Please install Python3"
    exit 1
fi

# Install Python dependencies if needed
echo "Installing Python dependencies..."
pip3 install flask flask-cors edge-tts google-generativeai python-dotenv requests

# Start assistant.py in background
echo "Starting assistant.py server..."
python3 assistant.py &
ASSISTANT_PID=$!

# Wait a moment for assistant.py to start
sleep 3

# Start app.py in background
echo "Starting app.py server..."
python3 app.py &
APP_PID=$!

# Wait a moment for servers to start
sleep 5

echo "Python servers started successfully!"
echo "Assistant PID: $ASSISTANT_PID"
echo "App PID: $APP_PID"
echo ""
echo "Starting Flutter app..."

# Start Flutter
flutter run -d chrome --web-port=3000

# Cleanup function
cleanup() {
    echo "Stopping Python servers..."
    kill $ASSISTANT_PID 2>/dev/null
    kill $APP_PID 2>/dev/null
    echo "Servers stopped."
}

# Set trap to cleanup on script exit
trap cleanup EXIT
