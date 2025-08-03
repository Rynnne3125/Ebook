# Use Python 3.11 slim image
FROM python:3.11-slim

# Install system dependencies for pdf2image
RUN apt-get update && apt-get install -y \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/ ./backend/
COPY . .

# Expose port
EXPOSE 5001

# Set environment variables
ENV FLASK_APP=backend/app.py
ENV FLASK_ENV=production

# Run the application
CMD ["python", "backend/app.py"]
